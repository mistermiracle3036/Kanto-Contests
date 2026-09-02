-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/summary_page_test.lua
--
-- The CONTEST MOVES summary page, driven headless through Gold's REAL
-- SummaryMenu with a stub game: no ROM, no window. It checks the page is
-- reached from the right edges and nowhere else, what it prints, that the
-- cursor moves, and -- the part a device test cannot show -- that a
-- Ribbons-shaped wrapper installed AFTER this mod's still fires on its own
-- edge, and this mod's still fires under it. Two mods on one wrap edge is
-- the collision this page was laid out to avoid.
package.path = "./?.lua;./?/init.lua;" .. package.path
local T = require("tests.modkit")
love = love or require("tests.love_stub")
local GameVersion = require("src.core.GameVersion")
GameVersion.current = "gold"
local run = T.sdk.loadMod("../Kanto-Contests", { generation = 2 })
T.eq(run.mod and run.mod.state, "loaded", "mod loaded on gen 2")
-- see gold_contest_test: this fails in bursts with no file changed; dump
-- the loader when it does so the burst gets characterised
if not (run.mod and run.mod.state == "loaded") then
  print("  loader.errors:", #(run.errors or {}))
  for i, e in ipairs(run.errors or {}) do print("   ", i, tostring(type(e) == "table" and (e.message or e.msg) or e)) end
  for id, m in pairs(run.loader and run.loader.mods or {}) do
    print("  loader.mods:", id, m.state, m.path, m.error)
  end
end

local Summary = require("src.ui.gen2.SummaryMenu")
local Mon = require("src.battle.gen2.Mon")
T.check(Summary._kcOriginals and Summary._kcOriginals.update,
  "the mod wrapped SummaryMenu.update with stash-originals")
T.eq(Summary.KC_CONTEST_PAGE, 4, "the contest page is page 4")

-- ---------------------------------------------------------------- fixtures

local function move(id) return { id = id, name = id, power = 40, type = "NORMAL",
  accuracy = 100, pp = 20, effect = "EFFECT_NORMAL_HIT" } end
local MOVES = { THUNDERPUNCH = move("THUNDERPUNCH"), FIRE_PUNCH = move("FIRE_PUNCH"),
                SWIFT = move("SWIFT"), NOT_A_MOVE = move("NOT_A_MOVE") }
local DATA = {
  moves = MOVES, items = {},
  pokemon = {
    growthRates = { GROWTH_MEDIUM_FAST = { numerator = 1, denominator = 1,
      squared = 0, linear = 0, constant = 0 } },
    PIKACHU = { id = "PIKACHU", index = 25, name = "PIKACHU",
      baseStats = { hp = 35, attack = 55, defense = 40, speed = 90,
        specialAttack = 50, specialDefense = 50 },
      types = { "ELECTRIC", "ELECTRIC" }, catchRate = 190, baseExp = 82,
      growthRate = "GROWTH_MEDIUM_FAST", genderRatio = 127,
      levelMoves = {}, evolutions = {} },
  },
}

-- an input whose "pressed" set is whatever the test says this frame
local pressed = {}
local input = { wasPressed = function(_, k) return pressed[k] == true end }
local function press(menu, key)
  pressed = { [key] = true }
  menu:update(0)
  pressed = {}
end

local function mkmon(ids)
  local m = Mon.new(DATA, "PIKACHU", 30)
  m.moves = {}
  for _, id in ipairs(ids) do m.moves[#m.moves + 1] = { id = id, pp = 20, maxPp = 20 } end
  return m
end

local closed = 0
local function open(ids, page)
  local mon = mkmon(ids)
  local game = { data = DATA, input = input, save = { party = { mon } } }
  local menu = Summary.new(game, { mon = mon, page = page,
                                   onClose = function() closed = closed + 1 end })
  return menu, mon
end

local function texts(menu)
  local out = {}
  for _, e in ipairs(menu:placements()) do out[#out + 1] = e.text end
  return table.concat(out, "|")
end

-- ---------------------------------------------------------- 1. the edges

do
  local menu = open({ "THUNDERPUNCH", "FIRE_PUNCH" }, Summary.GREEN_PAGE)
  press(menu, "right")
  T.eq(menu.page, 4, "right off MOVES opens the contest page")
  press(menu, "right")
  T.eq(menu.page, Summary.BLUE_PAGE, "right again is the stats page")
  press(menu, "left")
  T.eq(menu.page, 4, "left off the stats page comes back to it")
  press(menu, "left")
  T.eq(menu.page, Summary.GREEN_PAGE, "left again is MOVES")
  press(menu, "right"); press(menu, "a")
  T.eq(menu.page, Summary.BLUE_PAGE, "A on the contest page is the stats page, like right")
end

do  -- the stock cycle is otherwise untouched
  local menu = open({ "THUNDERPUNCH" }, Summary.PINK_PAGE)
  press(menu, "right")
  T.eq(menu.page, Summary.GREEN_PAGE, "PINK -> GREEN is still one press")
  press(menu, "left")
  T.eq(menu.page, Summary.PINK_PAGE, "GREEN -> PINK is still one press")
end

do  -- B closes from the page
  local menu = open({ "THUNDERPUNCH" }, Summary.GREEN_PAGE)
  press(menu, "right")
  local before = closed
  press(menu, "b")
  T.eq(closed, before + 1, "B on the contest page closes the summary")
end

-- ---------------------------------------------------- 2. what it prints

do
  local menu = open({ "THUNDERPUNCH", "FIRE_PUNCH", "SWIFT" }, Summary.GREEN_PAGE)
  press(menu, "right")
  local t = texts(menu)
  T.check(t:find("CONTEST MOVES", 1, true), "title present")
  T.check(t:find("COOL  |THUNDERPUNCH", 1, true), "THUNDERPUNCH is listed as COOL")
  T.check(t:find("BEAUTY|FIRE_PUNCH", 1, true), "FIRE_PUNCH is listed as BEAUTY")
  T.check(t:find("|-|", 1, true) or t:find("|-$"), "the empty fourth slot prints a dash")
  T.check(t:find("A highly", 1, true), "the cursor move's effect text is shown (line 1)")
  T.check(t:find("appealing move.", 1, true), "...and line 2")
  -- the upper half is still the stock summary's
  T.check(t:find("PIKACHU", 1, true), "the upper half (name) still draws")

  press(menu, "down"); press(menu, "down")
  T.eq(menu.kcCursor, 3, "down twice: cursor on the third move")
  t = texts(menu)
  T.check(t:find("performed first", 1, true), "SWIFT's effect text: works great when first")
  press(menu, "down")
  T.eq(menu.kcCursor, 1, "down wraps to the first move")
  press(menu, "up")
  T.eq(menu.kcCursor, 3, "up wraps to the last move")
end

do  -- every row stays inside the 20-tile screen
  local menu = open({ "THUNDERPUNCH", "FIRE_PUNCH", "SWIFT", "NOT_A_MOVE" }, Summary.GREEN_PAGE)
  press(menu, "right")
  local worst = 0
  for _, e in ipairs(menu:kcContestPlacements()) do
    worst = math.max(worst, e.x + #e.text)
  end
  T.check(worst <= 20, ("every placement ends by column 20 (worst %d)"):format(worst))
  T.check(texts(menu):find("----", 1, true), "an id the table lacks shows ----")
  menu.kcCursor = 4
  T.check(texts(menu):find("No contest data.", 1, true), "...and says so under the cursor")
end

-- ------------------------------------------------ 3. guards: egg, moveDetail

do
  local menu = open({ "THUNDERPUNCH" }, Summary.GREEN_PAGE)
  menu.moveDetail = true
  press(menu, "right")
  T.check(menu.page ~= 4, "the move-detail sub-screen keeps right for itself")
  menu.moveDetail = false
  menu.mon.isEgg = true
  press(menu, "right")
  T.check(menu.page ~= 4, "an egg has no contest page")
end

-- ------------------------------------- 4. coexistence with a Ribbons-shaped wrap

do
  -- Ribbons takes A/right on BLUE and left on PINK, and wraps AFTER this
  -- mod (load order is not ours to choose). Both must still work.
  local fired = 0
  local prev = Summary.update
  Summary.update = function(self, dt)
    local inp = self.game and self.game.input
    if inp and not self.moveDetail then
      if (self.page == Summary.BLUE_PAGE and (inp:wasPressed("a") or inp:wasPressed("right")))
          or (self.page == Summary.PINK_PAGE and inp:wasPressed("left")) then
        fired = fired + 1
        return
      end
    end
    return prev(self, dt)
  end

  local menu = open({ "THUNDERPUNCH" }, Summary.GREEN_PAGE)
  press(menu, "right")
  T.eq(menu.page, 4, "under the Ribbons-shaped wrap, GREEN+right still opens the contest page")
  press(menu, "right")
  T.eq(menu.page, Summary.BLUE_PAGE, "...and right again reaches BLUE")
  press(menu, "right")
  T.eq(fired, 1, "BLUE+right is Ribbons' and fires")
  press(menu, "left")
  T.eq(menu.page, 4, "BLUE+left is ours and still works")
  press(menu, "left"); press(menu, "left")
  T.eq(menu.page, Summary.PINK_PAGE, "back to PINK")
  press(menu, "left")
  T.eq(fired, 2, "PINK+left is Ribbons' and fires")
  Summary.update = prev
end

T.finish("summary page")
