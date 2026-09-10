-- Kanto Contests: the Gen 3 appeal round, as a pure module.
--
-- No engine requires, no globals, no love.*. main.lua loads it with
-- load(mod:read("contest_engine.lua")) -- the same second-file pattern
-- kanto_ribbons uses for ribbons.lua -- and drives it from the Gold battle
-- seam; tests/engine_test.lua drives it headless with a stub table and a
-- fixed rng. Every number here is pokeemerald's; the file:line for each is
-- in briefs/GEN3_CONTEST_RULES.md, which is the spec this implements.
--
-- Vocabulary (pokeemerald's, kept so the spec reads across):
--   contestant   { name, mon = { moves = {{id=...},...} }, round1 = pts,
--                  condition = 0..30, ai = "player"|rank }
--   turnOrder    position 0..3 of each contestant THIS turn (0 = first)
--   appeal       points, tens; /10 is hearts, display caps at 8
--   jam          points subtracted from an EARLIER appeal this turn
--   attention    the judge's attention = a combo starter is armed
--
-- Departure from Gen 3, deliberate: condition is a 0..30 bonus like the
-- original, but it is fed by the mon's contest stat for the category
-- (contest.c has a separate condition stat Gen 2 mons do not carry).

local E = {}

E.CONTESTANTS = 4
E.TURNS = 5
E.CATEGORIES = { "COOL", "BEAUTY", "CUTE", "SMART", "TOUGH" }

-- sContestExcitementTable (contest.c): rows = the contest, cols = the move.
E.EXCITEMENT = {
  COOL   = { COOL =  1, BEAUTY =  0, CUTE = -1, SMART = -1, TOUGH =  0 },
  BEAUTY = { COOL =  0, BEAUTY =  1, CUTE =  0, SMART = -1, TOUGH = -1 },
  CUTE   = { COOL = -1, BEAUTY =  0, CUTE =  1, SMART =  0, TOUGH = -1 },
  SMART  = { COOL = -1, BEAUTY = -1, CUTE =  0, SMART =  1, TOUGH =  0 },
  TOUGH  = { COOL =  0, BEAUTY = -1, CUTE = -1, SMART =  0, TOUGH =  1 },
}

-- ------------------------------------------------------------------ state

-- opts.moves / opts.effects: the KC_CONTEST_MOVES / KC_CONTEST_EFFECTS
-- tables. opts.rng: rng(lo, hi) -> lo..hi, rng(n) -> 1..n (the battle's
-- own love-style rng). opts.contest: the category. opts.contestants: 4.
function E.new(opts)
  assert(#opts.contestants == E.CONTESTANTS, "a contest is four contestants")
  local s = {
    contest = opts.contest,
    moves = opts.moves,
    effects = opts.effects,
    rng = opts.rng,
    turn = 0,                 -- 1..TURNS once started
    applause = 0,             -- 0..4, resets after passing 4
    frozen = nil,             -- contestant index that froze the crowd
    c = {},
  }
  for i, def in ipairs(opts.contestants) do
    s.c[i] = {
      name = def.name, mon = def.mon, ai = def.ai or "NORMAL",
      round1 = def.round1 or 0,
      condition = math.max(0, math.min(30, def.condition or 0)),
      total = 0,              -- cumulative appeal points (round 2)
      appeal = 0, base = 0,   -- this turn's
      prevMove = nil, currMove = nil, repeatCount = 0,
      attention = false, nervous = false, immune = false, safety = 0,
      moreEasilyStartled = false, exploded = false, skipNext = false,
      skipping = false, nextOrder = nil, order = i - 1,
    }
  end
  return s
end

local function moveRow(s, id) return id and s.moves[id] or nil end
local function effectRow(s, id)
  local m = moveRow(s, id)
  return m and s.effects[m.effect] or nil, m
end

function E.category(s, moveId)
  local m = moveRow(s, moveId)
  return (m and m.cat) or "TOUGH"
end

-- AreMovesContestCombo (contest_effect.c:58): prev is a starter, and curr's
-- `after` list names that starter.
function E.isCombo(s, prevId, currId)
  local prev, curr = moveRow(s, prevId), moveRow(s, currId)
  if not (prev and curr and prev.starter and curr.after) then return false end
  for _, id in ipairs(curr.after) do
    if id == prev.starter then return true end
  end
  return false
end

-- ------------------------------------------------------------- turn order

local function shuffled(s, n)
  local t = {}
  for i = 1, n do t[i] = i end
  for i = n, 2, -1 do
    local j = s.rng(1, i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

-- SortContestants: turn 1 by round-1 points, later turns by cumulative
-- total; ties random. Then ApplyNextTurnOrder honours explicit requests
-- (NEXT_APPEAL_EARLIER/LATER, SCRAMBLE) and fills the rest by rank.
function E.beginTurn(s)
  s.turn = s.turn + 1
  local key = s.turn == 1 and "round1" or "total"
  local tie = shuffled(s, E.CONTESTANTS)
  local idx = { 1, 2, 3, 4 }
  table.sort(idx, function(a, b)
    if s.c[a][key] ~= s.c[b][key] then return s.c[a][key] > s.c[b][key] end
    return tie[a] < tie[b]
  end)
  local order = {}                       -- order[slot 0..3] = contestant
  local taken = {}
  for i, ci in ipairs(idx) do
    local want = s.c[ci].nextOrder
    if want ~= nil and not order[want] then
      order[want] = ci; taken[ci] = true
    end
  end
  local slot = 0
  for _, ci in ipairs(idx) do
    if not taken[ci] then
      while order[slot] do slot = slot + 1 end
      order[slot] = ci; taken[ci] = true
    end
  end
  for slot_ = 0, E.CONTESTANTS - 1 do
    local ci = order[slot_]
    local c = s.c[ci]
    c.order = slot_
    c.nextOrder = nil
    c.appeal, c.base = 0, 0
    c.currMove = nil
    c.jammed = 0
    c.skipping = c.skipNext        -- JAMS_OTHERS_BUT_MISS_ONE_TURN
    c.skipNext = false
  end
  s.frozen = nil
  return order
end

function E.turnOrder(s)
  local order = {}
  for i, c in ipairs(s.c) do order[c.order] = i end
  return order
end

-- ------------------------------------------------------------------ jams

-- CanUnnerveContestant + WasAtLeastOneOpponentJammed, folded: returns the
-- jam actually landed on `ti` (0 if immune / safety / cannot act).
local function jam(s, ti, amount, ev)
  local t = s.c[ti]
  if t.immune or t.exploded or t.skipping then return 0 end
  if t.safety > 0 then
    t.safety = t.safety - 1
    ev[#ev + 1] = { kind = "unaffected", who = ti }
    return 0
  end
  if t.moreEasilyStartled then amount = amount * 2 end
  if amount <= 0 then return 0 end
  t.appeal = t.appeal - amount
  t.jammed = (t.jammed or 0) + amount
  ev[#ev + 1] = { kind = "startled", who = ti, jam = amount }
  return amount
end

-- contestants who appealed EARLIER this turn (turnOrder < mine)
local function earlier(s, ci)
  local out = {}
  for i, c in ipairs(s.c) do
    if c.order < s.c[ci].order and not c.skipping then out[#out + 1] = i end
  end
  table.sort(out, function(a, b) return s.c[a].order < s.c[b].order end)
  return out
end

-- the one who appealed immediately before me, or nil if I am first
local function front(s, ci)
  local mine = s.c[ci].order
  if mine == 0 then return nil end
  for i, c in ipairs(s.c) do
    if c.order == mine - 1 then return i end
  end
end

-- ---------------------------------------------------------------- effects

-- Each takes (s, ci, base, jamPts, ev) and mutates s.c[ci].appeal in place.
-- Names are pokeemerald's CONTEST_EFFECT_* minus the prefix; the mapping to
-- functions follows gContestEffectFuncs (contest_moves.h:3198), where the
-- three FRONT_MON effects share one body and the three PREV_MONS do too.
local FX = {}

FX.HIGHLY_APPEALING = function() end

FX.USER_MORE_EASILY_STARTLED = function(s, ci)
  s.c[ci].moreEasilyStartled = true
end

FX.GREAT_APPEAL_BUT_NO_MORE_MOVES = function(s, ci)
  s.c[ci].exploded = true
end

FX.REPETITION_NOT_BORING = function(s, ci)
  s.c[ci].repeated = false
  s.c[ci].repeatCount = 0
end

FX.AVOID_STARTLE_ONCE = function(s, ci) s.c[ci].safety = 1 end
FX.AVOID_STARTLE = function(s, ci) s.c[ci].immune = true end

local function startleFront(s, ci, _, jamPts, ev)
  local f = front(s, ci)
  local hit = f and jam(s, f, jamPts, ev) or 0
  if hit == 0 then ev[#ev + 1] = { kind = "missed", who = ci } end
end
FX.STARTLE_FRONT_MON = startleFront
FX.STARTLE_PREV_MON = startleFront
FX.BADLY_STARTLE_FRONT_MON = startleFront

local function startlePrev(s, ci, _, jamPts, ev)
  local hits = 0
  for _, ti in ipairs(earlier(s, ci)) do
    if jam(s, ti, jamPts, ev) > 0 then hits = hits + 1 end
  end
  if hits == 0 then ev[#ev + 1] = { kind = "missed", who = ci } end
end
FX.STARTLE_PREV_MONS = startlePrev
FX.BADLY_STARTLE_PREV_MONS = startlePrev

FX.JAMS_OTHERS_BUT_MISS_ONE_TURN = function(s, ci, base, jamPts, ev)
  s.c[ci].skipNext = true
  startlePrev(s, ci, base, jamPts, ev)
end

FX.STARTLE_MON_WITH_JUDGES_ATTENTION = function(s, ci, _, _, ev)
  local hits = 0
  for _, ti in ipairs(earlier(s, ci)) do
    local pts = s.c[ti].attention and 50 or 10
    if jam(s, ti, pts, ev) > 0 then hits = hits + 1 end
  end
  if hits == 0 then ev[#ev + 1] = { kind = "missed", who = ci } end
end

-- JamByMoveCategory: 40 to a same-category appeal, 10 otherwise
FX.STARTLE_MONS_SAME_TYPE_APPEAL = function(s, ci, _, _, ev)
  local cat = E.category(s, s.c[ci].currMove)
  local hits = 0
  for _, ti in ipairs(earlier(s, ci)) do
    local pts = E.category(s, s.c[ti].currMove) == cat and 40 or 10
    if jam(s, ti, pts, ev) > 0 then hits = hits + 1 end
  end
  if hits == 0 then ev[#ev + 1] = { kind = "missed", who = ci } end
end

FX.BADLY_STARTLE_MONS_WITH_GOOD_APPEALS = function(s, ci, _, _, ev)
  local hits = 0
  for _, ti in ipairs(earlier(s, ci)) do
    local a = s.c[ti].appeal
    local pts = a > 0 and math.ceil(a / 20) * 10 or 10   -- half, rounded up to a ten
    if jam(s, ti, pts, ev) > 0 then hits = hits + 1 end
  end
  if hits == 0 then ev[#ev + 1] = { kind = "missed", who = ci } end
end

FX.SHIFT_JUDGE_ATTENTION = function(s, ci, _, _, ev)
  local any = false
  for _, ti in ipairs(earlier(s, ci)) do
    local t = s.c[ti]
    if t.attention and not t.immune and t.safety == 0 then
      t.attention = false
      ev[#ev + 1] = { kind = "attention_lost", who = ti }
      any = true
    end
  end
  if not any then ev[#ev + 1] = { kind = "missed", who = ci } end
end

-- odds 60 / 30,30 / 20,20,20 by how many follow; condition resists 10 per
-- 10, an armed combo starter raises the odds 10. Nervous = appeal 0.
FX.MAKE_FOLLOWING_MONS_NERVOUS = function(s, ci, _, _, ev)
  local later = {}
  for i, c in ipairs(s.c) do
    if c.order > s.c[ci].order and not c.nervous and not c.skipping
       and not c.exploded then later[#later + 1] = i end
  end
  local odds = ({ [1] = 60, [2] = 30, [3] = 20 })[#later] or 0
  local any = false
  for _, ti in ipairs(later) do
    local t = s.c[ti]
    local mod_ = (t.attention and 10 or 0) - math.floor(t.condition / 10) * 10
    if s.rng(1, 100) <= odds + mod_ and not t.immune and t.safety == 0 then
      t.nervous = true
      ev[#ev + 1] = { kind = "nervous", who = ti }
      any = true
    else
      ev[#ev + 1] = { kind = "unaffected", who = ti }
    end
  end
  if not any then ev[#ev + 1] = { kind = "missed", who = ci } end
end

FX.WORSEN_CONDITION_OF_PREV_MONS = function(s, ci, _, _, ev)
  local any = false
  for _, ti in ipairs(earlier(s, ci)) do
    local t = s.c[ti]
    if t.condition > 0 and not t.immune and t.safety == 0 then
      t.condition = 0
      ev[#ev + 1] = { kind = "condition_lost", who = ti }
      any = true
    end
  end
  if not any then ev[#ev + 1] = { kind = "missed", who = ci } end
end

FX.BETTER_IF_FIRST = function(s, ci, base)
  if s.c[ci].order == 0 then s.c[ci].appeal = s.c[ci].appeal + 2 * base end
end
FX.BETTER_IF_LAST = function(s, ci, base)
  if s.c[ci].order == E.CONTESTANTS - 1 then
    s.c[ci].appeal = s.c[ci].appeal + 2 * base
  end
end

FX.APPEAL_AS_GOOD_AS_PREV_ONE = function(s, ci)
  local f = front(s, ci)
  local a = f and s.c[f].appeal or 0
  if a > 0 then s.c[ci].appeal = s.c[ci].appeal + a end
end

FX.APPEAL_AS_GOOD_AS_PREV_ONES = function(s, ci)
  local sum = 0
  for _, ti in ipairs(earlier(s, ci)) do sum = sum + s.c[ti].appeal end
  if sum > 0 then
    s.c[ci].appeal = math.floor((s.c[ci].appeal + sum / 2) / 10) * 10
  end
end

FX.BETTER_WHEN_LATER = function(s, ci)
  local slot = s.c[ci].order
  s.c[ci].appeal = slot == 0 and 10 or 20 * slot
end

FX.QUALITY_DEPENDS_ON_TIMING = function(s, ci)
  local r = s.rng(1, 10)
  s.c[ci].appeal = r <= 3 and 10 or r <= 6 and 20 or r <= 8 and 40
                   or r <= 9 and 60 or 80
end

-- the nearest earlier contestant who actually appealed
FX.BETTER_IF_SAME_TYPE = function(s, ci, base)
  local mine = s.c[ci].order
  for slot = mine - 1, 0, -1 do
    for i, c in ipairs(s.c) do
      if c.order == slot and not c.skipping and not c.nervous
         and not c.exploded and c.currMove then
        if E.category(s, c.currMove) == E.category(s, s.c[ci].currMove) then
          s.c[ci].appeal = s.c[ci].appeal + 2 * base
        end
        return
      end
    end
  end
end

FX.AFFECTED_BY_PREV_APPEAL = function(s, ci)
  local f = front(s, ci)
  if not f then return end
  local me, them = s.c[ci].appeal, s.c[f].appeal
  if me > them then s.c[ci].appeal = me * 2
  elseif me < them then s.c[ci].appeal = 0 end
end

FX.IMPROVE_CONDITION_PREVENT_NERVOUSNESS = function(s, ci, _, _, ev)
  local c = s.c[ci]
  if c.condition < 30 then
    c.condition = c.condition + 10
    c.conditionGained = true
    ev[#ev + 1] = { kind = "condition_up", who = ci }
  end
end

FX.BETTER_WITH_GOOD_CONDITION = function(s, ci)
  s.c[ci].tripleCondition = true
end

FX.NEXT_APPEAL_EARLIER = function(s, ci)
  if s.turn < E.TURNS then
    for _, c in ipairs(s.c) do
      if c.nextOrder ~= nil then c.nextOrder = c.nextOrder + 1 end
    end
    s.c[ci].nextOrder = 0
  end
end
FX.NEXT_APPEAL_LATER = function(s, ci)
  if s.turn < E.TURNS then s.c[ci].nextOrder = E.CONTESTANTS - 1 end
end
FX.SCRAMBLE_NEXT_TURN_ORDER = function(s)
  if s.turn < E.TURNS then
    local perm = shuffled(s, E.CONTESTANTS)
    for i, c in ipairs(s.c) do c.nextOrder = perm[i] - 1 end
  end
end

FX.EXCITE_AUDIENCE_IN_ANY_CONTEST = function(s, ci)
  s.c[ci].forceExcite = true
end

FX.BETTER_WHEN_AUDIENCE_EXCITED = function(s, ci)
  s.c[ci].appeal = ({ [0] = 10, 20, 30, 50, 60 })[math.min(s.applause, 4)]
end

FX.DONT_EXCITE_AUDIENCE = function(s, ci)
  if not s.frozen then s.frozen = ci end
end

E.FX = FX

-- ---------------------------------------------------------------- appeal

-- CalculateAppealMoveImpact, then the crowd step of the appeal task
-- (contest.c:4425 and :2199-2223). Returns the event list for the glue to
-- narrate. `who` is the contestant index; `moveId` the move used.
function E.appeal(s, ci, moveId)
  local c = s.c[ci]
  local ev = {}
  if c.skipping then
    ev[#ev + 1] = { kind = "skipped", who = ci }
    c.currMove = nil
    return ev
  end
  if c.exploded then
    ev[#ev + 1] = { kind = "no_more", who = ci }
    c.currMove = nil
    return ev
  end
  local fx, row = effectRow(s, moveId)
  if not fx then
    -- an id the table has never heard of: a flat, ordinary appeal
    fx = { appeal = 20, jam = 0 }
    row = { cat = "TOUGH", effect = "HIGHLY_APPEALING" }
  end
  c.currMove = moveId
  ev[#ev + 1] = { kind = "used", who = ci, move = moveId, cat = row.cat }

  -- 2. repeat check
  c.repeated = (c.prevMove == moveId)
  if c.repeated then c.repeatCount = c.repeatCount + 1 else c.repeatCount = 0 end

  -- 1. base
  c.base = fx.appeal
  c.appeal = fx.appeal
  c.tripleCondition, c.conditionGained, c.forceExcite = false, false, false

  -- 3. attention survives only into a combo finisher
  if c.attention and not E.isCombo(s, c.prevMove, moveId) then
    c.attention = false
  end

  -- 4. the effect
  local fn = FX[row.effect]
  if fn then fn(s, ci, c.base, fx.jam, ev) end

  -- 5. condition
  if c.conditionGained then c.appeal = c.appeal + (c.condition - 10)
  elseif c.tripleCondition then c.appeal = c.appeal + c.condition * 3
  else c.appeal = c.appeal + c.condition end

  -- 6. combo
  c.combo = false
  if E.isCombo(s, c.prevMove, moveId) and c.attention then
    c.combo = true
    c.attention = false
    c.appeal = c.appeal + c.base          -- "double the base"
    ev[#ev + 1] = { kind = "combo", who = ci }
  elseif row.starter then
    c.attention = true
    ev[#ev + 1] = { kind = "attention", who = ci }
  else
    c.attention = false
  end

  -- 7. repeat penalty
  if c.repeated then
    local pen = (c.repeatCount + 1) * 10
    c.appeal = c.appeal - pen
    ev[#ev + 1] = { kind = "repeat", who = ci, penalty = pen }
  end

  -- 8. nervous
  if c.nervous then
    c.attention = false
    c.appeal, c.base = 0, 0
    ev[#ev + 1] = { kind = "too_nervous", who = ci }
    c.nervous = false
  else
    -- 9. crowd
    local ex = E.EXCITEMENT[s.contest][row.cat] or 0
    if c.forceExcite then ex = 1 end
    if ex > 0 and c.repeated then ex = 0 end
    if s.frozen and s.frozen ~= ci then
      ev[#ev + 1] = { kind = "crowd_frozen", who = ci }
    elseif ex ~= 0 then
      local before = s.applause
      s.applause = math.max(0, s.applause + ex)
      if ex > 0 then
        local bonus = (before + ex > 4) and 60 or 10
        c.appeal = c.appeal + bonus
        ev[#ev + 1] = { kind = bonus == 60 and "crowd_wild" or "crowd_up",
                        who = ci, bonus = bonus, level = math.min(s.applause, 5) }
        if s.applause > 4 then s.applause = 0 end
      else
        ev[#ev + 1] = { kind = "crowd_down", who = ci, level = s.applause }
      end
    end
  end

  c.prevMove = moveId
  ev[#ev + 1] = { kind = "scored", who = ci, appeal = c.appeal,
                  hearts = E.hearts(c.appeal) }
  return ev
end

-- GetNumHeartsFromAppealPoints: /10, and the display shows at most 8
function E.hearts(points)
  local h = points >= 0 and math.floor(points / 10) or -math.floor(-points / 10)
  return math.max(-8, math.min(8, h))
end

-- RankContestants: totals accumulate at the END of the turn, after every
-- jam has landed, so a startled contestant banks the reduced figure.
function E.endTurn(s)
  for _, c in ipairs(s.c) do c.total = c.total + c.appeal end
  return E.standings(s)
end

-- cumulative appeal ranking, 1 = leading (ties share the better rank)
function E.standings(s)
  local out = {}
  for i, c in ipairs(s.c) do
    local rank = 1
    for _, o in ipairs(s.c) do if o.total > c.total then rank = rank + 1 end end
    out[i] = { who = i, total = c.total, rank = rank }
  end
  return out
end

-- CalculateTotalPointsForContestant + DetermineFinalStandings:
-- final = round1 + 2 x appeals; ties by round1, then random.
function E.final(s)
  local rows = {}
  for i, c in ipairs(s.c) do
    rows[#rows + 1] = { who = i, round1 = c.round1, appeals = c.total,
                        total = c.round1 + 2 * c.total, tie = s.rng(1, 1000) }
  end
  table.sort(rows, function(a, b)
    if a.total ~= b.total then return a.total > b.total end
    if a.round1 ~= b.round1 then return a.round1 > b.round1 end
    return a.tie < b.tie
  end)
  for place, r in ipairs(rows) do r.place = place end
  return rows
end

-- -------------------------------------------------------------------- AI

-- What a rival picks. NORMAL is random; SUPER prefers the contest's own
-- category; HYPER also refuses to repeat and finishes a combo it has armed;
-- MASTER scores every candidate by dry-running the appeal on a copy and
-- takes the best. Deterministic given the rng.
local function candidates(s, ci)
  local out = {}
  for _, m in ipairs(s.c[ci].mon.moves or {}) do
    if m and m.id and (m.pp == nil or m.pp > 0) then out[#out + 1] = m.id end
  end
  return out
end

local function copyState(s)
  local t = { contest = s.contest, moves = s.moves, effects = s.effects,
              turn = s.turn, applause = s.applause, frozen = s.frozen,
              rng = function(lo, hi) return hi and lo or 1 end, c = {} }
  for i, c in ipairs(s.c) do
    local d = {}
    for k, v in pairs(c) do d[k] = v end
    t.c[i] = d
  end
  return t
end

function E.chooseMove(s, ci, rank)
  local ids = candidates(s, ci)
  if #ids == 0 then return nil end
  rank = rank or s.c[ci].ai or "NORMAL"
  local c = s.c[ci]
  if rank == "NORMAL" then return ids[s.rng(1, #ids)] end

  local function ok(id)
    if rank == "SUPER" then return true end
    return id ~= c.prevMove                       -- HYPER+: never repeat
  end
  if rank ~= "NORMAL" and c.attention then      -- finish an armed combo
    for _, id in ipairs(ids) do
      if E.isCombo(s, c.prevMove, id) then return id end
    end
  end
  if rank == "MASTER" then
    local best, bestScore = nil, -math.huge
    for _, id in ipairs(ids) do
      if ok(id) then
        local t = copyState(s)
        E.appeal(t, ci, id)
        local score = t.c[ci].appeal
        if score > bestScore then best, bestScore = id, score end
      end
    end
    if best then return best end
  end
  -- SUPER / HYPER: same-category first, then anything allowed
  local same, any = {}, {}
  for _, id in ipairs(ids) do
    if ok(id) then
      any[#any + 1] = id
      if E.category(s, id) == s.contest then same[#same + 1] = id end
    end
  end
  if #same > 0 then return same[s.rng(1, #same)] end
  if #any > 0 then return any[s.rng(1, #any)] end
  return ids[s.rng(1, #ids)]
end

return E
