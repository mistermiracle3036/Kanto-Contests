-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/gen_gate_test.lua
-- (paths are engine-relative; the mod loads from ../Kanto-Contests)
-- headless load test for kanto_contests on both generations.
-- The harness injects loader.generation but does not set
-- GameVersion.current (a real boot sets both); the mod's entry branch
-- reads GameVersion, so align the two here the way a real boot would.
package.path = "./?.lua;./?/init.lua;" .. package.path
local T = require("tests.modkit")
local GameVersion = require("src.core.GameVersion")

-- these are the sandbox's own gaps (no ROM content loaded), the same set
-- modkit validate reports; they are not mod defects.
--
-- No tileset rows any more: since 0.17.0 every hall registers its OWN
-- composed sheet, so nothing references a vanilla tileset id and there is
-- nothing here for the sandbox to fail to resolve. The three allowances
-- that used to sit here are deliberately NOT kept "just in case" -- a
-- stale allowance in this list is the one thing that could hide a typo'd
-- tileset id behind a green test.
local KNOWN = {
  ['unresolved reference to trainers "OPP_GENTLEMAN"'] = true,
  ['unresolved reference to pokemon "CHANSEY"'] = true,
}
local function realErrors(run)
  local out = {}
  for _, e in ipairs(run.errors) do
    local msg = tostring(e.message or e)
    local known = false
    for pat in pairs(KNOWN) do
      if msg:find(pat, 1, true) then known = true break end
    end
    if not known then out[#out + 1] = msg end
  end
  return out
end

-- Engine 0.1.85 (Loader.lua's GEN1_ONLY_MODULES + scanRequire) files a
-- PLAYER-VISIBLE boot error when a mod requires a Gen 1-only module the
-- adapter cannot serve. `src.script.Commands` is on that list and the Gen 1
-- arm below the generation branch requires it -- so this asserts the branch
-- actually returns first. A static reader (gen2check, or a human reading
-- the sites) cannot see that; only executing the load can.
--
-- Note `src.battle.BattleState` is ALSO on the GEN1_ONLY list but IS served
-- by Gen2Compat, so it would never file this error either way. Commands is
-- the one that would, which makes it the honest canary.
local GEN1_ONLY_LEAK = "src.script.Commands"

-- The manifest says games: ["gen1", "gen2"], and ModTargets.expand("gen2")
-- resolves that to EVERY generation-2 version id -- gold, silver AND crystal
-- (src/mods/ModTargets.lua). So the claim being made is three Gen 2 games,
-- not one, and testing only Gold left two of them asserted but unexercised.
-- Crystal matters most: it is the one Gen 2 version on its own engine branch
-- (GameVersion.engine -> "crystal" where Gold and Silver share "gs").
for _, case in ipairs({ { gen = 1, version = "red" },
                        { gen = 1, version = "yellow" },
                        { gen = 2, version = "gold" },
                        { gen = 2, version = "silver" },
                        { gen = 2, version = "crystal" } }) do
  GameVersion.current = case.version
  local run = T.sdk.loadMod("../Kanto-Contests", { generation = case.gen })
  local mod = run.mod
  -- A nil mod means the loader never DISCOVERED it, which is a different
  -- failure from one that loaded badly -- and "state is nil" alone does not
  -- say which. Seen twice on Windows immediately after writing main.lua (a
  -- transient read failure, green on every re-run), so say what was found
  -- rather than leaving the next person to guess.
  if not mod then
    local seen = {}
    for id in pairs(run.mods or {}) do seen[#seen + 1] = id end
    table.sort(seen)
    print(("  (%s: loader discovered {%s}, %d error(s): %s)"):format(
      case.version, table.concat(seen, ", "), #(run.errors or {}),
      tostring((run.errors or {})[1] and
               ((run.errors or {})[1].message or run.errors[1]))))
  end
  T.eq(mod and mod.state, "loaded",
    ("%s: state is loaded (skipReason=%s)"):format(
      case.version, tostring(mod and mod.skipReason)))
  local errs = realErrors(run)
  T.eq(#errs, 0, ("%s: no boot errors (first: %s)"):format(
    case.version, tostring(errs[1])))

  if case.gen == 2 then
    local leaked = false
    for _, msg in ipairs(errs) do
      if msg:find(GEN1_ONLY_LEAK, 1, true) then leaked = true end
    end
    T.eq(leaked, false,
      case.version .. ": the Gen 1 arm never runs, so " .. GEN1_ONLY_LEAK ..
      " is never required")
  end
  if run.release then run.release() end
end
print("ALL TARGETED GAMES LOAD CLEAN: red, yellow, gold, silver, crystal")
print("gen 2: no Gen 1-only require leaked past the generation branch")
