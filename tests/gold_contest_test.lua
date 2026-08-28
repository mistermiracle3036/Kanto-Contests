-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/gold_contest_test.lua
--
-- Drives the REAL mod's hooks through Gold's REAL Battle, headlessly and
-- without a ROM, once per contest category.
--
-- This exists because 0.11.0 turned a COOL-only contest into five, and the
-- five-way behaviour is exactly what a Gold device round is worst at
-- checking: a wrong category scores silently, and "the meter did not move"
-- looks identical to "the move was opposed". Asserting it here means a
-- device test only has to confirm the menu and the wiring.
--
-- It also replaces coverage that was lost: 0.10.3/0.10.4 added a Gold battle
-- regression test, but release zips exclude tests/ and those versions only
-- ever existed as zips, so the files never reached the repo.
package.path = "./?.lua;./?/init.lua;" .. package.path
local T = require("tests.modkit")
love = love or require("tests.love_stub")

local GameVersion = require("src.core.GameVersion")
GameVersion.current = "gold"
local run = T.sdk.loadMod("../Kanto-Contests", { generation = 2 })
T.eq(run.mod and run.mod.state, "loaded", "mod loaded on gen 2")

local Battle = require("src.battle.gen2.Battle")
local Mon = require("src.battle.gen2.Mon")

-- One move per contest category, taken from the mod's own KC_CATEGORY table,
-- plus a move of a category the mod treats as OPPOSED to each.
-- KC_OPPOSED: COOL<->BEAUTY/TOUGH, BEAUTY<->COOL/CUTE, CUTE<->BEAUTY/SMART,
-- SMART<->CUTE/TOUGH, TOUGH<->COOL/SMART.
local CASES = {
  { kind = "COOL",   match = "THUNDERPUNCH", opposed = "FIRE_PUNCH" },  -- BEAUTY
  { kind = "BEAUTY", match = "FIRE_PUNCH",   opposed = "THUNDERPUNCH" },-- COOL
  { kind = "CUTE",   match = "DOUBLESLAP",   opposed = "FIRE_PUNCH" },  -- BEAUTY
  { kind = "SMART",  match = "PAY_DAY",      opposed = "DOUBLESLAP" },  -- CUTE
  { kind = "TOUGH",  match = "POUND",        opposed = "THUNDERPUNCH" },-- COOL
}

local TYPES = {
  NORMAL   = { id = "NORMAL",   index = 0, category = "physical" },
  FIRE     = { id = "FIRE",     index = 20, category = "special" },
  ELECTRIC = { id = "ELECTRIC", index = 4,  category = "special" },
}
local function move(id, mtype, power)
  return { id = id, name = id, power = power, type = mtype,
           accuracy = 100, pp = 20, effect = "EFFECT_NORMAL_HIT" }
end
local MOVES = {
  THUNDERPUNCH = move("THUNDERPUNCH", "ELECTRIC", 75),
  FIRE_PUNCH   = move("FIRE_PUNCH",   "FIRE",     75),
  DOUBLESLAP   = move("DOUBLESLAP",   "NORMAL",   15),
  PAY_DAY      = move("PAY_DAY",      "NORMAL",   40),
  POUND        = move("POUND",        "NORMAL",   40),
  STRUGGLE     = move("STRUGGLE",     "NORMAL",   40),
}
local POKEMON = {
  growthRates = { GROWTH_MEDIUM_FAST = { numerator = 1, denominator = 1,
    squared = 0, linear = 0, constant = 0 } },
  -- the entrant: high enough level that every appeal move is usable
  PIKACHU = { id = "PIKACHU", index = 25, name = "PIKACHU",
    baseStats = { hp = 35, attack = 55, defense = 40, speed = 90,
      specialAttack = 50, specialDefense = 50 },
    types = { "ELECTRIC", "ELECTRIC" }, catchRate = 190, baseExp = 82,
    growthRate = "GROWTH_MEDIUM_FAST", genderRatio = 127,
    levelMoves = {}, evolutions = {} },
  -- CHANSEY is the appeal meter: the biggest HP pool in the game, so an
  -- appeal reads as a percentage rather than a knockout
  CHANSEY = { id = "CHANSEY", index = 113, name = "CHANSEY",
    baseStats = { hp = 250, attack = 5, defense = 5, speed = 50,
      specialAttack = 35, specialDefense = 105 },
    types = { "NORMAL", "NORMAL" }, catchRate = 30, baseExp = 255,
    growthRate = "GROWTH_MEDIUM_FAST", genderRatio = 254,
    levelMoves = {}, evolutions = {} },
}
local DATA = { pokemon = POKEMON, moves = MOVES,
               type_chart = { types = TYPES, matchups = {} }, items = {} }

