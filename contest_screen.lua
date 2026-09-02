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

-- Gen 3's panel colours; the player's row is the light-green one
S.C = {
  stage      = { 88, 168, 72 }, stageLight = { 120, 200, 96 },
  panel      = { 250, 250, 136 }, panelMine = { 208, 248, 200 },
  panelLine  = { 168, 152, 72 }, ink = { 40, 40, 40 },
  heart      = { 224, 32, 32 }, heartJam = { 32, 32, 32 },
  bar        = { 240, 120, 120 }, box = { 248, 184, 184 },
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
  self:say("The stage scores\nare in!")
  self.phase = "intro"
end

-- nickname / trainer for a row
function S:names(ci)
  local c = self.s.c[ci]
  local mon = c.mon or {}
  local nick = mon.nickname or mon.name or mon.species or "?"
  return clip(nick, 9), clip(c.name, 8)
end

function S:moveName(id)
  local data = self.game and self.game.data
  local def = data and data.moves and data.moves[id]
  return (def and def.name) or tostring(id or "?")
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
  local before, crowd = #self.msgs, false
  for _, e in ipairs(ev) do
    local k, t = e.kind, nil
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
      -- dialogue-ok: nick is clipped to 9 -> 18
      t = ("%s's appeal\nwent over great."):format(nick); crowd = true
    elseif k == "crowd_wild" then t = "The crowd goes\nwild! +6 hearts!"; crowd = true
    elseif k == "crowd_down" then
      -- dialogue-ok: nick is clipped to 9 -> 18
      t = ("%s's appeal\ndid not go over."):format(nick); crowd = true
    elseif k == "crowd_frozen" then t = "The crowd stays\nquiet."; crowd = true
    elseif k == "scored" then
      local h = e.hearts or 0
      self.turnHearts[ci] = h
      -- dialogue-ok: nick is clipped to 9 -> 16
      if h <= 0 then t = ("%s failed\nto stand out..."):format(nick) end
    end
    if t then self:say(t) end
  end
  -- The APPLAUSE meter stays up for every line of an appeal that moved
  -- the crowd, so the reader sees the dots and the sentence that
  -- explains them together (a frame countdown had it gone before the
  -- text was read -- reported from device).
  if crowd then
    for i = before + 1, #self.msgs do self.msgs[i].applause = true end
  end
  -- jams change EARLIER contestants' hearts too
  for i, c in ipairs(self.s.c) do
    if c.currMove then self.turnHearts[i] = self.E.hearts(c.appeal) end
  end
end

function S:beginTurn()
  local order = self.E.beginTurn(self.s)
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
      self.phase = "tally"
      self:queueTally()
    else
      local mine = standings[1].rank
      -- dialogue-ok: %s is a placing, three glyphs
      self:say(("You stand %s\nafter %d."):format(({ "1st", "2nd", "3rd", "4th" })[mine], self.s.turn))
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
    -- dialogue-ok: nick is clipped to 9 -> 18; the move to 12 -> 18
    self:say(("%s appealed\nwith %s!"):format(nick, clip(self:moveName(id), 12)))
  end
  local ev = self.E.appeal(self.s, ci, id)
  self.pendingAnim = id
  self.pendingEvents = { ci = ci, ev = ev }
  self.phase = "resolve"
end

function S:queueTally()
  local final = self.E.final(self.s)
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
  rgb({ 255, 232, 120 }); G.rectangle("fill", 2, 18, 72, 26, 4, 4)
  rgb(S.C.bar); G.rectangle("line", 2, 18, 72, 26, 4, 4)
  if m.Font then rgb(S.C.heart); m.Font.draw("APPLAUSE", 6, 20) end
  for i = 1, 5 do
    if i <= math.min(self.s.applause, 5) then rgb({ 240, 48, 120 }) else rgb({ 255, 250, 200 }) end
    G.circle("fill", 10 + (i - 1) * 13, 37, 4)
  end
end

function S:drawTextBox()
  local m = self:mods()
  if not m.Chrome then return end
  local G = love.graphics
  rgb({ 255, 255, 255 }); G.rectangle("fill", 0, 96, S.ARENA_W, 48)
  if self.phase == "menu" and #self.msgs == 0 then
    m.Chrome.textbox(0, 12, 18, 4)
    local moves = self:playerMoves()
    for i, mv in ipairs(moves) do
      if i <= 4 then
        local row = self.s.moves[mv.id]
        local cat = row and row.cat or "----"
        m.Chrome.print(("%-6s %s"):format(cat:sub(1, 6), clip(self:moveName(mv.id), 11)), 2, 12 + i)
      end
    end
    m.Chrome.cursor(1, 12 + math.min(self.menuCursor, math.max(1, #moves)))
    return
  end
  m.Chrome.textbox(0, 12, 18, 4)
  local msg = self.msgs[1]
  if msg then
    local a, b = tostring(msg.text):match("^(.-)\n(.*)$")
    m.Chrome.print(a or msg.text, 1, 14)
    if b then m.Chrome.print(b, 1, 16) end
  end
end

function S:drawPanel()
  local m = self:mods()
  local G = love.graphics
  local L = self.currentLayout or self:layout()
  local maxPts = 0
  for _, c in ipairs(self.s.c) do maxPts = math.max(maxPts, c.round1 + 2 * c.total) end
  maxPts = math.max(maxPts, 200)
  local panelW = L.w - L.panelX
  for slot, ci in ipairs(self.rows) do
    local c = self.s.c[ci]
    local x0 = L.panelX
    local y = L.panelY + (slot - 1) * L.rowH
    rgb(ci == 1 and S.C.panelMine or S.C.panel)
    G.rectangle("fill", x0, y, panelW, L.rowH)
    rgb(S.C.panelLine); G.rectangle("line", x0 + 0.5, y + 0.5, panelW - 1, L.rowH - 1)
    local nick, trainer = self:names(ci)
    local h = self.turnHearts[ci] or 0
    local color = h >= 0 and S.C.heart or S.C.heartJam
    local pts = c.round1 + 2 * c.total
    local frac = math.max(0, math.min(1, pts / maxPts))
    if L.name == "wide" then
      -- 80px wide, 36 tall: nick / trainer stacked, hearts, then the bar
      if m.Font then
        rgb(S.C.ink)
        m.Font.draw(nick, x0 + 3, y + 2)
        m.Font.draw("/" .. trainer, x0 + 3, y + 11)
      end
      for i = 1, math.min(8, math.abs(h)) do drawHeart(x0 + 3 + (i - 1) * 9, y + 21, color) end
      rgb(S.C.bar); G.rectangle("fill", x0 + 4, y + 31, 70, 1)
      drawHeart(x0 + 4 + math.floor(70 * frac) - 3, y + 28, S.C.heart)
    else
      -- 160px wide, 18 tall: "NICK/TRAINER" on one line (at most 18
      -- glyphs = 144px), hearts under the name, the bar to their right
      if m.Font then
        rgb(S.C.ink)
        m.Font.draw(nick .. "/" .. trainer, x0 + 3, y + 1)
      end
      for i = 1, math.min(8, math.abs(h)) do drawHeart(x0 + 3 + (i - 1) * 9, y + 10, color) end
      rgb(S.C.bar); G.rectangle("fill", x0 + 82, y + 14, 72, 1)
      drawHeart(x0 + 82 + math.floor(72 * frac) - 3, y + 11, S.C.heart)
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
