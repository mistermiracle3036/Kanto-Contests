-- Dump a painted city exterior for the python renderer.
--   luajit tests/dump_city_paint.lua CIANWOOD_CITY out.txt
-- Emits the composed cells (source block + quadrant) and the collision word
-- per cell, plus the vanilla warps and signs so a facade that covers one is
-- visible rather than inferred.
local PROJECT = "C:/Users/dwitt/ce-new/mods/kc_layout/editor_project.lua"
local C = "C:/Users/dwitt/AppData/Roaming/pokemon-love2d/crystal/data/generated/"
local P = dofile(PROJECT)
local M = dofile(C .. "maps.lua")
local TS = dofile(C .. "tilesets.lua")
local PAL = dofile(C .. "palettes.lua")

local id, out = arg[1], arg[2]
local s = assert(P.layeredMaps[id], id .. " has not been painted")
local V = assert(M[id], id)
local CW, CH = s.cellWidth, s.cellHeight
local f = io.open(out, "w")
f:write(("ROOM %s %d %d\n"):format(id, CW, CH))
f:write("PAL\n")
for i, ref in ipairs(PAL.environments.TOWN.DAY) do
  local pal = type(ref) == "table" and ref or PAL.bg[ref]
  local o = {}
  for _, c in ipairs(pal) do o[#o + 1] = table.concat(c, ",") end
  f:write(i - 1, " ", table.concat(o, " "), "\n")
end
local seen = {}
for _, c in pairs(s.layers[1].cells) do
  if type(c) == "table" then
    local name = tostring(c.source):match("^@runtime:(.+)$")
    if name then seen[name] = true end
  end
end
for name in pairs(seen) do
  local ts = assert(TS[name], name)
  f:write(("TILESET %s %s %d %d\n"):format(name, ts.image, ts.imageWidth, ts.imageHeight))
  f:write("TILEPAL ", table.concat(ts.tilePalettes, ","), "\n")
  for i, b in ipairs(ts.blocks) do f:write("B ", i - 1, " ", table.concat(b, ","), "\n") end
  f:write("ENDTS\n")
end
f:write("CELLS\n")
for y = 0, CH - 1 do
  for x = 0, CW - 1 do
    local i = y * CW + x + 1
    local c = s.layers[1].cells[i]
    local src = c and tostring(c.source):match("^@runtime:(.+)$") or "?"
    local t = c and c.tile or 0
    local vb = V.blocks[math.floor(y / 2) * V.width + math.floor(x / 2) + 1] or 0
    local mark = (t ~= vb * 4 + ((y % 2) * 2 + (x % 2))) and "NEW" or "old"
    f:write(("%d %d %s %d %d %s %s\n"):format(x, y, src, math.floor(t / 4), t % 4,
      tostring(s.collision[i]), mark))
  end
end
f:write("WARPS\n")
for _, w in ipairs(V.warps or {}) do
  f:write(("%d,%d,%s\n"):format(w.x, w.y, tostring(w.destMap or w.map)))
end
f:write("SIGNS\n")
for _, e in ipairs(V.bgEvents or {}) do
  f:write(("%d,%d\n"):format(e.x, e.y))
end
f:close()
print(("%s %dx%d cells"):format(id, CW, CH))
