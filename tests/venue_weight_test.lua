-- Is the venue weighting well-formed, and does it actually bend the draw?
--
--   Run from the engine checkout:
--     luajit ../Kanto-Contests/tests/venue_weight_test.lua
--
-- KC_VENUE_WEIGHT was authored by ChatGPT against
-- exchange/work-orders/kanto_contests-venue-crowd-affinity.md. The order's
-- acceptance conditions are checked here rather than by eye at intake, so a
-- later edit -- by anyone -- has to keep meeting them:
--
--   * every key is a real name from one of the four cast lists. A typo
--     would not error; it would silently weight nobody;
--   * every value is 0-4, and no town changes more than 16;
--   * no pool has more than half its names weighted in any town, so a town
--     cannot quietly become a different cast;
--   * no pool can be weighted away to nothing.
--
-- And one behavioural check, because a valid table that does nothing is the
-- failure worth catching: the draw expands a pool so a name with weight N
-- appears N times, so the expansion is what the odds actually are.
local T = require("tests.harness")

local src = assert(io.open("../Kanto-Contests/main.lua")):read("*a")

local function lua_list(name)
  local i = assert(src:find("local " .. name .. " = {", 1, true), name)
  local j = assert(src:find("\n  }\n", i, true))
  local body = src:sub(i, j):gsub("%-%-[^\n]*", "")
  local out = {}
  for word in body:gmatch('"([A-Z0-9_]+)"') do out[#out + 1] = word end
  return out
end

local POOLS = {
  CAST_GYM = lua_list("CAST_GYM"),
  CAST_FOLK = lua_list("CAST_FOLK"),
  CAST_CUSTOM_RIVAL = lua_list("CAST_CUSTOM_RIVAL"),
  CAST_CUSTOM_CROWD = lua_list("CAST_CUSTOM_CROWD"),
}
local known = {}
for pool, list in pairs(POOLS) do
  for _, n in ipairs(list) do known[n] = pool end
end

local i = assert(src:find("local KC_VENUE_WEIGHT = {", 1, true))
local j = assert(src:find("\n  }\n", i, true))
local W = assert(load("return " .. src:sub(i + #"local KC_VENUE_WEIGHT = ", j + 4)))()

local TOWNS = { "GOLDENROD", "ECRUTEAK", "CIANWOOD", "BLACKTHORN" }
for _, town in ipairs(TOWNS) do
  local w = W[town]
  T.check(type(w) == "table", town .. " has a weighting")
  if w then
    local n, bad, range = 0, {}, {}
    local perPool = {}
    for name, value in pairs(w) do
      n = n + 1
      local pool = known[name]
      if not pool then bad[#bad + 1] = name end
      if pool then perPool[pool] = (perPool[pool] or 0) + 1 end
      if type(value) ~= "number" or value < 0 or value > 4
        or value ~= math.floor(value) then
        range[#range + 1] = ("%s=%s"):format(name, tostring(value))
      end
    end
    T.check(#bad == 0, ("%s: every name is in a cast list%s"):format(town,
      #bad > 0 and (" -- not found: " .. table.concat(bad, " ")) or ""))
    T.check(#range == 0, ("%s: every weight is a whole 0-4%s"):format(town,
      #range > 0 and (" -- " .. table.concat(range, " ")) or ""))
    T.check(n <= 16, ("%s: %d entries, at most 16"):format(town, n))
    for pool, list in pairs(POOLS) do
      local changed = perPool[pool] or 0
      T.check(changed * 2 <= #list,
        ("%s: %s keeps at least half its names at the default (%d of %d changed)")
          :format(town, pool, changed, #list))
    end
  end
end

-- The expansion IS the odds, so check it rather than the table again.
local function expand(pool, town)
  local w = W[town] or {}
  local out, count = {}, {}
  for _, name in ipairs(POOLS[pool]) do
    local k = w[name] or 1
    for _ = 1, k do out[#out + 1] = name end
    count[name] = k
  end
  return out, count
end

for _, town in ipairs(TOWNS) do
  for pool in pairs(POOLS) do
    local out = expand(pool, town)
    T.check(#out > 0, ("%s/%s is not weighted away to nothing"):format(town, pool))
  end
end

-- A leader belongs to their own town far more than to somebody else's.
local HOME = { WHITNEY = "GOLDENROD", MORTY = "ECRUTEAK",
               CHUCK = "CIANWOOD", CLAIR = "BLACKTHORN" }
for leader, home in pairs(HOME) do
  local _, athome = expand("CAST_GYM", home)
  for _, other in ipairs(TOWNS) do
    if other ~= home then
      local _, away = expand("CAST_GYM", other)
      T.check(athome[leader] > away[leader],
        ("%s turns up in %s more than in %s (%d vs %d)")
          :format(leader, home, other, athome[leader], away[leader]))
    end
  end
end

T.finish("venue weighting")
