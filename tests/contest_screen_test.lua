-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/contest_screen_test.lua
--
-- Drives contest_screen.lua's MODEL through a whole five-turn contest
-- headless: no love.graphics, no mod load, no animation data (so the
-- animation beat is skipped exactly as it would be on a cache without
-- battle_anims). What it proves: the phase machine reaches the tally and
-- calls back exactly once; the panel rows follow the turn order; hearts
-- land on the right rows; and every text-box line fits Gold's 18 x 2.
package.path = "./?.lua;./?/init.lua;" .. package.path
local T = require("tests.harness")

local E = dofile("../Kanto-Contests/contest_engine.lua")
local S = dofile("../Kanto-Contests/contest_screen.lua")

-- ---------------------------------------------------------------- fixtures

local FX = {
  HIGHLY_APPEALING     = { appeal = 40, jam = 0 },
  BADLY_STARTLE_FRONT_MON = { appeal = 10, jam = 40 },
  BETTER_IF_FIRST      = { appeal = 20, jam = 0 },
}
local MV = {
  POUND        = { cat = "TOUGH", effect = "HIGHLY_APPEALING", starter = "POUND" },
  THUNDERPUNCH = { cat = "COOL",  effect = "HIGHLY_APPEALING" },
  STOMP        = { cat = "TOUGH", effect = "BADLY_STARTLE_FRONT_MON" },
  SWIFT        = { cat = "COOL",  effect = "BETTER_IF_FIRST" },
}
local NAMES = {}
for id in pairs(MV) do NAMES[id] = { name = id } end

local function lowRng(lo, hi) return hi and lo or 1 end

