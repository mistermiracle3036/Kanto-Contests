-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/sprite_check.lua
--
-- An overworld sprite id the engine cannot resolve does NOT raise: it
-- silently draws the player sheet or nothing at all (see the custom
-- overworld sprite notes). So a typo in the contest cast would reach a
-- device as "some seats are empty" rather than as an error, and no
-- compile, gen2check or load test would say a word about it.
--
-- This walks the Gen 2 cast tables in main.lua and asserts every sprite
-- really exists in the player's extracted sprite data.
local CACHE = "C:/Users/dwitt/AppData/Roaming/pokemon-love2d/%s/data/generated/sprites.lua"
local src = assert(io.open("../Kanto-Contests/main.lua")):read("*a")

-- SPRITE_KC_* are registered by the mod itself from the canonical sprite
-- store, so they are legitimately absent from the vanilla table. Their
-- own correctness is what sprite_registry.py check covers.
local function ours(id) return id:match("^SPRITE_KC_") ~= nil end

local names = {}
local function collect(listName, why)
  for list in src:gmatch("local " .. listName .. " = {(.-)\n  }") do
    for name in list:gmatch('"([A-Z_0-9]+)"') do
      names[#names + 1] = { id = "SPRITE_" .. name, why = why }
    end
  end
end
collect("CAST_GYM", "gym"); collect("CAST_FOLK", "folk")
collect("CAST_PAIRS", "pair")
collect("CAST_CUSTOM_RIVAL", "custom-rival")
collect("CAST_CUSTOM_CROWD", "custom-crowd")

-- Gen 2 actors only. The Gen 1 arm has its own sprite names (SPRITE_GIRL
-- and friends) that live in rom_manifest.json rather than the Gen 2 table,
-- so checking those here reports a phantom -- it did exactly that once.
-- The tell is `movement`: numeric on Gen 2, a string like "STAY" on Gen 1.
for id, mv in src:gmatch('sprite = "(SPRITE_[A-Z_0-9]+)",[^\n]*\n?[^\n]-movement = ([^,%s]+)') do
  if mv:match("^%d") then names[#names + 1] = { id = id, why = "actor" } end
end


-- The custom cast is skipped above because it is not in the vanilla table
-- -- but that would let a typo in a pool ("KC_MAYY") through silently, the
-- exact failure this file exists to stop. So assert the other direction:
-- every SPRITE_KC_* a pool names must actually be REGISTERED by the mod.
local registered = {}
for id in src:gmatch('{ "(SPRITE_KC_[A-Z_0-9]+)", "') do registered[id] = true end
local unregistered = {}
for _, e in ipairs(names) do
  if ours(e.id) and not registered[e.id] then
    unregistered[#unregistered + 1] = ("%s (%s)"):format(e.id, e.why)
  end
end
if #unregistered > 0 then
  print(("FAIL: %d custom sprite(s) drawn but never registered"):format(#unregistered))
  for _, u in ipairs(unregistered) do print("   " .. u) end
  os.exit(1)
end
local nreg = 0
for _ in pairs(registered) do nreg = nreg + 1 end
print(("ok custom: %d registered, every pool reference resolves"):format(nreg))

local failed = false
for _, game in ipairs({ "gold", "crystal" }) do
  local ok, S = pcall(dofile, CACHE:format(game))
  if not ok or type(S) ~= "table" then
    print(("  (%s: no extracted sprite cache -- skipped)"):format(game))
  else
    local bad = {}
    for _, e in ipairs(names) do
      if not S[e.id] and not ours(e.id) then
        bad[#bad + 1] = ("%s (%s)"):format(e.id, e.why)
      end
    end
    if #bad > 0 then
      failed = true
      print(("FAIL %s: %d unknown sprite(s)"):format(game, #bad))
      for _, b in ipairs(bad) do print("   " .. b) end
    else
      print(("ok %s: all %d cast sprites exist"):format(game, #names))
    end
  end
end
if failed then os.exit(1) end
print("CAST SPRITES OK")
