"""Guard the border rule for every hall room.

    python tests/room_border_check.py

THE BORDER BUG, which this project has hit on every hand-painted room at
least once. Block id 0 in a map grid does not mean "tileset block 0" -- the
engine reads it as "draw the map header's border block", the thing painted
OUTSIDE the room (engine BorderFill.blockFor). So each composed room reserves
index 0 for that surround, and real blocks start at 1.

Two ways it goes wrong, and both have shipped:

  * a grid cell holds 0, and that row of the room renders as void
    (v0.18.1: "five builds of the void is still there");
  * index 0 holds a REAL block instead of a flat one, and the surround
    draws a fragment of wall tiling away in every direction. That is what
    0.34.40's read-back did to Ecruteak: it copied the first composed block
    into index 0 rather than a solid one.

So this asserts, for every room in KC_HALLS and every engine variant:

  1. index 0 is FLAT -- all sixteen tiles the same -- like Goldenrod's
     (mart tile 16) and Ecruteak's (traditional-house tile 5), both of
     which are the sheet's solid black;
  2. no map grid contains 0;
  3. every grid index is inside that room's block list;
  4. the grid has exactly width x height entries.

Pure text/Lua parsing of main.lua -- no game cache needed, so it runs
anywhere.
"""
import os
import re
import subprocess
import sys

here = os.path.dirname(os.path.abspath(__file__))
main_lua = os.path.join(here, "..", "main.lua")

LUA = os.environ.get("MODKIT_LUAJIT") or r"C:\Users\dwitt\AppData\Local\Programs\LuaJIT\bin\luajit.exe"
SCRIPT = r"""
local src = io.open(arg[1]):read("*a")
local i = src:find("local KC_HALLS = {", 1, true)
local j = src:find("\n}\n", i, true)
local H = assert(load("return " .. src:sub(i + #"local KC_HALLS = ", j + 1)))()
for town, rooms in pairs(H) do
  for which, d in pairs(rooms) do
    if type(d) == "table" and d.blocks and d.tiles then
      for engine, v in pairs(d.tiles.variants or {}) do
        local b0 = v.blocks[1]
        local flat = true
        for k = 2, 16 do if b0[k] ~= b0[1] then flat = false end end
        print(("VARIANT\t%s\t%s\t%s\t%s\t%d"):format(
          town, which, engine, tostring(flat), #v.blocks))
      end
      local lo, hi = math.huge, -math.huge
      for _, id in ipairs(d.blocks) do
        lo, hi = math.min(lo, id), math.max(hi, id)
      end
      print(("GRID\t%s\t%s\t%d\t%d\t%d\t%d"):format(
        town, which, #d.blocks, d.width * d.height, lo, hi))
    end
  end
end
"""

tmp = os.path.join(here, "_border_dump.lua")
open(tmp, "w", encoding="utf-8").write(SCRIPT)
try:
    out = subprocess.run([LUA, tmp, main_lua], capture_output=True, text=True)
finally:
    os.remove(tmp)
if out.returncode != 0:
    print("could not read KC_HALLS:", out.stderr.strip() or out.stdout.strip())
    sys.exit(2)

bad = 0
sizes = {}
for line in out.stdout.splitlines():
    parts = line.split("\t")
    if parts[0] == "VARIANT":
        _, town, which, engine, flat, count = parts
        sizes[(town, which, engine)] = int(count)
        if flat != "true":
            print(f"FAIL {town} {which} ({engine}): block 0 is not flat -- the "
                  f"surround will draw a fragment of the room")
            bad += 1
    elif parts[0] == "GRID":
        _, town, which, n, expect, lo, hi = parts
        n, expect, lo, hi = int(n), int(expect), int(lo), int(hi)
        if n != expect:
            print(f"FAIL {town} {which}: grid has {n} cells, room is {expect}")
            bad += 1
        if lo < 1:
            print(f"FAIL {town} {which}: grid contains {lo} -- 0 is the border "
                  f"block, so that cell renders as void")
            bad += 1
        for (t, w, engine), count in sizes.items():
            if t == town and w == which and hi >= count:
                print(f"FAIL {town} {which} ({engine}): grid uses block {hi} but "
                      f"the list has {count} (ids 0..{count - 1})")
                bad += 1
        print(f"{town} {which}: {n} cells, block ids {lo}..{hi}, index 0 flat")

print(f"{bad} problem(s)")
sys.exit(1 if bad else 0)
