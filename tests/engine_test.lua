-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/engine_test.lua
--
-- Drives contest_engine.lua headless: a stub move table with one move per
-- effect family, a scripted rng, and pokeemerald's numbers as the oracle
-- (briefs/GEN3_CONTEST_RULES.md). No engine, no love, no mod load -- the
-- module is pure, and this test is what keeps it that way.
package.path = "./?.lua;./?/init.lua;" .. package.path
local T = require("tests.harness")

local E = dofile("../Kanto-Contests/contest_engine.lua")

-- ---------------------------------------------------------------- fixtures

-- Only the fields the engine reads: appeal, jam, and the effect name.
local FX = {
  HIGHLY_APPEALING                    = { appeal = 40, jam = 0 },
  USER_MORE_EASILY_STARTLED           = { appeal = 60, jam = 0 },
  GREAT_APPEAL_BUT_NO_MORE_MOVES      = { appeal = 80, jam = 0 },
  REPETITION_NOT_BORING               = { appeal = 30, jam = 0 },
  AVOID_STARTLE_ONCE                  = { appeal = 20, jam = 0 },
  AVOID_STARTLE                       = { appeal = 10, jam = 0 },
  STARTLE_FRONT_MON                   = { appeal = 30, jam = 20 },
  BADLY_STARTLE_FRONT_MON             = { appeal = 10, jam = 40 },
  BADLY_STARTLE_PREV_MONS             = { appeal = 10, jam = 30 },
  STARTLE_MON_WITH_JUDGES_ATTENTION   = { appeal = 20, jam = 10 },
  JAMS_OTHERS_BUT_MISS_ONE_TURN       = { appeal = 40, jam = 40 },
  STARTLE_MONS_SAME_TYPE_APPEAL       = { appeal = 20, jam = 10 },
  BADLY_STARTLE_MONS_WITH_GOOD_APPEALS= { appeal = 20, jam = 10 },
  MAKE_FOLLOWING_MONS_NERVOUS         = { appeal = 20, jam = 0 },
  BETTER_IF_FIRST                     = { appeal = 20, jam = 0 },
  BETTER_IF_LAST                      = { appeal = 20, jam = 0 },
  APPEAL_AS_GOOD_AS_PREV_ONE          = { appeal = 10, jam = 0 },
  BETTER_WHEN_LATER                   = { appeal = 10, jam = 0 },
  BETTER_IF_SAME_TYPE                 = { appeal = 20, jam = 0 },
  AFFECTED_BY_PREV_APPEAL             = { appeal = 30, jam = 0 },
  IMPROVE_CONDITION_PREVENT_NERVOUSNESS = { appeal = 10, jam = 0 },
  NEXT_APPEAL_EARLIER                 = { appeal = 30, jam = 0 },
  BETTER_WHEN_AUDIENCE_EXCITED        = { appeal = 10, jam = 0 },
  DONT_EXCITE_AUDIENCE                = { appeal = 30, jam = 0 },
  EXCITE_AUDIENCE_IN_ANY_CONTEST      = { appeal = 10, jam = 0 },
}

