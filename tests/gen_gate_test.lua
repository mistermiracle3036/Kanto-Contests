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

-- these two are the sandbox's own gaps (no ROM content loaded), the same
-- pair modkit validate reports; they are not mod defects
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

for _, case in ipairs({ { gen = 1, version = "red" },
                        { gen = 2, version = "gold" } }) do
  GameVersion.current = case.version
  local run = T.sdk.loadMod("../Kanto-Contests", { generation = case.gen })
  local mod = run.mod
  T.eq(mod and mod.state, "loaded",
    ("gen %d: state is loaded (skipReason=%s)"):format(
      case.gen, tostring(mod and mod.skipReason)))
  local errs = realErrors(run)
  T.eq(#errs, 0, ("gen %d: no boot errors (first: %s)"):format(
    case.gen, tostring(errs[1])))
  if run.release then run.release() end
end
print("BOTH GENERATIONS LOAD CLEAN")
