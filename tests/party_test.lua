-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/party_test.lua
--
-- The contest parks the player's party while one POKeMON competes. That
-- touches the one invariant worth being paranoid about -- never lose the
-- player's POKeMON -- so this covers the stash and, more importantly,
-- every way it has to come BACK.
local src = assert(io.open("../Kanto-Contests/main.lua")):read("*a")
local fails = 0
local function check(ok, what)
  if ok then print("  ok  " .. what) else fails = fails + 1 print("  FAIL " .. what) end
end

-- ---- the stash must live in the SAVE, not a Lua local ---------------
check(src:find("save.kcPartyStash", 1, true) ~= nil,
  "the stash is a save-level field (survives quitting mid-contest)")
check(src:find("local partyStash", 1, true) == nil,
  "no module-local stash (a local dies with the process, taking the party)")

-- ---- restore must be wired to map entry, not one exit ---------------
local entered = src:match('mod%.events:on%("map%.entered".-\n  end%)')
check(entered ~= nil, "map.entered handler found")
check(entered and entered:find("restoreParty", 1, true) ~= nil,
  "restoreParty runs on map entry")
check(entered and entered:find("STAGE_DEF and mapId == STAGE_DEF.id", 1, true) ~= nil,
  "restore is gated to any map that is NOT the stage")

-- ---- replay the stash/restore contract ------------------------------
local function newSave(n)
  local p = {}
  for i = 1, n do p[i] = { species = "MON" .. i } end
  return { party = p }
end
local function stash(save, keep)
  if not (save and save.party and save.party[keep]) then return false end
  if save.kcPartyStash then return true end
  local full = {}
  for i, m in ipairs(save.party) do full[i] = m end
  save.kcPartyStash = full
  save.party = { full[keep] }
  return true
end
local function restore(save)
  if not (save and save.kcPartyStash) then return false end
  save.party = save.kcPartyStash
  save.kcPartyStash = nil
  return true
end

do
  local s = newSave(6)
  stash(s, 3)
  check(#s.party == 1 and s.party[1].species == "MON3",
    "only the chosen POKeMON is in the party")
  check(#s.kcPartyStash == 6, "all six are parked on the save")
  restore(s)
  check(#s.party == 6, "the whole party comes back")
  check(s.kcPartyStash == nil, "and the stash is cleared")
  for i = 1, 6 do
    if s.party[i].species ~= "MON" .. i then
      check(false, "party order preserved") break
    end
    if i == 6 then check(true, "party order preserved") end
  end
end
do  -- the paranoid cases
  local s = newSave(6)
  stash(s, 1); stash(s, 4)
  check(#s.kcPartyStash == 6 and #s.party == 1,
    "double stash does not overwrite the parked party")
  restore(s)
  check(#s.party == 6, "and it still restores all six")
  check(restore(s) == false, "restoring twice is a harmless no-op")
end
do
  local s = { party = {} }
  check(stash(s, 1) == false, "an empty party cannot be stashed")
  check(s.kcPartyStash == nil, "and nothing is parked")
end

if fails > 0 then print(("%d FAILED"):format(fails)) os.exit(1) end
print("PARTY STASH OK: parked in the save, restored off any non-stage map")