local function mon(nick, species, ...)
  local m = { nickname = nick, species = species, moves = {} }
  for _, id in ipairs({ ... }) do m.moves[#m.moves + 1] = { id = id, pp = 10 } end
  return m
end

local pressed = {}
local input = { wasPressed = function(_, k) return pressed[k] == true end }
local game = { data = { moves = NAMES }, input = input }

local function newScreen(playerMoves)
  local state = E.new({
    contest = "COOL", moves = MV, effects = FX, rng = lowRng,
    contestants = {
      { name = "GOLD",    mon = mon("PIKA", "PIKACHU", unpack(playerMoves)), round1 = 80, ai = "player" },
      { name = "WHITNEY", mon = mon("MILTANK", "MILTANK", "POUND"), round1 = 60, ai = "NORMAL" },
      { name = "MORTY",   mon = mon("GASTLY", "GASTLY", "STOMP"),   round1 = 40, ai = "NORMAL" },
      { name = "LYRA",    mon = mon("MARILL", "MARILL", "POUND"),   round1 = 20, ai = "NORMAL" },
    },
  })
  local done = {}
  local scr = S.new({
    engine = E, state = state, game = game, kind = "COOL", rank = "SUPER",
    onDone = function(place, final) done[#done + 1] = { place = place, final = final } end,
  })
  return scr, state, done
end

local function press(scr, key)
  pressed = { [key] = true }
  scr:update(0)
  pressed = {}
end
local function tick(scr, n) for _ = 1, (n or 1) do scr:update(0) end end
-- press A until the queue is empty (bounded), collecting what was shown
local function readAll(scr, seen)
  for _ = 1, 60 do
    if #scr.msgs == 0 then break end
    if seen then seen[#seen + 1] = scr.msgs[1].text end
    press(scr, "a")
  end
end

local shown = {}

-- ----------------------------------------------------------- 1. the intro

local scr, state, done = newScreen({ "THUNDERPUNCH", "SWIFT" })
T.eq(scr.phase, "intro", "opens on the intro")
T.check(scr.msgs[1].text:find("SUPER", 1, true) and scr.msgs[1].text:find("COOL", 1, true),
  "the first line names rank and category")
readAll(scr, shown)
tick(scr)                                  -- empty queue + intro phase -> turn 1
T.eq(state.turn, 1, "turn 1 began")
T.eq(scr.phase, "menu", "and the menu is open")
T.check(scr.msgs[1] and scr.msgs[1].text:find("Appeal no. 1", 1, true), "'Appeal no. 1!' is announced")
T.same({ scr.rows[1], scr.rows[2], scr.rows[3], scr.rows[4] }, { 1, 2, 3, 4 },
  "panel rows follow turn-1 order (round-1 points: player first)")

-- ------------------------------------------------------------- 2. a turn

readAll(scr, shown)
press(scr, "down")
T.eq(scr.menuCursor, 2, "down moves the menu cursor")
press(scr, "up")
T.eq(scr.menuCursor, 1, "up moves it back")
press(scr, "a")                            -- choose THUNDERPUNCH
T.eq(scr.chosen, "THUNDERPUNCH", "A picks the cursor move")
T.eq(scr.performer, 1, "the player appeals first and is on stage")
T.check(scr.msgs[1] and scr.msgs[1].text:find("PIKA appealed", 1, true), "the appeal is announced by nickname")
-- read the announcement; with no animation data the narration follows at once
readAll(scr, shown)
tick(scr)                                  -- resolve -> (no anim) -> narrated
readAll(scr, shown)
T.eq(scr.turnHearts[1], 5, "player's hearts on the panel: 4 + 1 crowd (COOL move in COOL)")
-- let the three rivals go
for _ = 1, 3 do
  tick(scr)                                -- narrated -> resolveNext (next rival)
  readAll(scr, shown)
  tick(scr)                                -- resolve -> narrated
  readAll(scr, shown)
end
T.eq(scr.slot, 4, "all four appealed")
tick(scr)                                  -- narrated -> resolveNext -> endTurn
T.check(scr.msgs[1] and scr.msgs[1].text:find("You stand", 1, true), "standing announced between turns")
T.eq(scr.phase, "between", "between turns")
T.check(state.c[1].total == 50, "player banked 50 this turn")
-- MORTY's STOMP (slot 3) badly startles the one in front (WHITNEY, slot 2)
T.check(scr.turnHearts[2] < 4, ("WHITNEY's row shows the jam (%d)"):format(scr.turnHearts[2]))
readAll(scr, shown)
tick(scr)
T.eq(state.turn, 2, "turn 2 began")
T.eq(scr.phase, "menu", "menu again")

-- ------------------------------------------------ 3. run it to the tally

local guard = 0
while not scr.finished and guard < 400 do
  guard = guard + 1
  if #scr.msgs > 0 then
    shown[#shown + 1] = scr.msgs[1].text
    press(scr, "a")
  elseif scr.phase == "menu" then
    press(scr, "a")
  else
    tick(scr)
  end
end
T.check(scr.finished, ("the contest reaches the end (steps: %d)"):format(guard))
T.eq(state.turn, 5, "five turns were played")
T.eq(#done, 1, "onDone called exactly once")
T.check(done[1] and done[1].place >= 1 and done[1].place <= 4, "with a placing 1..4")
T.check(done[1] and #done[1].final == 4, "and the four-row final")
local sawTally, sawPlace = false, false
for _, t in ipairs(shown) do
  if t:find("tallies", 1, true) then sawTally = true end
  if t:find("You place", 1, true) then sawPlace = true end
end
T.check(sawTally and sawPlace, "the tally and the placing were announced")

-- --------------------------------------------- 4. every line fits the box

local bad = {}
for _, t in ipairs(shown) do
  local lines = 0
  for seg in (t .. "\n"):gmatch("(.-)\n") do
    lines = lines + 1
    if #seg > 18 then bad[#bad + 1] = seg end
  end
  if lines > 2 then bad[#bad + 1] = t end
end
T.eq(#bad, 0, ("every text-box line is <= 18 cols and <= 2 rows (%s)"):format(table.concat(bad, " | ")))
T.check(#shown > 30, ("a full contest showed %d lines"):format(#shown))

-- ------------------------------------------ 5. repeat / no-PP guards

do
  local scr2 = newScreen({ "POUND" })
  readAll(scr2); tick(scr2); readAll(scr2)
  scr2.s.c[1].mon.moves[1].pp = 0
  press(scr2, "a")
  T.check(scr2.msgs[1] and scr2.msgs[1].text:find("No PP", 1, true), "a move with no PP is refused")
  T.eq(scr2.phase, "menu", "and the menu stays open")
end

T.finish("contest screen")