local MV = {
  POUND        = { cat = "TOUGH",  effect = "HIGHLY_APPEALING", starter = "POUND" },
  DOUBLESLAP   = { cat = "TOUGH",  effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", after = { "POUND" } },
  THUNDERPUNCH = { cat = "COOL",   effect = "HIGHLY_APPEALING", starter = "THUNDER_PUNCH" },
  FIRE_PUNCH   = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", starter = "FIRE_PUNCH",
                   after = { "THUNDER_PUNCH" } },
  SWIFT        = { cat = "COOL",   effect = "BETTER_IF_FIRST" },
  TAIL_WHIP    = { cat = "CUTE",   effect = "BETTER_IF_LAST" },
  STOMP        = { cat = "TOUGH",  effect = "BADLY_STARTLE_FRONT_MON" },
  HEADBUTT     = { cat = "TOUGH",  effect = "STARTLE_FRONT_MON" },
  ROCK_SLIDE   = { cat = "TOUGH",  effect = "BADLY_STARTLE_PREV_MONS" },
  THRASH       = { cat = "TOUGH",  effect = "JAMS_OTHERS_BUT_MISS_ONE_TURN" },
  SEISMIC_TOSS = { cat = "TOUGH",  effect = "STARTLE_MONS_SAME_TYPE_APPEAL" },
  SUPER_FANG   = { cat = "TOUGH",  effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS" },
  SING         = { cat = "CUTE",   effect = "MAKE_FOLLOWING_MONS_NERVOUS" },
  HARDEN       = { cat = "TOUGH",  effect = "AVOID_STARTLE_ONCE" },
  BIDE         = { cat = "TOUGH",  effect = "AVOID_STARTLE" },
  MIMIC        = { cat = "CUTE",   effect = "APPEAL_AS_GOOD_AS_PREV_ONE" },
  FLAIL        = { cat = "CUTE",   effect = "BETTER_WHEN_LATER" },
  COMET_PUNCH  = { cat = "TOUGH",  effect = "BETTER_IF_SAME_TYPE" },
  SLASH        = { cat = "COOL",   effect = "AFFECTED_BY_PREV_APPEAL" },
  GROWTH       = { cat = "BEAUTY", effect = "IMPROVE_CONDITION_PREVENT_NERVOUSNESS" },
  AGILITY      = { cat = "COOL",   effect = "NEXT_APPEAL_EARLIER" },
  RAGE         = { cat = "COOL",   effect = "REPETITION_NOT_BORING" },
  MAGNITUDE    = { cat = "TOUGH",  effect = "BETTER_WHEN_AUDIENCE_EXCITED" },
  WRAP         = { cat = "TOUGH",  effect = "DONT_EXCITE_AUDIENCE" },
  RETURN       = { cat = "CUTE",   effect = "EXCITE_AUDIENCE_IN_ANY_CONTEST" },
  EXPLOSION    = { cat = "BEAUTY", effect = "GREAT_APPEAL_BUT_NO_MORE_MOVES" },
  TAKE_DOWN    = { cat = "TOUGH",  effect = "USER_MORE_EASILY_STARTLED" },
}

-- rng that always answers the LOW end: shuffles are identity, odds fail
-- unless the threshold is 100, "random tie" is deterministic.
local function lowRng(lo, hi) return hi and lo or 1 end
-- ...and one that answers the HIGH end
local function highRng(lo, hi) return hi or lo end

local function mon(...)
  local m = { moves = {} }
  for _, id in ipairs({ ... }) do m.moves[#m.moves + 1] = { id = id, pp = 10 } end
  return m
end

-- four contestants with descending round-1 points, so turn 1 order is 1,2,3,4
local function contest(kind, rng, r1)
  r1 = r1 or { 40, 30, 20, 10 }
  return E.new({
    contest = kind, moves = MV, effects = FX, rng = rng or lowRng,
    contestants = {
      { name = "A", mon = mon("POUND"), round1 = r1[1] },
      { name = "B", mon = mon("POUND"), round1 = r1[2] },
      { name = "C", mon = mon("POUND"), round1 = r1[3] },
      { name = "D", mon = mon("POUND"), round1 = r1[4] },
    },
  })
end

local function kinds(ev)
  local out = {}
  for _, e in ipairs(ev) do out[#out + 1] = e.kind end
  return table.concat(out, ",")
end

-- --------------------------------------------------------------- 1. order

do
  local s = contest("TOUGH")
  local order = E.beginTurn(s)
  T.same(order, { [0] = 1, 2, 3, 4 }, "turn 1 order follows round-1 points")
  T.eq(s.c[1].order, 0, "leader appeals first")
  T.eq(s.c[4].order, 3, "trailer appeals last")
end

-- ---------------------------------------------------------- 2. base + crowd

do
  local s = contest("TOUGH")
  E.beginTurn(s)
  local ev = E.appeal(s, 1, "POUND")
  -- 40 base, +0 condition, +10 crowd (TOUGH move in a TOUGH contest)
  T.eq(s.c[1].appeal, 50, "matching move: 40 base + 10 crowd")
  T.eq(s.applause, 1, "applause meter rose by one")
  T.check(kinds(ev):find("attention"), "POUND is a combo starter: judge's attention")
  T.check(kinds(ev):find("crowd_up"), "crowd_up event emitted")

  local s2 = contest("BEAUTY")
  E.beginTurn(s2)
  E.appeal(s2, 1, "POUND")
  T.eq(s2.c[1].appeal, 40, "opposed move (TOUGH in BEAUTY): base only, no crowd bonus")
  T.eq(s2.applause, 0, "meter cannot go below zero")
end

-- ---------------------------------------------------- 3. crowd goes wild

do
  local s = contest("TOUGH")
  s.applause = 4
  E.beginTurn(s)
  E.appeal(s, 1, "POUND")
  T.eq(s.c[1].appeal, 100, "meter passing 4: +60 instead of +10")
  T.eq(s.applause, 0, "and the meter resets")
end

-- ---------------------------------------------------- 4. repeat penalty

do
  local s = contest("BEAUTY")          -- BEAUTY so POUND earns no crowd bonus
  E.beginTurn(s); E.appeal(s, 1, "POUND"); E.endTurn(s)
  E.beginTurn(s); E.appeal(s, 1, "POUND")
  T.eq(s.c[1].appeal, 20, "second use in a row: 40 - 20")
  E.endTurn(s)
  E.beginTurn(s); E.appeal(s, 1, "POUND")
  T.eq(s.c[1].appeal, 10, "third use in a row: 40 - 30")
  E.endTurn(s)
  E.beginTurn(s); local ev = E.appeal(s, 1, "RAGE")
  T.eq(s.c[1].repeatCount, 0, "a different move resets the count")
  E.endTurn(s)
  E.beginTurn(s); E.appeal(s, 1, "RAGE")
  T.eq(s.c[1].appeal, 30, "REPETITION_NOT_BORING: repeated without penalty")
end

-- ---------------------------------------------------------- 5. combos

do
  local s = contest("SMART")           -- neutral to COOL and BEAUTY: no crowd noise
  E.beginTurn(s); E.appeal(s, 1, "THUNDERPUNCH")
  T.check(s.c[1].attention, "starter arms the judge's attention")
  E.endTurn(s)
  E.beginTurn(s); local ev = E.appeal(s, 1, "FIRE_PUNCH")
  T.eq(s.c[1].appeal, 80, "combo finisher: base doubled (40 + 40)")
  T.check(kinds(ev):find("combo"), "combo event emitted")
  T.check(not s.c[1].attention, "attention is spent by the finisher")
  -- FIRE_PUNCH is itself a starter, but the combo consumed the turn's arming
  E.endTurn(s)
  E.beginTurn(s); E.appeal(s, 1, "FIRE_PUNCH")
  T.eq(s.c[1].appeal, 20, "repeating the finisher: no combo, 40 - 20 repeat")

  local s2 = contest("SMART")
  E.beginTurn(s2); E.appeal(s2, 1, "FIRE_PUNCH")   -- finisher with nothing armed
  T.eq(s2.c[1].appeal, 40, "finisher without an armed starter: plain base")
end

-- ------------------------------------------------------------ 6. jams

do
  local s = contest("SMART")
  E.beginTurn(s)
  E.appeal(s, 1, "POUND")               -- A: 40
  E.appeal(s, 2, "STOMP")               -- B: badly startles the one in front (jam 40)
  T.eq(s.c[1].appeal, 0, "A lost 40 to STOMP")
  T.eq(s.c[2].appeal, 10, "B scored STOMP's own 10")
  E.appeal(s, 3, "ROCK_SLIDE")          -- C: 30 to everyone earlier
  T.eq(s.c[1].appeal, -30, "A jammed again, can go negative")
  T.eq(s.c[2].appeal, -20, "B jammed too")
  E.appeal(s, 4, "HEADBUTT")            -- D: 20 to the one in front only (C)
  T.eq(s.c[3].appeal, -10, "HEADBUTT hit C (front) for 20")
  T.eq(s.c[2].appeal, -20, "HEADBUTT did not reach B")
  local st = E.endTurn(s)
  T.eq(s.c[1].total, -30, "totals bank the jammed figure")
end

do  -- immunity and the one-shot guard
  local s = contest("SMART")
  E.beginTurn(s)
  E.appeal(s, 1, "BIDE")                -- immune
  E.appeal(s, 2, "HARDEN")              -- safety 1
  E.appeal(s, 3, "ROCK_SLIDE")          -- 30 to both
  T.eq(s.c[1].appeal, 10, "AVOID_STARTLE: BIDE untouched")
  T.eq(s.c[2].appeal, 20, "AVOID_STARTLE_ONCE: HARDEN untouched")
  T.eq(s.c[2].safety, 0, "...and the guard is spent")
  E.appeal(s, 4, "ROCK_SLIDE")
  T.eq(s.c[2].appeal, -10, "second jam lands on HARDEN")
  T.eq(s.c[1].appeal, 10, "BIDE stays immune all turn")
end

do  -- judge's attention / same-type / good-appeals variants
  local s = contest("SMART")
  E.beginTurn(s)
  E.appeal(s, 1, "POUND")               -- A: 40, attention armed
  E.appeal(s, 2, "SWIFT")               -- B: 20 (not first)
  E.appeal(s, 3, "DOUBLESLAP")          -- C: 50 to attention-holder A, 10 to B
  T.eq(s.c[1].appeal, -10, "attention holder jammed 50")
  T.eq(s.c[2].appeal, 10, "non-holder jammed 10")

  local s2 = contest("SMART")
  E.beginTurn(s2)
  E.appeal(s2, 1, "POUND")              -- TOUGH
  E.appeal(s2, 2, "SWIFT")              -- COOL
  E.appeal(s2, 3, "SEISMIC_TOSS")       -- TOUGH: 40 to TOUGH appeals, 10 to others
  T.eq(s2.c[1].appeal, 0, "same-category appeal jammed 40")
  T.eq(s2.c[2].appeal, 10, "other category jammed 10")

  local s3 = contest("SMART")
  E.beginTurn(s3)
  E.appeal(s3, 1, "POUND")              -- 40
  E.appeal(s3, 2, "SUPER_FANG")         -- half of 40 = 20
  T.eq(s3.c[1].appeal, 20, "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS takes half")
end

-- --------------------------------------------------- 7. position effects

do
  local s = contest("SMART")
  E.beginTurn(s)
  E.appeal(s, 1, "SWIFT")
  T.eq(s.c[1].appeal, 60, "BETTER_IF_FIRST when first: 20 + 2x20")
  E.appeal(s, 2, "SWIFT")
  T.eq(s.c[2].appeal, 20, "BETTER_IF_FIRST when not first: base only")
  E.appeal(s, 3, "TAIL_WHIP")
  T.eq(s.c[3].appeal, 20, "BETTER_IF_LAST when third: base only")
  E.appeal(s, 4, "TAIL_WHIP")
  T.eq(s.c[4].appeal, 60, "BETTER_IF_LAST when last: 20 + 2x20")

  local s2 = contest("SMART")
  E.beginTurn(s2)
  E.appeal(s2, 1, "FLAIL"); E.appeal(s2, 2, "FLAIL")
  E.appeal(s2, 3, "FLAIL"); E.appeal(s2, 4, "FLAIL")
  T.same({ s2.c[1].appeal, s2.c[2].appeal, s2.c[3].appeal, s2.c[4].appeal },
         { 10, 20, 40, 60 }, "BETTER_WHEN_LATER: 10/20/40/60 by slot")

  local s3 = contest("SMART")
  E.beginTurn(s3)
  E.appeal(s3, 1, "POUND")              -- 40
  E.appeal(s3, 2, "MIMIC")              -- 10 + 40
  T.eq(s3.c[2].appeal, 50, "AS_GOOD_AS_PREV_ONE adds the front appeal")
  E.appeal(s3, 3, "SLASH")              -- 30 < 50 -> 0
  T.eq(s3.c[3].appeal, 0, "AFFECTED_BY_PREV_APPEAL: lower than front -> 0")
  E.appeal(s3, 4, "COMET_PUNCH")        -- COOL front (SLASH) vs TOUGH: no
  T.eq(s3.c[4].appeal, 20, "BETTER_IF_SAME_TYPE: different category, base only")

  local s4 = contest("SMART")
  E.beginTurn(s4)
  E.appeal(s4, 1, "POUND")              -- TOUGH
  E.appeal(s4, 2, "COMET_PUNCH")        -- TOUGH after TOUGH
  T.eq(s4.c[2].appeal, 60, "BETTER_IF_SAME_TYPE: same category, 20 + 2x20")
end

-- ------------------------------------------------ 8. condition, nervous

do
  local s = contest("SMART")
  E.beginTurn(s)
  E.appeal(s, 1, "GROWTH")
  T.eq(s.c[1].condition, 10, "condition up by 10")
  T.eq(s.c[1].appeal, 10, "gain turn adds condition - 10 (so +0)")
  E.endTurn(s)
  E.beginTurn(s); E.appeal(s, 1, "SWIFT")   -- first again, 60 + 10 condition
  T.eq(s.c[1].appeal, 70, "condition adds to every later appeal")

  -- the roll is rng(1,100) <= odds (20 each when three follow): a low roll
  -- lands on everyone, a high roll on nobody -- there is no 100% in Gen 3
  local s2 = contest("SMART", lowRng)
  E.beginTurn(s2)
  E.appeal(s2, 1, "SING")
  T.check(s2.c[2].nervous and s2.c[3].nervous and s2.c[4].nervous,
    "SING on a low roll unnerves all three who follow")
  local s5 = contest("SMART", highRng)
  E.beginTurn(s5)
  E.appeal(s5, 1, "SING")
  T.check(not (s5.c[2].nervous or s5.c[3].nervous or s5.c[4].nervous),
    "SING on a high roll unnerves nobody")
  E.appeal(s2, 2, "POUND")
  T.eq(s2.c[2].appeal, 0, "a nervous contestant scores nothing")
  T.check(not s2.c[2].nervous, "nervousness is spent by the failed appeal")
end

-- -------------------------------------- 9. skip a turn, no more moves

do
  local s = contest("SMART")
  E.beginTurn(s); E.appeal(s, 1, "THRASH"); E.endTurn(s)
  T.check(s.c[1].skipNext, "THRASH marks the next turn skipped")
  E.beginTurn(s)
  local ev = E.appeal(s, 1, "POUND")
  T.eq(kinds(ev), "skipped", "skipped turn: one event, no score")
  T.eq(s.c[1].appeal, 0, "skipped turn scores zero")
  E.endTurn(s)
  E.beginTurn(s)
  E.appeal(s, 1, "EXPLOSION")
  T.eq(s.c[1].appeal, 80, "EXPLOSION: 80")
  E.endTurn(s)
  E.beginTurn(s)
  ev = E.appeal(s, 1, "POUND")
  T.eq(kinds(ev), "no_more", "after EXPLOSION nothing more is allowed")
end

-- -------------------------------------------------- 10. turn order shifts

do
  local s = contest("SMART")
  E.beginTurn(s)                        -- order 1,2,3,4 by round1
  E.appeal(s, 1, "POUND"); E.appeal(s, 2, "POUND"); E.appeal(s, 3, "POUND")
  E.appeal(s, 4, "AGILITY")             -- last asks to go first next turn
  E.endTurn(s)
  local order = E.beginTurn(s)
  T.eq(order[0], 4, "NEXT_APPEAL_EARLIER: D appeals first next turn")
  T.eq(order[1], 1, "then the leader on points")
end

do  -- ranking by cumulative total from turn 2
  local s = contest("SMART")            -- 40/30/20/10: order 1,2,3,4 on turn 1
  E.beginTurn(s)
  E.appeal(s, 1, "SWIFT")               -- first: 60
  E.appeal(s, 2, "POUND")               -- 40
  E.appeal(s, 3, "POUND")               -- 40
  E.appeal(s, 4, "TAIL_WHIP")           -- last: 60
  E.endTurn(s)
  local order = E.beginTurn(s)
  T.check(s.c[1].order <= 1 and s.c[4].order <= 1, "the two 60s appeal first")
  T.check(s.c[2].order >= 2 and s.c[3].order >= 2, "the two 40s appeal after")
end

-- ------------------------------------------------------- 11. final tally

do
  -- RAGE is REPETITION_NOT_BORING, so it is the one move that can be used
  -- five turns running at full value; everyone else alternates to dodge
  -- the repeat penalty (which a first draft of this test forgot -- the
  -- engine was right and the test was wrong).
  local s = contest("SMART", lowRng, { 100, 0, 0, 0 })
  local alt = { "BIDE", "HARDEN" }
  for t = 1, 5 do
    E.beginTurn(s)
    E.appeal(s, 1, alt[t % 2 + 1])      -- 20,10,20,10,20 = 80
    E.appeal(s, 2, "RAGE")              -- 30 x 5 = 150
    E.appeal(s, 3, alt[t % 2 + 1]); E.appeal(s, 4, alt[t % 2 + 1])   -- 80 each
    E.endTurn(s)
  end
  local final = E.final(s)
  local byWho = {}
  for _, r in ipairs(final) do byWho[r.who] = r end
  T.eq(byWho[1].total, 100 + 2 * 80, "final = round1 + 2 x appeals (A)")
  T.eq(byWho[2].total, 0 + 2 * 150, "final = round1 + 2 x appeals (B)")
  T.eq(byWho[2].place, 1, "300 beats 260: B wins despite A's condition lead")
  T.eq(byWho[1].place, 2, "A's round-1 lead still holds second")
end

-- ------------------------------------------------------------ 12. hearts

T.eq(E.hearts(0), 0, "0 points = 0 hearts")
T.eq(E.hearts(45), 4, "45 points = 4 hearts")
T.eq(E.hearts(120), 8, "hearts cap at 8 on display")
T.eq(E.hearts(-25), -2, "negative points = black hearts")

-- --------------------------------------------------------------- 13. AI

do
  local s = E.new({
    contest = "COOL", moves = MV, effects = FX, rng = lowRng,
    contestants = {
      { name = "P", mon = mon("POUND") },
      { name = "N", mon = mon("POUND", "THUNDERPUNCH"), ai = "NORMAL" },
      { name = "S", mon = mon("POUND", "THUNDERPUNCH"), ai = "SUPER" },
      { name = "M", mon = mon("SWIFT", "POUND"),        ai = "MASTER" },
    },
  })
  E.beginTurn(s)
  T.eq(E.chooseMove(s, 3, "SUPER"), "THUNDERPUNCH", "SUPER prefers the contest's own category")
  T.eq(E.chooseMove(s, 4, "MASTER"), "SWIFT", "MASTER dry-runs and takes the best (SWIFT first = 60)")
  -- HYPER refuses to repeat
  s.c[3].prevMove = "THUNDERPUNCH"
  T.eq(E.chooseMove(s, 3, "HYPER"), "POUND", "HYPER never repeats its previous move")
  -- an armed starter is finished if a finisher is in hand
  s.c[3].attention = true; s.c[3].prevMove = "THUNDERPUNCH"
  s.c[3].mon = mon("FIRE_PUNCH", "POUND")
  T.eq(E.chooseMove(s, 3, "HYPER"), "FIRE_PUNCH", "an armed combo is finished when possible")
  T.eq(E.chooseMove(s, 2, "NORMAL"), "POUND", "NORMAL is random (low rng -> first move)")
end

-- ---------------------------------------------------- 14. unknown move id

do
  local s = contest("SMART")            -- neutral to TOUGH: no crowd bonus
  E.beginTurn(s)
  local ev = E.appeal(s, 1, "NOT_A_MOVE")
  T.eq(s.c[1].appeal, 20, "an id the table lacks is a flat 20 (TOUGH), no crash")
  T.eq(s.c[1].nervous, false, "...and leaves state sane")
end

T.finish("contest engine")
