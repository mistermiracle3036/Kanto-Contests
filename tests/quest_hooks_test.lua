-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/quest_hooks_test.lua
--
-- The quest hook's data side (briefs/KANTO_CONTESTS_QUEST_HOOKS.md): the
-- cast-plan validator applies a good plan whole and ignores a bad one whole,
-- the payload builder is plain data, and the exports another mod reads exist.
-- The event/hold/resume flow needs a live stage and is on the device list.
package.path = "./?.lua;./?/init.lua;" .. package.path
local T = require("tests.modkit")
love = love or require("tests.love_stub")
local GameVersion = require("src.core.GameVersion")
GameVersion.current = "gold"

local run
for attempt = 1, 4 do
  run = T.sdk.loadMod("../Kanto-Contests", { generation = 2 })
  if run.mod and run.mod.state == "loaded" then break end
  if #(run.errors or {}) > 0 then break end
  run.release()
  local until_ = os.clock() + 0.4
  while os.clock() < until_ do end
end
T.eq(run.mod and run.mod.state, "loaded", "mod loaded on gen 2")

local exports = run.loader and run.loader.exports and run.loader.exports.kanto_contests
T.check(type(exports) == "table", "kanto_contests exports exist")
T.eq(exports and exports.questHooks, 1, "questHooks version is 1")
T.eq(type(exports and exports.lastContest), "function", "lastContest() is exported")
T.eq(exports and exports.lastContest(), nil, "no contest yet -> lastContest() is nil")

local test = exports and exports._test
T.check(type(test) == "table" and type(test.applyCastPlan) == "function", "_test.applyCastPlan exposed")

if test then
  local world = { sprites = { SPRITE_JQP_DUPLICA = {}, SPRITE_LASS = {} } }
  local function lineup() return { "SPRITE_KC_ASH", "SPRITE_LASS", "SPRITE_BIKER" } end
  local function plan(p) test.setSave({ kcCastPlan = p }) end

  plan(nil)
  local c = lineup()
  T.eq(test.applyCastPlan(world, c, "COOL"), nil, "no plan -> nil (nothing to apply)")
  T.eq(c[1], "SPRITE_KC_ASH", "no plan leaves the draw alone")

  plan({ tag = "t", slots = { [2] = { sprite = "SPRITE_JQP_DUPLICA", name = "DUPLICA" } } })
  c = lineup()
  T.eq(test.applyCastPlan(world, c, "COOL"), nil, "a good plan applies")
  T.eq(c[2], "SPRITE_JQP_DUPLICA", "slot 2 is the planned sprite")
  T.eq(c[1], "SPRITE_KC_ASH", "other slots untouched")

  plan({ slots = { [1] = { sprite = "SPRITE_JQP_DUPLICA" }, [3] = { sprite = "SPRITE_NOBODY" } } })
  c = lineup()
  T.eq(test.applyCastPlan(world, c, "COOL"), "sprite", "an unknown sprite ignores the plan")
  T.eq(c[1], "SPRITE_KC_ASH", "...and applies NOTHING (no half line-up)")

  plan({ slots = { [4] = { sprite = "SPRITE_LASS" } } })
  c = lineup()
  T.eq(test.applyCastPlan(world, c, "COOL"), "slot", "slot 4 does not exist")

  plan({ hall = "ECRUTEAK", slots = { [1] = { sprite = "SPRITE_LASS" } } })
  c = lineup()
  T.eq(test.applyCastPlan(world, c, "COOL"), "hall", "another hall's plan is skipped here")

  plan({ kinds = { "CUTE" }, slots = { [1] = { sprite = "SPRITE_LASS" } } })
  c = lineup()
  T.eq(test.applyCastPlan(world, c, "COOL"), "kinds", "a CUTE-only plan is skipped for COOL")
  c = lineup()
  T.eq(test.applyCastPlan(world, c, nil), nil, "...but the queue (kind unknown) applies it")
  T.eq(c[1], "SPRITE_LASS", "queue slot 1 is the planned sprite")

  plan({ slots = { ["2"] = { sprite = "SPRITE_LASS" } } })
  c = lineup()
  T.eq(test.applyCastPlan(world, c, "COOL"), nil, "string slot keys are accepted")
  T.eq(c[2], "SPRITE_LASS", "...and land on the right slot")

  plan(nil)
  local p = test.contestPayload(nil, nil)
  T.eq(type(p), "table", "contestPayload builds a table")
  T.eq(type(p.coordinators), "table", "...with a coordinators table")
  local hasFn = false
  for _, v in pairs(p) do if type(v) == "function" then hasFn = true end end
  T.check(not hasFn, "the payload is plain data (no functions) before the emitter adds resume")
end

T.finish("quest hooks")
