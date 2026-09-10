-- Can every hall actually be played, as SHIPPED?
--
--   Run from the engine checkout:
--     luajit ../Kanto-Contests/tests/hall_playable_test.lua
--
-- room_border_check.py guards how a room is DRAWN. This guards whether it
-- can be walked: the collision that ships in KC_HALLS, per engine variant,
-- against the cells the mod actually uses.
--
-- Written after Blackthorn came back from the Content Editor with its stage
-- steps drawn but marked solid -- 24 reachable cells instead of Ecruteak's
-- 108, so the player was warped onto a platform they could not leave -- and
-- its exit mat painted but walking like plain floor. Neither is visible in
-- a render and neither breaks a compile. Four things are checked:
--
--   1. every warp cell is a carpet, because a warp record on plain floor is
--      never looked up and the room has no exit;
--   2. the arrival cell is somewhere the player can stand;
--   3. every actor stands on a cell that is not a plain wall;
--   4. every actor can be TALKED TO from the floor the player can reach --
--      adjacent, or one cell further across a COUNTER (0x90), which is what
--      doubles the reach of an A press (engine Permissions.isCounter). A
--      lobby whose desk is plain solid has an unreachable judge, which is
--      the whole hall.
local T = require("tests.harness")

local SOLID, COUNTER = 0x07, 0x90
local CARPET = { [0x70] = true, [0x76] = true, [0x78] = true, [0x7e] = true }

local src = assert(io.open("../Kanto-Contests/main.lua")):read("*a")
local i = src:find("local KC_HALLS = {", 1, true)
local j = src:find("\n}\n", i, true)
local KC_HALLS = assert(load("return " .. src:sub(i + #"local KC_HALLS = ", j + 1)))()

-- the collision byte of one cell, for one engine variant
local function byteAt(def, engine, x, y)
  local v = def.tiles and def.tiles.variants
    and (def.tiles.variants[engine] or def.tiles.variants.gs)
  local coll = v and v.collision
  if not coll then return nil end
  if x < 0 or y < 0 or x >= def.width * 2 or y >= def.height * 2 then return nil end
  local id = def.blocks[math.floor(y / 2) * def.width + math.floor(x / 2) + 1]
  local quad = id and coll[id + 1]                 -- blocks are addressed id + 1
  if not quad then return nil end
  return quad[(y % 2) * 2 + (x % 2) + 1]
end

-- the floor the player can walk to from the arrival cell
local function reachable(def, engine)
  local W, H = def.width * 2, def.height * 2
  local function standable(x, y)
    local b = byteAt(def, engine, x, y)
    return b ~= nil and b ~= SOLID and b ~= COUNTER
  end
  local seen, q = {}, {}
  local ax, ay = def.arrival.x, def.arrival.y
  if standable(ax, ay) then seen[ay * W + ax] = true; q[1] = { ax, ay } end
  local n = 1
  while n <= #q do
    local x, y = q[n][1], q[n][2]; n = n + 1
    for _, d in ipairs({ { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }) do
      local nx, ny = x + d[1], y + d[2]
      if standable(nx, ny) and not seen[ny * W + nx] then
        seen[ny * W + nx] = true; q[#q + 1] = { nx, ny }
      end
    end
  end
  return seen, W, H
end

local function checkRoom(town, which, def, engine)
  local tag = ("%s %s (%s)"):format(town, which, engine)
  local W = def.width * 2
  local seen = reachable(def, engine)

  for _, w in ipairs(def.warps or {}) do
    T.check(CARPET[byteAt(def, engine, w.x, w.y)] == true,
      ("%s: exit (%d,%d) is a carpet"):format(tag, w.x, w.y))
  end

  local a = byteAt(def, engine, def.arrival.x, def.arrival.y)
  T.check(a ~= nil and a ~= SOLID,
    ("%s: the player lands somewhere they can stand"):format(tag))

  local count = 0
  for _ in pairs(seen) do count = count + 1 end
  T.check(count > 1, ("%s: the arrival cell is not walled in (%d cells)"):format(tag, count))

  for _, act in ipairs(def.actors or {}) do
    local b = byteAt(def, engine, act.x, act.y)
    T.check(b ~= nil and b ~= SOLID,
      ("%s: %s does not stand in a wall"):format(tag, act.name))
    local talkable = false
    for _, d in ipairs({ { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }) do
      local mx, my = act.x + d[1], act.y + d[2]
      if seen[my * W + mx] then talkable = true end
      if byteAt(def, engine, mx, my) == COUNTER
        and seen[(my + d[2]) * W + (mx + d[1])] then talkable = true end
    end
    T.check(talkable, ("%s: %s can be talked to"):format(tag, act.name))
  end
end

for _, town in ipairs({ "GOLDENROD", "ECRUTEAK", "CIANWOOD", "BLACKTHORN" }) do
  local hall = KC_HALLS[town]
  T.check(hall ~= nil, town .. " is in KC_HALLS")
  if hall then
    T.check(type(hall.rank) == "string", town .. " runs a named rank")
    for _, engine in ipairs({ "gs", "crystal" }) do
      if hall.lobby then checkRoom(town, "lobby", hall.lobby, engine) end
      if hall.stage then checkRoom(town, "stage", hall.stage, engine) end
    end
  end
end

-- Every rank has a hall. This is the check that would have said "HYPER and
-- MASTER are unreachable" out loud for the eleven versions that was true.
local RANKS = { NORMAL = false, SUPER = false, HYPER = false, MASTER = false }
for _, hall in pairs(KC_HALLS) do
  if hall.rank then RANKS[hall.rank] = true end
end
for rank, has in pairs(RANKS) do
  T.check(has, rank .. " rank has a hall to be won at")
end

T.finish("hall playability")
