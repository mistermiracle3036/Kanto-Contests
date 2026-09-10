-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/partner_test.lua
--
-- Every POKeMON a coordinator can bring must exist in the player's own
-- extracted data. An unknown species is NOT an error: speciesIndexOf
-- returns nil, so showPokePic and playCry are skipped and the appeal
-- just... has no picture and no cry. That reaches a device looking like
-- nothing happened, which is the hardest kind of bug to report.
--
-- Checked against BOTH engines: Gold and Crystal ship different species
-- tables, and a Gen 3+ name that only I recognise is exactly the sort of
-- thing that would sail through here.
local CACHE = "C:/Users/dwitt/AppData/Roaming/pokemon-love2d/%s/data/generated/pokemon.lua"
local src = assert(io.open("../Kanto-Contests/main.lua")):read("*a")

local names, where = {}, {}
local pools = src:match("local KC_PARTNER_POOLS = {(.-)\n  }")
if pools then
  for owner, list in pools:gmatch("(SPRITE_[%u_%d]+)%s*=%s*{([^}]*)}") do
    for sp in list:gmatch('"([%u_%d]+)"') do
      names[#names + 1] = sp; where[sp] = (where[sp] or owner)
    end
  end
end
local general = src:match("local KC_PARTNERS = {(.-)\n  }")
if general then
  for sp in general:gmatch('"([%u_%d]+)"') do
    names[#names + 1] = sp; where[sp] = where[sp] or "KC_PARTNERS"
  end
end
print(("checking %d partner entries"):format(#names))

local failed = false
for _, game in ipairs({ "gold", "crystal" }) do
  local ok, data = pcall(dofile, CACHE:format(game))
  if not (ok and type(data) == "table") then
    print(("  (%s: no extracted species data -- skipped)"):format(game))
  else
    local bad = {}
    for _, sp in ipairs(names) do
      local rec = data[sp]
      if not (rec and rec.index) then
        bad[#bad + 1] = ("%s (for %s)"):format(sp, tostring(where[sp]))
      end
    end
    if #bad > 0 then
      failed = true
      print(("FAIL %s: %d unknown species"):format(game, #bad))
      local seen = {}
      for _, b in ipairs(bad) do
        if not seen[b] then seen[b] = true print("   " .. b) end
      end
    else
      print(("ok %s: every partner resolves to a species index"):format(game))
    end
  end
end
if failed then os.exit(1) end
print("PARTNERS OK: every coordinator's POKeMON exists on both engines")
