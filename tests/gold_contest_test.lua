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

-- Align GameVersion with the injected generation, exactly as
-- gen_gate_test does and for the same reason: the harness sets
-- loader.generation but NOT GameVersion.current, while a real boot sets
-- both. The mod reads GameVersion when registering OPP_KC_JUDGE, so
-- without this the trainer record comes out incomplete and the whole
-- mod fails schema validation -- which presents as every contest
-- assertion below failing at once, with no clue that the cause is the
-- harness rather than the code.
local GameVersion = require("src.core.GameVersion")
GameVersion.current = "gold"
local run = T.sdk.loadMod("../Kanto-Contests", { generation = 2 })
T.eq(run.mod and run.mod.state, "loaded", "mod loaded on gen 2")
-- This check fails in BURSTS (6 of 6 one minute, 0 of 6 the next) with no
-- file changed between; a standalone probe loads through the burst. Cause
-- still unknown (2026-09-01). When it fails, say everything the loader
-- knows, so the next burst is characterised rather than retried.
if not (run.mod and run.mod.state == "loaded") then
  print("  loader.errors:", #(run.errors or {}))
  for i, e in ipairs(run.errors or {}) do print("   ", i, tostring(type(e) == "table" and (e.message or e.msg) or e)) end
  for id, m in pairs(run.loader and run.loader.mods or {}) do
    print("  loader.mods:", id, m.state, m.path, m.error)
  end
  print("  disabled:", run.loader and next(run.loader.disabled or {}) or "none")
end

local Battle = require("src.battle.gen2.Battle")
local Mon = require("src.battle.gen2.Mon")

-- One move per contest category, taken from the mod's own KC_CATEGORY table,
-- plus a move of a category the mod treats as OPPOSED to each.
-- KC_OPPOSED: COOL<->BEAUTY/TOUGH, BEAUTY<->COOL/CUTE, CUTE<->BEAUTY/SMART,
-- SMART<->CUTE/TOUGH, TOUGH<->COOL/SMART.
-- One matching and one off-category move per contest, chosen from the
-- real Gen 3 table so nothing else fires: no jams, and no combo between
-- the pair (THUNDERPUNCH -> FIRE_PUNCH IS a combo, which is why the
-- off-category move is never the other elemental punch). `base` is the
-- move's own hearts; the crowd adds one to a matching move and nothing
-- to an off-category one (0 or -1 on the excitement table, floored).
--   THUNDERPUNCH COOL 40   FIRE_PUNCH BEAUTY 40   WATER_GUN CUTE 40
--   POUND TOUGH 40         DIG SMART 10 (AVOID_STARTLE; no SMART move is
--   a plain 40 in Gen 1-2)
local CASES = {
  { kind = "COOL",   match = "THUNDERPUNCH", base = 4, opposed = "WATER_GUN",  obase = 4 },
  { kind = "BEAUTY", match = "FIRE_PUNCH",   base = 4, opposed = "WATER_GUN",  obase = 4 },
  { kind = "CUTE",   match = "WATER_GUN",    base = 4, opposed = "FIRE_PUNCH", obase = 4 },
  { kind = "SMART",  match = "DIG",          base = 1, opposed = "FIRE_PUNCH", obase = 4 },
  { kind = "TOUGH",  match = "POUND",        base = 4, opposed = "THUNDERPUNCH", obase = 4 },
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
  -- types are irrelevant here (contest damage is zeroed by the
  -- battle.damage hook); the entries just have to exist for mkmon
  WATER_GUN    = move("WATER_GUN",    "NORMAL",   40),
  DIG          = move("DIG",          "NORMAL",   60),
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
-- (Battle.lua:95-105): rng(lo,hi) = lo + random(hi-lo+1).
-- highRoll maxes every roll (rng(lo,hi) -> hi); lowRoll floors it (-> lo).
-- The moves used below are chosen so nothing rolls for a jam or a nervous
-- check -- the rng only decides the rivals' stage hearts and tie-breaks.
-- Both directions are exercised.
local function highRoll(n) return (n or 1) - 1 end
local function lowRoll(_) return 0 end

local E = dofile("../Kanto-Contests/contest_engine.lua")

-- one contest; `judge` extras (kcRank, kcRivals, kcAppealHearts,
-- kcPlayerName) ride the trainer table exactly as runGoldContest sets them
local function runContest(kind, moveIds, random, extra)
  local player = mkmon("PIKACHU", 30, moveIds)
  local meter = mkmon("CHANSEY", 30, { "POUND" })
  meter.nickname = "APPEAL"
  local judge = { name = "JUDGE", baseMoney = 0, party = { meter },
                  kcContest = kind }
  for k, v in pairs(extra or {}) do judge[k] = v end
  local save = { party = { player }, player = { id = 1, badges = {} } }
  local battle = Battle.new({ data = DATA, party = { player },
                              trainer = judge, save = save,
                              random = random or highRoll })
  return battle, meter, player
end

local function drainFor(meter, hearts)
  return math.max(1, math.floor(meter.stats.hp * hearts / 40))
end

-- Every category: a move OF the contest's category earns the crowd's
-- +1 heart on top of its 4 (40 points); an OPPOSED move keeps its 4 but
-- the crowd gives nothing. Gen 3 never zeroes an appeal for category --
-- the old "opposed scores nothing" rule is gone.
for _, case in ipairs(CASES) do
  local battle, meter = runContest(case.kind, { case.match, case.opposed })
  local before = meter.hp
  battle:takeTurn({ kind = "move", move = case.match })
  T.eq(before - meter.hp, drainFor(meter, case.base + 1),
    ("%s: %s matches -> %d hearts + 1 from the crowd"):format(case.kind, case.match, case.base))
  before = meter.hp
  battle:takeTurn({ kind = "move", move = case.opposed })
  T.eq(before - meter.hp, drainFor(meter, case.obase),
    ("%s: %s is off-category -> %d hearts, no crowd"):format(case.kind, case.opposed, case.obase))
  T.eq(battle.kcState.turn, 2, ("%s: two appeals in"):format(case.kind))
  T.check(not battle.over,
    ("%s: two appeals in, the contest is still running"):format(case.kind))
end

-- 1. Five appeals end the contest, whatever the meter shows. The verdict is
--    E.final's, and the outcome string follows the placing.
do
  local battle, meter = runContest("TOUGH", { "THUNDERPUNCH" })
  for _ = 1, 5 do battle:takeTurn({ kind = "move", move = "THUNDERPUNCH" }) end
  T.check(battle.over, "TOUGH: contest ends after five appeals")
  T.eq(battle.kcState.turn, 5, "TOUGH: the engine counted five turns")
  T.check(meter.hp > 0, "TOUGH: the meter mon never faints")
  T.check(battle.kcPlace ~= nil, "a placing was decided")
  T.eq(battle.outcome, battle.kcPlace == 1 and "win" or "run",
    "win exactly when placed 1st, otherwise a clean run")
end

-- 2. The repeat penalty. Five THUNDERPUNCH in TOUGH (opposed: 40, no
--    crowd) go 40, 20, 10, 0, -10 -- pokeemerald's (repeatCount+1)*10.
do
  local battle = runContest("TOUGH", { "THUNDERPUNCH" })
  for _ = 1, 5 do battle:takeTurn({ kind = "move", move = "THUNDERPUNCH" }) end
  T.eq(battle.kcState.c[1].total, 60, "40+20+10+0-10: the repeat penalty bites")
end

-- 3. The crowd. Two COOL moves alternated in a COOL contest never
--    repeat, so the meter climbs 1,2,3,4 and the fifth matching appeal
--    tips it: +60 instead of +10, then it resets. COOL on purpose: the
--    headless rivals only know POUND (TOUGH), and TOUGH is exactly 0 to a
--    COOL crowd, so the meter is the player's alone and the arithmetic
--    does not depend on who appealed first. (A first draft used BEAUTY,
--    where TOUGH is -1: three rivals then LOWER the meter by 3 a turn,
--    which is Gen 3 behaving correctly and the test being wrong.)
--    STRUGGLE is COOL in Gen 3, a plain 40 with no combo links either way,
--    so THUNDERPUNCH's armed starter simply lapses each turn.
do
  local battle = runContest("COOL", { "THUNDERPUNCH", "STRUGGLE" })
  local seq = { "THUNDERPUNCH", "STRUGGLE", "THUNDERPUNCH", "STRUGGLE", "THUNDERPUNCH" }
  for i = 1, 4 do
    battle:takeTurn({ kind = "move", move = seq[i] })
    T.eq(battle.kcState.applause, i, ("applause meter at %d after appeal %d"):format(i, i))
  end
  battle:takeTurn({ kind = "move", move = seq[5] })
  T.eq(battle.kcState.applause, 0, "the meter resets after going wild")
  T.eq(battle.kcState.c[1].total, 50 * 4 + 100, "4 x 50, then 40 + 60: the crowd went wild")
end

-- 4. What the stage hands the judging: the three coordinators by name and
--    their stage hearts (x20 points), the rank, and the player's name.
do
  local battle = runContest("TOUGH", { "POUND" }, nil, {
    kcRank = "MASTER",
    kcRivals = { { name = "WHITNEY" }, { name = "BUG CATCHER" }, { name = "LYRA" } },
    kcAppealHearts = { 3, 4, 5 },
    kcPlayerName = "GOLD",
  })
  battle:takeTurn({ kind = "move", move = "POUND" })
  local s = battle.kcState
  T.eq(s.c[1].name, "GOLD", "the player appeals under their own name")
  T.same({ s.c[2].name, s.c[3].name, s.c[4].name },
         { "WHITNEY", "BUG CATCHER", "LYRA" }, "the stage's coordinators are the judging's rivals")
  T.same({ s.c[2].round1, s.c[3].round1, s.c[4].round1 }, { 60, 80, 100 },
         "stage hearts carry over at 20 points each")
  T.eq(s.c[2].ai, "MASTER", "rivals think at the contest's rank")
  T.eq(s.c[1].ai, "player", "the player is never driven by the AI")
end

-- 5. Without a stage (headless, or a contest entered some other way) the
--    rivals fall back to the legacy names and roll their stage hearts on
--    the battle rng -- high roll 6, low roll 2 -- and the round still runs.
do
  local hi = runContest("TOUGH", { "POUND" }, highRoll)
  hi:takeTurn({ kind = "move", move = "POUND" })
  T.eq(hi.kcState.c[2].name, "PIPER", "no stage: legacy rival names")
  T.eq(hi.kcState.c[2].round1, 120, "no stage, high roll: 6 hearts x 20")
  local lo = runContest("TOUGH", { "POUND" }, lowRoll)
  lo:takeTurn({ kind = "move", move = "POUND" })
  T.eq(lo.kcState.c[2].round1, 40, "no stage, low roll: 2 hearts x 20")
end

-- 6. The final tally is E.final's: round1 + 2 x appeals for all four, and
--    the player's placing is where their row landed.
do
  local battle = runContest("TOUGH", { "POUND", "STRUGGLE" })
  local seq = { "POUND", "STRUGGLE", "POUND", "STRUGGLE", "POUND" }
  for i = 1, 5 do battle:takeTurn({ kind = "move", move = seq[i] }) end
  local s = battle.kcState
  local final = E.final(s)
  for _, r in ipairs(final) do
    T.eq(r.total, s.c[r.who].round1 + 2 * s.c[r.who].total,
      ("final total for contestant %d = round1 + 2 x appeals"):format(r.who))
  end
  local mine
  for _, r in ipairs(final) do if r.who == 1 then mine = r end end
  T.eq(mine.total, s.c[1].round1 + 2 * s.c[1].total, "player's final = round1 + 2 x appeals")
  T.check(battle.kcPlace >= 1 and battle.kcPlace <= 4, "placing is 1..4")
end

T.finish("gold contest")
