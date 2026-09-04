-- Kanto Contests: the judging as a screen of its own, laid out like
-- Ruby/Sapphire's appeal round.
--
--   +----------------------------------+------------+
--   |  arena 160x144 (Gold's battle    | panel 80px |
--   |  frame, so move animations need  | 4 rows:    |
--   |  no translation): judge at the   |  nick      |
--   |  enemy pic box, the performing   |  /trainer  |
--   |  mon's BACK pic at the player    |  hearts    |
--   |  box, APPLAUSE meter top-left,   |  standing  |
--   |  text box / move menu below      |            |
--   +----------------------------------+------------+
--
-- Loaded by main.lua with load(mod:read("contest_screen.lua")) like
-- contest_engine.lua. The MODEL (turn flow, rows, messages, menu) is pure
-- Lua driven by update(); tests/contest_screen_test.lua runs a whole
-- contest through it headless. The DRAW layer requires engine modules
-- lazily and is the one part only a device can show.
--
-- Move animations are Gold's own: an AnimRunner over data.gen2BattleAnims
-- with the performer standing in the player slot (turn 0 -- Gen 3 also
-- shows the back sprite, facing the judge), presented through
-- BattleAnimView exactly as BattleState does. Where the cache has no
-- animation data the beat is skipped and the flow continues.

local S = {}
-- Two layouts, chosen per frame from the window's orientation. The arena is
-- always Gold's 160x144 battle frame at the top-left (so move animations
-- need no translation); the panel goes BESIDE it when the screen is wider
-- than tall, and BELOW it when it is upright. The wide canvas alone forced
-- the phone onto its side (0.34.0, reported from device) -- everything
-- else in the game plays in portrait, so portrait is the default.
S.WIDE = { name = "wide", w = 240, h = 144, panelX = 160, panelY = 0,   rowH = 36 }
-- 18px rows: 216 tall keeps the whole panel above the touch controls when
-- the UI is centred (24px rows ran under the D-pad -- reported from device)
S.TALL = { name = "tall", w = 160, h = 216, panelX = 0,   panelY = 144, rowH = 18 }
S.ARENA_W = 160
S.W, S.H = S.TALL.w, S.TALL.h   -- defaults; see S:layout()
-- the results ceremony: frames for the bars to fill, then a hold with
-- the winner lit before the placings are read
S.CEREMONY_FILL = 120
S.CEREMONY_HOLD = 75

-- 0..1 of the appeal points to show on the bars: 1 outside the ceremony
function S:ceremonyGrow()
  if self.phase ~= "ceremony" or not self.ceremony then return 1 end
  local t = math.min(1, self.ceremony / S.CEREMONY_FILL)
  return 1 - (1 - t) * (1 - t)          -- ease out: fast start, soft landing
end

-- pure: which layout for a window of w x h pixels
function S.layoutFor(w, h)
  if type(w) == "number" and type(h) == "number" and w > h then return S.WIDE end
  return S.TALL
end

function S:layout()
  local ok, w, h = pcall(function() return love.graphics.getDimensions() end)
  local L = S.layoutFor(ok and w or nil, ok and h or nil)
  self.currentLayout = L
  return L
end

-- Restrained GBC-style window colours. White stays behind the opaque battle
-- art; cream, lavender and the player's mint tint belong to the UI only.
S.C = {
  stage      = { 88, 168, 72 }, stageLight = { 120, 200, 96 },
  panel      = { 248, 240, 216 }, panelMine = { 216, 240, 208 },
  panelLine  = { 152, 144, 176 }, ink = { 48, 40, 64 },
  heart      = { 208, 64, 96 }, heartJam = { 48, 40, 64 },
  bar        = { 224, 144, 160 }, box = { 232, 224, 240 },
  paper      = { 255, 255, 255 }, muted = { 200, 192, 208 },
  combo      = { 32, 112, 56 }, disabled = { 144, 144, 152 },
}

local HEART = {
  "01100110", "11111111", "11111111", "01111110", "00111100", "00011000",
}

local function clip(s, n)
  s = tostring(s or "")
  if #s > n then return s:sub(1, n) end
  return s
end

-- ------------------------------------------------------------------ model

