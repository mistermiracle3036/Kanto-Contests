-- Can the player walk up to every spectator?
--
--   Run from the engine checkout:
--     luajit ../Kanto-Contests/tests/crowd_reach_test.lua
--
-- The painted chairs are decoration; a spectator can stand on any cell. What
-- they cannot do is stand somewhere the player can never reach, because NPCs
-- block movement in Gen 2 and a crowd across a gap walls off everyone behind
-- it. That only became visible once leaving the stage might be a walk rather
-- than a warp, and it is invisible in a render either way.
--
-- ALL-OCCUPIED IS THE WORST CASE, which is what makes this checkable at all:
-- a contest fills only some of the places, and freeing one can only add floor
-- -- added floor cannot disconnect a walkway or take a neighbour away. So if
-- the room holds up with every place taken, it holds for any contest.
--
-- Asserted per town AND per engine variant, against the collision that
-- actually ships, so a repaint that walls somebody in fails here.
local T = require("tests.harness")

local SOLID = 0x07
local CARPET = { [0x70] = true, [0x76] = true, [0x78] = true, [0x7e] = true }

-- the cells the contest itself owns, which must never be offered as places
local RESERVED = {
  ["3,8"] = "the line-up", ["4,6"] = "the mark",
  ["3,7"] = "the walk to the mark", ["3,6"] = "the walk to the mark",
  ["4,8"] = "a coordinator", ["5,8"] = "a coordinator", ["6,8"] = "a coordinator",
}

local src = assert(io.open("../Kanto-Contests/main.lua")):read("*a")

-- KC_HALLS is at file scope and closes on column 0; the tables inside
-- kcGold are indented two, so the closer is part of the ask
local function table_after(marker, closer)
  local i = assert(src:find(marker, 1, true), marker)
  local j = assert(src:find(closer, i, true), marker .. " has no close")
  return src:sub(i + #marker, j + #closer - 1)
end

local H = assert(load("return " .. table_after("local KC_HALLS = ", "\n}\n")))()
-- FACE_* are locals in main.lua; only the cells matter here
local seatsSrc = table_after("local KC_STAGE_SEATS = ", "\n  }\n")
  :gsub("FACE_DOWN", '"down"'):gsub("FACE_UP", '"up"')
  :gsub("FACE_LEFT", '"left"'):gsub("FACE_RIGHT", '"right"')
local SEATS = assert(load("return " .. seatsSrc))()

local function byteAt(def, engine, x, y)
  local v = def.tiles.variants[engine] or def.tiles.variants.gs
  local coll = v and v.collision
  if not coll then return nil end
  if x < 0 or y < 0 or x >= def.width * 2 or y >= def.height * 2 then return nil end
  local id = def.blocks[math.floor(y / 2) * def.width + math.floor(x / 2) + 1]
  local quad = id and coll[id + 1]
  return quad and quad[(y % 2) * 2 + (x % 2) + 1]
end

local N4 = { { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }

for town, list in pairs(SEATS) do
  local hall = H[town]
  T.check(hall ~= nil and hall.stage ~= nil, town .. " has a stage")
  if hall and hall.stage then
    local def = hall.stage
    local W = def.width * 2
    T.check(#list > 0, town .. ": the crowd has somewhere to stand")

    for _, engine in ipairs({ "gs", "crystal" }) do
      local tag = ("%s (%s)"):format(town, engine)
      local occupied, bad = {}, 0
      for _, s in ipairs(list) do
        local b = byteAt(def, engine, s.x, s.y)
        if b == nil or b == SOLID then bad = bad + 1 end
        occupied[s.y * W + s.x] = true
      end
      T.check(bad == 0, ("%s: every place is somewhere a person can stand"):format(tag))

      -- the floor left over, walked from where the player lands
      local free = {}
      for y = 0, def.height * 2 - 1 do
        for x = 0, def.width * 2 - 1 do
          local b = byteAt(def, engine, x, y)
          if b ~= nil and b ~= SOLID and not occupied[y * W + x] then
            free[y * W + x] = { x, y }
          end
        end
      end
      local ax, ay = def.arrival.x, def.arrival.y
      local seen, q = {}, {}
      if free[ay * W + ax] then seen[ay * W + ax] = true; q[1] = { ax, ay } end
      local n = 1
      while n <= #q do
        local x, y = q[n][1], q[n][2]; n = n + 1
        for _, d in ipairs(N4) do
          local nx, ny = x + d[1], y + d[2]
          local k = ny * W + nx
          if free[k] and not seen[k] then seen[k] = true; q[#q + 1] = { nx, ny } end
        end
      end

      local stranded = 0
      for k in pairs(free) do if not seen[k] then stranded = stranded + 1 end end
      T.check(stranded == 0,
        ("%s: with every place taken the floor is still one piece (%d cut off)")
          :format(tag, stranded))

      local unreachable = {}
      for _, s in ipairs(list) do
        local ok = false
        for _, d in ipairs(N4) do
          if seen[(s.y + d[2]) * W + (s.x + d[1])] then ok = true end
        end
        if not ok then unreachable[#unreachable + 1] = ("(%d,%d)"):format(s.x, s.y) end
      end
      T.check(#unreachable == 0,
        ("%s: every spectator can be walked up to%s"):format(tag,
          #unreachable > 0 and (" -- " .. table.concat(unreachable, " ")) or ""))
    end

    local clashes = {}
    for _, s in ipairs(list) do
      local why = RESERVED[s.x .. "," .. s.y]
      if why then clashes[#clashes + 1] = ("(%d,%d) is %s"):format(s.x, s.y, why) end
    end
    T.check(#clashes == 0, ("%s: no place sits on a cell the contest owns%s")
      :format(town, #clashes > 0 and (" -- " .. table.concat(clashes, ", ")) or ""))
  end
end

-- The point of the whole change: a bigger room the higher you go, and each
-- band has to fit the hall that runs it.
local bands = assert(load("return " .. table_after("local CROWD_BY_RANK = ", "\n  }\n")))()
local RANK_TOWN = {}
for town, hall in pairs(H) do
  if hall.rank then RANK_TOWN[hall.rank] = town end
end
local order = { "NORMAL", "SUPER", "HYPER", "MASTER" }
for i, rank in ipairs(order) do
  local b = bands[rank]
  T.check(type(b) == "table" and b[1] and b[2], rank .. " has a crowd size")
  if b then
    T.check(b[1] <= b[2], rank .. ": the band is the right way round")
    if i > 1 then
      local prev = bands[order[i - 1]]
      T.check(b[1] > prev[1] and b[2] > prev[2],
        ("%s draws a bigger crowd than %s"):format(rank, order[i - 1]))
    end
    local town = RANK_TOWN[rank]
    if town and SEATS[town] then
      T.check(#SEATS[town] >= b[2],
        ("%s holds %d, and %s can want up to %d"):format(town, #SEATS[town], rank, b[2]))
    end
  end
end

T.finish("crowd reach")
