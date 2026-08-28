-- Kanto Contests -- R/S-style Pokemon Contests as judge "battles".
--
-- TWO ARMS, ONE FILE. Gold is a parallel engine: a Gold boot never loads
-- src/battle/BattleState.lua or src/inventory/ItemEffects.lua, so every
-- Gen 1 wrapper below would land on modules nothing instantiates. The
-- entry function branches on generation FIRST, before any Gen 1 require
-- executes -- on Gold, an executed require for an unserved Gen 1 module
-- is a loader ERROR in the mod manager, not a silent no-op.
--
-- File scope carries only pure Lua (contest data + arithmetic), shared by
-- both arms. The Gen 1 arm is the mod as it has always been. The Gold arm
-- (kcGold, below the data) is the 0.10.0 spike: Goldenrod attendant,
-- judge battle, appeal scoring via the generation-agnostic battle hooks.

-- ------------------------------------------------------------------
-- SHARED CONTEST DATA -- pure Lua, safe at chunk load on any generation.
-- Gen 3 assigned every Gen 1 move a contest category; this table is that
-- mapping (best-effort recall -- flavor data, any wrong entry is a cheap
-- one-line fix; an id miss falls back to TOUGH). Gold movesets can carry
-- Gen 2 moves this table has never heard of -- same TOUGH fallback until
-- their categories are added deliberately.
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

-- Slice 4, first half: rival coordinators. Three named entrants shared by
-- every contest and both arms -- they stand in each hall, get their hearts
-- announced in the Introduction Round, and from round 2 may JAM the routine,
-- healing the judge's meter. They are pressure and personality, not
-- battlers: the win condition is still the meter, so both arms drive them
-- with the same three pieces below and no battle-side machinery.
local KC_RIVALS = {
  { name = "PIPER" },   -- sweet-snack CUTE partisan
  { name = "REX" },     -- sour-snack TOUGH grinder
  { name = "FIONA" },   -- immaculate BEAUTY veteran
}
-- Tuning provisional per NOTES.md: revisit after real playtests.
local KC_JAM_CHANCE = 30   -- percent, rolled once per round in rounds 2..4
local KC_JAM_HEAL = 0.08   -- fraction of the meter one jam restores
local KC_JAM_CAP = 2       -- jams per contest, total across all rivals

-- Both battles expose the same love-style rng: Gen 1 BattleState.rng is
-- love.math.random directly (BattleState.lua:657) and Gen 2 Battle.rng is
-- loveStyleRng over opts.random (Battle.lua:94-105) -- rng(lo,hi) -> lo..hi
-- inclusive on both, which is why these helpers can be shared.
local function kcRollRivalHearts(rng)
  local out = {}
  for i = 1, #KC_RIVALS do
    -- 2..6, under the player's ceiling of 8: a pampered entrant can always
    -- out-shine the field, and a raw one can be out-shone
    out[i] = rng and rng(2, 6) or 4
  end
  return out
end