local function mkmon(species, level, moves)
  local m = Mon.new(DATA, species, level)
  m.moves = {}
  for _, id in ipairs(moves) do
    m.moves[#m.moves + 1] = { id = id, pp = MOVES[id].pp, maxPp = MOVES[id].pp }
  end
  return m
end

-- Battle.random(n) -> 0..n-1, and Battle.rng is loveStyleRng over it
-- (Battle.lua:86-105): rng(lo,hi) = lo + random(hi-lo+1).
-- neverJam maxes every roll: rng(1,100) -> 100 > 30, so no rival ever
-- jams and the category assertions below measure pure appeal scoring.
-- alwaysJam floors every roll: rng(1,100) -> 1, rng(1,3) -> 1 (PIPER),
-- rng(2,6) -> 2 hearts.
local function neverJam(n) return (n or 1) - 1 end
local function alwaysJam(_) return 0 end

-- one contest, returning how far the meter moved for each move
local function runContest(kind, moveIds, random)
  local player = mkmon("PIKACHU", 30, moveIds)
  local meter = mkmon("CHANSEY", 30, { "POUND" })
  meter.nickname = "APPEAL"
  local judge = { name = "JUDGE", baseMoney = 0, party = { meter },
                  kcContest = kind }
  local save = { party = { player }, player = { id = 1, badges = {} } }
  local battle = Battle.new({ data = DATA, party = { player },
                              trainer = judge, save = save,
                              random = random or neverJam })
  return battle, meter, player
end

for _, case in ipairs(CASES) do
  local battle, meter = runContest(case.kind, { case.match, case.opposed })

  -- a move OF the contest's category drains the meter
  local before = meter.hp
  battle:takeTurn({ kind = "move", move = case.match })
  local matched = before - meter.hp
  T.check(matched > 0,
    ("%s: %s is a %s move and must score (drained %d)")
      :format(case.kind, case.match, case.kind, matched))

  -- a move of an OPPOSED category scores nothing
  before = meter.hp
  battle:takeTurn({ kind = "move", move = case.opposed })
  local opposedDrain = before - meter.hp
  T.eq(opposedDrain, 0,
    ("%s: %s is opposed and must score nothing")
      :format(case.kind, case.opposed))

  T.check(not battle.over,
    ("%s: two appeals in, the contest is still running"):format(case.kind))
end

-- The two ways a contest ends, both in a NON-COOL contest -- the whole point
-- of 0.11.0 is that these no longer only work for COOL.

-- 1. Out of appeals. Five OPPOSED moves score nothing, so the meter never
--    fills and the round limit is what stops it: a clean "run", no blackout.
do
  local battle, meter = runContest("TOUGH", { "THUNDERPUNCH" })
  for _ = 1, 5 do battle:takeTurn({ kind = "move", move = "THUNDERPUNCH" }) end
  T.check(battle.over, "TOUGH: contest ends after five appeals")
  T.eq(battle.outcome, "run",
    "TOUGH: running out of appeals ends as a run, not a knockout")
  T.check(meter.hp > 0, "TOUGH: the meter mon never faints")
end

-- 2. The meter fills. Five MATCHING moves score every time, which is a win --
--    and it must arrive as a win rather than as the meter mon fainting
--    (0.10.7: the contest ends before Gold's normal faint resolver, so the
--    judge is never announced as defeated and no prize money is paid).
do
  local battle, meter = runContest("TOUGH", { "POUND" })
  for _ = 1, 5 do
    if not battle.over then battle:takeTurn({ kind = "move", move = "POUND" }) end
  end
  T.check(battle.over, "TOUGH: filling the meter ends the contest")
  T.eq(battle.outcome, "win", "TOUGH: a filled meter is a win")
end

-- 3. Rival jams (0.12.0). With every roll floored, a rival jams each
--    eligible round: never round 1, then rounds 2 and 3, then the cap of
--    two stops rounds 4 and 5. FIRE_PUNCH is BEAUTY, neutral in TOUGH
--    (opposed there is COOL/SMART), so every appeal drains exactly 10%
--    and the arithmetic below is closed-form.
do
  local battle, meter = runContest("TOUGH", { "FIRE_PUNCH" }, alwaysJam)
  local maxhp = meter.stats.hp
  local appeal = math.ceil(maxhp * 0.10)
  local heal = math.ceil(maxhp * 0.08)

  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  T.eq(battle.kcJams or 0, 0, "round 1 never jams, even with the roll floored")
  T.eq(meter.hp, maxhp - appeal, "round 1 is pure appeal drain")
  T.same(battle.kcRivalHearts, { 2, 2, 2 },
    "rival hearts rolled through the battle rng (floored -> 2 each)")

  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  T.eq(battle.kcJams, 1, "round 2 jams")
  T.eq(meter.hp, maxhp - 2 * appeal + heal,
    "the jam healed 8% of the meter back")

  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  T.eq(battle.kcJams, 2, "round 3 jams again")

  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  T.eq(battle.kcJams, 2, "the cap of two holds from round 4 on")
  T.eq(meter.hp, maxhp - 4 * appeal + 2 * heal,
    "meter arithmetic exact across appeals and jams")

  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  T.check(battle.over, "the five-appeal limit still ends the contest")
  T.eq(battle.outcome, "run", "jammed contest still exits as a clean run")
end

-- 3b. The rivals APPEAL every round (0.13.2). Before this they were
--     announced once and then only surfaced on a jam roll, so a whole
--     contest could pass with them doing nothing -- which is how it read
--     on device. One rival performs per round, rotating, and their
--     scores accumulate toward the final placement.
do
  local battle, meter = runContest("TOUGH", { "FIRE_PUNCH" })
  T.eq(battle.kcRivalScore, nil, "no rival scores before the contest opens")

  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  T.check(type(battle.kcRivalScore) == "table",
    "the introduction seeds the rival scoreboard")
  local scored = 0
  for i = 1, 3 do
    if (battle.kcRivalScore[i] or 0) > 0 then scored = scored + 1 end
  end
  T.eq(scored, 1, "exactly ONE rival appeals in round 1, not all three")
  T.check((battle.kcRivalScore[1] or 0) > 0,
    "the rotation starts with the first coordinator")
  T.check((battle.kcPlayerScore or 0) > 0,
    "the player's own appeal scores in the same currency")

  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  T.check((battle.kcRivalScore[2] or 0) > 0,
    "round 2 hands the turn to the next coordinator")

  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  T.check((battle.kcRivalScore[3] or 0) > 0,
    "round 3 reaches the third, so all three are seen in one contest")

  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" })
  T.check(battle.over, "five appeals still end it")
  -- neutral appeals only: 5 x 10 points, which the rivals can beat, so a
  -- placement is computed rather than assumed
  T.check(battle.kcPlayerScore == 50,
    "five neutral appeals score 50 (10 each)")
end

-- 4. And with sane rolls, jams never fire here: the neverJam default
--    maxes rng(1,100), so scoring stays exactly the pre-0.12.0 numbers --
--    which is also what keeps every assertion above this block honest.
do
  local battle, meter = runContest("TOUGH", { "FIRE_PUNCH" })
  local maxhp = meter.stats.hp
  for _ = 1, 4 do battle:takeTurn({ kind = "move", move = "FIRE_PUNCH" }) end
  T.eq(battle.kcJams or 0, 0, "no jam at 100-roll: chance gate works")
  T.eq(meter.hp, maxhp - 4 * math.ceil(maxhp * 0.10),
    "pure drain when no rival interferes")
end

T.finish("gold contest")
