-- Read a room back out of the Content Editor and check it before it is
-- transplanted into main.lua.
--
--   1. developer paints in the editor (see CANDIDATES below) and Saves
--   2. this reads editor_project.lua back, recovers each room as VANILLA
--      block ids, and walks the geometry against the real imported cache
--   3. only then does the layout go into KC_HALLS
--
-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/read_editor_layout.lua
--   luajit ../Kanto-Contests/tests/read_editor_layout.lua GOLDENROD_CITY
--
-- WHY THE BACK-MAPPING EXISTS
--
-- Opening a map in the editor's painter converts it to a LAYERED map: it
-- composites a private tileset PNG out of the tiles in use and repoints
-- the map at it, so `maps.X.tileset` becomes e.g.
-- KC_LAYOUT_..._LAYERED and `blocks` becomes indices into that.
--
-- We can never ship that. The composited PNG is built from the player's
-- own ROM tiles, and this mod's standing rule is that no ROM-derived art
-- is redistributed (THIRD_PARTY_NOTICES: "no assets or data from those
-- games are included").
--
-- We do not have to. Each painted cell records where it came from --
-- `{ source = "@runtime:TILESET_MART", tile = N }` -- and N is
-- `vanillaBlockId * 4 + quadrant` (quadrants 0..3 = TL, TR, BL, BR;
-- a cell is one quarter of a block). So a block stamped whole reverses
-- exactly: its four cells carry one block id and quadrants 0,1,2,3, and
-- we recover the vanilla id. Verified against a known layout, 20/20.
--
-- A block whose quadrants come from DIFFERENT vanilla blocks cannot be
-- expressed as a vanilla block id, so it is reported as MIXED and the
-- room is refused -- that is the case that would otherwise force a
-- shipped tileset.
package.path = "./?.lua;./?/init.lua;" .. package.path
local Perm = require("src.world.gen2.Permissions")

-- There are TWO Content Editor installs on this machine and both carry a
-- kc_layout project. Reading the wrong one silently hands you the
-- developer's PREVIOUS paint -- no error, no warning, and the transplant
-- looks like it worked. On 2026-08-31 ce-trial was 44 minutes stale and
-- that is exactly what happened. So do not trust one hardcoded path:
-- take whichever project was saved most recently, and say which.
local CANDIDATES = {
  "C:/Users/dwitt/ce-new/mods/kc_layout/editor_project.lua",
  "C:/Users/dwitt/ce-trial/mods/kc_layout/editor_project.lua",
}
local CACHE = "C:/Users/dwitt/AppData/Roaming/pokemon-love2d/crystal/data/generated/"

-- os.time is sandbox-safe and this file never ships (tests/ is excluded).
local function mtime(path)
  local p = io.popen('powershell -NoProfile -Command "'
    .. '(Get-Item -LiteralPath \'' .. path .. '\').LastWriteTimeUtc.Ticks" 2>NUL')
  if not p then return nil end
  local out = p:read("*a"); p:close()
  return tonumber((out or ""):match("%d+"))
end

local PROJECT, best, seen = nil, -1, {}
for _, path in ipairs(CANDIDATES) do
  local f = io.open(path, "r")
  if f then
    f:close()
    local t = mtime(path) or 0
    seen[#seen + 1] = { path = path, t = t }
    if t > best then best, PROJECT = t, path end
  end
end

if not PROJECT then
  print("no editor project found. Looked in:")
  for _, p in ipairs(CANDIDATES) do print("  " .. p) end
  print("open the Content Editor, load kc_layout, and Save once.")
  os.exit(1)
end

print("reading: " .. PROJECT)
if #seen > 1 then
  print("NOTE: " .. #seen .. " installs carry a kc_layout project. Using the")
  print("      most recently saved one. The editor's status bar after a Save")
  print("      is the authority -- if it names a different path, stop.")
  for _, s in ipairs(seen) do
    print(string.format("      %s%s", s.path, s.path == PROJECT and "   <- using" or "   (older)"))
  end
end

local chunk = loadfile(PROJECT)
if not chunk then
  print("could not load " .. PROJECT)
  os.exit(1)
end
local project = chunk()
local tilesets = dofile(CACHE .. "tilesets.lua")
local vanillaMaps = dofile(CACHE .. "maps.lua")

-- Recover a room from the editor as data we can actually ship.
--
-- Best case: every block was stamped whole, so it is a plain vanilla block
-- id and the room needs no tileset of its own.
--
-- Otherwise the room is COMPOSED: the painter works at quarter-block
-- granularity, so we build our own blocks out of those quarters. That is
-- still shippable, because a block is only sixteen tile NUMBERS -- the
-- image stays the player's own extracted sheet
-- ("assets/generated/tilesets/x.png", which Assets.resolve maps to their
-- cache, Assets.lua:36-54). Numbers ship; ROM art does not.
--
-- The one thing we cannot do is mix TWO sheets in one room: a map binds a
-- single image (TileRenderer.lua:473) and every tile number indexes it.
-- The editor's collision vocabulary -> Gen 2 collision bytes.
-- It offers no COUNTER mode, so a talk-across-a-counter cell cannot be
-- painted; a room that needs one keeps whole vanilla blocks there.
local COLL_BYTE = {
  solid = 0x07, walk = 0x00, grass = 0x14, water = 0x01, shore = 0x0A,
}

local QUAD = { [0] = {1,2,5,6}, [1] = {3,4,7,8},
               [2] = {9,10,13,14}, [3] = {11,12,15,16} }

-- does a painted collision quad match a vanilla block's own
local function sameColl(painted, vanilla)
  if not vanilla then return false end
  for i = 1, 4 do
    if (painted[i] or 0) ~= (vanilla[i] or 0) then return false end
  end
  return true
end

local function quadOf(ts, blockId, q)
  local blk = ts.blocks and ts.blocks[blockId + 1]
  local col = ts.collision and ts.collision[blockId + 1]
  if not blk then return nil end
  local tiles = {}
  for _, i in ipairs(QUAD[q]) do tiles[#tiles + 1] = blk[i] end
  return tiles, col and col[q + 1]
end

local function vanillaRoom(id)
  local m = project.maps and project.maps[id]
  if not m then return nil, "not in the editor project" end
  local lm = project.layeredMaps and project.layeredMaps[id]
  if not lm then
    -- never opened in the painter: still plain vanilla blocks
    return { tileset = m.tileset, width = m.width, height = m.height,
             blocks = m.blocks, layered = false, whole = true,
             composed = {}, foreign = {}, source = tilesets[m.tileset] }
  end
  local cells, cw = (lm.layers and lm.layers[1] and lm.layers[1].cells), lm.cellWidth
  if not cells or not cw then return nil, "layered map has no ground layer" end

  -- which sheets did the paint actually use
  local sheets, foreign = {}, {}
  for i = 0, m.width * m.height * 4 - 1 do
    local c = cells[i + 1]
    if c and c.source then
      local name = tostring(c.source):gsub("^@runtime:", "")
      sheets[name] = (sheets[name] or 0) + 1
    end
  end
  local names = {}
  for n in pairs(sheets) do names[#names + 1] = n end
  table.sort(names, function(a, b) return sheets[a] > sheets[b] end)
  local base = names[1] or tostring(lm.baseTileset)
  if #names > 1 then
    for by = 0, m.height - 1 do
      for bx = 0, m.width - 1 do
        for q = 0, 3 do
          local cx, cy = bx * 2 + (q % 2), by * 2 + math.floor(q / 2)
          local c = cells[cy * cw + cx + 1]
          local name = c and c.source
            and tostring(c.source):gsub("^@runtime:", "") or base
          if name ~= base then
            foreign[#foreign + 1] = ("block (%d,%d) %s corner is %s")
              :format(bx, by, ({ [0]="top-left", [1]="top-right",
                                 [2]="bottom-left", [3]="bottom-right" })[q],
                      name)
          end
        end
      end
    end
  end

  local ts = tilesets[base]
  if not ts then return nil, base .. " is not a cache tileset" end

  -- Read every block once: its four quadrants' tiles, the passage the
  -- editor painted over it, and whether it is a whole vanilla block whose
  -- painted passage still agrees with the vanilla one.
  local info, allWhole = {}, true
  for by = 0, m.height - 1 do
    for bx = 0, m.width - 1 do
      local tiles, coll, ids, quads, ok = {}, {}, {}, {}, true
      for q = 0, 3 do
        local cx, cy = bx * 2 + (q % 2), by * 2 + math.floor(q / 2)
        local c = cells[cy * cw + cx + 1]
        if not (c and c.tile) then ok = false break end
        local sid, sq = math.floor(c.tile / 4), c.tile % 4
        local t = quadOf(ts, sid, sq)
        if not t then ok = false break end
        ids[#ids + 1], quads[#quads + 1] = sid, sq
        tiles[q] = t
        -- COLLISION COMES FROM THE EDITOR'S OWN LAYER, not from whichever
        -- block the quarter was cut out of: the painter separates
        -- appearance from passage (MapBuilder's Collision tool) and every
        -- cell starts "solid".
        coll[q + 1] = COLL_BYTE[lm.collision and lm.collision[cy * cw + cx + 1]]
          or COLL_BYTE.solid
      end
      local whole = ok
        and ids[1] == ids[2] and ids[2] == ids[3] and ids[3] == ids[4]
        and quads[1] == 0 and quads[2] == 1 and quads[3] == 2 and quads[4] == 3
        and sameColl(coll, ts.collision[ids[1] + 1])
      if not whole then allWhole = false end
      info[by * m.width + bx + 1] =
        { ok = ok, whole = whole, id = ids[1], tiles = tiles, coll = coll }
    end
  end

  -- ONE numbering system per room. A vanilla block id and a composed
  -- block index are both just numbers in `blocks`, so mixing them makes
  -- id 1 and composed-index 1 indistinguishable -- which is exactly how
  -- this tool once reported walls in a room that was fine. So: all whole,
  -- or compose everything.
  local blocks, composed, keyOf = {}, {}, {}
  for index = 1, m.width * m.height do
    local b = info[index]
    if allWhole then
      blocks[index] = b.id or 0
    elseif not b.ok then
      blocks[index] = 0
    else
      local t = {
        b.tiles[0][1], b.tiles[0][2], b.tiles[1][1], b.tiles[1][2],
        b.tiles[0][3], b.tiles[0][4], b.tiles[1][3], b.tiles[1][4],
        b.tiles[2][1], b.tiles[2][2], b.tiles[3][1], b.tiles[3][2],
        b.tiles[2][3], b.tiles[2][4], b.tiles[3][3], b.tiles[3][4],
      }
      local key = table.concat(t, ",") .. "|" .. table.concat(b.coll, ",")
      if not keyOf[key] then
        composed[#composed + 1] = { tiles = t, coll = b.coll }
        keyOf[key] = #composed - 1
      end
      blocks[index] = keyOf[key]
    end
  end
  local whole = allWhole

  return { tileset = base, width = m.width, height = m.height,
           blocks = blocks, layered = true, foreign = foreign,
           composed = composed, whole = whole, source = ts }
end

local target = ...

-- ---------- exterior: what changed against vanilla ----------
if target then
  local room, why = vanillaRoom(target)
  if not room then
    print(("%s: %s"):format(target, why))
    print("open it in the editor (that copies the vanilla map in) and Save.")
    os.exit(1)
  end
  local base = vanillaMaps[target]
  if not base then print("no vanilla map " .. target) os.exit(1) end
  print(("== %s: %dx%d blocks%s =="):format(target, room.width, room.height,
    room.layered and " (painted)" or ""))
  if room.mixed and #room.mixed > 0 then
    for _, m in ipairs(room.mixed) do print("  !! " .. m) end
    print("  Stamp WHOLE blocks -- a part-block cannot be applied without")
    print("  shipping a tileset built from ROM tiles, which this mod does not do.")
    os.exit(1)
  end
  local changes = 0
  for i = 1, room.width * room.height do
    local was, now = base.blocks[i], room.blocks[i]
    if was ~= now then
      changes = changes + 1
      print(("  mod.world:replaceBlock(%d, %d, 0x%02X)   -- was 0x%02X")
        :format((i - 1) % room.width, math.floor((i - 1) / room.width), now, was))
    end
  end
  print(("  %d block(s) changed"):format(changes))
  print("")
  print("  Take these lines, NOT the editor's own maps:patch for this map --")
  print("  that patch carries a bare `objects` list, and lists replace")
  print("  wholesale (Merge.lua:29-49), so it would erase every other mod's")
  print("  NPCs here and the vanilla ones with them.")
  os.exit(0)
end

-- ---------- interiors ----------
local ids = {}
for id in pairs(project.maps or {}) do
  if id:find("^KC_") then ids[#ids + 1] = id end
end
table.sort(ids)
if #ids == 0 then print("no KC_ rooms in the editor project") os.exit(1) end

local problems = 0
for _, id in ipairs(ids) do
  local room, why = vanillaRoom(id)
  if not room then
    print(("== %s == !! %s"):format(id, why))
    problems = problems + 1
  else
    print(("== %s  %dx%d blocks  %s%s =="):format(id, room.width, room.height,
      room.tileset, room.layered and "  (painted)" or ""))

    -- a second sheet is the one thing that cannot be resolved here: a map
    -- binds ONE image (TileRenderer.lua:473)
    if room.foreign and #room.foreign > 0 then
      for _, f in ipairs(room.foreign) do print("  !! " .. f) end
      print(("  Repaint those %d corner(s) from %s. A room renders from one"):
        format(#room.foreign, room.tileset))
      print("  sheet only, so a second one has nowhere to live.")
      problems = problems + 1
    end

    -- collision comes from the composed blocks when there are any
    local function collAt(cx, cy)
      if cx < 0 or cy < 0 or cx >= room.width * 2 or cy >= room.height * 2 then
        return nil
      end
      local b = room.blocks[math.floor(cy / 2) * room.width
                            + math.floor(cx / 2) + 1] or 0
      local q
      if room.whole or not room.composed or #room.composed == 0 then
        q = room.source and room.source.collision[b + 1]
      else
        q = room.composed[b + 1] and room.composed[b + 1].coll
      end
      return q and q[(cy % 2) * 2 + (cx % 2) + 1]
    end
    local function walk(cx, cy)
      local c = collAt(cx, cy)
      return c ~= nil and Perm.isWalkable(c)
    end

    if room.whole then
      print("  every block is a whole vanilla block -- no tileset needed")
      print("    blocks = {")
      for by = 0, room.height - 1 do
        local row = {}
        for bx = 0, room.width - 1 do
          row[#row + 1] = ("0x%02X"):format(
            room.blocks[by * room.width + bx + 1] or 0)
        end
        print("      " .. table.concat(row, ", ") .. ",")
      end
      print("    },")
    else
      print(("  composed: %d custom block(s) over the player's own %s sheet")
        :format(#room.composed, room.tileset))
      print("  (ships as numbers; the image stays their cache file)")
      print(("    image = %q,"):format(tostring(room.source.image)))
      print(("    imageWidth = %d, imageHeight = %d, tilesPerRow = %d,")
        :format(room.source.imageWidth or 0, room.source.imageHeight or 0,
                room.source.tilesPerRow or 16))
      print("    blocks = {")
      for _, b in ipairs(room.composed) do
        print("      { " .. table.concat(b.tiles, ", ") .. " },")
      end
      print("    },")
      print("    collision = {")
      for _, b in ipairs(room.composed) do
        print("      { " .. table.concat(b.coll, ", ") .. " },")
      end
      print("    },")
      print("    map blocks = {")
      for by = 0, room.height - 1 do
        local row = {}
        for bx = 0, room.width - 1 do
          row[#row + 1] = tostring(room.blocks[by * room.width + bx + 1] or 0)
        end
        print("      " .. table.concat(row, ", ") .. ",")
      end
      print("    },")
    end

    print("  walk grid ( . floor  = counter  # solid ):")
    local floor = 0
    for cy = 0, room.height * 2 - 1 do
      local row = {}
      for cx = 0, room.width * 2 - 1 do
        if walk(cx, cy) then row[#row + 1] = "." floor = floor + 1
        elseif Perm.isCounter(collAt(cx, cy)) then row[#row + 1] = "="
        else row[#row + 1] = "#" end
      end
      print("    " .. table.concat(row))
    end

    local sx, sy
    for cy = room.height * 2 - 1, 0, -1 do
      for cx = 0, room.width * 2 - 1 do
        if not sx and walk(cx, cy) then sx, sy = cx, cy end
      end
    end
    if not sx then
      print("  !! no walkable cell at all")
      problems = problems + 1
    else
      local seen, stack, n = {}, { { sx, sy } }, 0
      while #stack > 0 do
        local c = table.remove(stack)
        local key = c[2] * 100 + c[1]
        if not seen[key] and walk(c[1], c[2]) then
          seen[key] = true
          n = n + 1
          stack[#stack + 1] = { c[1] + 1, c[2] }
          stack[#stack + 1] = { c[1] - 1, c[2] }
          stack[#stack + 1] = { c[1], c[2] + 1 }
          stack[#stack + 1] = { c[1], c[2] - 1 }
        end
      end
      if n ~= floor then
        print(("  !! %d of %d floor cells are CUT OFF from the rest"):format(
          floor - n, floor))
        problems = problems + 1
      else
        print(("  ok: all %d floor cells connect"):format(floor))
      end
    end
    print("")
  end
end

if problems > 0 then
  print(problems .. " problem(s) -- fix in the editor before transplanting")
  os.exit(1)
end
print("layouts read clean; safe to transplant into KC_HALLS")