-- One roll per round: the rival who jams, or nil. Owns the round gate and
-- the cap; the arms only apply the heal and speak the lines.
local function kcJamRoll(b, rng)
  local round = b.kcRound or 0
  if round < 2 or round >= KC_ROUNDS then return nil end
  if (b.kcJams or 0) >= KC_JAM_CAP then return nil end
  if not rng or rng(1, 100) > KC_JAM_CHANCE then return nil end
  b.kcJams = (b.kcJams or 0) + 1
  return KC_RIVALS[rng(1, #KC_RIVALS)]
end

-- 0.13.2: THE RIVALS APPEAL TOO.
--
-- Until now they were announced once at the introduction and then only
-- surfaced if a jam happened to roll -- 30% a round, so a whole contest
-- could pass without them doing a thing, which is exactly how it read on
-- device. A contest is four coordinators taking turns, so now one rival
-- performs after every appeal of yours, rotating, and the judge reacts.
-- Their scores accumulate, and the contest ends with a PLACEMENT.
--
-- Deliberately ONE rival per round rather than all three: three extra
-- boxes a round is a wall of text between your own appeals.
local KC_RIVAL_REACTIONS = {
  { text = "The judge nods.",     score = 12 },
  { text = "The crowd cheers!",   score = 18 },
  { text = "Polite applause.",    score = 9 },
  { text = "The judge frowns.",   score = 3 },
}

-- Whose turn it is this round, what the judge thought, and the points.
-- Scores are the same currency the player's appeals earn (see kcAppealPoints)
-- so the placement at the end compares like with like.
local function kcRivalTurn(b, rng)
  local index = ((b.kcRound or 1) - 1) % #KC_RIVALS + 1
  local rival = KC_RIVALS[index]
  local roll = KC_RIVAL_REACTIONS[rng and rng(1, #KC_RIVAL_REACTIONS) or 1]
  b.kcRivalScore = b.kcRivalScore or {}
  b.kcRivalScore[index] = (b.kcRivalScore[index] or 0) + roll.score
  return rival, roll
end

-- The player's appeal in the same points as the rivals'.
local function kcAppealPoints(cat, kind)
  if cat == kind then return 25 end
  if KC_OPPOSED[kind] and KC_OPPOSED[kind][cat] then return 0 end
  return 10
end

-- Where the player finished, 1 = won the contest. Hearts count for both
-- sides at the same rate, so the Introduction Round matters to the final
-- standing and not just to the head start.
local KC_PLACES = { "1st", "2nd", "3rd", "4th" }
local function kcPlacement(b)
  local mine = (b.kcPlayerScore or 0) + (b.kcHearts or 0) * 3
  local ahead = 0
  for i = 1, #KC_RIVALS do
    local theirs = ((b.kcRivalScore and b.kcRivalScore[i]) or 0)
      + (((b.kcRivalHearts and b.kcRivalHearts[i]) or 0) * 3)
    if theirs > mine then ahead = ahead + 1 end
  end
  return KC_PLACES[ahead + 1] or "4th"
end

local KC_STAT_KEY = { COOL = "cool", BEAUTY = "beauty", CUTE = "cute",
                      SMART = "smart", TOUGH = "tough" }
local KC_STAT_ORDER = { "COOL", "BEAUTY", "CUTE", "SMART", "TOUGH" }

local function kcCondition(mon)
  if not mon then return nil end
  local c = mon.contest
  if type(c) ~= "table" then
    c = { cool = 0, beauty = 0, cute = 0, smart = 0, tough = 0 }
    mon.contest = c
  end
  for _, k in pairs(KC_STAT_KEY) do c[k] = c[k] or 0 end
  return c
end
local function kcSheen(mon) return (mon and mon.kcSheen) or 0 end

-- APPRAISER WORDING -- ALL PROVISIONAL (see NOTES.md); one table each so
-- renaming is a single edit. Thresholds are upper bounds.
local KC_TIERS = {
  { upTo = 20,  word = "dull" },
  { upTo = 50,  word = "promising" },
  { upTo = 80,  word = "impressive" },
  { upTo = 100, word = "radiant" },
}
local KC_SHEEN_LINES = {
  { upTo = 20,  text = "It could use\nsome pampering." },
  { upTo = 50,  text = "It is coming\nalong nicely." },
  { upTo = 80,  text = "It looks well\nlooked after." },
  { upTo = 100, text = "It is glowing,\nand quite full!" },
}
local function kcBand(table_, n)
  for _, row in ipairs(table_) do
    if n <= row.upTo then return row end
  end
  return table_[#table_]
end

-- INTRODUCTION ROUND scoring (see the 0.9.0 CHANGELOG for the design):
-- score = primary + 0.5*each opposed-pair secondary + 0.5*sheen.
-- All four rank rows ship; only NORMAL is reachable until ranks land.
local KC_INTRO_THRESHOLDS = {
  NORMAL = {  11,  21,  31,  41,  51,  61,  71,  81 },
  SUPER  = {  91, 111, 131, 151, 171, 191, 211, 231 },
  HYPER  = { 171, 201, 231, 261, 291, 321, 351, 381 },
  MASTER = { 321, 361, 401, 441, 481, 521, 561, 601 },
}
local KC_INTRO_METER_FRACTION = 0.35

-- The five Gen 3 scarves. Crystal can equip these through its real held-item
-- menu (`mon.item`); Gen 1 has no held items, so using one records the worn
-- category on `mon.kcScarf`. Contest scoring accepts either representation.
local KC_SCARF_BONUS = 20
local KC_SCARVES = {
  { id = "KC_RED_SCARF",    name = "RED SCARF",    label = "RED",    category = "COOL" },
  { id = "KC_BLUE_SCARF",   name = "BLUE SCARF",   label = "BLUE",   category = "BEAUTY" },
  { id = "KC_PINK_SCARF",   name = "PINK SCARF",   label = "PINK",   category = "CUTE" },
  { id = "KC_GREEN_SCARF",  name = "GREEN SCARF",  label = "GREEN",  category = "SMART" },
  { id = "KC_YELLOW_SCARF", name = "YELLOW SCARF", label = "YELLOW", category = "TOUGH" },
}
local KC_SCARF_BY_ID, KC_SCARF_BY_CATEGORY = {}, {}
for _, row in ipairs(KC_SCARVES) do
  KC_SCARF_BY_ID[row.id] = row
  KC_SCARF_BY_CATEGORY[row.category] = row
end

local function kcScarfCategory(mon)
  if not mon then return nil end
  local held = KC_SCARF_BY_ID[mon.item]
  if held then return held.category end
  local worn = mon.kcScarf
  if KC_SCARF_BY_ID[worn] then return KC_SCARF_BY_ID[worn].category end
  return KC_SCARF_BY_CATEGORY[worn] and worn or nil
end

local function kcHasScarf(save, row)
  if not (save and row) then return false end
  if save.inventory and (save.inventory[row.id] or 0) > 0 then return true end
  local function wears(mon)
    return mon and (mon.item == row.id
      or kcScarfCategory(mon) == row.category)
  end
  for _, mon in ipairs(save.party or {}) do
    if wears(mon) then return true end
  end
  for _, box in pairs(save.boxes or {}) do
    for _, mon in ipairs(box or {}) do
      if wears(mon) then return true end
    end
  end
  return false
end

local function kcEligibleScarf(save, mon)
  local cond = kcCondition(mon)
  for _, row in ipairs(KC_SCARVES) do
    if (cond[KC_STAT_KEY[row.category]] or 0) >= 100
        and not kcHasScarf(save, row) then return row end
  end
  return nil
end

local function kcIntroHearts(mon, kind, rank)
  local cond = kcCondition(mon)
  local score = cond[KC_STAT_KEY[kind]] or 0
  for sec in pairs(KC_OPPOSED[kind] or {}) do
    score = score + 0.5 * (cond[KC_STAT_KEY[sec]] or 0)
  end
  score = score + 0.5 * kcSheen(mon)
  if kcScarfCategory(mon) == kind then score = score + KC_SCARF_BONUS end
  local hearts = 0
  for i, need in ipairs(KC_INTRO_THRESHOLDS[rank]
                        or KC_INTRO_THRESHOLDS.NORMAL) do
    if score >= need then hearts = i end
  end
  return hearts, score
end

-- Snack data. The items themselves are only REGISTERED on Gen 1 (the
-- registry targets Gen 1 data tables); the definitions are shared so the
-- Gold arm can grow a delivery route without re-stating them.
local KC_SNACK_CONDITION = 20
local KC_SNACK_SHEEN     = 10
local KC_SNACK_PRICE     = 500  -- TUNABLE, see NOTES.md
local KC_SNACKS = {
  { id = "KC_SPICY_SNACK",  name = "SPICY SNACK",  flavor = "Spicy",  category = "COOL"   },
  { id = "KC_DRY_SNACK",    name = "DRY SNACK",    flavor = "Dry",    category = "BEAUTY" },
  { id = "KC_SWEET_SNACK",  name = "SWEET SNACK",  flavor = "Sweet",  category = "CUTE"   },
  { id = "KC_BITTER_SNACK", name = "BITTER SNACK", flavor = "Bitter", category = "SMART"  },
  { id = "KC_SOUR_SNACK",   name = "SOUR SNACK",   flavor = "Sour",   category = "TOUGH"  },
}
local KC_SNACK_BY_ID = {}
for _, s in ipairs(KC_SNACKS) do KC_SNACK_BY_ID[s.id] = s end

-- ------------------------------------------------------------------
-- THE GOLD ARM. Goldenrod City gets a Contest attendant who leads into a
-- private Contest Hall; its judge starts a COOL contest as a judge battle.
-- Most of this arm rides mod.world, events and generation-agnostic battle
-- hooks. Gold has no hook that can
-- REPLACE a move before its effect runs, however, so the core appeal
-- conversion wraps src.battle.gen2.Battle:useMove directly; the contract is
-- source-verified in both 0.1.79 and 0.2.4.
--
-- Gold's hall vendor feeds snacks on the spot instead of putting them in the
-- bag: Gold's item path still has no ItemEffects seam. The custom map and
-- party picker follow the source-verified Hidden Grottos 0.1.3 and
-- SelectMonFromParty patterns.
-- ------------------------------------------------------------------
-- A HALL IS TWO ROOMS: a LOBBY you arrive in, and a STAGE the judge leads
-- you onto when a contest starts.
--
-- 0.14.0 built one room and it read as a lobby -- services, a queue, a
-- counter -- which is right for what it is and wrong for where a contest
-- happens. So the lobby stays a lobby, and the performance moved out to
-- its own room where the other coordinators are waiting.
--
-- Both rooms are the town's own materials, and every block is the
-- player's imported cache, never mod art (0.13.0 tried mod art and it did
-- not read as Gen 2 at all).
--
--   GOLDENROD  lobby TILESET_MART -- the Department Store: tiled floor,
--              shelving, a service counter the judge takes entries at.
--              Collision 0x90 is COUNTER: not walkable, but it DOUBLES an
--              A press's reach (Permissions.lua:136-140,
--              World:facingObjectCell gen2/World.lua:7825), and npcAt
--              walks the runtime npc list, so a spawned judge is talked
--              to across it like a clerk.
--              stage TILESET_RADIO_TOWER -- the town's own broadcast
--              studio: equipment banks either side of an open floor, the
--              gap between them the way up to the judge. A televised
--              contest is what Goldenrod would do with one.
--   ECRUTEAK   TILESET_TRADITIONAL_HOUSE, the Dance Theatre: tatami and
--              raised boards. It is a STAGE-shaped room already and has
--              no attendant yet, so it stays one room until the town gets
--              an entrance and a lobby of its own.
--
-- A town with no `stage` runs its contest where the player stands, which
-- is exactly what every version before this one did.
--
-- Geometry for every room is verified offline against BOTH the gold and
-- crystal caches (scratchpad/verify_hall.lua).
local KC_HALLS = {
  GOLDENROD = {
    lobby = {
    id = "KC_JOHTO_CONTEST_HALL",   -- unchanged: the id players' saves know
    label = "GOLDENROD CONTEST HALL",
    tileset = "TILESET_MART",
    song = "GOLDENROD_DEPT_STORE_1F",
    palette = "PALETTE_DAY",
    width = 5, height = 4,          -- 10x8 cells
    arrival = { x = 5, y = 7 },
    --   0x03 back wall   rows 0-1 (top solid, bottom open: the stage)
    --   counter run      row 2 barred but for a gap at each end, row 3 floor
    --   0x04 floor       rows 4-5, where the coordinators queue
    --   0x04 floor       rows 6-7, the entry strip and its services
    -- 0x07 / 0x20 are the left- and right-wall columns the dept store
    -- uses; 0x0D is its counter block (top row counter, floor below).
    blocks = {
      0x03, 0x03, 0x03, 0x03, 0x03,
      0x07, 0x0D, 0x0D, 0x0D, 0x20,
      0x07, 0x04, 0x04, 0x04, 0x20,
      0x07, 0x04, 0x04, 0x04, 0x20,
    },
    actors = {
      -- behind the counter, talked to across it
      { name = "KC_HALL_JUDGE", marker = "kcHallJudge",
        sprite = "SPRITE_GENTLEMAN", x = 4, y = 1, movement = 6 },
      { name = "KC_HALL_VENDOR", marker = "kcHallVendor",
        sprite = "SPRITE_TEACHER", x = 1, y = 7, movement = 9 },
      { name = "KC_HALL_APPRAISER", marker = "kcHallAppraiser",
        sprite = "SPRITE_BEAUTY", x = 8, y = 7, movement = 8 },
      { name = "KC_HALL_EXIT", marker = "kcHallExit",
        sprite = "SPRITE_OLD_LINK_RECEPTIONIST", x = 6, y = 7, movement = 7 },
      -- the coordinator line; (5,5) beside FIONA is the player's place
      { name = "KC_RIVAL_PIPER", marker = "kcRivalPiper",
        sprite = "SPRITE_LASS", x = 2, y = 5, movement = 7 },
      { name = "KC_RIVAL_REX", marker = "kcRivalRex",
        sprite = "SPRITE_YOUNGSTER", x = 3, y = 5, movement = 7 },
      { name = "KC_RIVAL_FIONA", marker = "kcRivalFiona",
        sprite = "SPRITE_COOLTRAINER_F", x = 4, y = 5, movement = 7 },
      { name = "KC_AUD_1", marker = "kcAudience",
        sprite = "SPRITE_POKEFAN_M", x = 1, y = 4, movement = 9 },
      { name = "KC_AUD_2", marker = "kcAudience",
        sprite = "SPRITE_GRANNY", x = 8, y = 4, movement = 8 },
      { name = "KC_AUD_3", marker = "kcAudience",
        sprite = "SPRITE_TWIN", x = 8, y = 6, movement = 8 },
    },
    },
    -- The stage the judge leads you onto. Goldenrod's own Radio Tower
    -- studio: 0x0A equipment banks flank an open centre column, and that
    -- gap is the way up to the judge -- the same "barrier with a way
    -- through" the lobby counter and Ecruteak's stage lip both use.
    stage = {
      id = "KC_JOHTO_CONTEST_STAGE",
      label = "CONTEST STAGE",
      tileset = "TILESET_RADIO_TOWER",
      song = "RADIO_TOWER_1F",
      palette = "PALETTE_DAY",
      width = 5, height = 4,        -- 10x8 cells
      arrival = { x = 5, y = 7 },
      blocks = {
        0x02, 0x02, 0x02, 0x02, 0x02,  -- back wall; cell row 1 is the stage
        0x1F, 0x0A, 0x01, 0x0A, 0x20,  -- equipment banks, open centre
        0x1F, 0x01, 0x01, 0x01, 0x20,  -- the floor you walk up
        0x1F, 0x01, 0x01, 0x01, 0x20,  -- the way in
      },
      actors = {
        -- talk to him here and the contest begins
        { name = "KC_STAGE_JUDGE", marker = "kcStageJudge",
          sprite = "SPRITE_GENTLEMAN", x = 4, y = 1, movement = 6 },
        -- the other coordinators, already on stage and facing it
        { name = "KC_RIVAL_PIPER", marker = "kcRivalPiper",
          sprite = "SPRITE_LASS", x = 2, y = 5, movement = 7 },
        { name = "KC_RIVAL_REX", marker = "kcRivalRex",
          sprite = "SPRITE_YOUNGSTER", x = 3, y = 5, movement = 7 },
        { name = "KC_RIVAL_FIONA", marker = "kcRivalFiona",
          sprite = "SPRITE_COOLTRAINER_F", x = 4, y = 5, movement = 7 },
        { name = "KC_AUD_1", marker = "kcAudience",
          sprite = "SPRITE_POKEFAN_M", x = 1, y = 4, movement = 9 },
        { name = "KC_AUD_2", marker = "kcAudience",
          sprite = "SPRITE_GRANNY", x = 8, y = 4, movement = 8 },
        -- the way back down to the lobby, so the stage is never a trap
        { name = "KC_STAGE_EXIT", marker = "kcStageExit",
          sprite = "SPRITE_OLD_LINK_RECEPTIONIST", x = 8, y = 7, movement = 8 },
      },
    },
  },
  -- Kept whole from 0.13.2 and ready for an Ecruteak attendant; nothing
  -- reaches it yet, which is why the town has no entrance wired. One
  -- room, so a contest there runs where the player stands.
  ECRUTEAK = {
    lobby = {
    id = "KC_ECRUTEAK_CONTEST_HALL",
    label = "ECRUTEAK CONTEST HALL",
    tileset = "TILESET_TRADITIONAL_HOUSE",
    song = "DANCE_THEATER",
    palette = "PALETTE_DAY",
    width = 5, height = 5,          -- 10x10 cells
    arrival = { x = 5, y = 8 },
    blocks = {
      0x2D, 0x2D, 0x2D, 0x2D, 0x2D,  -- back wall
      0x2C, 0x2C, 0x2C, 0x2C, 0x2C,  -- the stage
      0x2E, 0x30, 0x30, 0x30, 0x2F,  -- stage lip; stairs both ends
      0x10, 0x04, 0x04, 0x04, 0x0E,  -- the floor
      0x05, 0x2A, 0x06, 0x07, 0x2B,  -- doorway row
    },
    actors = {
      { name = "KC_HALL_JUDGE", marker = "kcHallJudge",
        sprite = "SPRITE_GENTLEMAN", x = 4, y = 2, movement = 6 },
      { name = "KC_HALL_VENDOR", marker = "kcHallVendor",
        sprite = "SPRITE_TEACHER", x = 1, y = 9, movement = 9 },
      { name = "KC_HALL_APPRAISER", marker = "kcHallAppraiser",
        sprite = "SPRITE_BEAUTY", x = 8, y = 9, movement = 8 },
      { name = "KC_HALL_EXIT", marker = "kcHallExit",
        sprite = "SPRITE_OLD_LINK_RECEPTIONIST", x = 6, y = 9, movement = 7 },
      { name = "KC_RIVAL_PIPER", marker = "kcRivalPiper",
        sprite = "SPRITE_LASS", x = 2, y = 6, movement = 7 },
      { name = "KC_RIVAL_REX", marker = "kcRivalRex",
        sprite = "SPRITE_YOUNGSTER", x = 3, y = 6, movement = 7 },
      { name = "KC_RIVAL_FIONA", marker = "kcRivalFiona",
        sprite = "SPRITE_COOLTRAINER_F", x = 4, y = 6, movement = 7 },
      { name = "KC_AUD_1", marker = "kcAudience",
        sprite = "SPRITE_GRANNY", x = 0, y = 6, movement = 9 },
      { name = "KC_AUD_2", marker = "kcAudience",
        sprite = "SPRITE_POKEFAN_M", x = 9, y = 6, movement = 8 },
      { name = "KC_AUD_3", marker = "kcAudience",
        sprite = "SPRITE_TWIN", x = 2, y = 8, movement = 7 },
      { name = "KC_AUD_4", marker = "kcAudience",
        sprite = "SPRITE_ROCKER", x = 8, y = 7, movement = 7 },
    },
    },
  },
}

local function kcGold(mod, VERSION)
  -- The town this build's attendant leads into.
  local TOWN = "GOLDENROD"
  local HALL_DEF = KC_HALLS[TOWN].lobby
  local STAGE_DEF = KC_HALLS[TOWN].stage      -- nil for a one-room town
  local HALL = HALL_DEF.id
  local HALL_ARRIVAL_X = HALL_DEF.arrival.x
  local HALL_ARRIVAL_Y = HALL_DEF.arrival.y

  -- Every hall in KC_HALLS is registered, whether or not a town has an
  -- attendant leading into it yet: a map costs nothing until it is warped
  -- to, and registering them together keeps the town table the single
  -- place a hall is described.
  --
  -- No tileset registration: mod maps and vanilla maps resolve `tileset`
  -- through the same merged gen2 table the cache populates -- one lookup,
  -- no new mechanism. (In the ROM-free test sandbox those ids are
  -- unresolved references exactly like OPP_GENTLEMAN and CHANSEY; the
  -- KNOWN list in tests/gen_gate_test.lua covers them.)
  local goldData = mod.game and mod.game.data
  local mapSongs = goldData and goldData.audio and goldData.audio.mapSongs
  local ROOMS = {}
  for _, town in pairs(KC_HALLS) do
    if town.lobby then ROOMS[#ROOMS + 1] = town.lobby end
    if town.stage then ROOMS[#ROOMS + 1] = town.stage end
  end
  for _, def in ipairs(ROOMS) do
    mod.content.maps:register(def.id, {
      id = def.id,
      label = def.label,
      generation = 2,
      tileset = def.tileset,
      width = def.width, height = def.height,
      blocks = def.blocks,
      borderBlock = 0,
      palette = def.palette,
      environment = "INDOOR",
      phoneService = false,
      objects = {}, warps = {}, signs = {}, connections = {},
      callbacks = {}, sceneScripts = {}, bgEvents = {}, coordEvents = {},
    })
    -- each hall borrows the music of the room it is dressed as, falling
    -- back to the Goldenrod street theme rather than to silence
    local song = mapSongs
      and (mapSongs[def.song] or mapSongs.GOLDENROD_CITY)
    if song then mod.content.map_songs:register(def.id, song) end
  end
  -- The attendant's spot.
  --
  -- 0.10.0 guessed (14,14) and the first Gold test found her unreachable.
  -- She was standing INSIDE A WALL: resolving that cell through the
  -- player's own imported Gold cache and the engine's Permissions module
  -- gives collision byte 0x07, which `isWalkable` rejects. Nothing
  -- crashes when a runtime object lands in a wall -- the player simply
  -- can never face it, so the talk seam is never reached. That is the
  -- whole "judge is unreachable" report; the talk wiring was fine.
  --
  -- (22,8) is measured, not guessed: walkable, on the main east-west
  -- street, three open sides with a wall to the north so she stands with
  -- her back to a building rather than in the middle of traffic, no
  -- vanilla object on it (Goldenrod has 14, none within a cell of here),
  -- and not a warp tile.
  --
  -- movement is NUMERIC on Gen 2 -- 6 = STANDING_DOWN (Npc.lua's MOVE
  -- table). 0.10.0 passed the Gen 1 string "STAY", which means nothing
  -- here; every vanilla Goldenrod object uses a number (7, 2, 8, 5, ...).
  local KCG = { map = "GOLDENROD_CITY", x = 22, y = 8,
                sprite = "SPRITE_TEACHER", movement = 6 }

  -- Never trust a hardcoded cell again: check it at runtime and, if it is
  -- unusable, walk outward for the nearest cell that is. ALWAYS report the
  -- cell finally used -- a silent fallback is how a mod ends up asserting
  -- a spot that never worked (kanto_rocks shipped an actor one cell off
  -- its designed tile and only the placement log revealed it).
  local function pickCell(world)
    local map = world and world.map
    if not (map and map.isWalkableCell) then return KCG.x, KCG.y, "unchecked" end
    local occupied = {}
    for _, npc in ipairs(world.npcs or {}) do
      if npc.cellX and npc.cellY then
        occupied[npc.cellY * 1000 + npc.cellX] = true
      end
    end
    local function usable(x, y)
      return map:isWalkableCell(x, y) and not occupied[y * 1000 + x]
    end
    if usable(KCG.x, KCG.y) then return KCG.x, KCG.y, "designed" end
    for r = 1, 4 do
      for dy = -r, r do
        for dx = -r, r do
          if math.max(math.abs(dx), math.abs(dy)) == r then
            local x, y = KCG.x + dx, KCG.y + dy
            if usable(x, y) then return x, y, ("fallback r=%d"):format(r) end
          end
        end
      end
    end
    return nil, nil, "no walkable cell within 4"
  end

  -- The judge, as a plain trainer table -- Gold's Battle.new takes
  -- opts.trainer directly (Battle.lua:222, enemyParty from trainer.party
  -- at :254), so no registry is involved. THIS TABLE'S IDENTITY IS THE
  -- CONTEST MARKER: hooks recognise our battle by b.trainer.kcContest,
  -- which no race can miss because we hand the table in ourselves.
  -- trainer.attributes is optional (enemyTrySwitchOrItem returns false
  -- when it is not a table, Battle.lua:3747).
  -- Crystal's native GENTLEMAN front is the direct Gen 2 counterpart to the
  -- Gentleman used for Red's contest judge. It is also Gentleman Preston's
  -- class in Olivine Lighthouse (the trainer with two Growlithe), so the hall
  -- and battle portraits now agree without shipping replacement artwork.
  -- kcContest is rewritten per contest by runGoldContest from the category
  -- the player picked; COOL here is only the value a contest that somehow
  -- started without going through that menu would fall back to.
  local judge = { name = "JUDGE", class = "GENTLEMAN",
                  baseMoney = 0, party = {}, kcContest = "COOL" }

  local function inContest(b)
    return b and b.trainer and b.trainer.kcContest or nil
  end

  -- Gold's battle.damage seam only runs for damaging moves. Status moves
  -- therefore executed their real effects and scored nothing in 0.10.0-
  -- 0.10.2. battle.move_used is observational and cannot suppress an effect;
  -- Battle:useMove is the source-verified funnel for every Gold move, so the
  -- contest arm replaces it just as the Gen 1 arm replaces performMove.
  --
  -- Stash the engine original once and always rebuild from it. Module tables
  -- survive hot reload, so a sentinel-only wrapper would keep old code alive.
  local GoldBattle = require("src.battle.gen2.Battle")
  local GoldBattleUI = require("src.ui.gen2.BattleState")
  local Runtime = require("src.mods.Runtime")
  GoldBattle._kcOriginals = GoldBattle._kcOriginals or {}
  GoldBattle._kcOriginals.useMove = GoldBattle._kcOriginals.useMove
    or GoldBattle.useMove
  GoldBattle._kcOriginals.tryRun = GoldBattle._kcOriginals.tryRun
    or GoldBattle.tryRun
  local vanillaGoldUseMove = GoldBattle._kcOriginals.useMove
  local vanillaGoldTryRun = GoldBattle._kcOriginals.tryRun

  -- Gold's UI is a method table too. Stash each original separately so a
  -- 0.10.3 -> 0.10.4 hot reload can add these wrappers even though the Battle
  -- module already carries its older _kcOriginals table.
  GoldBattleUI._kcOriginals = GoldBattleUI._kcOriginals or {}
  local UIO = GoldBattleUI._kcOriginals
  UIO.new = UIO.new or GoldBattleUI.new
  UIO.statusTag = UIO.statusTag or GoldBattleUI.statusTag
  UIO.genderSymbol = UIO.genderSymbol or GoldBattleUI.genderSymbol
  UIO.chooseMenu = UIO.chooseMenu or GoldBattleUI.chooseMenu

  -- The same Introduction Round Kanto runs after its send-outs. On the real
  -- UI path this is queued by GoldBattleUI.new, after the HUD has captured the
  -- meter's full HP, so the opening head start visibly drains. goldAppeal calls
  -- it as a fallback for headless drivers and any alternate battle screen.
  local function applyGoldIntro(b)
    if not inContest(b) or b.kcIntroDone then return end
    b.kcIntroDone = true
    local entrant, meter = b.player, b.enemy
    if not (entrant and meter) then return end

    local kind = tostring(inContest(b))

    -- The rivals go first, so the player's score lands as the answer.
    -- One emit per page: Gold's battle box wraps to two 18-tile rows and
    -- CUTS the rest (gen2/BattleState.lua:3636-3639 printMessage), and it
    -- has no \f -- the multi-page trick sayPages does on Gen 1 has to be
    -- separate emits here.
    b.kcRivalHearts = kcRollRivalHearts(b.rng)
    b.kcRivalScore, b.kcPlayerScore = {}, 0
    b:emit({ kind = "message", text = "Rival entrants\ntake the stage!" })
    for i, rival in ipairs(KC_RIVALS) do
      b:emit({ kind = "message",
        text = ("%s scores\n%d hearts!"):format(rival.name,
                                                b.kcRivalHearts[i]) })
    end
    b:emit({ kind = "message", text = "Now, your\nentrant..." })

    local hearts = kcIntroHearts(entrant, kind, b.kcRank or "NORMAL")
    b.kcHearts = hearts
    local scarf = KC_SCARF_BY_CATEGORY[kcScarfCategory(entrant)]
    if scarf and scarf.category == kind then
      -- two emits, not one string with \f: battle messages have no pages
      b:emit({ kind = "message",
        text = ("%s\nshines!"):format(scarf.name) })
      b:emit({ kind = "message", text = "The audience\ntakes notice!" })
    end
    if hearts <= 0 then
      b:emit({ kind = "message", text = "The audience is silent..." })
      return
    end

    b:emit({ kind = "message",
             text = "The audience holds up its score..." })
    b:emit({ kind = "message",
             text = ("%d %s!"):format(hearts,
               hearts == 1 and "heart" or "hearts") })
    local maxhp = meter.maxHp or (meter.stats and meter.stats.hp)
                  or meter.hp or 1
    local dmg = math.max(1, math.floor(
      maxhp * KC_INTRO_METER_FRACTION * hearts / 8))
    b:dealDamage(entrant, meter, dmg, { effectiveness = 10 })
  end

  local function goldAppeal(b, attacker, meter, moveId)
    applyGoldIntro(b)
    local move = b:findMove(attacker, moveId)
    local def = b:moveDef(moveId)
    local name = b:monName(attacker)
    if not def then
      b:emit({ kind = "message", text = name .. " has no move to use!" })
      return
    end
    if move and (move.pp or 0) <= 0 then
      b:emit({ kind = "message", text = "No PP left for this move!" })
      return
    end
    if move then move.pp = (move.pp or 1) - 1 end

    -- Preserve Gold's normal move announcement and the public event, but stop
    -- before the move's effect list. Growl cannot lower a stat, Thunder Wave
    -- cannot paralyze, and damaging moves cannot hit on top of their appeal.
    b.moveEvent = b:emit({ kind = "move", side = b:sideOf(attacker),
      move = moveId,
      text = ("%s\nused %s!"):format(name, def.name or moveId) })
    if Runtime.wants("battle.move_used") then
      Runtime.emit("battle.move_used", {
        battle = b, user = attacker, target = meter, move = def,
        moveId = moveId, side = b:sideOf(attacker), isCalled = false,
      })
    end

    local cat = KC_CATEGORY[moveId] or "TOUGH"
    local kind = inContest(b)
    local maxhp = meter.maxHp or (meter.stats and meter.stats.hp)
                  or meter.hp or 1
    b.kcRound = (b.kcRound or 0) + 1
    local dmg
    if cat == kind then
      dmg = math.ceil(maxhp * 0.25)
    elseif KC_OPPOSED[kind] and KC_OPPOSED[kind][cat] then
      dmg = 0
    else
      dmg = math.ceil(maxhp * 0.10)
    end
    -- the same points the rivals earn, for the placement at the end
    b.kcPlayerScore = (b.kcPlayerScore or 0) + kcAppealPoints(cat, kind)

    mod.log:info("contest appeal %d: %s (%s) in %s -> %d of %d",
                 b.kcRound, tostring(moveId), cat, kind, dmg, maxhp)
    if dmg > 0 then
      b:dealDamage(attacker, meter, dmg, {
        effectiveness = 10, move = def, moveId = moveId,
      })
    end
    -- Each emit is one box-fill: the Gold battle box shows TWO 18-tile
    -- rows and CUTS anything past them rather than scrolling
    -- (gen2/BattleState.lua:3636-3639). These three ran to a third
    -- wrapped row -- "is delighted!", "frowns." and the verdict tail were
    -- being cut on device -- so each reaction is now two short emits.
    if cat == kind then
      b:emit({ kind = "message",
               text = ("A perfect\n%s appeal!"):format(kind) })
      b:emit({ kind = "message", text = "The judge is\ndelighted!" })
    elseif dmg == 0 then
      -- dialogue-ok: both %s are contest categories, six glyphs at most
      b:emit({ kind = "message",
               text = ("A %s move in\na %s contest?"):format(cat, kind) })
      b:emit({ kind = "message", text = "The judge frowns." })
    else
      b:emit({ kind = "message", text = "The judge nods\npolitely." })
      b:emit({ kind = "message",
               text = ("A %s move,\nbut it works."):format(cat) })
    end
    if (meter.hp or 0) <= 0 then
      -- Stop before runTurn reaches resolveFaints. That vanilla path would
      -- faint the hidden Chansey, print a trainer defeat and award money.
      -- The captured damage event still animates the APPEAL bar to zero; the
      -- live stand-in is restored to 1 HP as a belt against later sweep calls.
      b.kcMeterComplete = true
      meter.hp = 1
      b:emit({ kind = "message", text = "The APPEAL meter\nis full!" })
      b:emit({ kind = "message", text = "The judge declares\na winner!" })
      b:emit({ kind = "message", text = "You place 1st\nof 4!" })
      b:endBattle("win")
      return
    end

    -- Slice 4: a rival may jam, rounds 2..4, at most twice a contest.
    -- AFTER the win check on purpose -- a jam pressures the rounds you
    -- have left, it never snatches back a meter you just filled.
    local rival = kcJamRoll(b, b.rng)
    if rival then
      local heal = math.ceil(maxhp * KC_JAM_HEAL)
      -- direct write, not dealDamage: heals have no damage event. The bar
      -- redraws from hp next frame; it steps rather than animates, noted
      -- in NOTES.md as cosmetic.
      meter.hp = math.min(maxhp, (meter.hp or 0) + heal)
      b:emit({ kind = "message",
               text = ("%s cuts in\nand jams you!"):format(rival.name) })
      b:emit({ kind = "message",
               text = "The judge's meter\nrecovers a little!" })
    end

    -- A rival takes their turn after yours, rotating. This is the beat
    -- that makes them read as competitors rather than set dressing.
    if b.kcRound < KC_ROUNDS then
      local next_, roll = kcRivalTurn(b, b.rng)
      if next_ then
        b:emit({ kind = "message",
                 text = ("%s appeals\nnext!"):format(next_.name) })
        b:emit({ kind = "message", text = roll.text })
      end
      -- dialogue-ok: both %d are round counts, one digit each
      b:emit({ kind = "message",
               text = ("The judge has seen\n%d of %d appeals."):format(
                 b.kcRound, KC_ROUNDS) })
    end
  end

  GoldBattle.useMove = function(self, attacker, defender, moveId)
    if not inContest(self) then
      return vanillaGoldUseMove(self, attacker, defender, moveId)
    end
    -- Gold forces a dry opponent to Struggle after enemy_action returns nil.
    -- Swallow the meter mon here so the judge is idle in presentation too.
    if attacker ~= self.player then return end
    local ok, err = pcall(goldAppeal, self, attacker, defender, moveId)
    if not ok then
      mod.log:warn("kc gold appeal: %s", tostring(err))
      pcall(function()
        self:emit({ kind = "message", text = "KC error: appeal failed" })
      end)
    end
  end

  -- RUN is withdrawing, never the trainer-battle refusal. This direct funnel
  -- is earlier than battle.run (which Gold only calls after the trainer gate),
  -- so the contest must own tryRun itself.
  GoldBattle.tryRun = function(self, ...)
    if not inContest(self) then return vanillaGoldTryRun(self, ...) end
    -- two-row budget again: the old single line wrapped to three rows and
    -- "disappointed" was cut
    self:emit({ kind = "message", text = "You left the\nstage..." })
    self:emit({ kind = "run",
      text = "The judge looks\ndisappointed." })
    self:endBattle("run")
    return true
  end

  -- Gen 2 contest presentation. The judge asks the engine for Crystal's own
  -- GENTLEMAN class front. The stand-in Chansey remains the appeal meter, but
  -- the native judge portrait owns the enemy picture box for the whole contest.
  GoldBattleUI.new = function(game, opts)
    local state = UIO.new(game, opts)
    local b = state and state.battle
    if not inContest(b) then return state end

    if state.ballRows then state.ballRows.enemy = false end
    state.showEnemyHud = true
    if not state.enemyTrainerImage then
      mod.log:warn("kc gen2 judge art: native GENTLEMAN front missing")
      b:emit({ kind = "message", text = "KC error: native judge art missing" })
    end
    local contestQueue = {}
    for _, ev in ipairs(state.queue or {}) do
      if ev.kind == "message" and type(ev.text) == "string"
          and ev.text:find("wants to battle!", 1, true) then
        ev.text = ("The %s contest is beginning!"):format(inContest(b))
      elseif ev.kind == "trainer-slide" then
        -- A normal trainer front leaves before the opponent is sent out.
        -- There is no opponent here: keep the judge in the picture box.
        ev = nil
      elseif ev.kind == "send" and ev.side == "enemy" then
        -- A contest has no opponent send-out. Turning this into a plain
        -- message keeps the judge portrait in place, skips Chansey's ball
        -- animation and cry, and leaves the APPEAL HUD visible.
        ev.kind, ev.side, ev.mon = "message", nil, nil
        ev.text = "The judge takes his place!"
      elseif ev.kind == "sendout" and b.player then
        ev.text = state:name(b.player) .. " takes the stage!"
      end
      if ev then contestQueue[#contestQueue + 1] = ev end
    end
    state.queue = contestQueue

    local ok, err = pcall(applyGoldIntro, b)
    if not ok then
      mod.log:warn("kc gold intro: %s", tostring(err))
      b:emit({ kind = "message", text = "KC error: intro failed" })
    end
    state:pushAll(b:takeEvents())
    return state
  end

  -- PlaceNonFaintStatus suppresses the level when statusTag returns any
  -- string. A single blank is therefore the narrow, display-only override;
  -- the judge cannot receive a real status because every move is an appeal.
  GoldBattleUI.statusTag = function(self, mon, side)
    if side == "enemy" and inContest(self and self.battle) then return " " end
    return UIO.statusTag(self, mon, side)
  end

  GoldBattleUI.genderSymbol = function(self, mon)
    if inContest(self and self.battle)
        and mon == self:activeMon("enemy") then return nil end
    return UIO.genderSymbol(self, mon)
  end

  local function refuseGoldMenu(state, text)
    state.phase = "resolving"
    state:push({ kind = "message", text = text })
    state:advanceQueue()
    return true
  end

  GoldBattleUI.chooseMenu = function(self, choice)
    if inContest(self and self.battle) and self.phase == "menu" then
      if choice == "party" then
        return refuseGoldMenu(self, "No switching during a contest!")
      elseif choice == "item" then
        return refuseGoldMenu(self, "No items during a contest!")
      end
    end
    return UIO.chooseMenu(self, choice)
  end

  -- Belts around any engine-owned auxiliary path; goldAppeal bypasses both.
  mod.hooks:wrap("battle.accuracy", function(next_, ctx, ...)
    if type(ctx) == "table" and inContest(ctx.battle) then return true end
    return next_(ctx, ...)
  end)

  mod.hooks:wrap("battle.damage", function(next_, c, ...)
    if not (type(c) == "table" and inContest(c.battle)) then
      return next_(c, ...)
    end
    return 0, { effectiveness = 10 }
  end)

  -- THE FIVE-APPEAL LIMIT, at the turn seam. endBattle("run") is the
  -- engine's own clean exit (Battle.lua:384, outcome vocabulary at :231)
  -- -- same "no blackout, no prize" shape as Gen 1's result = "run" --
  -- and turn_ended is the safe moment: the turn's own events are done.
  -- The useMove wrapper above swallows the meter mon's forced Struggle, so
  -- each round contains only the entrant's appeal and the judge's reaction.
  mod.events:on("battle.turn_ended", function(ev)
    local ok, err = pcall(function()
      local b = ev and ev.battle
      if not (b and inContest(b)) then return end
      if b.over then return end
      if (b.kcRound or 0) >= KC_ROUNDS then
        mod.log:info("contest over: %d appeals, meter %d left",
                     b.kcRound, (b.enemy and b.enemy.hp) or -1)
        -- was ONE ~70-char line into a box that cuts after two wrapped
        -- rows: the player saw "The routine is over... The judge" and the
        -- verdict never displayed
        b:emit({ kind = "message", text = "The routine is\nover..." })
        b:emit({ kind = "message", text = "The judge shakes\nhis head." })
        -- where you actually finished against the other three
        -- dialogue-ok: %s is a placement, three glyphs
        b:emit({ kind = "message",
                 text = ("You place %s\nof 4!"):format(kcPlacement(b)) })
        b:endBattle("run")
      end
    end)
    if not ok then mod.log:warn("kc gold limit: %s", tostring(err)) end
  end)

  -- Ask for no enemy move. Gold's dry-mon fallback substitutes STRUGGLE, and
  -- the contest-only useMove wrapper above suppresses that final fallback.
  mod.hooks:wrap("battle.enemy_action", function(next_, battle, ...)
    if inContest(battle) then return nil end
    return next_(battle, ...)
  end)

  -- Runtime actors are the same private-map pattern Hidden Grottos uses:
  -- the map record owns geometry; map.entered repopulates transient people.
  local hallReturn
  local stageReturn
  -- forward: runGoldContest ends by walking the player back off the
  -- stage, and it is defined above the lobby judge that sends them there
  local leaveStage
  local function onStageNow()
    local here = mod.world:current()
    return STAGE_DEF ~= nil and here ~= nil and here.mapId == STAGE_DEF.id
  end
  local entranceCell = { x = KCG.x, y = KCG.y }
  -- The cast for the town this build leads into, from the same table that
  -- describes its room. Movement values are Npc.lua MOVE numerics:
  -- 6/7/8/9 = standing DOWN/UP/LEFT/RIGHT. Every cell and every talk
  -- approach is verified against both caches by
  -- scratchpad/verify_hall.lua before any device round.
  local HALL_ACTORS = HALL_DEF.actors

  -- One page-set each; showText pages on \f in the overworld box (unlike
  -- battle emits). Every row <= 18 glyphs, two rows a page.
  local function talkPiper(world)
    world:showText(
      "I raised my\nPOKeMON on\fSWEET SNACKS.\nCUTE is mine!")
  end
  local function talkRex(world)
    world:showText(
      "Grit. Sweat.\nSOUR SNACKS.\fTOUGH contests\nare true tests!")
  end
  local function talkFiona(world)
    world:showText(
      "My routine is\nflawless.\fBEAUTY is not\nwon. It is worn.")
  end
  -- One cheer covers the whole ring. Reaching most of them means facing
  -- a ledge cell, so much of the audience is scenery in practice.
  local function talkAudience(world)
    world:showText("Go on! Dazzle\nus, newcomer!")
  end

  local function markerExists(world, marker)
    for _, actor in ipairs((world and world.npcs) or {}) do
      if actor.def and actor.def[marker] then return true end
    end
    return false
  end

  local function spawnMarked(mapId, def, marker)
    local actor = {}
    for key, value in pairs(def) do actor[key] = value end
    actor[marker] = true
    local id, err = mod.world:spawnNpc(mapId, actor)
    if not id then
      mod.log:warn("contest actor %s failed: %s",
                   tostring(def.name), tostring(err))
      return false
    end
    return true
  end

  local function ensureGoldenrodAttendant(world)
    if markerExists(world, "kcAttendant") then return end
    local x, y, how = pickCell(world)
    if not x then
      mod.log:warn("contest attendant NOT placed: %s", how)
      return
    end
    entranceCell.x, entranceCell.y = x, y
    local def = {
      name = "KC_GOLDENROD_ATTENDANT",
      sprite = KCG.sprite, x = x, y = y,
      movement = KCG.movement,
    }
    local ok = spawnMarked(KCG.map, def, "kcAttendant")
    mod.log:info("contest attendant at %s %d,%d (%s) placed=%s",
                 KCG.map, x, y, how, tostring(ok))
  end

  local function ensureRoomActors(world, def)
    for _, row in ipairs(def.actors) do
      if not markerExists(world, row.marker) then
        spawnMarked(def.id, row, row.marker)
      end
    end
  end

  -- Set when the judge takes an entry in the lobby and cleared when the
  -- contest actually starts; it is what the stage judge reads to know
  -- which of the five he is about to judge.
  local pendingContest

  mod.events:on("map.entered", function(ev)
    local ok, err = pcall(function()
      local mapId = ev and ev.mapId
      local world = mod.world:overworld()
      if mapId == KCG.map then
        ensureGoldenrodAttendant(world)
      elseif mapId == HALL then
        ensureRoomActors(world, HALL_DEF)
      elseif STAGE_DEF and mapId == STAGE_DEF.id then
        ensureRoomActors(world, STAGE_DEF)
      end
    end)
    if not ok then mod.log:warn("kc gold spawn: %s", tostring(err)) end
  end)

  local function nameOf(game, mon)
    return (mon and mon.nickname)
      or (mon and game.data.pokemon[mon.species]
          and game.data.pokemon[mon.species].name)
      or "POKeMON"
  end

  local function enterHall(world)
    hallReturn = mod.world:current()
    local ok, err = mod.world:warpTo(
      HALL, HALL_ARRIVAL_X, HALL_ARRIVAL_Y, "up")
    if not ok then
      mod.log:warn("contest hall warp failed: %s", tostring(err))
      world:showText("KC error: hall\nentrance failed")
    end
  end

  local function leaveHall(world)
    local target = hallReturn or {
      mapId = KCG.map,
      x = entranceCell.x,
      y = entranceCell.y + 1,
      facing = "down",
    }
    local ok, err = mod.world:warpTo(
      target.mapId, target.x, target.y, target.facing or "down")
    if not ok then
      mod.log:warn("contest hall exit failed: %s", tostring(err))
      world:showText("KC error: hall\nexit failed")
    end
  end

  local function visitHall(world)
    -- Two rows per page. This asked its question across FOUR \n-separated
    -- rows, and only \v and \f wait for a button (TextBox.lua:4-5), so rows
    -- three and four scrolled the first two away unread -- the player saw
    -- "Would you like / to go inside?" over a YES/NO box and never learned
    -- what they were saying yes to.
    -- NESTED, not sequential -- the engine's own ask pattern
    -- (World.lua:5903). askYesNo called on the line after showText finds no
    -- stayed box (that only exists once the last page finishes typing) and
    -- takes its fallback: it pushes a SECOND, instant box holding only the
    -- final page, stacked over the first box while it is still typing. The
    -- player answers on the duplicate, then the original box is revealed
    -- underneath and has to be paged through again -- the 0.11.0 device
    -- report, "not showing full text" and "lines weirdly repeated", is both
    -- halves of this one call shape.
    world:showText(
      "The GOLDENROD\nCONTEST HALL!\fWould you like\nto go inside?",
      function()
        world:askYesNo(function(yes)
          if yes then enterHall(world)
          else world:showText("Come back any\ntime!") end
        end)
      end)
  end

  -- The five contests. Everything downstream of this menu was already
  -- category-generic -- appeal scoring, the opposed-category penalty, the
  -- Introduction Round's hearts, the scarf bonus, every judge reaction -- so
  -- until now the mod computed all five and could only ever be told COOL.
  -- Kanto Ribbons has likewise mapped all five categories since it shipped
  -- the contest resolver; it awards only the ones its catalog has drawn, so
  -- the other four light up there with no change on this side.
  local CONTEST_MENU = {
    top = 1, left = 3, bottom = 14, right = 17,
    dataFlags = 0xc0, cursor = 1,
    items = { "COOL", "BEAUTY", "CUTE", "SMART", "TOUGH", "CANCEL" },
  }

  local function runGoldContest(world, kind)
    local game = world.game
    local Mon = require("src.battle.gen2.Mon")
    local meter = Mon.new(game.data, "CHANSEY", 30)
    if not meter then
      world:showText("KC error: no\nmeter mon")
      return
    end
    meter.nickname = "APPEAL"
    judge.party = { meter }
    -- The contest marker every hook reads. Set per contest rather than once
    -- on the shared judge table, so the category the player chose is the one
    -- scoring, reacting and being recorded.
    judge.kcContest = kind
    world:startBattle({ trainer = judge, save = game.save },
      function(outcome)
        -- Off the stage and back to the lobby afterwards, win or lose:
        -- the routine is over, so standing on an empty stage is not an
        -- ending. Nested in the closing line's callback so the box is
        -- read before the screen moves.
        local function backToLobby()
          if onStageNow() then leaveStage(world) end
        end
        if outcome ~= "win" then
          world:showText("Not quite this\ntime. Practice!", backToLobby)
          return
        end
        -- Battle.playerIndex is firstHealthy, so mirror it when recording
        -- the win on the entrant after the contest screen closes.
        for _, mon in ipairs((game.save and game.save.party) or {}) do
          if not mon.isEgg and (mon.hp or 0) > 0 then
            mon.contestWins = mon.contestWins or {}
            mon.contestWins[kind] = (mon.contestWins[kind] or 0) + 1
            break
          end
        end
        -- dialogue-ok: %s is a contest category, six glyphs at most
        world:showText(("Magnificent!\nTruly %s!"):format(kind), backToLobby)
      end)
  end

  -- The lobby judge TAKES THE ENTRY; he does not judge it here. Once a
  -- category is picked he leads the player out to the stage, where the
  -- other coordinators are already waiting -- 0.14.0 ran the whole contest
  -- in this room, and the room reads as a lobby, which is what it is.
  --
  -- A town with no stage keeps the old behaviour and performs on the spot.
  local function startGoldContest(world)
    world:showText(
      "Welcome to the\nCONTEST HALL!\fWhich contest\nwill you enter?",
      function()
        world:openScriptMenu(CONTEST_MENU, "vertical", function(choice)
          -- 1-based; 0 is B/CANCEL, and CANCEL is the last row.
          local kind = KC_STAT_ORDER[tonumber(choice) or 0]
          if not kind then
            world:showText("Take your time.\nThe stage waits.")
            return
          end
          if not STAGE_DEF then
            runGoldContest(world, kind)
            return
          end
          pendingContest = kind
          -- The walk out is a WARP, not a scene script. Gold scene
          -- scripts that walk the player are what stranded Colosseum
          -- visitors in a void when one stayed armed; nothing here arms
          -- anything that outlives the trip.
          world:showText(
            "Then follow me\nto the stage!",
            function()
              stageReturn = mod.world:current()
              local ok, err = mod.world:warpTo(
                STAGE_DEF.id, STAGE_DEF.arrival.x, STAGE_DEF.arrival.y, "up")
              if not ok then
                pendingContest = nil
                mod.log:warn("contest stage warp failed: %s", tostring(err))
                world:showText("KC error: stage\nentrance failed")
              end
            end)
        end)
      end)
  end

  -- On the stage: the judge who actually runs the contest. The category
  -- was chosen at the lobby counter, so there is no second menu.
  local function stageJudge(world)
    local kind = pendingContest
    if not kind then
      -- wandered in without entering: say so rather than starting
      -- something the player did not ask for
      world:showText("Enter at the desk\ndownstairs first!")
      return
    end
    -- dialogue-ok: %s is a contest category, six glyphs at most
    world:showText(
      ("The %s\nCONTEST!\fTake the stage!"):format(kind),
      function()
        pendingContest = nil
        runGoldContest(world, kind)
      end)
  end

  leaveStage = function(world)
    pendingContest = nil
    local back = stageReturn
      or { mapId = HALL, x = HALL_ARRIVAL_X, y = HALL_ARRIVAL_Y }
    local ok, err = mod.world:warpTo(
      back.mapId, back.x, back.y, back.facing or "up")
    if not ok then
      mod.log:warn("contest stage exit failed: %s", tostring(err))
      world:showText("KC error: stage\nexit failed")
    end
  end

  local SNACK_MENU = {
    top = 1, left = 3, bottom = 14, right = 17,
    dataFlags = 0xc0, cursor = 1,
    items = { "SPICY  500", "DRY    500", "SWEET  500",
              "BITTER 500", "SOUR   500", "CANCEL" },
  }

  local function feedSnack(world, snack)
    local game, save = world.game, world.game and world.game.save
    local player = save and save.player
    if not (game and save and player) then
      world:showText("KC error: no\ntrainer data")
      return
    end
    if (player.money or 0) < KC_SNACK_PRICE then
      world:showText("You don't have\nenough money.")
      return
    end
    world:selectPartyMon("Choose a POKeMON.", function(_, mon)
      if not mon then return end
      if mon.isEgg then
        world:showText("An EGG can't eat\na POKeSNACK.")
        return
      end
      if kcSheen(mon) >= 100 then
        world:showText(("%s has had\nplenty!\fAny more would\nbe wasted.")
          :format(nameOf(game, mon)))
        return
      end
      player.money = math.max(0, (player.money or 0) - KC_SNACK_PRICE)
      local cond = kcCondition(mon)
      local key = KC_STAT_KEY[snack.category]
      cond[key] = math.min(100, cond[key] + KC_SNACK_CONDITION)
      mon.kcSheen = math.min(100, kcSheen(mon) + KC_SNACK_SHEEN)
      -- dialogue-ok: the last %s is a contest category, six glyphs at most
      world:showText(("%s ate the\n%s!\fIts %s rose!")
        :format(nameOf(game, mon), snack.name, snack.category))
    end)
  end

  local function offerSnack(world, snack)
    -- nested for the same reason as visitHall above
    world:showText(("A %s\ncosts %d.\fFeed it now?")
      :format(snack.name, KC_SNACK_PRICE), function()
        world:askYesNo(function(yes)
          if yes then feedSnack(world, snack) end
        end)
      end)
  end

  local function openSnackVendor(world)
    world:showText(
      "POKeSNACKS!\nFive flavors.\fThey raise contest\ncondition.",
      function()
        world:openScriptMenu(SNACK_MENU, "vertical", function(choice)
          local snack = KC_SNACKS[tonumber(choice) or 0]
          if snack then offerSnack(world, snack) end
        end)
      end)
  end

  local function appraiseGold(world)
    local game = world.game
    world:showText("I can read contest\ncondition.\fWhich POKeMON?", function()
      world:selectPartyMon("Choose a POKeMON.", function(_, mon)
        if not mon then return end
        if mon.isEgg then
          world:showText("An EGG has no\ncontest condition.")
          return
        end
        local cond = kcCondition(mon)
        local pages = { ("%s, is it?\nLet me look..."):format(nameOf(game, mon)) }
        local rows = {}
        for _, cat in ipairs(KC_STAT_ORDER) do
          rows[#rows + 1] = ("%s: %s"):format(cat,
            kcBand(KC_TIERS, cond[KC_STAT_KEY[cat]]).word)
          if #rows == 2 then
            pages[#pages + 1] = table.concat(rows, "\n")
            rows = {}
          end
        end
        if #rows > 0 then pages[#pages + 1] = table.concat(rows, "\n") end
        pages[#pages + 1] =
          kcBand(KC_SHEEN_LINES, kcSheen(mon)).text
        local worn = KC_SCARF_BY_CATEGORY[kcScarfCategory(mon)]
        if worn then
          pages[#pages + 1] = ("It is wearing a\n%s."):format(worn.name)
        end
        local earned = kcEligibleScarf(game.save, mon)
        if earned then
          local ok, _, why = mod.exports.giveScarf(game.save, earned.category)
          if ok and why == "given" then
            pages[#pages + 1] = ("You earned the\n%s!"):format(earned.name)
            pages[#pages + 1] = "Give it to a\nPOKeMON to wear."
          elseif not ok then
            pages[#pages + 1] = ("A %s is\nyours..."):format(earned.name)
            pages[#pages + 1] = "But your PACK is\nfull. Come back!"
          end
        end
        world:showText(table.concat(pages, "\f"))
      end)
    end)
  end

  -- World:interactBody asks this facade's talkTo after resolving an NPC.
  -- Own only the four marker fields above and chain every other actor.
  local OW = require("src.world.OverworldController")
  OW._kcOriginals = OW._kcOriginals or { talkTo = OW.talkTo }
  local baseTalk = OW._kcOriginals.talkTo
  OW.talkTo = function(world, npc)
    local def = npc and npc.def
    local handler = def and (
      (def.kcAttendant and visitHall)
      or (def.kcHallJudge and startGoldContest)
      or (def.kcHallVendor and openSnackVendor)
      or (def.kcHallAppraiser and appraiseGold)
      or (def.kcHallExit and leaveHall)
      or (def.kcStageJudge and stageJudge)
      or (def.kcStageExit and leaveStage)
      or (def.kcRivalPiper and talkPiper)
      or (def.kcRivalRex and talkRex)
      or (def.kcRivalFiona and talkFiona)
      or (def.kcAudience and talkAudience)
    )
    if not handler then
      if baseTalk then return baseTalk(world, npc) end
      return nil
    end
    local ok, err = pcall(handler, world)
    if not ok then
      mod.log:warn("kc gold talk: %s", tostring(err))
      pcall(function() world:showText("KC error: hall\ninteraction failed") end)
    end
    return true
  end

  -- Gold banner: the Gen 1 say() is a TextBox this boot never loads, so
  -- the world's own text box is the channel.
  local bannerShown = false
  mod.events:on("map.entered", function()
    if bannerShown then return end
    if not mod.options:get("show_banner") then return end
    bannerShown = true
    pcall(function()
      local world = mod.world:overworld()
      if world and world.showText then
        world:showText(("KANTO CONTESTS\nv%s ALPHA\fJOHTO preview"):format(VERSION))
      end
    end)
  end)

  mod.log:info("kanto_contests %s loaded (gen 2 arm)", VERSION)
end

return function(mod)
  local VERSION = "0.15.0"
  mod.exports.version = VERSION
  mod.exports.owns = {
    trainers = { "OPP_KC_JUDGE" },
    maps = { "KC_CONTEST_HALL", "KC_JOHTO_CONTEST_HALL",
             "KC_ECRUTEAK_CONTEST_HALL" },
    -- KC_JOHTO_HALL_TILES retired in 0.13.1: the Johto hall reads the
    -- vanilla TILESET_TRADITIONAL_HOUSE (borrowed, never owned)
    tilesets = { "KC_HALL_TILES" },
    items = { "KC_SPICY_SNACK", "KC_DRY_SNACK", "KC_SWEET_SNACK",
              "KC_BITTER_SNACK", "KC_SOUR_SNACK", "KC_RED_SCARF",
              "KC_BLUE_SCARF", "KC_PINK_SCARF", "KC_GREEN_SCARF",
              "KC_YELLOW_SCARF" },
    -- mon fields this mod writes; a decorator may read them, not write them
    monFields = { "contest", "kcSheen", "kcScarf", "contestWins" },
    commands = { "kanto_contests:start_contest", "kanto_contests:base_talk",
                 "kanto_contests:ribbons_missing", "kanto_contests:snack_mart",
                 "kanto_contests:appraise" },
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

  -- shared read-only exports, meaningful on both generations
  mod.exports.categories = KC_CATEGORY
  mod.exports.opposed = KC_OPPOSED
  mod.exports.snacks = {}
  for _, s in ipairs(KC_SNACKS) do mod.exports.snacks[s.category] = s.id end
  mod.exports.scarves = {}
  for _, s in ipairs(KC_SCARVES) do mod.exports.scarves[s.category] = s.id end
  mod.exports.wornScarf = kcScarfCategory
  mod.exports.readCondition = function(mon)
    return kcCondition(mon), kcSheen(mon)
  end

  local Bag = require("src.inventory.Bag")
  mod.exports.giveScarf = function(save, category)
    local row = KC_SCARF_BY_CATEGORY[tostring(category or ""):upper()]
    if not (save and row) then return false, nil, "bad_category" end
    save.inventory = save.inventory or {}
    if kcHasScarf(save, row) then return true, row.id, "owned" end
    local data = mod.game and mod.game.data
    if not Bag.add(save, row.id, 1, data) then
      return false, row.id, "bag_full"
    end
    return true, row.id, "given"
  end

  -- Shared item records: Crystal treats them as ordinary holdable ITEM-pocket
  -- accessories; Gen 1's field-use wrapper below supplies its equip action.
  for _, row in ipairs(KC_SCARVES) do
    mod.content.items:register(row.id, {
      id = row.id, name = row.name, price = 0, tossable = true,
      needsTarget = true,
    })
  end

  -- No EXP from a contest, on either generation: both engines raise
  -- battle.exp_award with the battle in ctx. Gen 1 marks the battle with
  -- b.contest, the Gold arm marks it through the judge trainer table --
  -- accept both spellings. (Gen 1 additionally guards awardExp itself,
  -- below, because another mod owning this chain already bypassed the
  -- hook once -- see the 0.7.2 CHANGELOG.)
  mod.hooks:wrap("battle.exp_award", function(next_, ctx, ...)
    local b = type(ctx) == "table" and ctx.battle
    if b and (b.contest or (b.trainer and b.trainer.kcContest)) then return end
    return next_(ctx, ...)
  end)

  -- THE GENERATION BRANCH. Everything below this point is Gen 1 code:
  -- registrations into Gen 1 data tables, requires of Gen 1 modules,
  -- wrappers on classes a Gold boot never instantiates. On Gold, an
  -- executed require for an unserved Gen 1 module is a loader ERROR, so
  -- the branch must come before the first one runs.
  local GameVersion = require("src.core.GameVersion")
  if GameVersion.generation() >= 2 then
    return kcGold(mod, VERSION)
  end

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
    -- Sprites all verified present in BOTH tools/rom_manifest.json and
    -- rom_manifest_yellow.json -- an unknown sprite id purges the whole
    -- mod silently. The two new NPCs stand on the floor row (block value
    -- 1) either side of the entrance, leaving the middle column clear so
    -- the walk from the warp to the judge is never blocked.
    objects = {
      { index = 1, name = "KC_JUDGE",
        sprite = "SPRITE_GENTLEMAN",
        x = 3, y = 2,
        movement = "STAY", range = "DOWN",
        text = "TEXT_KC_JUDGE" },
      { index = 2, name = "KC_VENDOR",
        sprite = "SPRITE_CLERK",
        x = 2, y = 4,
        movement = "STAY", range = "RIGHT",
        text = "TEXT_KC_VENDOR" },
      { index = 3, name = "KC_APPRAISER",
        sprite = "SPRITE_BEAUTY",
        x = 5, y = 4,
        movement = "STAY", range = "LEFT",
        text = "TEXT_KC_APPRAISER" },
      -- Slice 4's rival coordinators, waiting their turn. Sprites verified
      -- in BOTH rom_manifest.json and rom_manifest_yellow.json (Gen 1 has
      -- no SPRITE_LASS; SPRITE_GIRL is the counterpart the Gold arm's LASS
      -- maps to). The warp from Celadon lands the player at (4,5), so the
      -- rivals keep that cell and the middle walk to the judge clear.
      { index = 4, name = "KC_RIVAL_PIPER",
        sprite = "SPRITE_GIRL",
        x = 2, y = 5,
        movement = "STAY", range = "RIGHT",
        text = "TEXT_KC_RIVAL_PIPER" },
      { index = 5, name = "KC_RIVAL_REX",
        sprite = "SPRITE_YOUNGSTER",
        x = 5, y = 5,
        movement = "STAY", range = "LEFT",
        text = "TEXT_KC_RIVAL_REX" },
      { index = 6, name = "KC_RIVAL_FIONA",
        sprite = "SPRITE_COOLTRAINER_F",
        x = 5, y = 6,
        movement = "STAY", range = "LEFT",
        text = "TEXT_KC_RIVAL_FIONA" },
    },
  })

  -- ------------------------------------------------------------------
  -- THE SNACK ITEMS, and why they are not wired the documented way.
  --
  -- mod.content.item_effects EXISTS and validates (Schemas.lua:750,
  -- fields use/needsTarget/battle/field) -- but NOTHING IN THE ENGINE
  -- READS IT. Searched all of 0.1.75: the only references to
  -- `item_effects` anywhere are that schema entry and a test asserting
  -- the record merges into data.item_effects. ItemEffects.use never
  -- consults it, no UI does, and there is no item-use hook in the entire
  -- hook list. A snack registered as an item_effect would sit in the bag
  -- and silently do nothing. Same story for the items schema's own
  -- `needsTarget` field: ItemEffects.needsTarget (ItemEffects.lua:75) is
  -- a hardcoded id list and only ever reads `itemDef.machine`.
  --
  -- So the two functions are replaced instead, stash-originals like every
  -- other engine wrapper here. Both are plain module-table entries and
  -- BagMenu calls them as `ItemEffects.use(...)` / `ItemEffects.needsTarget(...)`
  -- -- runtime table lookups (BagMenu.lua:50, :407), so a replacement is
  -- seen. Deliberately NOT also registering item_effects records: if a
  -- later engine wires that registry up, both paths would fire and the
  -- snack would apply twice.
  --
  -- use() returns (result, messages): "consumed" makes BagMenu decrement
  -- the item and page the messages, "failed" prints without consuming
  -- (BagMenu.lua:256 and the contract at ItemEffects.lua:5-11).
  -- ------------------------------------------------------------------
  for _, s in ipairs(KC_SNACKS) do
    mod.content.items:register(s.id, {
      id = s.id, name = s.name, price = KC_SNACK_PRICE, tossable = true,
      -- no `effect`: it would point at the dead registry. no `index`:
      -- optional in the schema, and SNAG_BALL ships without one.
    })
  end

  local ItemEffectsM = require("src.inventory.ItemEffects")
  ItemEffectsM._kcOriginals = ItemEffectsM._kcOriginals or {}
  local IO_ = ItemEffectsM._kcOriginals
  for _, fn in ipairs({ "use", "needsTarget" }) do
    IO_[fn] = IO_[fn] or ItemEffectsM[fn]
  end

  -- Without this the bag would use a snack on nobody: needsTarget is what
  -- makes BagMenu open the party picker first.
  ItemEffectsM.needsTarget = function(id, itemDef)
    if KC_SNACK_BY_ID[id] or KC_SCARF_BY_ID[id] then return true end
    return IO_.needsTarget(id, itemDef)
  end

  ItemEffectsM.use = function(data, save, itemId, target, battle, moveIndex, ow)
    local snack = KC_SNACK_BY_ID[itemId]
    local scarf = KC_SCARF_BY_ID[itemId]
    if not snack and not scarf then
      return IO_.use(data, save, itemId, target, battle, moveIndex, ow)
    end
    if scarf then
      if battle then return "failed", { "Not during a\ncontest!" } end
      if not target then return "failed", { "Wear it on which\nPOKeMON?" } end
      local name = target.nickname
                   or (data.pokemon[target.species]
                       and data.pokemon[target.species].name)
                   or "POKeMON"
      if kcScarfCategory(target) == scarf.category then
        return "kept", { ("%s already\nwears that scarf."):format(name) }
      end
      target.kcScarf = scarf.category
      return "kept", {
        ("%s put on\n%s!"):format(name, scarf.name),
        -- dialogue-ok: %s is a contest category, six glyphs at most
        ("It adds flair to\n%s contests!"):format(scarf.category),
      }
    end
    local ok, result, messages = pcall(function()
      -- Snacks are a field item. Refusing in battle matches how the
      -- engine treats vitamins and stones (ItemEffects.lua:153-158).
      if battle then
        return "failed", { "Not now! There's\na contest on!" }
      end
      if not target then
        return "failed", { "Feed it to which\nPOKeMON?" }
      end
      local name = target.nickname
                   or (data.pokemon[target.species] and data.pokemon[target.species].name)
                   or "POKeMON"
      if kcSheen(target) >= 100 then
        -- "too sheeny" was the internal name leaking out; nothing in the
        -- game ever tells the player a number called sheen exists. Say
        -- what is actually true instead: this one has had its fill, for
        -- good.
        return "failed", { ("%s has had\nplenty!"):format(name),
                           "Any more would\nbe wasted." }
      end
      local cond = kcCondition(target)
      local key = KC_STAT_KEY[snack.category]
      cond[key] = math.min(100, cond[key] + KC_SNACK_CONDITION)
      target.kcSheen = math.min(100, kcSheen(target) + KC_SNACK_SHEEN)
      -- Line budget is 18 glyphs and BOTH substitutions are long: a
      -- nickname is up to 10 and "BITTER SNACK" is 12, so name and snack
      -- can never share a line, and the second page drops the name
      -- entirely (it is on the page before).
      return "consumed", {
        -- "the" moved DOWN a line: ending line 1 with "the" and opening
        -- line 2 with the snack name rendered close enough to read as
        -- one word on device ("ate theSPICY..."). Worst case now is
        -- "the BITTER SNACK!" = 17 glyphs, inside the 18 budget.
        ("%s ate\nthe %s!"):format(name, snack.name),
        ("Its %s rose!"):format(snack.category),
      }
    end)
    if not ok then
      say("KC error (snack):\n" .. tostring(result))
      return "failed", { "Nothing happened." }
    end
    return result, messages
  end

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
          -- battle messages split on [\n\v] only, so a third row here would
          -- scroll unread and \f is not available to page it
          battle:sayNext(("That was appeal\n%d of %d."):format(n, KC_ROUNDS))
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
        -- enemyHidden only. Up to 0.7.5 this also pinned
        -- showEnemyTrainer = true "for anything else that reads it" --
        -- and something else DOES read it: WideBattle's file-local
        -- drawHUDs draws the enemy status panel only `if not
        -- battle.showEnemyTrainer` (WideBattle.lua:131), and unlike the
        -- classic path there is no mod wrapper in between to flip it
        -- back, because file-locals are unreachable from a mod. So the
        -- pinned flag erased the appeal meter in the wide layout.
        -- The judge does not need it pinned: the drawPicsLayer wrapper
        -- sets it for the duration of each draw on BOTH layouts (wide
        -- calls drawPicsLayer through the method table,
        -- WideBattle.lua:343-345). Wide now shows judge + meter, with
        -- the classic-only polish (APPEAL label row, hidden level, no
        -- HP:) simply absent there.
        b.enemyHidden = true
      end)
      -- THE INTRODUCTION ROUND, as its own queued act so it plays after
      -- the whole intro (this act is appended behind the send-out rows
      -- the same way the flag act above is). Rows queued from INSIDE a
      -- running act insert at nextInsert in call order -- the exact
      -- pattern kcAppeal already relies on -- so the announcement pages
      -- land first and the meter drain follows them.
      b:act(function()
        local okI, errI = pcall(function()
          local mon = b.player and b.player.mon
          local target = b.enemy
          if not (mon and target and target.mon) then return end
          -- Slice 4: the rivals present first, so the player's score
          -- lands as the answer. sayNext pages via sayPages, so \f is
          -- fine here (unlike the Gold arm's raw emits).
          b.kcRivalHearts = kcRollRivalHearts(b.rng)
          b.kcRivalScore, b.kcPlayerScore = {}, 0
          b:sayNext("Rival entrants\ntake the stage!")
          for i, rival in ipairs(KC_RIVALS) do
            b:sayNext(("%s scores\n%d hearts!"):format(rival.name,
                                                       b.kcRivalHearts[i]))
          end
          b:sayNext("Now, your\nentrant...")

          local hearts = kcIntroHearts(mon, tostring(b.contest),
                                       b.kcRank or "NORMAL")
          b.kcHearts = hearts   -- announced against the rivals' scores above
          local scarf = KC_SCARF_BY_CATEGORY[kcScarfCategory(mon)]
          if scarf and scarf.category == tostring(b.contest) then
            b:sayNext(("%s\nshines!\fThe audience\ntakes notice!"):format(scarf.name))
          end
          if hearts <= 0 then
            -- no drain: silence IS the zero-hearts result, and the bar
            -- not moving is the visual confirmation
            b:sayNext("The audience is\nsilent...")
            return
          end
          b:sayNext("The audience holds\nup its score...")
          -- the number gets its own WAITING page (sayNext, not auto) --
          -- v0.4's lesson: information on a fast page is never read
          b:sayNext(("%d %s!"):format(hearts,
                                      hearts == 1 and "heart" or "hearts"))
          -- through the engine's own damage call so the bar visibly
          -- drains, same as every appeal; never set HP silently
          local maxhp = (target.mon.stats and target.mon.stats.hp)
                        or target.mon.hp
          local dmg = math.max(1, math.floor(
            maxhp * KC_INTRO_METER_FRACTION * hearts / 8))
          b:applyDamage(target, dmg)
        end)
        if not okI then say("KC error (intro):\n" .. tostring(errI)) end
      end)
    end)
    if not ok then say("KC error (start):\n" .. tostring(err)) end
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
  -- Stashed per KEY rather than as one table literal. A table literal
  -- behind `or` is only built the FIRST time this mod loads in a process,
  -- so a version that adds a new entry (0.7.2 adding awardExp) would find
  -- the older version's table already present and read nil for it -- the
  -- same staleness the sentinel pattern causes, one level down. Per-key
  -- `or` backfills the new entries and never re-stashes an existing one.
  BattleStateM._kcOriginals = BattleStateM._kcOriginals or {}
  local O = BattleStateM._kcOriginals
  for _, fn in ipairs({ "drawHUDs", "drawPicsLayer", "drawTextArea", "say",
                        "sayNext", "performMove", "openParty", "openItems",
                        "tryRun", "awardExp" }) do
    O[fn] = O[fn] or BattleStateM[fn]
  end
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
  -- ONLY 0x71 ("HP") is dropped. 0x62 is ":[" -- a colon AND the bar's
  -- left cap in one tile -- so suppressing it too (0.5.0-0.7.1) left the
  -- meter open-ended, which is invisible while there is fill to terminate
  -- the line and obvious the moment it drains to empty. The two glyphs
  -- can't be separated without editing the sheet, and the sheet is
  -- ROM-extracted at build time, so it isn't in the repo to edit. Keeping
  -- the cap costs a small ":" where the label was; that is exactly how
  -- vanilla renders during move-select, where the TYPE box covers "HP"
  -- and leaves ":[" showing.
  local kcHideMeterLabel = false
  HudTilesM.tile = function(code, x, y, tint)
    if kcHideMeterLabel and code == 0x71 and x == 16 and y == 16 then
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
    if drew then
      pcall(function()
        -- Wipe the colon but keep the cap. 0x62 is ":[" drawn at x=24:
        -- "HP:[" runs H,P in 0x71 then ':' and '[' in 0x62, so the colon
        -- owns the tile's left half and the bar's left cap the right.
        -- 0.7.2 kept the whole tile to close the meter and the stray ':'
        -- was more than the label removal was worth; painting over the
        -- left 4px drops it and leaves the cap hard against the bar.
        -- (If the cap ever looks nicked, this width is the dial -- the
        -- glyph sheet is ROM-extracted at build time, so the exact split
        -- cannot be read from the repo.)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 24, 16, 4, 8)
        if wasName and wasName ~= "" then
          love.graphics.setColor(0, 0, 0, 1)
          Font.draw(wasName, kcNameX(1, wasName), 8)
        end
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
      -- No longer promises a ribbon "in a future update" -- 0.7.0 made
      -- ribbons real, and the judge announces one himself right after
      -- this line when Kanto Ribbons is installed. Two mentions would be
      -- redundant and the old one was actively wrong, so the prize line
      -- sticks to the prize.
      return "A fine " .. kind .. "\nperformance!"
             .. "\fEnjoy the prize\nmoney!"
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
      -- "A fair appeal" read as a verdict on quality rather than as the
      -- middle rung of a ladder, so it was impossible to tell whether it
      -- meant "fine" or "poor". Naming the move's category and saying it
      -- still works makes the three outcomes legible from the text alone:
      -- delighted (match) > nods politely (off-category) > frowns
      -- (opposed, and scores nothing).
      react = "The judge nods\npolitely.\fA " .. cat .. " move,\nbut it works."
    end
    if dmg > 0 then self:applyDamage(target, dmg) end
    self:sayNext(react)
    -- round bookkeeping + endings
    self.kcPlayerScore = (self.kcPlayerScore or 0) + kcAppealPoints(cat, kind)
    self.kcRound = (self.kcRound or 0) + 1
    if target.mon.hp <= 0 then
      self:sayNext("You place 1st\nof 4!")
      self:onFaint(target)   -- vanilla victory path; texts already rewritten
      return
    end
    -- Slice 4: a rival may jam, rounds 2..4, at most twice a contest.
    -- After the win check on purpose: a jam pressures the rounds left,
    -- it never snatches back a meter that just filled. Direct hp write --
    -- applyDamage is damage-only -- so the bar steps rather than
    -- animates; cosmetic, noted in NOTES.md.
    local rival = kcJamRoll(self, self.rng)
    if rival then
      local heal = math.ceil(maxhp * KC_JAM_HEAL)
      target.mon.hp = math.min(maxhp, (target.mon.hp or 0) + heal)
      self:sayNext(("%s cuts in\nand jams you!\fThe judge's meter\nrecovers a little!")
        :format(rival.name))
    end
    if self.kcRound < KC_ROUNDS then
      -- a rival's own turn, rotating: the beat that makes them read as
      -- competitors rather than set dressing
      local next_, roll = kcRivalTurn(self, self.rng)
      if next_ then
        self:sayNext(("%s appeals\nnext!\f%s"):format(next_.name, roll.text))
      end
    else
      self:sayNext("The routine is\nover...")
      self:sayNext("The judge shakes\nhis head.")
      -- dialogue-ok: %s is a placement, three glyphs
      self:sayNext(("You place %s\nof 4!"):format(kcPlacement(self)))
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
  -- 5. No EXP from a contest. The battle.exp_award hook is registered
  -- once, in the shared section above the generation branch (both
  -- engines raise it with the battle in ctx). What follows is the Gen 1
  -- belt on top of that hook. The hook above demonstrably
  -- worked on device in 0.5.0 ("No EXP for winning" confirmed) and just as
  -- demonstrably did not in 0.7.1 (1638 EXP, screenshotted), with nothing
  -- between those versions touching it. I could not reproduce or explain
  -- that from the source, so this second guard deliberately does not
  -- depend on the explanation being right.
  --
  -- awardExp is the single funnel: both callers reach EXP through it
  -- (BattleState.lua:3873 the faint/victory path, :4460 the catch path),
  -- and the hook lives INSIDE it. Replacing the method covers every way
  -- the inner hook chain could be bypassed -- another mod wrapping
  -- exp_award at a higher priority and not calling next, the chain being
  -- rebuilt, or an engine build where that call site differs.
  --
  -- If EXP still appears after this, that is genuinely informative: it
  -- means something is granting it OUTSIDE awardExp entirely, which is a
  -- different mod, not this one.
  BattleStateM.awardExp = function(self)
    if self.contest then
      self.participants = {}   -- what vanilla clears on its way out
      return
    end
    return O.awardExp(self)
  end

  -- ------------------------------------------------------------------
  -- commands
  -- ------------------------------------------------------------------
  -- choose_contest: which of the five the player is entering.
  --
  -- The five-way choice is a real list, not a chain of yes/no prompts. The
  -- developer's own report on the snack vendor was that stepping past items
  -- one prompt at a time is "weird" and that seeing them at a glance is the
  -- fix; the same applies here, and even more so, because a player refusing
  -- COOL to reach TOUGH would answer NO four times.
  --
  -- Sets lastCheck so the script's jump_if_false is the cancel arm, and
  -- leaves the answer in `chosenContest` for start_contest to read: the VM
  -- passes literal arguments only, so there is no way to hand a runtime
  -- answer to the next command except a shared upvalue.
  local chosenContest
  mod.content.commands:register("kanto_contests:choose_contest", {
    foreground = true,
    fn = function(ctx)
      local runner = ctx.runner
      local Screens = require("src.ui.Screens")
      local items = {}
      for _, cat in ipairs(KC_STAT_ORDER) do
        items[#items + 1] = { label = cat, value = cat }
      end
      chosenContest = nil
      -- Screens.push forwards its varargs to the screen's new()
      -- (Screens.lua:184-188), so this is ListMenu.new(game, title, items,
      -- opts) -- the same generic list the bag and shop use
      -- (src/ui/ListMenu.lua:63).
      Screens.push(ctx.game, "ListMenu", "CONTEST", items, {
        -- ASYMMETRIC ON PURPOSE, and it is the engine's asymmetry, not a
        -- slip: ListMenu's B/empty paths pop themselves before calling
        -- onCancel (ListMenu.lua:196, 218), while the A path calls onChoose
        -- and leaves the screen standing (:223). Popping in both arms would
        -- take the overworld off the stack behind the menu.
        onChoose = function(item)
          chosenContest = item and item.value
          ctx.game.stack:pop()
          runner:resume()
        end,
        onCancel = function() runner:resume() end,
      })
      -- Screens.push does not yield; the appraiser's picker needs the same
      -- explicit pair.
      runner:yield()
      ctx.lastCheck = chosenContest ~= nil
    end,
  })

  -- judge_line: the judge's category-aware lines.
  --
  -- The script VM passes LITERAL arguments, so a `show_text` row cannot
  -- interpolate the category the player just picked -- which is exactly how
  -- the COOL-only wording got baked into five separate rows of this script.
  -- Composing them here keeps the judge saying the contest actually being
  -- judged, and keeps the stale-dialogue failure from coming straight back
  -- the next time a category is added.
  --
  -- Widths are worst case at BEAUTY, the longest of the five:
  -- "BEAUTY enough yet." is exactly 18.
  mod.content.commands:register("kanto_contests:judge_line", {
    foreground = true,
    fn = function(ctx, key)
      local cat = chosenContest or "COOL"
      local lines = {
        -- dialogue-ok: %s is a contest category, six glyphs at most
        won = ("Magnificent!\nTruly %s!\fA %s RIBBON\nfor your POKeMON!")
          :format(cat, cat),
        -- dialogue-ok: %s is a contest category, six glyphs at most
        won_plain = ("Magnificent!\nTruly %s!\fA fine %s\nperformance!")
          :format(cat, cat),
        -- dialogue-ok: %s is a contest category, six glyphs at most
        lost_plain = ("Hmm. Not quite\n%s enough yet.\fKeep practicing!")
          :format(cat),
      }
      -- required here, not through the file-scope `Commands` local: that one
      -- is declared further down, so at this point in the chunk the name
      -- would resolve to a nil global and only fail when the judge speaks.
      require("src.script.Commands").show_text(ctx, lines[key] or "")
    end,
  })

  -- start_contest: Commands.start_battle's confirmed body, plus
  -- battle.contest set before the push so every later hook can key off it.
  -- With no argument it runs the category chosen by choose_contest.
  mod.content.commands:register("kanto_contests:start_contest", {
    foreground = true,
    fn = function(ctx, contestType)
      contestType = contestType or chosenContest
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

      -- The entrant, captured now rather than at onFinish: this is the
      -- mon that walked on stage, and "one POKeMON, one routine" (2c
      -- above) means it is still the performer at the end -- PkMn is
      -- refused all contest long. makeBattler stores `mon = mon` by
      -- REFERENCE (BattleState.lua:458-459) and newTrainer sources it
      -- from Party.firstHealthy(game.save.party) (BattleState.lua:709),
      -- so this IS the live save party entry. Writing to it persists
      -- with the save -- confirmed by reading both, not assumed.
      local entrant = battle.player and battle.player.mon

      battle.onFinish = function(result)
        ctx.lastBattleResult = result
        ctx.lastCheck = result == "win"
        -- Record the win ON THE MON, keyed by category. Per-mon rather
        -- than in mod.save so it survives boxing, evolution and trading
        -- (the same reason kanto_ribbons keeps mon.earthWins there), and
        -- counted per category so a future per-category ribbon or rank
        -- needs no save migration.
        --
        -- This is the whole cross-mod contract with Kanto Ribbons: it
        -- reads mon.contestWins and awards the Contest Ribbon on its own
        -- next sync. No hard dependency either way -- with the ribbons
        -- mod absent this is just an unread field, and a ribbon already
        -- earned survives this mod being uninstalled.
        if result == "win" and entrant then
          local cat = tostring(battle.contest or "COOL")
          entrant.contestWins = entrant.contestWins or {}
          entrant.contestWins[cat] = (entrant.contestWins[cat] or 0) + 1
        end
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

  -- ribbons_missing: is Kanto Ribbons ABSENT? Sets lastCheck for
  -- jump_if_true, the same channel start_contest uses. Not foreground --
  -- it neither draws nor waits, so it must not yield the runner.
  --
  -- mod.find(id) returns {id, version, exports} or nil for a mod that is
  -- absent, disabled, failed, OR has not run yet (Loader.lua:725-735),
  -- which is why this is called from the talk script at talk time rather
  -- than resolved once at load.
  --
  -- Phrased as "missing" rather than "installed" so the FAILURE mode is
  -- the safe one. ScriptRunner skips an unresolvable command with only a
  -- log line (ScriptRunner.lua:157) and leaves lastCheck untouched -- and
  -- at this point in the script lastCheck is still `true` from
  -- start_contest's win. With the test inverted, a skipped command falls
  -- to the plain line: the judge under-promises instead of announcing a
  -- ribbon that was never awarded.
  -- True when the judge must NOT promise a ribbon for the contest just run.
  --
  -- Installed-or-not was the whole test while COOL was the only contest.
  -- With five, "Kanto Ribbons is installed" stopped being the same question
  -- as "there is a ribbon for THIS contest": that mod maps all five
  -- categories but awards only the ones its catalog has actually drawn, and
  -- today only COOL is drawn. Promising a BEAUTY RIBBON would dangle a prize
  -- that cannot be awarded or shown -- the exact thing the plain-line branch
  -- exists to avoid.
  --
  -- So ask its catalog. mod.find returns {id, version, exports}
  -- (Loader.lua:1428-1434) and Kanto Ribbons publishes `catalog`. Anything
  -- unexpected in another mod's exports falls through to "no promise", which
  -- is the safe direction: the player is never told about a ribbon that does
  -- not arrive, and a ribbon that does arrive unannounced is a nice surprise.
  mod.content.commands:register("kanto_contests:ribbons_missing", {
    fn = function(ctx)
      local wanted = chosenContest or "COOL"
      local ok, available = pcall(function()
        local handle = mod.find("kanto_ribbons")
        if not handle or not handle.exports then return false end
        for _, entry in ipairs(handle.exports.catalog or {}) do
          if type(entry) == "table" and entry.id == wanted then return true end
        end
        return false
      end)
      ctx.lastCheck = not (ok and available)
    end,
  })

  -- snack_mart: the vendor opens a REAL mart. 0.8.0 walked the player
  -- through five yes/no prompts because the script `ask` opcode is yes/no
  -- only -- one snack per prompt, and you had to scroll past all five to
  -- leave. ShopMenu is the engine's own mart and gives the whole flow for
  -- free: every snack visible at once with its price, the BUY/SELL/QUIT
  -- loop, the 1-99 quantity selector, the money box, the not-enough-money
  -- line, and the ¥ glyph.
  --
  -- ShopMenu.new(game, stock, onQuit) takes stock as a plain array of item
  -- ids (ShopMenu.lua:152, and buy() reads them with data.items[id]), so
  -- a mod's own items need nothing special. This is exactly how the engine
  -- opens a scripted mart -- Commands.open_mart pushes the same screen and
  -- yields its runner on the same callback (Commands.lua:852-864) -- the
  -- only difference is that our stock is a literal instead of coming from
  -- a ROM text entry's `mart` field.
  --
  -- SELL comes along with BUY, which is correct rather than incidental:
  -- snacks are ordinary items and a mart that refuses to take them back
  -- would be the odd case.
  local Commands = require("src.script.Commands")
  local KC_STOCK = {}
  for _, s in ipairs(KC_SNACKS) do KC_STOCK[#KC_STOCK + 1] = s.id end
  mod.content.commands:register("kanto_contests:snack_mart", {
    foreground = true,
    fn = function(ctx)
      local runner = ctx.runner
      local Screens = require("src.ui.Screens")
      Screens.push(ctx.game, "ShopMenu", KC_STOCK, function()
        runner:resume()
      end)
      runner:yield()
    end,
  })

  -- appraise: reads condition in fuzzy tiers, never numbers. Picks the mon
  -- through the engine's own party picker (pickOnly + onSwitch is
  -- documented as the "item / script target" mode, PartyMenu.lua:8), so
  -- any mon can be appraised -- not just the lead, which would be odd
  -- when the bag lets you feed any of them.
  mod.content.commands:register("kanto_contests:appraise", {
    foreground = true,
    fn = function(ctx)
      local runner = ctx.runner
      local Screens = require("src.ui.Screens")
      local picked
      Screens.push(ctx.game, "PartyMenu", {
        pickOnly = true,
        onSwitch = function(mon) picked = mon; runner:resume() end,
        onCancel = function() runner:resume() end,
      })
      runner:yield()
      if not picked then return end
      local cond = kcCondition(picked)
      local name = picked.nickname
                   or (ctx.game.data.pokemon[picked.species]
                       and ctx.game.data.pokemon[picked.species].name)
                   or "POKeMON"
      -- Pages of two stat lines each. The nickname is kept OUT of the stat
      -- lines on purpose: "This <10-char nick>'s BEAUTY" overflows 18
      -- glyphs, which is the bug this mod already shipped once.
      local pages = { ("%s, is it?\nLet me look..."):format(name) }
      local line = {}
      for _, cat in ipairs(KC_STAT_ORDER) do
        line[#line + 1] = ("%s: %s"):format(cat,
          kcBand(KC_TIERS, cond[KC_STAT_KEY[cat]]).word)
        if #line == 2 then
          pages[#pages + 1] = table.concat(line, "\n")
          line = {}
        end
      end
      if #line > 0 then pages[#pages + 1] = table.concat(line, "\n") end
      pages[#pages + 1] = kcBand(KC_SHEEN_LINES, kcSheen(picked)).text
      local worn = KC_SCARF_BY_CATEGORY[kcScarfCategory(picked)]
      if worn then
        pages[#pages + 1] = ("It is wearing a\n%s."):format(worn.name)
      end
      local earned = kcEligibleScarf(ctx.game.save, picked)
      if earned then
        local ok, _, why =
          mod.exports.giveScarf(ctx.game.save, earned.category)
        if ok and why == "given" then
          pages[#pages + 1] = ("You earned the\n%s!"):format(earned.name)
          pages[#pages + 1] = "Use it on a\nPOKeMON to wear."
        elseif not ok then
          pages[#pages + 1] = ("A %s is\nyours..."):format(earned.name)
          pages[#pages + 1] = "But your BAG is\nfull. Come back!"
        end
      end
      -- show_text blocks on its own; the picker above needed our yield
      -- because Screens.push does not.
      Commands.show_text(ctx, table.concat(pages, "\f"))
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
      -- Our own text keys, so no ROM-constant trap applies to either.
      TEXT_KC_VENDOR = {
        { "face_player" },
        { "show_text", "POKeSNACKS!\fThey raise a\nPOKeMON's contest\fcondition -- but\nonly so far." },
        { "ask", "Want to see what\nI have?" },
        { "jump_if_false", "no_sale" },
        { "kanto_contests:snack_mart" },
        { "jump", "done" },
        { "label", "no_sale" },
        { "show_text", "Come back when\nyou're peckish!" },
        { "label", "done" },
      },
      -- The rivals' one line each -- same voices as the Gold hall, and the
      -- same names the jam and intro announcements use in the battle.
      TEXT_KC_RIVAL_PIPER = {
        { "face_player" },
        { "show_text", "I raised my\nPOKeMON on\fSWEET SNACKS.\nCUTE is mine!" },
      },
      TEXT_KC_RIVAL_REX = {
        { "face_player" },
        { "show_text", "Grit. Sweat.\nSOUR SNACKS.\fTOUGH contests\nare true tests!" },
      },
      TEXT_KC_RIVAL_FIONA = {
        { "face_player" },
        { "show_text", "My routine is\nflawless.\fBEAUTY is not\nwon. It is worn." },
      },
      TEXT_KC_APPRAISER = {
        { "face_player" },
        { "show_text", "I can read a\nPOKeMON's contest\fcondition at a\nglance." },
        { "ask", "Shall I take a\nlook at one?" },
        { "jump_if_false", "no_thanks" },
        { "kanto_contests:appraise" },
        { "jump", "done" },
        { "label", "no_thanks" },
        { "show_text", "Any time, dear." },
        { "label", "done" },
      },
      TEXT_KC_JUDGE = {
        { "face_player" },
        { "show_text", "Welcome to the\nCONTEST HALL!\fI judge all five\ncontests." },
        -- was a three-row `ask`: the third row scrolled the first away with
        -- no button wait, and a yes/no cannot pick one of five anyway
        { "show_text", "Appeal with your\nPOKeMON's moves!" },
        { "kanto_contests:choose_contest" },
        { "jump_if_false", "later" },
        { "kanto_contests:start_contest" },
        { "jump_if_true", "won" },
        -- The losing line has to respect the same rule as the winning one:
        -- with Kanto Ribbons absent there is no ribbon to be short of, so
        -- "not quite ribbon material" dangles a prize that does not exist
        -- in this install. Same inverted test as the win branch below, so
        -- a skipped command still lands on the plain line.
        -- This covers withdrawing as well as losing: RUN ends the contest
        -- with result "run", which is not "win", so both arrive here.
        { "kanto_contests:ribbons_missing" },
        { "jump_if_true", "lost_plain" },
        { "show_text", "Hmm. Not quite\nribbon material\fyet. Keep\npracticing!" },
        { "jump", "done" },
        { "label", "lost_plain" },
        { "kanto_contests:judge_line", "lost_plain" },
        { "jump", "done" },
        { "label", "won" },
        -- The COOL RIBBON is awarded by Kanto Ribbons, not by this mod, so
        -- the judge only promises one when that mod is actually installed.
        -- Checked at TALK time rather than load time: mod.find returns nil
        -- for a mod that "has not run yet" (Loader.lua:725-735) and
        -- neither mod's priority guarantees an order, so a load-time check
        -- could be wrong in one direction. The test is inverted so that a
        -- skipped command falls to the plain line -- see ribbons_missing.
        { "kanto_contests:ribbons_missing" },
        { "jump_if_true", "won_plain" },
        { "kanto_contests:judge_line", "won" },
        { "jump", "done" },
        { "label", "won_plain" },
        { "kanto_contests:judge_line", "won_plain" },
        { "jump", "done" },
        { "label", "later" },
        { "show_text", "Come back any\ntime!" },
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
      -- "ALPHA" rather than "ready": this is the one status signal that
      -- reaches someone who installed from a Discord link and never saw
      -- the release page. 18 glyphs per line, so it has to be this terse.
      say("KANTO CONTESTS\nv" .. VERSION .. " ALPHA")
    end)
    if not ok then mod.log:warn("banner failed: %s", tostring(err)) end
  end)

  mod.log:info("kanto_contests %s loaded", VERSION)
end
