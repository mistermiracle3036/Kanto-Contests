-- Kanto Contests -- R/S-style Pokemon Contests as judge "battles".
-- v0.1.0: smallest testable slice. One COOL contest, one judge, one hall.
-- Proves: mod map + hall entry, battle vs judge, judge portrait STAYS on
-- screen after the intro, judge takes no actions, win/lose returns to the
-- talk script. Appeal scoring, PokeSnacks, condition, ranks: later slices.

return function(mod)
  local VERSION = "0.6.0"
  mod.exports.version = VERSION
  mod.exports.owns = {
    trainers = { "OPP_KC_JUDGE" },
    maps = { "KC_CONTEST_HALL" },
    tilesets = { "KC_HALL_TILES" },
    commands = { "kanto_contests:start_contest", "kanto_contests:base_talk" },
  }

  -- ------------------------------------------------------------------
  -- on-screen diagnostics (the only output channel on iPhone)
  -- ------------------------------------------------------------------
  local function say(msg)
    local ok = pcall(function()
      local TextBox = require("src.render.TextBox")
      local game = mod.world.game
      if not (game and game.stack) then return end
      game.stack:push(TextBox.new(game, msg))
    end)
    if not ok then mod.log:warn("say failed: %s", tostring(msg)) end
  end

  mod.options:define({
    { key = "show_banner", type = "toggle",
      label = "Show load banner", default = true },
  })

  -- ------------------------------------------------------------------
  -- tileset + contest hall map
  -- ------------------------------------------------------------------
  local function fill(n)
    local t = {}
    for i = 1, 16 do t[i] = n end
    return t
  end

  mod.content.tilesets:register("KC_HALL_TILES", {
    id = "KC_HALL_TILES",
    image = mod.path .. "/assets/contest_tiles.png",
    imageWidth = 24, imageHeight = 8, tilesPerRow = 3,
    trueColor = true,
    blocks = {
      fill(0),   -- block 0: wall
      fill(1),   -- block 1: floor
      fill(2),   -- block 2: stage rug
    },
    walkable = { 1, 2 },
  })

  -- 4x4 blocks = 8x8 walk cells. Rug row at the top (judge's stage),
  -- floor below, whole bottom cell row warps out (nobody gets stuck).
  mod.content.maps:register("KC_CONTEST_HALL", {
    id = "KC_CONTEST_HALL", label = "ContestHall", index = 1743,
    tileset = "KC_HALL_TILES",
    width = 4, height = 4,
    blocks = {
      0, 0, 0, 0,
      0, 2, 2, 0,
      0, 1, 1, 0,
      0, 1, 1, 0,
    },
    borderBlock = 0,
    -- LAST_MAP + out-of-range destWarp: Warp.resolve falls back to the
    -- remembered outdoor cell, so the player lands back beside the girl.
    warps = {
      { x = 2, y = 7, destMap = "LAST_MAP", destWarp = 99 },
      { x = 3, y = 7, destMap = "LAST_MAP", destWarp = 99 },
      { x = 4, y = 7, destMap = "LAST_MAP", destWarp = 99 },
      { x = 5, y = 7, destMap = "LAST_MAP", destWarp = 99 },
    },
    signs = {},
    objects = {
      { index = 1, name = "KC_JUDGE",
        sprite = "SPRITE_GENTLEMAN",   -- confirmed in R/B and Y manifests
        x = 3, y = 2,
        movement = "STAY", range = "DOWN",
        text = "TEXT_KC_JUDGE" },
    },
  })

  -- ------------------------------------------------------------------
  -- appeal scoring data
  -- Gen 3 assigned every Gen 1 move a contest category; this table is
  -- that mapping (best-effort recall -- flavor data, so any single wrong
  -- entry is a cheap one-line fix, and an id miss falls back to TOUGH).
  -- Keys validated against the manifest's canonical moveOrder at build
  -- time so no key can silently fail to match.
  -- ------------------------------------------------------------------
  local KC_CATEGORY = {
    POUND = "TOUGH", KARATE_CHOP = "TOUGH", DOUBLESLAP = "CUTE",
    COMET_PUNCH = "TOUGH", MEGA_PUNCH = "TOUGH", PAY_DAY = "SMART",
    FIRE_PUNCH = "BEAUTY", ICE_PUNCH = "BEAUTY", THUNDERPUNCH = "COOL",
    SCRATCH = "TOUGH", VICEGRIP = "TOUGH", GUILLOTINE = "COOL",
    RAZOR_WIND = "COOL", SWORDS_DANCE = "BEAUTY", CUT = "COOL",
    GUST = "SMART", WING_ATTACK = "COOL", WHIRLWIND = "SMART",
    FLY = "SMART", BIND = "TOUGH", SLAM = "TOUGH",
    VINE_WHIP = "COOL", STOMP = "TOUGH", DOUBLE_KICK = "COOL",
    MEGA_KICK = "COOL", JUMP_KICK = "COOL", ROLLING_KICK = "COOL",
    SAND_ATTACK = "CUTE", HEADBUTT = "TOUGH", HORN_ATTACK = "COOL",
    FURY_ATTACK = "COOL", HORN_DRILL = "COOL", TACKLE = "TOUGH",
    BODY_SLAM = "TOUGH", WRAP = "TOUGH", TAKE_DOWN = "TOUGH",
    THRASH = "TOUGH", DOUBLE_EDGE = "TOUGH", TAIL_WHIP = "CUTE",
    POISON_STING = "SMART", TWINEEDLE = "COOL", PIN_MISSILE = "COOL",
    LEER = "COOL", BITE = "TOUGH", GROWL = "CUTE",
    ROAR = "COOL", SING = "CUTE", SUPERSONIC = "SMART",
    SONICBOOM = "COOL", DISABLE = "SMART", ACID = "SMART",
    EMBER = "BEAUTY", FLAMETHROWER = "BEAUTY", MIST = "BEAUTY",
    WATER_GUN = "CUTE", HYDRO_PUMP = "BEAUTY", SURF = "BEAUTY",
    ICE_BEAM = "BEAUTY", BLIZZARD = "BEAUTY", PSYBEAM = "BEAUTY",
    BUBBLEBEAM = "BEAUTY", AURORA_BEAM = "BEAUTY", HYPER_BEAM = "COOL",
    PECK = "COOL", DRILL_PECK = "COOL", SUBMISSION = "COOL",
    LOW_KICK = "TOUGH", COUNTER = "TOUGH", SEISMIC_TOSS = "TOUGH",
    STRENGTH = "TOUGH", ABSORB = "SMART", MEGA_DRAIN = "SMART",
    LEECH_SEED = "SMART", GROWTH = "BEAUTY", RAZOR_LEAF = "COOL",
    SOLARBEAM = "COOL", POISONPOWDER = "SMART", STUN_SPORE = "SMART",
    SLEEP_POWDER = "SMART", PETAL_DANCE = "BEAUTY", STRING_SHOT = "SMART",
    DRAGON_RAGE = "COOL", FIRE_SPIN = "BEAUTY", THUNDERSHOCK = "COOL",
    THUNDERBOLT = "COOL", THUNDER_WAVE = "COOL", THUNDER = "COOL",
    ROCK_THROW = "TOUGH", EARTHQUAKE = "TOUGH", FISSURE = "TOUGH",
    DIG = "SMART", TOXIC = "SMART", CONFUSION = "SMART",
    PSYCHIC_M = "SMART", HYPNOSIS = "SMART", MEDITATE = "BEAUTY",
    AGILITY = "COOL", QUICK_ATTACK = "COOL", RAGE = "COOL",
    TELEPORT = "COOL", NIGHT_SHADE = "SMART", MIMIC = "CUTE",
    SCREECH = "SMART", DOUBLE_TEAM = "COOL", RECOVER = "SMART",
    HARDEN = "TOUGH", MINIMIZE = "CUTE", SMOKESCREEN = "SMART",
    CONFUSE_RAY = "SMART", WITHDRAW = "CUTE", DEFENSE_CURL = "CUTE",
    BARRIER = "COOL", LIGHT_SCREEN = "BEAUTY", HAZE = "BEAUTY",
    REFLECT = "SMART", FOCUS_ENERGY = "COOL", BIDE = "TOUGH",
    METRONOME = "CUTE", MIRROR_MOVE = "SMART", SELFDESTRUCT = "BEAUTY",
    EGG_BOMB = "TOUGH", LICK = "CUTE", SMOG = "TOUGH",
    SLUDGE = "TOUGH", BONE_CLUB = "TOUGH", FIRE_BLAST = "BEAUTY",
    WATERFALL = "TOUGH", CLAMP = "TOUGH", SWIFT = "COOL",
    SKULL_BASH = "TOUGH", SPIKE_CANNON = "COOL", CONSTRICT = "TOUGH",
    AMNESIA = "CUTE", KINESIS = "SMART", SOFTBOILED = "BEAUTY",
    HI_JUMP_KICK = "COOL", GLARE = "TOUGH", DREAM_EATER = "SMART",
    POISON_GAS = "SMART", BARRAGE = "TOUGH", LEECH_LIFE = "SMART",
    LOVELY_KISS = "BEAUTY", SKY_ATTACK = "COOL", TRANSFORM = "SMART",
    BUBBLE = "CUTE", DIZZY_PUNCH = "SMART", SPORE = "BEAUTY",
    FLASH = "BEAUTY", PSYWAVE = "SMART", SPLASH = "CUTE",
    ACID_ARMOR = "TOUGH", CRABHAMMER = "TOUGH", EXPLOSION = "BEAUTY",
    FURY_SWIPES = "TOUGH", BONEMERANG = "TOUGH", REST = "CUTE",
    ROCK_SLIDE = "TOUGH", HYPER_FANG = "COOL", SHARPEN = "CUTE",
    CONVERSION = "BEAUTY", TRI_ATTACK = "BEAUTY", SUPER_FANG = "TOUGH",
    SLASH = "COOL", SUBSTITUTE = "SMART", STRUGGLE = "TOUGH",
  }
  -- "do not use" pairs per contest, from the R/S rules
  local KC_OPPOSED = {
    COOL   = { BEAUTY = true, TOUGH = true },
    BEAUTY = { COOL = true,   CUTE = true },
    CUTE   = { BEAUTY = true, SMART = true },
    SMART  = { CUTE = true,   TOUGH = true },
    TOUGH  = { COOL = true,   SMART = true },
  }
  local KC_ROUNDS = 5
  -- published read-only for other mods (and for the move-select box below);
  -- kanto_contests owns these tables -- decorators should not write them
  mod.exports.categories = KC_CATEGORY
  mod.exports.opposed = KC_OPPOSED

  -- ------------------------------------------------------------------
  -- the judge: a trainer class that never acts.
  -- brain returning nil is safe end to end: priority(nil)==0 in
  -- TurnOrder and executeAction returns immediately on a nil action.
  -- ------------------------------------------------------------------
  mod.content.trainers:register("OPP_KC_JUDGE", {
    id = "OPP_KC_JUDGE", name = "JUDGE",
    basePic = "OPP_GENTLEMAN",
    baseMoney = 20,
    -- The stand-in mon (never visible) exists to be the appeal meter.
    -- CHANSEY for the biggest HP stat in the game: appeal damage is
    -- computed as fractions of max HP, so the pool size only sets how
    -- smooth the bar drain looks, and vanilla attacks aren't what
    -- drains it anymore.
    -- makeBattler names the battler `mon.nickname or def.name`, so the
    -- nickname is what the appeal meter is labelled with.
    parties = { { { level = 30, species = "CHANSEY" } } },
    brain = function(battle)
      pcall(function()
        local n = battle.kcRound or 0
        if n > 0 and n < KC_ROUNDS then
          battle:sayNext(("The judge has\nseen %d of %d\nappeals."):format(n, KC_ROUNDS))
        else
          battle:sayNext("The judge is\nwatching intently!")
        end
      end)
      return nil
    end,
  })

  -- ------------------------------------------------------------------
  -- keep the judge on screen: battle.started fires at the END of
  -- enter(), when the whole intro queue is already built, so an act()
  -- appended here runs AFTER the send-outs -- it re-shows the trainer
  -- pic and hides the stand-in mon for the rest of the contest.
  -- ------------------------------------------------------------------
  mod.events:on("battle.started", function(payload)
    local ok, err = pcall(function()
      local b = payload and payload.battle
      if not (b and b.contest) then return end
      b:act(function()
        -- display is handled by the draw wrappers below; this just keeps
        -- the underlying flags consistent for anything else that reads them
        b.showEnemyTrainer = true
        b.enemyHidden = true
      end)
    end)
    if not ok then say("KC error (started):\n" .. tostring(err)) end
  end)

  -- ------------------------------------------------------------------
  -- PRESENTATION TAKEOVER.  Three vanilla behaviours fight the contest
  -- illusion; all three are display-only, so they are fixed at the draw
  -- and message layers rather than by wrestling the intro queue (whose
  -- send-out rows are already built by the time battle.started fires --
  -- which is exactly why v0.2 showed CLEFAIRY during "Go! MACHOKE").
  -- Stash-originals pattern: a sentinel would keep old code alive
  -- across a hot reload.
  -- ------------------------------------------------------------------
  local BattleStateM = require("src.battle.BattleState")
  BattleStateM._kcOriginals = BattleStateM._kcOriginals or {
    drawHUDs = BattleStateM.drawHUDs,
    drawPicsLayer = BattleStateM.drawPicsLayer,
    drawTextArea = BattleStateM.drawTextArea,
    say = BattleStateM.say,
    sayNext = BattleStateM.sayNext,
    performMove = BattleStateM.performMove,
    openParty = BattleStateM.openParty,
    openItems = BattleStateM.openItems,
    tryRun = BattleStateM.tryRun,
  }
  local O = BattleStateM._kcOriginals
  local Font = require("src.render.Font")

  -- The "HP" + ":[" tiles at the head of the appeal bar.
  -- BattleState captured `hudTile`/`drawHPBar` as file-local upvalues at
  -- load (BattleState.lua:4738-4739), so replacing HudTiles.tile cannot
  -- reach BattleState's own chrome calls -- but HudTiles.drawHPBar's body
  -- calls HudTiles.tile through the MODULE TABLE (HudTiles.lua:147-148,
  -- 171-173), so a replacement there does reach the bar's own tiles and
  -- nothing else.  0x71 = "HP", 0x62 = ":[" (home/pokemon.asm DrawHPBar).
  -- Gated twice over: a flag set only inside the contest arm of drawHUDs
  -- below, AND the enemy bar's exact pixel origin (drawHPBar(_, 2, 2) ->
  -- x=16,y=16; the player bar is tx=10,ty=9 -> x=80,y=72), so the party
  -- menu and status screen bars are untouched.
  local HudTilesM = require("src.render.HudTiles")
  HudTilesM._kcOriginals = HudTilesM._kcOriginals or { tile = HudTilesM.tile }
  local hudO = HudTilesM._kcOriginals
  local kcHideMeterLabel = false
  HudTilesM.tile = function(code, x, y, tint)
    if kcHideMeterLabel and y == 16
       and ((code == 0x71 and x == 16) or (code == 0x62 and x == 24)) then
      return
    end
    return hudO.tile(code, x, y, tint)
  end

  -- 1. The mon must NEVER be seen.  drawPicsLayer draws the trainer pic
  -- `if showEnemyTrainer`, else the mon.  In a contest force the first
  -- branch for the whole battle, and blank the foe pic's slide offset so
  -- the judge doesn't walk off during the send-out he isn't making.
  BattleStateM.drawPicsLayer = function(self, slide, sx, sy, onlySide, skipMenuClip)
    if not (self.contest and self.trainerPic) then
      return O.drawPicsLayer(self, slide, sx, sy, onlySide, skipMenuClip)
    end
    local wasShow, foeOff = self.showEnemyTrainer, self.picOff and self.picOff.foe
    self.showEnemyTrainer = true
    if self.picOff then self.picOff.foe = nil end
    local ok, err = pcall(O.drawPicsLayer, self, slide, sx, sy, onlySide, skipMenuClip)
    self.showEnemyTrainer = wasShow
    if self.picOff then self.picOff.foe = foeOff end
    if not ok then error(err) end
  end

  -- 2. The appeal meter.  drawHUDs draws the enemy HUD only
  -- `if not self.showEnemyTrainer` (the vanilla rule that the HUD stays
  -- down while a trainer pic holds the mon slot), so a contest clears
  -- the flag for the draw only.  The level is suppressed the same way:
  -- the HUD prints <LV>+level ONLY when shownStatus is nil, and
  -- statusLabel returns an unknown status string unchanged -- so a blank
  -- one prints nothing where the level was.
  -- The `HP:` label goes with it: an appeal meter is not hit points, so
  -- kcHideMeterLabel drops the two label tiles for the duration of the
  -- vanilla call only.  The bar keeps its segments and right cap and simply
  -- starts two tiles further left of nothing; if it reads too bare on
  -- device, restoring the 0x62 ":[" arm above puts the bracket back.
  -- APPEAL sits one row lower than a mon's name would, closing the gap the
  -- blanked level row left between the label and the meter.  The vanilla
  -- HUD prints the name at y=0 and <LV>+level at y=8 (BattleState.lua:5482,
  -- 5486); a contest blanks the level, so row 8 is free and the label drops
  -- into it.  Done by blanking the name for the vanilla call and reprinting
  -- it after -- nameX's own centring rule is reproduced so the label lands
  -- exactly where the engine would have put it, one row down.
  local function kcNameX(tx, name)
    local n = #Font.split(name)
    return tx * 8 + (n <= 2 and 16 or n <= 4 and 8 or 0)
  end
  BattleStateM.drawHUDs = function(self, slide)
    if not self.contest then return O.drawHUDs(self, slide) end
    local wasShow = self.showEnemyTrainer
    local wasStatus = self.enemy and self.enemy.shownStatus
    local wasName = self.enemy and self.enemy.name
    self.showEnemyTrainer = false
    if self.enemy and not wasStatus then self.enemy.shownStatus = " " end
    if self.enemy then self.enemy.name = "" end
    kcHideMeterLabel = true
    local ok, err = pcall(O.drawHUDs, self, slide)
    kcHideMeterLabel = false
    self.showEnemyTrainer = wasShow
    if self.enemy then
      self.enemy.shownStatus = wasStatus
      self.enemy.name = wasName
    end
    if not ok then error(err) end
    -- Reprint only when the vanilla pass actually drew the enemy HUD, or
    -- the label floats alone over the send-out and the intro ball rows.
    -- This is BattleState.lua:5471's own predicate minus showEnemyTrainer,
    -- which the contest arm above forces false for the duration.
    local drew = self.enemy and not self.enemySendingOut
                 and not self:growInScale(self.enemy) and slide == 0
                 and not self.introBalls and not self.enemy.fainted
    if drew and wasName and wasName ~= "" then
      pcall(function()
        love.graphics.setColor(0, 0, 0, 1)
        Font.draw(wasName, kcNameX(1, wasName), 8)
      end)
    end
  end

  -- 2b. The move-select info box.  PrintMenuItem's TYPE/PP box sits at
  -- (0,8) 11x5 with "TYPE/" at (1,9), the type at (2,10) and PP at (5,11)
  -- (BattleState.lua:5649-5695).  A contest has no type chart, so rows 9
  -- and 10 are repainted with the move's CONTEST CATEGORY instead; the PP
  -- row is left alone (appeals still spend PP).  Repaint-after rather than
  -- a replacement of drawTextArea: the vanilla body is 130 lines of other
  -- phases and re-deriving it would rot on the next engine bump.
  -- The `disabled!` branch draws at (1,10) instead of the type and is left
  -- alone -- a disabled move is still disabled in a contest.
  BattleStateM.drawTextArea = function(self)
    local ok, err = pcall(O.drawTextArea, self)
    if not ok then error(err) end
    if not (self.contest and self.phase == "moveSelect") then return end
    pcall(function()
      local moves = self.player and self.player.curMoves
      local sel = moves and moves[self.moveIndex]
      if not sel then return end
      if self.player.disabledSlot == self.moveIndex then return end
      if not self.data.moves[sel.id] then return end
      local cat = KC_CATEGORY[sel.id] or "TOUGH"
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 8, 72, 72, 16)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw("CATEGORY", 8, 72)
      Font.draw(cat, 16, 80)
    end)
  end

  -- 2c. One POKeMON, one routine.  A contest entrant performs with the mon
  -- it walked on stage with, so PkMn and ITEM are refused at the menu.
  -- openParty/openItems are the only seams the FIGHT/PkMn/ITEM/RUN grid
  -- reaches them through (BattleState.lua:1963-1966); refusing here mirrors
  -- their own phase bookkeeping (phase="messages", afterQueue="menu") so
  -- the menu comes straight back and no turn is spent.
  -- Post-faint replacement uses openReplacementMenu, and the SHIFT prompt
  -- pushes PartyMenu directly, so neither is affected by this.
  BattleStateM.openParty = function(self)
    if not self.contest then return O.openParty(self) end
    self.phase = "messages"
    self.afterQueue = "menu"
    self:say("No switching\nduring a contest!")
  end

  BattleStateM.openItems = function(self)
    if not self.contest then return O.openItems(self) end
    self.phase = "messages"
    self.afterQueue = "menu"
    self:say("No items during\na contest!")
  end

  -- RUN becomes withdrawing from the contest.  Vanilla would print
  -- _NoRunningText ("no running from a trainer battle!") because a contest
  -- is kind == "trainer" (BattleState.lua:4349); `result = "run"` is the
  -- same clean exit the 5-appeal limit uses -- no blackout, no prize.
  BattleStateM.tryRun = function(self)
    if not self.contest then return O.tryRun(self) end
    self.phase = "messages"
    self.afterQueue = "finish"
    self:say("You left the\nstage.\fThe judge looks\ndisappointed.")
    self.result = "run"
  end

  -- 3. Battle language -> contest language.  Every message goes through
  -- say/sayNext, so one rewriter covers the intro, the send-out and the
  -- faint without touching the engine's own text tables.
  local function contestText(self, text)
    if not (self.contest and type(text) == "string") then return text end
    local kind = tostring(self.contest)
    -- The intro is Strings("%s wants\nto fight!") (BattleState.lua:726) --
    -- the line break falls BETWEEN "wants" and "to", so the old
    -- find("wants to") never matched and the judge has been announcing a
    -- fight since v0.3.0. Match either side of the break instead.
    if text:find("wants", 1, true) and text:find("fight", 1, true) then
      return "The " .. kind .. " CONTEST\nis about to begin!"
    end
    if text:find("APPEAL", 1, true) and text:find("sent", 1, true) then
      return "The judge takes\nhis seat."
    end
    if text:find("APPEAL", 1, true) and text:find("fainted", 1, true) then
      return "The judge is\nfully impressed!"
    end
    if text:find("for winning", 1, true) then
      -- Two lines per page, <=18 chars each: v0.4 put three lines on the
      -- first page and the box clipped it to "future update... E".
      return "The " .. kind .. " RIBBON\nawaits a future"
             .. "\fupdate! Enjoy\nthe prize money!"
    end
    return text
  end
  -- THE PAGE-BREAK TRAP (v0.5.0 shipped straight into it).  A battle
  -- message is NOT a TextBox.  TextBox pages on "\f" (TextBox.lua:141),
  -- but BattleState:startMessage splits on "[\n\v]" ONLY
  -- (BattleState.lua:1037) -- an "\f" is just another glyph in the middle
  -- of the line, and the box's interior is 18 glyphs wide with NO wrap
  -- (drawTextArea blits at 8 + (i-1)*8 from a 20-tile box), so the rest is
  -- silently clipped off the right edge.  That is why v0.5.0's reaction
  -- and congratulation lines still read as cut off.
  -- The engine's own convention is to split pages into separate queue rows
  -- (the trainer-defeat path does exactly this, BattleState.lua:4043), so
  -- every contest string goes through here and comes out one row per page.
  -- Consecutive sayNext calls stay in call order: each increments
  -- nextInsert before inserting.
  local function sayPages(self, fn, text)
    if type(text) ~= "string" or not text:find("\f", 1, true) then
      return fn(self, text)
    end
    local last
    for page in (text .. "\f"):gmatch("(.-)\f") do
      if page ~= "" then last = fn(self, page) end
    end
    return last
  end
  BattleStateM.say = function(self, text)
    return sayPages(self, O.say, contestText(self, text))
  end
  BattleStateM.sayNext = function(self, text)
    return sayPages(self, O.sayNext, contestText(self, text))
  end

  -- 4. THE APPEAL ROUND.  performMove is the whole player-move pipeline
  -- (announce -> anim -> PP -> effects -> damage), so a contest replaces
  -- it wholesale for the player's side: every move becomes a pure appeal.
  -- No accuracy roll, no type chart, no side effects -- Growl must never
  -- actually lower the judge's ATTACK.  The replacement reuses the
  -- engine's own beats in vanilla order (announce text, anim row via
  -- nextInsert, applyDamage -> drainNext, then reaction text), exactly
  -- the pattern continueTrapping uses.
  local function kcAppeal(self, user, target, moveInst)
    local move = self:moveDef(moveInst)
    if not move then return end
    if not moveInst.struggle then
      moveInst.pp = math.max(0, (moveInst.pp or 1) - 1)
    end
    -- announce + anim, vanilla's exact pattern from performMove
    self:sayNextAuto(self:romText("_ItemUseText001", "%s\nused %s!",
                                  user.name, move.name))
    self.nextInsert = (self.nextInsert or 0) + 1
    table.insert(self.queue, self.nextInsert,
                 { anim = move.id, attackerIsPlayer = true })
    -- score it
    local cat = KC_CATEGORY[move.id] or "TOUGH"
    local kind = tostring(self.contest)
    local maxhp = (target.mon.stats and target.mon.stats.hp) or target.mon.hp
    local dmg, react
    -- Reaction text is two lines per page, <=18 chars a line, with the
    -- CATEGORY sentence LAST: the box waits for A on the final page only,
    -- so anything on an earlier page scrolls past before it can be read
    -- (v0.4 buried the category on page one and it flew by).
    if cat == kind then
      dmg = math.max(1, math.ceil(maxhp * 0.25))
      react = "The judge is\ndelighted!\fA perfect " .. kind .. "\nappeal!"
    elseif KC_OPPOSED[kind] and KC_OPPOSED[kind][cat] then
      dmg = 0
      react = "The judge frowns.\fA " .. cat .. " move in\na " .. kind .. " contest?"
    else
      dmg = math.max(1, math.ceil(maxhp * 0.10))
      react = "The judge nods\npolitely.\fA fair " .. cat .. "\nappeal."
    end
    if dmg > 0 then self:applyDamage(target, dmg) end
    self:sayNext(react)
    -- round bookkeeping + endings
    self.kcRound = (self.kcRound or 0) + 1
    if target.mon.hp <= 0 then
      self:onFaint(target)   -- vanilla victory path; texts already rewritten
      return
    end
    if self.kcRound >= KC_ROUNDS then
      self:sayNext("The routine is\nover...")
      self:sayNext("The judge shakes\nhis head. Not\nquite this time!")
      -- end as "run": no blackout, no prize -- the clean contest loss
      self.result = "run"
      self.afterQueue = "finish"
    end
  end

  BattleStateM.performMove = function(self, user, target, moveInst, isCalled)
    if not (self.contest and user and user.isPlayer) then
      return O.performMove(self, user, target, moveInst, isCalled)
    end
    local ok, err = pcall(kcAppeal, self, user, target, moveInst)
    if not ok then say("KC error (appeal):\n" .. tostring(err)) end
  end

  -- ------------------------------------------------------------------
  -- 5. No EXP from a contest.  Winning routed through the vanilla
  -- faint/victory path, so awardExp paid out a full trainer-battle share
  -- (1638 EXP off one COOL contest on device).  awardExp factors the
  -- payout into a `battle.exp_award` hook explicitly so a mod can replace
  -- it wholesale (BattleState.lua:3836-3868) -- so this is the engine's
  -- own seam, not a wrapper: skipping next() skips the whole share,
  -- which also means no "gained EXP. Points!" line and no level-up flow.
  -- self.participants is still cleared by the caller afterwards.
  -- The chain runs for EVERY battle, so a non-contest call MUST fall
  -- through to next(ctx) untouched.
  -- ------------------------------------------------------------------
  mod.hooks:wrap("battle.exp_award", function(next_, ctx)
    local b = ctx and ctx.battle
    if b and b.contest then return end
    return next_(ctx)
  end)

  -- ------------------------------------------------------------------
  -- commands
  -- ------------------------------------------------------------------
  -- start_contest: Commands.start_battle's confirmed body, plus
  -- battle.contest set before the push so every later hook can key off it.
  mod.content.commands:register("kanto_contests:start_contest", {
    foreground = true,
    fn = function(ctx, contestType)
      local BattleState = require("src.battle.BattleState")
      local runner = ctx.runner
      local ok, battle = pcall(BattleState.newTrainer,
                               ctx.game, "OPP_KC_JUDGE", 1)
      if not ok or not battle then
        say("KC error (battle):\n" .. tostring(battle))
        ctx.lastCheck = false
        return
      end
      battle.contest = contestType or "COOL"
      -- The judge's stand-in mon IS the appeal meter, so label it that way.
      -- The trainers schema only accepts level+species per party entry
      -- (strict validation), so the nickname is applied here instead.
      -- makeBattler already computed .name, so set both.
      pcall(function()
        battle.enemy.mon.nickname = "APPEAL"
        battle.enemy.name = "APPEAL"
      end)
      battle.endBattleText, ctx.endBattleText = ctx.endBattleText, nil
      battle.onFinish = function(result)
        ctx.lastBattleResult = result
        ctx.lastCheck = result == "win"
        if ctx.overworld then
          if result == "win" then
            ctx.afterScript = ctx.afterScript or {}
            table.insert(ctx.afterScript, function()
              ctx.overworld:afterBattle(result, battle)
            end)
          else
            ctx.overworld:afterBattle(result, battle)
          end
        end
        runner:resume()
      end
      if ctx.overworld and ctx.overworld.pushBattle then
        ctx.overworld:pushBattle(battle)
      else
        ctx.game.stack:push(battle)
      end
      runner:yield()
    end,
  })

  -- base_talk: preserve a vanilla NPC's own line on gated-off branches
  -- (engine-guide pattern, confirmed working in shipped mods).
  local MapScripts = require("src.script.MapScripts")
  mod.content.commands:register("kanto_contests:base_talk", {
    foreground = true,
    fn = function(ctx, mapId, textId)
      local runner = ctx.runner
      local base = MapScripts.baseTalk(mapId, textId)
      if base then
        base(ctx.game, ctx.overworld, ctx.npc, function() runner:resume() end)
        runner:yield()
        return
      end
      -- No hand-ported engine script for this NPC (the Celadon girl has
      -- none -- baseTalk indexes `base[mapId].talk` only). Her vanilla line
      -- lives in ROM text, which showMapText reaches via
      -- Data:resolveText(mapLabel, textConst); do the same here.
      local ow = ctx.overworld
      local label = ow and ow.map and ow.map.def and ow.map.def.label
      if not label then return end
      local ok, text = pcall(function()
        return (ctx.game.data:resolveText(label, textId))
      end)
      if not ok or not text then return end
      local TextBox = require("src.render.TextBox")
      ctx.game.stack:push(TextBox.new(ctx.game, text,
        function() runner:resume() end))
      runner:yield()
    end,
  })

  -- ------------------------------------------------------------------
  -- entrance: the Celadon little girl knows the way.
  -- TEXT_CELADONCITY_LITTLE_GIRL is IDENTICAL in the R/B and Yellow
  -- manifests and unclaimed by engine flavor/story scripts.
  -- ------------------------------------------------------------------
  mod.content.map_scripts:register("CELADON_CITY", {
    priority = 500,
    talk = {
      TEXT_CELADONCITY_LITTLE_GIRL = {
        { "face_player" },
        { "ask", "The new CONTEST\nHALL is so fun!\fWant me to show\nyou the way?" },
        { "jump_if_false", "no_thanks" },
        { "show_text", "This way!" },
        { "warp", "KC_CONTEST_HALL", 4, 5, "up" },
        { "jump", "done" },
        { "label", "no_thanks" },
        { "kanto_contests:base_talk", "CELADON_CITY",
          "TEXT_CELADONCITY_LITTLE_GIRL" },
        { "label", "done" },
      },
    },
  })

  -- ------------------------------------------------------------------
  -- the judge's dialogue in the hall (our own text key -- no trap)
  -- ------------------------------------------------------------------
  mod.content.map_scripts:register("KC_CONTEST_HALL", {
    priority = 500,
    talk = {
      TEXT_KC_JUDGE = {
        { "face_player" },
        { "show_text", "Welcome to the\nCONTEST HALL!\fI judge the COOL\ncontest." },
        { "ask", "Appeal to me with\nyour POKeMON's\nmoves. Enter?" },
        { "jump_if_false", "later" },
        { "kanto_contests:start_contest", "COOL" },
        { "jump_if_true", "won" },
        { "show_text", "Hmm. Not quite\nribbon material\nyet. Practice!" },
        { "jump", "done" },
        { "label", "won" },
        { "show_text", "Magnificent!\nTruly COOL!\fRibbons come in\nthe next update!" },
        { "jump", "done" },
        { "label", "later" },
        { "show_text", "Come back when\nyou feel COOL!" },
        { "label", "done" },
      },
    },
  })

  -- ------------------------------------------------------------------
  -- load banner. NOT on game.ready: Game.lua emits that while "nothing is
  -- on the stack yet" and pushes the title screen immediately after, so a
  -- TextBox there is discarded (v0.1: no banner ever appeared). First map
  -- entry of the session is the first moment a box survives.
  -- ------------------------------------------------------------------
  local bannerShown = false
  mod.events:on("map.entered", function()
    local ok, err = pcall(function()
      if bannerShown then return end
      if not mod.options:get("show_banner") then return end
      bannerShown = true
      say("KANTO CONTESTS\nv" .. VERSION .. " ready!")
    end)
    if not ok then mod.log:warn("banner failed: %s", tostring(err)) end
  end)

  mod.log:info("kanto_contests %s loaded", VERSION)
end
