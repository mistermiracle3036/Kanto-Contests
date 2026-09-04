-- Read a painted city exterior out of the Content Editor bridge and print
-- the facade table for it.
--
--   luajit tests/read_city_facade.lua CIANWOOD_CITY BLACKTHORN_CITY
--
-- DO NOT take the editor's own maps:patch output for a vanilla map. That
-- record carries a bare `objects` list, and lists REPLACE wholesale
-- (Merge.lua), so applying it would erase every other mod's NPCs on the map
-- and the vanilla ones with them. Instead this diffs the paint against the
-- cache and emits only the CHANGED blocks, which the mod stamps one at a
-- time with World:replaceBlock on map.entered -- per block, touching
-- nothing else.
--
-- Each block is emitted as four (vanilla block, quadrant) pairs rather than
-- baked tile ids, because Gold and Crystal number TILESET_JOHTO's blocks
-- differently; the mod composes the sixteen tiles from whichever game is
-- running.
--
-- It also reports what the facade COVERS: a vanilla sign or warp under the
-- new building is unreachable afterwards, and its text has to be moved.
local PROJECT = "C:/Users/dwitt/ce-new/mods/kc_layout/editor_project.lua"
local CACHE = "C:/Users/dwitt/AppData/Roaming/pokemon-love2d/crystal/data/generated/"

local CELL_COLL = {
  solid = 0x07, walk = 0x00, grass = 0x18, water = 0x21, shore = 0x23,
  cut = 0x12, door = 0x71, stairs = 0x7a, cave = 0x7b, panel = 0x7c,
  carpet_down = 0x70, carpet_left = 0x76, carpet_up = 0x78, carpet_right = 0x7e,
  carpet = 0x70, ledge_right = 0xa0, ledge_left = 0xa1, ledge_up = 0xa2,
  ledge_down = 0xa3, ledge = 0xa3, face_right = 0xb0, face_left = 0xb1,
  face_up = 0xb2, face_down = 0xb3, face = 0xb2,
}

-- Cells the paint cannot finish, applied on the way out and printed when
-- they fire. Same reason as the rooms: the editor draws a doorway happily
-- but leaves it walking like open ground.
local FORCE = {
  CIANWOOD_CITY = {
    { 7, 23, 0x71, "the hall doorway is drawn but carries plain floor collision" },
  },
}

local P = dofile(PROJECT)
local MAPS = dofile(CACHE .. "maps.lua")

for _, id in ipairs(arg) do
  local s = assert(P.layeredMaps[id], id .. " has not been painted")
  local V = assert(MAPS[id], id)
  local CW, CH = s.cellWidth, s.cellHeight
  local W, H = V.width, V.height
  assert(CW == W * 2 and CH == H * 2, id .. " is not the vanilla size")

  local forced = {}
  for _, f in ipairs(FORCE[id] or {}) do
    forced[f[2] * CW + f[1]] = f
  end

  local out, doors, covered = {}, {}, {}
  for by = 0, H - 1 do
    for bx = 0, W - 1 do
      local q, coll, changed, here = {}, {}, false, {}
      local vb = V.blocks[by * W + bx + 1] or 0
      for n = 0, 3 do
        local x, y = bx * 2 + (n % 2), by * 2 + math.floor(n / 2)
        local i = y * CW + x + 1
        local c = s.layers[1].cells[i]
        local tile = c and c.tile or 0
        if tile ~= vb * 4 + n then changed = true end
        q[#q + 1] = math.floor(tile / 4)
        q[#q + 1] = tile % 4
        local byte = CELL_COLL[s.collision[i]] or 0x07
        local f = forced[y * CW + x]
        if f and byte ~= f[3] then
          io.stderr:write(("      %s (%d,%d) 0x%02X -> 0x%02X  %s\n")
            :format(id, x, y, byte, f[3], f[4]))
          byte = f[3]
          changed = true
        end
        coll[#coll + 1] = byte
        -- collected first and filed after: whether the BLOCK is repainted
        -- is not known until all four quadrants have been compared, and
        -- reading the flag mid-loop missed a door in an earlier quadrant
        if byte == CELL_COLL.door then here[#here + 1] = { x, y } end
      end
      for _, d in ipairs(here) do doors[#doors + 1] = { d[1], d[2], changed } end
      if changed then
        out[#out + 1] = ("    { bx = %d, by = %d, q = { %s }, coll = { %s } },")
          :format(bx, by, table.concat(q, ", "),
                  ("0x%02X, 0x%02X, 0x%02X, 0x%02X"):format(coll[1], coll[2], coll[3], coll[4]))
        for _, e in ipairs(V.bgEvents or {}) do
          if math.floor(e.x / 2) == bx and math.floor(e.y / 2) == by then
            covered[#covered + 1] = ("sign at (%d,%d)"):format(e.x, e.y)
          end
        end
        for _, w in ipairs(V.warps or {}) do
          if math.floor(w.x / 2) == bx and math.floor(w.y / 2) == by then
            covered[#covered + 1] = ("warp at (%d,%d) -> %s")
              :format(w.x, w.y, tostring(w.destMap or w.map))
          end
        end
      end
    end
  end

  -- a door inside the repaint is the new one; the town's own doors are not
  local new = {}
  for _, d in ipairs(doors) do
    if d[3] then new[#new + 1] = ("(%d,%d)"):format(d[1], d[2]) end
  end

  print(("  local KC_%s_FACADE = {"):format(id:gsub("_CITY$", "")))
  print(table.concat(out, "\n"))
  print("  }")
  io.stderr:write(("%s: %d changed block(s); door cell(s) inside the repaint: %s\n")
    :format(id, #out, #new > 0 and table.concat(new, " ") or "NONE"))
  if #covered > 0 then
    io.stderr:write("  covers: " .. table.concat(covered, ", ") .. "\n")
  end
end
