"""Does every hall room draw the SAME PICTURE on Gold and on Crystal?

    python tests/engine_parity_check.py

Each room ships two composed variants, one per engine, built from that
game's own tileset -- which is right, because the two games number their
tileset blocks differently. What that cannot fix is a room built out of a
block whose Gold definition is different ART. The composition succeeds, no
check complains, and the room simply looks wrong on Gold and Silver.

Found by rendering the shipped data on both engines and looking: Blackthorn's
lobby desk is a wooden counter on Crystal and a row of black gaps on Gold,
because TILESET_FACILITY has 48 of its 128 blocks redrawn between the two.
Goldenrod and Ecruteak are pixel-identical on both, so this is a property of
which blocks a room happens to use, not of the pipeline.

Two things are checked, and only one of them is a judgement call.

OUT OF RANGE is a hard failure. Gold's sheets are 128x48 -- 96 tiles, ids
0..95 -- where Crystal's are 128x128 with 256. A block above Gold's range
carries junk tile numbers in Gold's own data, so a room painted out of one
composes to tiles that do not exist and draws as black gaps. That is what
Blackthorn's desk did: TILESET_FACILITY blocks 96, 97 and 100 are real
furniture on Crystal and out-of-range junk on Gold.

DIFFERS is reported, not failed: the same block drawn from a different tile
is often just a palette change between the two games (Cianwood's table is
blue on Crystal and pink on Gold, and both read as a table).
"""
import os
import re
import subprocess
import sys

here = os.path.dirname(os.path.abspath(__file__))
main_lua = os.path.join(here, "..", "main.lua")
LUA = os.environ.get("MODKIT_LUAJIT") or \
    r"C:\Users\dwitt\AppData\Local\Programs\LuaJIT\bin\luajit.exe"

SCRIPT = r"""
local src = io.open(arg[1]):read("*a")
local i = src:find("local KC_HALLS = {", 1, true)
local j = src:find("\n}\n", i, true)
local H = assert(load("return " .. src:sub(i + #"local KC_HALLS = ", j + 1)))()
for town, hall in pairs(H) do
  for which, def in pairs(hall) do
    if type(def) == "table" and def.tiles and def.blocks then
      -- a tile id the variant's own sheet does not contain
      for engine, v in pairs(def.tiles.variants) do
        local tiles = math.floor(v.imageWidth / 8) * math.floor(v.imageHeight / 8)
        for y = 0, def.height * 2 - 1 do
          for x = 0, def.width * 2 - 1 do
            local id = def.blocks[math.floor(y / 2) * def.width + math.floor(x / 2) + 1]
            local b = v.blocks[id + 1]
            local worst = -1
            if b then
              for ty = 0, 1 do
                for tx = 0, 1 do
                  local k = ((y % 2) * 2 + ty) * 4 + (x % 2) * 2 + tx + 1
                  if (b[k] or 0) >= tiles and (b[k] or 0) > worst then worst = b[k] end
                end
              end
            end
            if worst >= 0 then
              print(("RANGE\t%s\t%s\t%s\t%d\t%d\t%d\t%d")
                :format(town, which, engine, x, y, worst, tiles))
            end
          end
        end
      end
      local gs, cr = def.tiles.variants.gs, def.tiles.variants.crystal
      if gs and cr then
        for y = 0, def.height * 2 - 1 do
          for x = 0, def.width * 2 - 1 do
            local id = def.blocks[math.floor(y / 2) * def.width + math.floor(x / 2) + 1]
            local a, b = gs.blocks[id + 1], cr.blocks[id + 1]
            local same = true
            if not (a and b) then same = false else
              -- the cell is one quadrant: a 2x2 corner of the 4x4 block
              for ty = 0, 1 do
                for tx = 0, 1 do
                  local k = ((y % 2) * 2 + ty) * 4 + (x % 2) * 2 + tx + 1
                  if a[k] ~= b[k] then same = false end
                end
              end
            end
            if not same then
              print(("DIFF\t%s\t%s\t%d\t%d"):format(town, which, x, y))
            end
          end
        end
        print(("ROOM\t%s\t%s\t%d\t%d"):format(town, which, def.width * 2, def.height * 2))
      end
    end
  end
end
"""

tmp = os.path.join(here, "_parity_dump.lua")
open(tmp, "w", encoding="utf-8").write(SCRIPT)
try:
    out = subprocess.run([LUA, tmp, main_lua], capture_output=True, text=True)
finally:
    os.remove(tmp)
if out.returncode != 0:
    print("could not read KC_HALLS:", out.stderr.strip() or out.stdout.strip())
    sys.exit(2)

rooms, diffs, oor = {}, {}, {}
for line in out.stdout.splitlines():
    p = line.split("\t")
    if p[0] == "ROOM":
        rooms[(p[1], p[2])] = int(p[3]) * int(p[4])
    elif p[0] == "DIFF":
        diffs.setdefault((p[1], p[2]), []).append((int(p[3]), int(p[4])))
    elif p[0] == "RANGE":
        oor.setdefault((p[1], p[2], p[3]), []).append(
            (int(p[4]), int(p[5]), int(p[6]), int(p[7])))

bad = 0
for key in sorted(oor):
    town, which, engine = key
    cells = oor[key]
    tiles = cells[0][3]
    where = ", ".join(f"({x},{y})" for x, y, _t, _n in cells[:12])
    more = "" if len(cells) <= 12 else f" and {len(cells) - 12} more"
    top = max(t for _x, _y, t, _n in cells)
    print(f"FAIL  {town} {which} ({engine}): {len(cells)} cell(s) use tile {top}, "
          f"but this engine's sheet holds {tiles} -- they draw as black gaps. "
          f"{where}{more}")
    bad += 1

total = 0
for key in sorted(rooms):
    town, which = key
    cells = diffs.get(key, [])
    total += len(cells)
    if not cells:
        print(f"{town} {which}: identical on Gold and Crystal ({rooms[key]} cells)")
        continue
    where = ", ".join(f"({x},{y})" for x, y in cells[:12])
    more = "" if len(cells) <= 12 else f" and {len(cells) - 12} more"
    print(f"DIFFERS  {town} {which}: {len(cells)} of {rooms[key]} cells draw "
          f"differently on Gold -- {where}{more}")

print(f"{total} cell(s) differ between the engines; {bad} room(s) draw out-of-range tiles")
sys.exit(1 if bad else 0)
