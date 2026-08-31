-- Read a room back out of the Content Editor and check it before it is
-- transplanted into main.lua.
--
-- The workflow this closes:
--   1. developer paints a room in the editor (ce-trial/mods/kc_layout)
--      and presses Save, which regenerates editor_project.lua
--   2. this reads that file, prints each room's blocks ready to paste into
--      KC_HALLS, and walks the geometry against the real imported cache
--   3. only then does the layout go into main.lua
--
-- Step 3 is the point: the editor happily paints a room the player cannot
-- cross, and every layout bug this project has had -- the attendant inside
-- a wall, services on an unreachable row -- was a geometry bug that a
-- walk check catches for free.
--
-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/read_editor_layout.lua
--   luajit ../Kanto-Contests/tests/read_editor_layout.lua GOLDENROD_CITY
-- With a map id, prints the CHANGED BLOCKS against the vanilla cache
-- instead -- what an exterior edit needs, as replaceBlock coordinates.
package.path = "./?.lua;./?/init.lua;" .. package.path
local Perm = require("src.world.gen2.Permissions")

local PROJECT = "C:/Users/dwitt/ce-trial/mods/kc_layout/editor_project.lua"
local CACHE = "C:/Users/dwitt/AppData/Roaming/pokemon-love2d/gold/data/generated/"

local chunk = loadfile(PROJECT)
if not chunk then
  print("no editor project at " .. PROJECT)
  print("open the Content Editor, load the kc_layout mod, and Save once.")
  os.exit(1)
end
local project = chunk()
local tilesets = dofile(CACHE .. "tilesets.lua")
local vanillaMaps = dofile(CACHE .. "maps.lua")

local target = ...

-- ---------- exterior: what changed against vanilla ----------
if target then
  local edited = project.maps and project.maps[target]
  if not edited then
    print(("%s is not in the editor project -- open it in the editor "):format(target)
      .. "(it copies the vanilla map in on first edit) and Save.")
    os.exit(1)
  end
  local base = vanillaMaps[target]
  if not base then print("no vanilla map " .. target) os.exit(1) end
  print(("== %s: %dx%d blocks =="):format(target, edited.width, edited.height))
  local changes = 0
  for i = 1, edited.width * edited.height do
    local was, now = base.blocks[i], edited.blocks[i]
    if was ~= now then
      changes = changes + 1
      local bx = (i - 1) % edited.width
      local by = math.floor((i - 1) / edited.width)
      print(("  mod.world:replaceBlock(%d, %d, 0x%02X)   -- was 0x%02X")
        :format(bx, by, now, was))
    end
  end
  print(("  %d block(s) changed"):format(changes))
  if edited._isNew then
    print("  !! _isNew is true: the editor thinks this is a NEW map, so it")
    print("     would emit maps:register, not maps:patch. Check the id.")
  end
  print("")
  print("  NOTE: take the replaceBlock lines, not the editor's own")
  print("  maps:patch output. That patch carries a bare `objects` list, and")
  print("  a bare list REPLACES wholesale -- it would erase every other")
  print("  mod's NPCs on this map, and the vanilla ones (Merge.lua:29-49).")
  os.exit(0)
end

-- ---------- interiors: blocks + a walk check ----------
local ids = {}
for id in pairs(project.maps or {}) do
  if id:find("^KC_") then ids[#ids + 1] = id end
end
table.sort(ids)
if #ids == 0 then print("no KC_ rooms in the editor project") os.exit(1) end

local problems = 0
for _, id in ipairs(ids) do
  local m = project.maps[id]
  local ts = tilesets[m.tileset]
  print(("== %s  %dx%d blocks  %s =="):format(id, m.width, m.height, m.tileset))
  if not ts then
    print("  !! unknown tileset " .. tostring(m.tileset))
    problems = problems + 1
  else
    -- the array, formatted for KC_HALLS
    print("    blocks = {")
    for by = 0, m.height - 1 do
      local row = {}
      for bx = 0, m.width - 1 do
        row[#row + 1] = ("0x%02X"):format(m.blocks[by * m.width + bx + 1] or 0)
      end
      print("      " .. table.concat(row, ", ") .. ",")
    end
    print("    },")

    -- and what it plays like
    local function coll(cx, cy)
      if cx < 0 or cy < 0 or cx >= m.width * 2 or cy >= m.height * 2 then
        return nil
      end
      local b = m.blocks[math.floor(cy / 2) * m.width + math.floor(cx / 2) + 1]
      local q = ts.collision[(b or 0) + 1]
      return q and q[(cy % 2) * 2 + (cx % 2) + 1]
    end
    local function walk(cx, cy)
      local c = coll(cx, cy)
      return c ~= nil and Perm.isWalkable(c)
    end
    print("  walk grid ( . floor  = counter  # solid ):")
    local floor = 0
    for cy = 0, m.height * 2 - 1 do
      local row = {}
      for cx = 0, m.width * 2 - 1 do
        if walk(cx, cy) then row[#row + 1] = "." floor = floor + 1
        elseif Perm.isCounter(coll(cx, cy)) then row[#row + 1] = "="
        else row[#row + 1] = "#" end
      end
      print("    " .. table.concat(row))
    end

    -- one connected region, or the room has an island in it
    local sx, sy
    for cy = m.height * 2 - 1, 0, -1 do
      for cx = 0, m.width * 2 - 1 do
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
        print(("  !! %d of %d floor cells are CUT OFF from the entrance"):format(
          floor - n, floor))
        print("     (a wall closed the room in two -- the player would be")
        print("      stranded, or an NPC unreachable)")
        problems = problems + 1
      else
        print(("  ok: all %d floor cells connect"):format(floor))
      end
    end
  end
  print("")
end

if problems > 0 then
  print(problems .. " problem(s) -- fix in the editor before transplanting")
  os.exit(1)
end
print("layouts read clean; safe to transplant into KC_HALLS")
