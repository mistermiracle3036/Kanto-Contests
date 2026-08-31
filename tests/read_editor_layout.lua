-- Read a room back out of the Content Editor and check it before it is
-- transplanted into main.lua.
--
--   1. developer paints in the editor (ce-trial/mods/kc_layout) and Saves
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

local PROJECT = "C:/Users/dwitt/ce-trial/mods/kc_layout/editor_project.lua"
local CACHE = "C:/Users/dwitt/AppData/Roaming/pokemon-love2d/gold/data/generated/"

local chunk = loadfile(PROJECT)
if not chunk then
  print("no editor project at " .. PROJECT)
  print("open the Content Editor, load kc_layout, and Save once.")
  os.exit(1)
end
local project = chunk()
local tilesets = dofile(CACHE .. "tilesets.lua")
local vanillaMaps = dofile(CACHE .. "maps.lua")

-- A room as vanilla data: tileset id + block ids, however it was painted.
-- Returns nil plus a reason when a block cannot be expressed vanilla.
local function vanillaRoom(id)
  local m = project.maps and project.maps[id]
  if not m then return nil, "not in the editor project" end
  local lm = project.layeredMaps and project.layeredMaps[id]
  if not lm then
    -- never opened in the painter: still plain vanilla blocks
    return { tileset = m.tileset, width = m.width, height = m.height,
             blocks = m.blocks, layered = false }
  end
  local base = tostring(lm.baseTileset or "")
  local cells, cw = (lm.layers and lm.layers[1] and lm.layers[1].cells), lm.cellWidth
  if not cells or not cw then return nil, "layered map has no ground layer" end
  local blocks, mixed = {}, {}
  for by = 0, m.height - 1 do
    for bx = 0, m.width - 1 do
      local ids, quads, ok = {}, {}, true
      for q = 0, 3 do
        local cx = bx * 2 + (q % 2)
        local cy = by * 2 + math.floor(q / 2)
        local c = cells[cy * cw + cx + 1]
        if not (c and c.tile) then ok = false break end
        -- a cell painted from another tileset cannot be a block of this one
        if c.source and not tostring(c.source):find(base, 1, true) then
          ok = false
          mixed[#mixed + 1] = ("(%d,%d) uses %s, not %s")
            :format(bx, by, tostring(c.source), base)
          break
        end
        ids[#ids + 1] = math.floor(c.tile / 4)
        quads[#quads + 1] = c.tile % 4
      end
      local index = by * m.width + bx + 1
      if ok and ids[1] == ids[2] and ids[2] == ids[3] and ids[3] == ids[4]
         and quads[1] == 0 and quads[2] == 1 and quads[3] == 2 and quads[4] == 3 then
        blocks[index] = ids[1]
      else
        blocks[index] = 0
        if ok then
          mixed[#mixed + 1] = ("(%d,%d) is part-blocks, not one whole block")
            :format(bx, by)
        end
      end
    end
  end
  return { tileset = base, width = m.width, height = m.height,
           blocks = blocks, layered = true, mixed = mixed }
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
    if room.mixed and #room.mixed > 0 then
      for _, m in ipairs(room.mixed) do print("  !! " .. m) end
      print("  Stamp WHOLE blocks: a part-block would need a tileset built")
      print("  from ROM tiles, and this mod ships no ROM-derived art.")
      problems = problems + 1
    end
    local ts = tilesets[room.tileset]
    if not ts then
      print("  !! " .. tostring(room.tileset) .. " is not a cache tileset")
      problems = problems + 1
    else
      print("    blocks = {")
      for by = 0, room.height - 1 do
        local row = {}
        for bx = 0, room.width - 1 do
          row[#row + 1] = ("0x%02X"):format(room.blocks[by * room.width + bx + 1] or 0)
        end
        print("      " .. table.concat(row, ", ") .. ",")
      end
      print("    },")

      local function coll(cx, cy)
        if cx < 0 or cy < 0 or cx >= room.width * 2 or cy >= room.height * 2 then
          return nil
        end
        local b = room.blocks[math.floor(cy / 2) * room.width
                              + math.floor(cx / 2) + 1]
        local q = ts.collision[(b or 0) + 1]
        return q and q[(cy % 2) * 2 + (cx % 2) + 1]
      end
      local function walk(cx, cy)
        local c = coll(cx, cy)
        return c ~= nil and Perm.isWalkable(c)
      end
      print("  walk grid ( . floor  = counter  # solid ):")
      local floor = 0
      for cy = 0, room.height * 2 - 1 do
        local row = {}
        for cx = 0, room.width * 2 - 1 do
          if walk(cx, cy) then row[#row + 1] = "." floor = floor + 1
          elseif Perm.isCounter(coll(cx, cy)) then row[#row + 1] = "="
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
    end
    print("")
  end
end

if problems > 0 then
  print(problems .. " problem(s) -- fix in the editor before transplanting")
  os.exit(1)
end
print("layouts read clean as vanilla blocks; safe to transplant into KC_HALLS")
