-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/credits_test.lua [mod dir]
--
-- The in-game credits screen (0.37.33) is EMBEDDED, not built here:
-- lib/credits.lua is shared code and lib/credits_data.lua is generated from
-- sprites/REGISTRY.json, both copied byte-for-byte and never edited. So what
-- is worth asserting is the part this mod owns -- that attaching it really
-- puts ONE row in the START menu carrying THIS mod's artists, and that a
-- second mod embedding the same library still leaves one row with both mods'
-- artists merged. Neither is visible in a compile, and the failure mode
-- (two CREDITS rows, or none) only shows on a device.
package.path = "./?.lua;./?/init.lua;" .. package.path
local T = require("tests.modkit")
love = love or require("tests.love_stub")
local GameVersion = require("src.core.GameVersion")
GameVersion.current = "gold"
-- The checkout stamps 0.0.0-dev (CI fills the real number in), which no
-- mod's game_version range can satisfy -- an unsatisfied range is a SKIP,
-- and a skipped mod reads exactly like a missing one. Same line as
-- tests/release_behavior_test.lua and tests/gen_gate_test.lua.
require("src.core.Version").engine = "0.2.24"

-- The mod directory, so this can also run against a copy of the tree: the
-- harness's Windows directory probe renames a folder to itself and is denied
-- while any shell sits in it (NOTES.md), which reads as "mod absent".
local MOD = ((arg and arg[1]) or "../Kanto-Contests"):gsub("\\", "/")
-- Split into parent + folder: the harness filesystem always prefixes its
-- root (tests/fs_io.lua abs()), so an absolute path handed to loadMod
-- becomes "./C:/..." and the mod is silently never discovered. Same split
-- as tests/release_behavior_test.lua.
local ROOT, FOLDER = MOD:match("^(.*)/([^/]+)$")
assert(ROOT and FOLDER, "pass the mod directory")

local run
for attempt = 1, 4 do
  run = T.sdk.loadMods({ FOLDER }, { generation = 2, root = ROOT })
  run.mod = select(2, next(run.mods))
  if run.mod and run.mod.state == "loaded" then break end
  if #(run.errors or {}) > 0 then break end
  run.release()
  local until_ = os.clock() + 0.4
  while os.clock() < until_ do end
end
T.eq(run.mod and run.mod.state, "loaded", "mod loaded on gen 2")

-- The menu the engine would hand the hook chain: StartMenu.lua builds a list
-- and passes it through ui.start_menu.items, keeping whatever comes back.
local Runtime = require("src.mods.Runtime")
local function startMenuRows()
  local items = { { id = "pokemon", label = "POKeMON" }, { id = "exit", label = "EXIT" } }
  return Runtime.call("ui.start_menu.items", function(_, list) return list end,
    { save = {}, stack = { top = function() return nil end } }, items)
end

local rows = startMenuRows()
T.check(type(rows) == "table", "the hook returns a list")

local credits = {}
for _, row in ipairs(rows) do
  if row.label == "CREDITS" then credits[#credits + 1] = row end
end
T.eq(#credits, 1, "exactly one CREDITS row")
local row = credits[1]
T.check(row ~= nil and type(row.creditsEntries) == "table", "the row carries entries")
T.check(row and row.onSelect ~= nil, "the row can be selected")

-- Every artist in the generated data reaches the row, once each.
local data = assert(loadfile(MOD .. "/lib/credits_data.lua"))()
T.check(#data > 0, "the generated data is not empty")
local seen = {}
for _, entry in ipairs(row.creditsEntries) do
  T.check(not seen[entry.artist], "no artist is listed twice: " .. tostring(entry.artist))
  seen[entry.artist] = true
end
local missing = {}
for _, entry in ipairs(data) do
  if not seen[entry.artist] then missing[#missing + 1] = entry.artist end
end
T.eq(#missing, 0, "every artist in lib/credits_data.lua is on the row"
  .. (#missing > 0 and (" -- missing " .. table.concat(missing, ", ")) or ""))
T.check(seen["Bani"] and seen["Blaklyte"], "a couple of known names are really there")

-- A SECOND mod embedding the same library: one row still, and its artists
-- merge in beside ours. This is the whole point of the election, and it
-- cannot be checked from this mod's code alone.
local lib = assert(loadfile(MOD .. "/lib/credits.lua"))()
local other = {
  id = "other_mod",
  ui = run.mod.api and run.mod.api.ui or require("src.ui.ModUI"),
  log = { info = function() end, warn = function() end },
  -- Hooks:wrap(name, callback, priority, owner) -- the loader binds a mod's
  -- own hooks table to exactly this (src/mods/Loader.lua).
  hooks = { wrap = function(_, name, fn) return Runtime.hooks:wrap(name, fn, 0, "other_mod") end },
}
lib.attach(other, { { artist = "A Second Mod's Artist", works = { "Someone" },
                      mods = { "Other Mod" } } })

local rows2 = startMenuRows()
local credits2 = {}
for _, r in ipairs(rows2) do
  if r.label == "CREDITS" then credits2[#credits2 + 1] = r end
end
T.eq(#credits2, 1, "two embedding mods still make exactly one CREDITS row")
local both = {}
for _, entry in ipairs(credits2[1].creditsEntries) do both[entry.artist] = true end
T.check(both["Bani"], "our artists survive the second mod's registration")
T.check(both["A Second Mod's Artist"], "the second mod's artists are merged in")

run.release()
T.finish("credits screen")