-- opts.engine   contest_engine module
-- opts.state    an engine state from engine.new(...)
-- opts.game     for data (moves, pokemon, palettes, anims) and input
-- opts.kind, opts.rank
-- opts.onDone(place, final)   called once after the tally
-- opts.judgeClass  trainer class id for the judge's art (default GENTLEMAN)
function S.new(opts)
  local self = setmetatable({}, { __index = S })
  self.E = assert(opts.engine, "engine")
  self.s = assert(opts.state, "state")
  self.game = opts.game
  self.kind = opts.kind or self.s.contest
  self.rank = opts.rank or "NORMAL"
  self.onDone = opts.onDone
  self.judgeClass = opts.judgeClass or "GENTLEMAN"
  -- "full": the move list takes the panel rows and the text box becomes
  -- a card about the highlighted move (0.34.26); "classic": the list in
  -- the text box over the panels, as 0.34.25 and earlier
  self.moveMenu = opts.moveMenu or "full"
  self.isOpaque = true
  self.msgs = {}            -- queue of { text=, wait=bool }
  self.phase = "intro"      -- intro | menu | resolve | tally | done
  self.performer = nil      -- contestant index whose mon is on stage
  self.rows = {}            -- panel rows in display order (contestant idx)
  self.turnHearts = {}      -- [ci] = hearts shown this turn
  self.menuCursor = 1
  self.anim = nil           -- AnimRunner while a move animation plays
  self.animTimer = 0
  self.finished = false
  self.frame = 0
  for i = 1, self.E.CONTESTANTS do self.rows[i] = i; self.turnHearts[i] = 0 end
  self:queueIntro()
  return self
end

function S:say(text, tag)
  local m = { text = text }
  if tag then for k, v in pairs(tag) do m[k] = v end end
  self.msgs[#self.msgs + 1] = m
end

function S:queueIntro()
  -- dialogue-ok: rank and category are at most 6 glyphs -> 15
  self:say(("The %s\n%s CONTEST!"):format(self.rank, self.kind))
  self:say("Stage scores set\nthe first order.")
  self.phase = "intro"
end

-- nickname / trainer for a row. A Gen 2 name is up to 10 glyphs
-- (MISDREAVUS, SUDOWOODO) and the 9-clip cut the last letter off on
-- device; every line built from `nick` below is budgeted for 10, and the
-- tall panel's "NICK/TRAINER" line (18 glyphs) leaves the trainer 7 --
-- which every vanilla trainer name and the player's name fit.
function S:names(ci)
  local c = self.s.c[ci]
  local mon = c.mon or {}
  local nick = mon.nickname or mon.name or mon.species or "?"
  return clip(nick, 10), clip(c.name, 7)
end

-- The battle menu's own click on a pick: BattleState.lua plays
-- Sfx_ReadText2 on A in its move list, and this menu was silent.
function S:click()
  local data = self.game and self.game.data
  local okS, Sound = pcall(require, "src.core.Sound")
  if data and okS and Sound and Sound.play and data.audio and data.audio.sfx
     and data.audio.sfx.Sfx_ReadText2 then
    pcall(Sound.play, data, "Sfx_ReadText2")
  end
end

function S:moveName(id)
  local data = self.game and self.game.data
  local def = data and data.moves and data.moves[id]
  return (def and def.name) or tostring(id or "?")
end

-- A combo STARTER id as the player should read it. The `after` lists use
-- the contest data's own spellings (THUNDER_PUNCH, VICE_GRIP, PSYCHIC),
-- which are not always the engine's move ids (THUNDERPUNCH, VICEGRIP,
-- PSYCHIC_M), so moveName() fell through to the raw underscored id on
-- the move card (code review). Try the id, then the id with its
-- underscores removed, then just make it readable.
function S:starterName(id)
  local data = self.game and self.game.data
  local moves = data and data.moves or {}
  id = tostring(id or "?")
  local def = moves[id] or moves[(id:gsub("_", ""))]
  if def and def.name then return def.name end
  return (id:gsub("_", " "))
end

function S:playerMoves()
  local mon = self.s.c[1].mon or {}
  local out = {}
  for _, m in ipairs(mon.moves or {}) do
    if m and m.id then out[#out + 1] = m end
  end
  return out
end

-- the engine's events for one appeal -> text-box lines (18 x 2 each)
function S:narrate(ci, ev)
  local nick = self:names(ci)
  local before, crowd, level, wild = #self.msgs, false, nil, false
  for _, e in ipairs(ev) do
    if e.level then level = e.level end
    if e.kind == "crowd_wild" then wild = true end
    local k, t, t2 = e.kind, nil, nil
    if k == "skipped" then t = ("%s is\ncatching breath."):format(nick)
    elseif k == "no_more" then t = ("%s has\nnothing left!"):format(nick)
    elseif k == "attention" then t = ("The JUDGE eyes\n%s."):format(nick)
    elseif k == "combo" then t = "A combo!\nThe JUDGE beams!"
    elseif k == "startled" then
      t = ("%s was\nstartled! -%d"):format(self:names(e.who), math.floor(e.jam / 10))
    elseif k == "missed" then t = "It tried to\nstartle others..."
    elseif k == "repeat" then t = ("Same move again.\n-%d hearts"):format(e.penalty / 10)
    elseif k == "too_nervous" then t = ("%s froze!\nToo nervous."):format(nick)
    elseif k == "nervous" then t = ("%s looks\nnervous..."):format(self:names(e.who))
    elseif k == "attention_lost" then t = ("The JUDGE\nignores %s"):format(self:names(e.who))
    elseif k == "condition_up" then t = ("%s looks\nsharper!"):format(nick)
    elseif k == "condition_lost" then t = ("%s looks\nrattled."):format(self:names(e.who))
    elseif k == "crowd_up" then
      -- dialogue-ok: nick is clipped to 10 -> 16
      t = ("%s's act\nwent over great."):format(nick); crowd = true
    elseif k == "crowd_wild" then t = "The crowd goes\nwild! +6 hearts!"; crowd = true
    elseif k == "crowd_down" then
      -- dialogue-ok: nick is clipped to 10 -> 16
      t = ("%s's act\ndid not go over."):format(nick); crowd = true
    elseif k == "crowd_frozen" then t = "The crowd stays\nquiet."; crowd = true
    elseif k == "scored" then
      local h = e.hearts or 0
      self.turnHearts[ci] = h
      -- dialogue-ok: nick is clipped to 10 -> 17
      if h <= 0 then t = ("%s failed\nto stand out..."):format(nick) end
      -- the JUDGE's verdict (0.34.34): Gen 3's judge comments on every
      -- appeal, and the hearts alone did not say how it landed
      if h >= 8 then t2 = "The JUDGE is\nastonished!"
      elseif h >= 5 then t2 = "The JUDGE is\nimpressed!"
      elseif h >= 3 then t2 = "The JUDGE nods\napprovingly."
      elseif h >= 1 then t2 = "The JUDGE looks\nunmoved."
      else t2 = "The JUDGE frowns." end
    end
    if t then self:say(t) end
    if t2 then self:say(t2) end
  end
  -- The APPLAUSE meter stays up for every line of an appeal that moved
  -- the crowd, so the reader sees the dots and the sentence that
  -- explains them together (a frame countdown had it gone before the
  -- text was read -- reported from device).
  if crowd then
    for i = before + 1, #self.msgs do
      local m = self.msgs[i]
      m.applause = true
      -- the meter as it stood for THIS appeal: the engine resets it to 0
      -- in the same step the crowd goes wild, so reading it live showed an
      -- empty meter under "The crowd goes wild!" -- the least dramatic
      -- possible moment (device). wild lights all five and flashes.
      m.applauseLevel = level
      m.wild = wild
    end
  end
  -- jams change EARLIER contestants' hearts too
  for i, c in ipairs(self.s.c) do
    if c.currMove then self.turnHearts[i] = self.E.hearts(c.appeal) end
  end
end

function S:beginTurn()
  -- the order was already drawn at the end of the last turn (for the
  -- preview line); the first turn draws it here
  local order = self.nextOrder or self.E.beginTurn(self.s)
  self.nextOrder = nil
  for slot = 0, self.E.CONTESTANTS - 1 do self.rows[slot + 1] = order[slot] end
  for i = 1, self.E.CONTESTANTS do self.turnHearts[i] = 0 end
  self.order = order
  self.slot = 0
  -- your own POKeMON stands on stage while you choose (it stood empty
  -- before, reported from device); the performer changes as each appeals
  self.performer = 1
  self:say(("Appeal no. %d!\nWhich move?"):format(self.s.turn))
  self.phase = "menu"
end

-- one contestant's appeal, in slot order
function S:resolveNext()
  if self.slot >= self.E.CONTESTANTS then
    local standings = self.E.endTurn(self.s)
    if self.s.turn >= self.E.TURNS then
      -- Gen 3's results ceremony (0.34.33): the bars fill to their final
      -- totals, the winner's row lights up, THEN the placings are read.
      self.final = self.E.final(self.s)
      self.ceremony = 0
      self.phase = "ceremony"
    else
      local mine = standings[1].rank
      local turnNo = self.s.turn
      -- dialogue-ok: %s is a placing, three glyphs
      self:say(("You stand %s\nafter %d."):format(({ "1st", "2nd", "3rd", "4th" })[mine], turnNo))
      -- Gen 3 shows next turn's order right after the appeals, so effects
      -- like "appeals earlier next turn" are visible. E.beginTurn decides
      -- that order (and advances the turn), so it runs here and S:beginTurn
      -- takes the result.
      self.nextOrder = self.E.beginTurn(self.s)
      local first = self.nextOrder[0]
      if first then
        -- dialogue-ok: nick is clipped to 10 -> 15
        self:say(("%s goes\nfirst next."):format((self:names(first))))
      end
      self.phase = "between"
    end
    return
  end
  local ci = self.order[self.slot]
  self.slot = self.slot + 1
  local id = (ci == 1) and self.chosen or self.E.chooseMove(self.s, ci)
  self.performer = ci
  self:cry(ci)
  local nick = self:names(ci)
  if id then
    -- dialogue-ok: nick is clipped to 10 -> 18; the move to 12 -> 18
    self:say(("%s appeals\nwith %s!"):format(nick, clip(self:moveName(id), 12)))
  end
  local ev = self.E.appeal(self.s, ci, id)
  self.pendingAnim = id
  self.pendingEvents = { ci = ci, ev = ev }
  self.phase = "resolve"
end

function S:queueTally()
  -- Reuse the ceremony's ranking: final() draws a random exact-tie break.
  -- Drawing it twice could crown one winner and award another.
  local final = self.final or self.E.final(self.s)
  self.final = final
  self:say("The JUDGE tallies\nthe scores...")
  local place
  local P = { "1st", "2nd", "3rd", "4th" }
  for _, r in ipairs(final) do
    -- dialogue-ok: placing 3 + nick 9 -> 14
    self:say(("%s: %s\n%d points"):format(P[r.place], (self:names(r.who)), r.total))
    if r.who == 1 then place = r.place end
  end
  self.place = place
  self.final = final
  -- dialogue-ok: %s is a placing, three glyphs
  self:say(("You place %s\nof 4!"):format(P[place] or "4th"))
end

function S:cry(ci)
  local mon = self.s.c[ci] and self.s.c[ci].mon
  local data = self.game and self.game.data
  if not (mon and mon.species and data) then return end
  local ok, Sound = pcall(require, "src.core.Sound")
  if ok and Sound and Sound.playCry then pcall(Sound.playCry, data, mon.species) end
end

-- Gold's move animation for `id`, performer in the player slot. Returns
-- true when one is running; false (and nothing else happens) when the
-- cache has no animation data, so the flow simply carries on.
function S:startAnim(id)
  local data = self.game and self.game.data
  local anims = data and data.gen2BattleAnims
  if not (anims and anims.moves and anims.scripts) then return false end
  local key = anims.moves[id]
  if not (key and anims.scripts[key]) then return false end
  local okR, AnimRunner = pcall(require, "src.battle.gen2.AnimRunner")
  if not okR then return false end
  local audio = data.audio or {}
  local okS, Sound = pcall(require, "src.core.Sound")
  local perf = self.s.c[self.performer or 1].mon
  self.anim = AnimRunner.new({
    data = anims, constants = data.gen2Constants,
    battleTurn = 0, animId = id, param = 0,
    sfxOrder = audio.sfxOrder,
    flying = { player = false, enemy = false },
    hooks = {
      sound = function(name)
        if okS and name and audio.sfx and audio.sfx[name] then pcall(Sound.playStereo, data, name) end
      end,
      cry = function()
        if okS and perf and perf.species and audio.cries and audio.cries[perf.species] then
          pcall(Sound.playCry, data, perf.species)
        end
      end,
      pokeballWobble = function() return 0 end,
    },
  })
  self.anim:start(key)
  self.animTimer = 0
  return true
end

function S:pressed(k)
  local input = self.game and self.game.input
  return input and input:wasPressed(k)
end

function S:update(_dt)
  self.frame = self.frame + 1

  -- a move animation owns the screen until it ends (or 6 seconds, as a net)
  if self.anim then
    self.animTimer = self.animTimer + 1
    local more = self.anim:step()
    if not more or self.animTimer > 360 then
      self.anim = nil
      self:afterAnim()
    end
    return
  end

  -- messages: A advances
  if #self.msgs > 0 then
    -- the crowd's roar, the first frame a wild line is up. SFX_KC_APPLAUSE
    -- is registered by main.lua only when assets/applause.ogg ships; with
    -- no such sfx Sound.play is a silent no-op.
    local top = self.msgs[1]
    if top.wild and not top.roared then
      top.roared = true
      local data = self.game and self.game.data
      local okS, Sound = pcall(require, "src.core.Sound")
      if okS and Sound and Sound.play and data then pcall(Sound.play, data, "SFX_KC_APPLAUSE") end
    end
    if self:pressed("a") or self:pressed("b") then table.remove(self.msgs, 1) end
    return
  end

  if self.phase == "intro" then
    self:beginTurn()
  elseif self.phase == "menu" then
    local moves = self:playerMoves()
    local n = math.max(1, #moves)
    if self:pressed("up") then self.menuCursor = (self.menuCursor - 2) % n + 1
    elseif self:pressed("down") then self.menuCursor = self.menuCursor % n + 1
    elseif self:pressed("a") then
      self:click()
      local m = moves[self.menuCursor]
      if m and (m.pp == nil or m.pp > 0) then
        if m.pp then m.pp = m.pp - 1 end
        self.chosen = m.id
        self.phase = "resolving"
        self:resolveNext()
      elseif m then
        self:say("No PP left for\nthis move!")
      end
    end
  elseif self.phase == "resolve" then
    -- the announcement has been read; play the animation, then narrate
    if self.pendingAnim and self:startAnim(self.pendingAnim) then
      self.pendingAnim = nil
      return
    end
    self.pendingAnim = nil
    self:afterAnim()
  elseif self.phase == "resolving" or self.phase == "narrated" then
    self:resolveNext()
  elseif self.phase == "between" then
    self:beginTurn()
  elseif self.phase == "ceremony" then
    -- A skips to the end of the fill; the applause plays as the bars land
    self.ceremony = (self.ceremony or 0) + 1
    if self:pressed("a") or self:pressed("b") then self.ceremony = math.max(self.ceremony, S.CEREMONY_FILL) end
    if self.ceremony == S.CEREMONY_FILL then
      local data = self.game and self.game.data
      local okS, Sound = pcall(require, "src.core.Sound")
      if okS and Sound and Sound.play and data then pcall(Sound.play, data, "SFX_KC_APPLAUSE") end
      -- rows fall into finishing order once the totals are up
      for _, r in ipairs(self.final) do self.rows[r.place] = r.who end
    end
    if self.ceremony >= S.CEREMONY_FILL + S.CEREMONY_HOLD then
      self.ceremony = nil
      self.phase = "tally"
      self:queueTally()
    end
  elseif self.phase == "tally" then
    self.phase = "done"
    self.finished = true
    if self.onDone then self.onDone(self.place, self.final) end
  end
end

function S:afterAnim()
  local p = self.pendingEvents
  self.pendingEvents = nil
  if p then self:narrate(p.ci, p.ev) end
  self.phase = "narrated"
end

-- ------------------------------------------------------------------- draw

function S:uiSize()
  local L = self:layout()
  return L.w, L.h
end

function S:sgbPalettes()
  local L = self.currentLayout or self:layout()
  local okP, PaletteFX = pcall(require, "src.render.PaletteFX")
  if okP and PaletteFX then
    local mode = PaletteFX.mode or "gbc"
    if mode == "og" or mode == "og_inv" or mode == "classic" then
      return { PaletteFX.zone(PaletteFX.GRAYS, 0, 0, L.w / 8 - 1, L.h / 8 - 1) }
    end
  end
  return { { colors = false, x = 0, y = 0, w = L.w, h = L.h } }
end

local function rgb(c, a) love.graphics.setColor(c[1] / 255, c[2] / 255, c[3] / 255, a or 1) end

function S:mods()
  if self._mods then return self._mods end
  local m = {}
  local function try(name) local ok, v = pcall(require, name); return ok and v or nil end
  m.Chrome = try("src.ui.gen2.Chrome")
  m.Font = try("src.render.Font")
  m.Assets = try("src.render.Assets")
  m.Palettes = try("src.world.gen2.Palettes")
  m.GbcPalette = try("src.render.GbcPalette")
  m.View = try("src.ui.gen2.BattleAnimView")
  m.BattleState = try("src.ui.gen2.BattleState")
  self._mods = m
  return m
end

function S:image(path)
  self.images = self.images or {}
  if not path then return nil end
  local cached = self.images[path]
  if cached == nil then
    local m = self:mods()
    local ok, img = pcall(m.Assets.image, path)
    cached = (ok and img) or false
    self.images[path] = cached
  end
  return cached or nil
end

local function drawHeart(px, py, color)
  rgb(color)
  for r = 1, #HEART do
    local line = HEART[r]
    for c = 1, #line do
      if line:sub(c, c) == "1" then love.graphics.rectangle("fill", px + c - 1, py + r - 1, 1, 1) end
    end
  end
end

-- Integer-pixel window trim (no rounded/subpixel outlines at native size).
local function window(px, py, w, h, fill)
  local G = love.graphics
  rgb(S.C.ink); G.rectangle("fill", px, py, w, h)
  rgb(S.C.paper); G.rectangle("fill", px + 1, py + 1, w - 2, h - 2)
  rgb(fill); G.rectangle("fill", px + 2, py + 2, w - 4, h - 4)
end

function S:comboReady(id)
  local c = self.s.c[1]
  return not c.skipping and not c.exploded and not c.nervous
    and c.attention and c.prevMove and self.E.isCombo(self.s, c.prevMove, id)
end

function S:moveTag(mv)
  -- Only announce an actionable bonus on the highlighted move. A starter
  -- is merely a possible setup, not a combo the player can use right now.
  if mv and (mv.pp == nil or mv.pp > 0) and self:comboReady(mv.id) then
    return "COMBO", "READY!", true
  end
  return nil
end

-- A quiet category tab and five turn pips occupy only the vacant upper
-- left. A ready combo gets a small badge; other moves leave the stage clear.
function S:drawStageTrim()
  local G, m = love.graphics, self:mods()
  window(2, 2, 88, 15, S.C.box)
  if m.Font then rgb(S.C.ink); m.Font.draw(clip(self.kind, 6), 6, 5) end
  for i = 1, self.E.TURNS do
    rgb(i <= (self.s.turn or 0) and S.C.heart or S.C.muted)
    G.rectangle("fill", 64 + (i - 1) * 4, 7, 3, 4)
  end
  -- The original sprite boxes and their white backgrounds are untouched.
  rgb(S.C.muted); G.rectangle("fill", 98, 58, 52, 1)
  rgb(S.C.box); G.rectangle("fill", 104, 59, 40, 1)
  if m.Font then rgb(S.C.ink); m.Font.draw("JUDGE", 104, 63) end
  if self.phase == "menu" and #self.msgs == 0 and self.moveMenu == "full" then
    local tag, detail, combo = self:moveTag(self:menuMove())
    if not tag then return end
    window(2, 20, 92, 26, combo and S.C.panelMine or S.C.panel)
    if m.Font then
      rgb(combo and S.C.combo or S.C.ink)
      m.Font.draw(tag, 6, 24)
      m.Font.draw(detail, 6, 35)
    end
  end
end

-- the performer's back pic at Gold's player box (tiles 2,6; 6 tiles),
-- through the species palette, honouring the animation's hide/slide/shade
function S:drawPerformer()
  local ci = self.performer
  local mon = ci and self.s.c[ci].mon
  local data = self.game and self.game.data
  local def = mon and data and data.pokemon and data.pokemon[mon.species]
  if not def then return end
  local m = self:mods()
  local image = self:image(def.spriteBack)
  if not image then return end
  local G = love.graphics
  local slide, shade, hidden = 0, nil, false
  if self.anim and self.anim.bg then
    local bg = self.anim.bg
    hidden = bg.hidden and bg.hidden.player
    slide = (bg.slide and bg.slide.player) or 0
    shade = bg.monShade and bg.monShade.player
  end
  if hidden then return end
  local w, h = image:getDimensions()
  local scale = tonumber(def.battleScaleBack) or 1
  local box = 6 * 8
  local px = 2 * 8 + math.floor((box - w * scale) / 2) + slide
  local py = 6 * 8 + (box - h * scale)
  local colors = m.Palettes and data.gen2Palettes
    and m.Palettes.monColors(data.gen2Palettes, mon.species, mon.shiny)
  if shade and m.View and colors then colors = m.View.shadeColors(colors, shade) end
  G.setColor(1, 1, 1, 1)
  local function body() G.draw(image, px, py, 0, scale, scale) end
  if colors and not def.trueColor and m.GbcPalette and m.GbcPalette.available() then
    m.GbcPalette.with(colors, body)
  else
    body()
  end
end

-- the judge: the trainer class's front pic at Gold's enemy box
function S:drawJudge()
  local data = self.game and self.game.data
  local m = self:mods()
  if not (data and m.BattleState and m.BattleState.trainerArt) then return end
  local path, trueColor = m.BattleState.trainerArt(data, self.judgeClass)
  local image = self:image(path)
  if not image then return end
  local G = love.graphics
  local w, h = image:getDimensions()
  local box = 7 * 8
  local px = 12 * 8 + math.max(0, math.floor((box - w) / 2))
  local py = math.max(0, box - h)
  local colors = m.Palettes and data.gen2Palettes
    and m.Palettes.trainerColors(data.gen2Palettes, self.judgeClass)
  G.setColor(1, 1, 1, 1)
  local function body() G.draw(image, px, py) end
  if colors and not trueColor and m.GbcPalette and m.GbcPalette.available() then
    m.GbcPalette.with(colors, body)
  else
    body()
  end
end

-- A plain white arena, like Gold's own battles. The green stage was Gen 3's
-- look and only served to outline the white box the judge's art sits in
-- (developer, 2026-09-01).
function S:drawArenaBackground()
  local G = love.graphics
  rgb({ 255, 255, 255 }); G.rectangle("fill", 0, 0, S.ARENA_W, 96)
  self:drawStageTrim()
  self:drawJudge()
  self:drawPerformer()
end

-- Shown while the text box is on a line that moved the crowd (tagged in
-- narrate), and while an appeal that will move it is still animating.
function S:applauseVisible()
  local m = self.msgs[1]
  if m and m.applause then return true end
  if self.anim and self.pendingEvents then
    for _, e in ipairs(self.pendingEvents.ev) do
      if e.kind == "crowd_up" or e.kind == "crowd_wild" or e.kind == "crowd_down"
         or e.kind == "crowd_frozen" then return true end
    end
  end
  return false
end

function S:drawApplause()
  if not self:applauseVisible() then return end
  local m = self:mods()
  local G = love.graphics
  local msg = self.msgs[1]
  local level = (msg and msg.applauseLevel) or math.min(self.s.applause, 5)
  local wild = msg and msg.wild
  -- Five inset pixel lamps; the wild snapshot still lights every lamp.
  local hot = wild and (self.frame % 8 < 4)
  window(2, 20, 88, 26, hot and S.C.box or S.C.panel)
  if m.Font then
    rgb(wild and S.C.heart or S.C.ink)
    m.Font.draw(wild and "WILD!!" or "APPLAUSE", 6, 24)
  end
  for i = 1, 5 do
    local x = 8 + (i - 1) * 15
    rgb(S.C.panelLine); G.rectangle("fill", x, 35, 11, 7)
    rgb((wild or i <= level) and (hot and S.C.bar or S.C.heart) or S.C.paper)
    G.rectangle("fill", x + 1, 36, 9, 5)
    if wild or i <= level then
      rgb(S.C.paper); G.rectangle("fill", x + 2, 36, 2, 1)
    end
  end
end

function S:drawTextBox()
  local m = self:mods()
  if not m.Chrome then return end
  local G = love.graphics
  rgb({ 255, 255, 255 }); G.rectangle("fill", 0, 96, S.ARENA_W, 48)
  if self.phase == "menu" and #self.msgs == 0 and self.moveMenu == "full" then
    self:drawMoveInfo()
    return
  end
  if self.phase == "menu" and #self.msgs == 0 then
    m.Chrome.textbox(0, 12, 18, 4)
    local moves = self:playerMoves()
    for i, mv in ipairs(moves) do
      if i <= 4 then
        local row = self.s.moves[mv.id]
        local cat = row and row.cat or "----"
        m.Chrome.print(("%-6s %s"):format(cat:sub(1, 6), clip(self:moveName(mv.id), 10)), 2, 12 + i)
      end
    end
    m.Chrome.cursor(1, 12 + math.min(self.menuCursor, math.max(1, #moves)))
    return
  end
  m.Chrome.textbox(0, 12, 18, 4)
  if self.phase == "ceremony" then
    m.Chrome.print("The JUDGE tallies", 1, 14)
    m.Chrome.print("the scores...", 1, 16)
    return
  end
  local msg = self.msgs[1]
  if msg then
    local a, b = tostring(msg.text):match("^(.-)\n(.*)$")
    m.Chrome.print(a or msg.text, 1, 14)
    if b then m.Chrome.print(b, 1, 16) end
  end
end

-- Picking a move, FULL INFO style (0.34.26, asked for from the device):
-- the four panel rows become the move list and the text box a card
-- about the highlighted move -- the Gen 3 arrangement, where the list
-- shows name and category and a window under it explains the move.
function S:menuMove()
  local moves = self:playerMoves()
  local i = math.min(self.menuCursor, math.max(1, #moves))
  return moves[i], i, moves
end

-- The card, in the text box's 18x4 interior (tile rows 13-16):
--   13  APPEAL and its hearts (one per 10 points, up to 8)
--   14  JAM and its dark hearts; the combo note now has its own stage tab
--   15-16  the effect's own two lines (the KC_CONTEST_EFFECTS text)
function S:drawMoveInfo()
  local m = self:mods()
  if not m.Chrome then return end
  m.Chrome.textbox(0, 12, 18, 4)
  local mv = self:menuMove()
  if not mv then return end
  local row = self.s.moves[mv.id]
  local eff = row and self.s.effects and self.s.effects[row.effect]
  local appeal = eff and eff.appeal or 0
  local jam = eff and eff.jam or 0
  m.Chrome.print("APPEAL", 1, 13)
  m.Chrome.print("JAM", 1, 14)
  for i = 1, 8 do
    drawHeart(64 + (i - 1) * 9, 105, i <= math.floor(appeal / 10) and S.C.heart or S.C.box)
    drawHeart(64 + (i - 1) * 9, 113, i <= math.floor(jam / 10) and S.C.heartJam or S.C.box)
  end
  local text = eff and eff.text or ""
  local a, b = tostring(text):match("^(.-)\n(.*)$")
  m.Chrome.print(a or text, 1, 15)
  if b then m.Chrome.print(b, 1, 16) end
end

-- The list, in the panel rows: cursor, move name, category. A move that
-- would combo with the one just performed is printed in green; one with
-- no PP left in grey.
function S:drawMoveList()
  local m = self:mods()
  local G = love.graphics
  local L = self.currentLayout or self:layout()
  local _, cur, moves = self:menuMove()
  local panelW = L.w - L.panelX
  for slot = 1, self.E.CONTESTANTS do
    local x0, y = L.panelX, L.panelY + (slot - 1) * L.rowH
    rgb(slot == cur and S.C.panelMine or S.C.panel)
    G.rectangle("fill", x0, y, panelW, L.rowH)
    rgb(S.C.paper); G.rectangle("fill", x0, y, panelW, 1)
    rgb(S.C.panelLine); G.rectangle("fill", x0, y + L.rowH - 1, panelW, 1)
    local mv = moves[slot]
    if mv and m.Font then
      local row = self.s.moves[mv.id]
      local name = clip(self:moveName(mv.id), 10)
      local cat = (row and row.cat or "----"):sub(1, 6)
      local noPP = mv.pp ~= nil and mv.pp <= 0
      local combo = self:comboReady(mv.id)
      rgb(noPP and S.C.disabled or (combo and S.C.combo or S.C.ink))
      if L.name == "wide" then
        -- Ten full glyphs need ALL 80px; put the cursor beside category.
        m.Font.draw(name, x0, y + 4)
        m.Font.draw(cat, x0 + 12, y + 19)
      else
        m.Font.draw(name, x0 + 12, y + 5)
        m.Font.draw(cat, x0 + panelW - 6 * 8 - 4, y + 5)
      end
    end
    if slot == cur then
      rgb(S.C.ink)
      local cy = y + (L.name == "wide" and 23 or 9)
      for i = 0, 3 do G.rectangle("fill", x0 + 3 + i, cy - 3 + i, 1, 7 - i * 2) end
    end
  end
end

function S:drawPanel()
  if self.phase == "menu" and #self.msgs == 0 and self.moveMenu == "full" then
    return self:drawMoveList()
  end
  local m = self:mods()
  local G = love.graphics
  local L = self.currentLayout or self:layout()
  local maxPts = 0
  for _, c in ipairs(self.s.c) do maxPts = math.max(maxPts, c.round1 + 2 * c.total) end
  maxPts = math.max(maxPts, 200)
  local panelW = L.w - L.panelX
  local grow = self:ceremonyGrow()
  local winner = nil
  if self.phase == "ceremony" and self.ceremony and self.ceremony >= S.CEREMONY_FILL and self.final then
    for _, r in ipairs(self.final) do if r.place == 1 then winner = r.who end end
  end
  for slot, ci in ipairs(self.rows) do
    local c = self.s.c[ci]
    local x0 = L.panelX
    local y = L.panelY + (slot - 1) * L.rowH
    local lit = winner == ci and (self.frame % 16 < 8)
    rgb(lit and { 255, 255, 255 } or (ci == 1 and S.C.panelMine or S.C.panel))
    G.rectangle("fill", x0, y, panelW, L.rowH)
    rgb(S.C.paper); G.rectangle("fill", x0, y, panelW, 1)
    rgb(S.C.panelLine); G.rectangle("fill", x0, y + L.rowH - 1, panelW, 1)
    local nick, trainer = self:names(ci)
    local h = self.turnHearts[ci] or 0
    local color = h >= 0 and S.C.heart or S.C.heartJam
    -- during the ceremony the appeal half of the score grows in
    local pts = c.round1 + 2 * c.total * grow
    local frac = math.max(0, math.min(1, pts / maxPts))
    if L.name == "wide" then
      -- 80px wide, 36 tall: nick / trainer stacked, hearts, then the bar
      if m.Font then
        rgb(S.C.ink)
        m.Font.draw(nick, x0, y + 2)            -- exactly 80px for 10 glyphs
        m.Font.draw("/" .. trainer, x0 + 3, y + 11)
      end
      for i = 1, math.min(8, math.abs(h)) do drawHeart(x0 + 3 + (i - 1) * 9, y + 21, color) end
      rgb(S.C.muted); G.rectangle("fill", x0 + 4, y + 30, 70, 3)
      rgb(S.C.bar); G.rectangle("fill", x0 + 4, y + 30, math.floor(70 * frac), 3)
      drawHeart(x0 + 4 + math.floor(70 * frac) - 3, y + 28, S.C.heart)
    else
      -- 160px wide, 18 tall: "NICK/TRAINER" on one line (at most 18
      -- glyphs = 144px), hearts under the name, the bar to their right
      if m.Font then
        rgb(S.C.ink)
        m.Font.draw(nick .. "/" .. trainer, x0 + 3, y + 1)
      end
      for i = 1, math.min(8, math.abs(h)) do drawHeart(x0 + 3 + (i - 1) * 9, y + 10, color) end
      rgb(S.C.muted); G.rectangle("fill", x0 + 83, y + 13, 69, 3)
      rgb(S.C.bar); G.rectangle("fill", x0 + 83, y + 13, math.floor(69 * frac), 3)
      drawHeart(x0 + 83 + math.floor(69 * frac) - 3, y + 11, S.C.heart)
      -- Performer cue stays beyond the longest nickname/trainer line.
      if self.performer == ci and self.phase ~= "ceremony" and self.phase ~= "tally" then
        rgb(S.C.ink)
        G.rectangle("fill", x0 + 152, y + 3, 2, 5)
        G.rectangle("fill", x0 + 154, y + 4, 2, 3)
        G.rectangle("fill", x0 + 156, y + 5, 1, 1)
      end
    end
  end
end

function S:draw()
  local m = self:mods()
  local G = love.graphics
  local L = self:layout()
  G.setColor(1, 1, 1, 1)
  G.rectangle("fill", 0, 0, L.w, L.h)
  local function drawBg() self:drawArenaBackground() end
  if self.anim and m.View then
    self.view = self.view or m.View.new(self.game.data.gen2BattleAnims, self.game.data.gen2Palettes)
    local fake = { player = self.s.c[self.performer or 1].mon, enemy = nil }
    local ok = pcall(function()
      self.view:present(self.anim, drawBg, fake)
      self.view:drawObjects(self.anim, fake)
    end)
    if not ok then drawBg() end
  else
    drawBg()
  end
  self:drawApplause()
  self:drawTextBox()
  self:drawPanel()
  G.setColor(1, 1, 1, 1)
end

return S
