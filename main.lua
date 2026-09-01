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
      id = "KC_JOHTO_CONTEST_HALL",
      warps = {
        { x = 4, y = 7, destMap = "GOLDENROD_CITY", destWarp = 1 },
        { x = 5, y = 7, destMap = "GOLDENROD_CITY", destWarp = 1 },
      },
      label = "GOLDENROD CONTEST HALL",
      song = "GOLDENROD_DEPT_STORE_1F",
      palette = "PALETTE_DAY",
      width = 5, height = 4,
      -- One square left of the old spot. Both 4,7 and 5,7 are COLL_CARPET
      -- (0x70) -- the doorway is two tiles wide -- so this is the same
      -- kind of tile, and the warp cooldown is what stops an arrival on
      -- a carpet from bouncing straight back out.
      arrival = { x = 4, y = 7 },
      tiles = {
        id = "KC_GOLDENROD_LOBBY_TILES",
        source = "TILESET_MART",
        variants = {
          gs = {
            image = "assets/generated/tilesets/mart.png",
            imageWidth = 128, imageHeight = 128, tilesPerRow = 16,
            border = 0,
            tilePalettes = {
              1, 5, 1, 1, 1, 1, 1, 1, 3, 3, 4, 2, 1, 1, 7, 7, 1, 1, 1, 1,
              1, 1, 1, 1, 6, 6, 6, 2, 7, 7, 1, 5, 1, 1, 2, 2, 2, 2, 4, 4,
              4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 2, 1,
              1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 3, 1, 3, 3, 1, 1, 1, 1,
              1, 1, 2, 5, 5, 5, 7, 7, 7, 7, 7, 7, 2, 2, 6, 6, 8, 8, 8, 8,
              8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
              8, 8, 8, 8, 8, 8, 8, 8, 1, 1, 1, 3, 3, 3, 3, 1, 1, 3, 3, 2,
              2, 4, 4, 7, 1, 1, 1, 5, 5, 5, 7, 1, 1, 1, 4, 1, 1, 1, 5, 5,
              1, 1, 1, 1, 1, 2, 4, 2, 2, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2,
              2, 2, 2, 2, 2, 6, 6, 6, 6, 6, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1,
              1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 1, 1, 4, 1,
              4, 2, 6, 6,
            },
      blocks = {
              { 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 },
              { 14, 15, 14, 15, 28, 29, 28, 29, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 34, 35, 1, 1, 50, 51, 1, 1, 36, 37, 1, 1, 52, 53, 1, 1 },
              { 30, 30, 30, 30, 26, 26, 26, 26, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 34, 35, 1, 1, 50, 51, 1, 1, 36, 37, 1, 1, 52, 53 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 11, 11, 11, 11, 27, 27, 27, 27 },
            },
      collision = {
              { 7, 7, 7, 7 },
              { 7, 7, 0, 0 },
              { 7, 0, 7, 0 },
              { 144, 144, 0, 0 },   -- the desk: COUNTER, talk across it
              { 0, 7, 0, 7 },
              { 0, 0, 0, 0 },
              { 0, 0, 112, 112 },
            },
    },
          crystal = {
            image = "assets/generated/tilesets/mart.png",
            imageWidth = 128, imageHeight = 128, tilesPerRow = 16,
            border = 0,
            tilePalettes = {
              1, 5, 1, 1, 1, 1, 1, 1, 3, 3, 4, 2, 1, 1, 7, 7, 1, 1, 1, 1,
              1, 1, 1, 1, 6, 6, 6, 2, 7, 7, 1, 5, 1, 1, 2, 2, 2, 2, 4, 4,
              4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 2, 1,
              1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 3, 1, 3, 3, 1, 1, 1, 1,
              1, 1, 2, 5, 5, 5, 7, 7, 7, 7, 7, 7, 2, 2, 6, 6, 8, 8, 8, 8,
              8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
              8, 8, 8, 8, 8, 8, 8, 8, 1, 1, 1, 3, 3, 3, 3, 1, 1, 3, 3, 2,
              2, 4, 4, 7, 1, 1, 1, 5, 5, 5, 7, 1, 1, 1, 4, 1, 1, 1, 5, 5,
              1, 1, 1, 1, 1, 2, 4, 2, 2, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2,
              2, 2, 2, 2, 2, 6, 6, 6, 6, 6, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1,
              1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 1, 1, 4, 1,
              4, 2, 6, 6,
            },
      blocks = {
              { 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 },
              { 14, 15, 14, 15, 28, 29, 28, 29, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 34, 35, 1, 1, 50, 51, 1, 1, 36, 37, 1, 1, 52, 53, 1, 1 },
              { 30, 30, 30, 30, 26, 26, 26, 26, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 34, 35, 1, 1, 50, 51, 1, 1, 36, 37, 1, 1, 52, 53 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 11, 11, 11, 11, 27, 27, 27, 27 },
            },
      collision = {
              { 7, 7, 7, 7 },
              { 7, 7, 0, 0 },
              { 7, 0, 7, 0 },
              { 144, 144, 0, 0 },   -- the desk: COUNTER, talk across it
              { 0, 7, 0, 7 },
              { 0, 0, 0, 0 },
              { 0, 0, 112, 112 },
            },
    },
        },
      },
      blocks = {
        1, 1, 1, 1, 1,
        2, 3, 3, 3, 4,
        2, 5, 5, 5, 4,
        2, 5, 6, 5, 4,
      },
      actors = {
        { name = "KC_HALL_JUDGE", marker = "kcHallJudge",
          sprite = "SPRITE_GENTLEMAN", x = 4, y = 1, movement = 6 },
        { name = "KC_HALL_VENDOR", marker = "kcHallVendor",
          sprite = "SPRITE_TEACHER", x = 1, y = 7, movement = 9 },
        { name = "KC_HALL_APPRAISER", marker = "kcHallAppraiser",
          sprite = "SPRITE_BEAUTY", x = 8, y = 7, movement = 8 },
        { name = "KC_AUD_1", marker = "kcAudience",
          sprite = "SPRITE_POKEFAN_M", x = 1, y = 4, movement = 9 },
        { name = "KC_AUD_2", marker = "kcAudience",
          sprite = "SPRITE_GRANNY", x = 2, y = 4, movement = 9 },
        { name = "KC_AUD_3", marker = "kcAudience",
          sprite = "SPRITE_TWIN", x = 6, y = 6, movement = 7 },
      },
    },
    stage = {
      id = "KC_JOHTO_CONTEST_STAGE",
      warps = {
        { x = 4, y = 13, destMap = "KC_JOHTO_CONTEST_HALL", destWarp = 1 },
        { x = 5, y = 13, destMap = "KC_JOHTO_CONTEST_HALL", destWarp = 1 },
      },
      label = "CONTEST STAGE",
      song = "GOLDENROD_GAME_CORNER",
      palette = "PALETTE_DAY",
      width = 5, height = 7,
      -- The player arrives at the END OF THE LINE on the stage itself and
      -- is called up to the mark; they never have to climb.
      arrival = { x = 3, y = 8 },
      tiles = {
        id = "KC_GOLDENROD_STAGE_TILES",
        source = "TILESET_MART",
        border = 0,
        variants = {
          gs = {
            image = "assets/generated/tilesets/mart.png",
            imageWidth = 128, imageHeight = 48, tilesPerRow = 16,
            border = 0,
            tilePalettes = { 1, 5, 1, 1, 1, 1, 1, 1, 3, 3, 4, 2, 1, 1, 7, 7, 1, 1, 1, 1, 1, 1, 1, 1, 6, 6, 6, 2, 7, 7, 1, 5, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 3, 1, 3, 3, 1, 1, 1, 1, 1, 1, 2, 5, 5, 5, 7, 7, 7, 7, 7, 7, 2, 2, 6, 6 },
            blocks = {
              { 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 },
              { 14, 15, 14, 15, 28, 29, 28, 29, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 4, 5, 36, 37, 20, 21, 52, 53 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 36, 37, 36, 37, 52, 53, 52, 53 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 36, 37, 4, 5, 52, 53, 20, 21 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 11, 11, 11, 11, 27, 27, 27, 27 },
            },
            collision = {
              { 0x07, 0x07, 0x07, 0x07 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0xB0 },
              { 0xB3, 0xB3, 0xB7, 0xB2 },
              { 0xB3, 0xB3, 0xB2, 0xB2 },
              { 0xB3, 0xB3, 0xB2, 0xB6 },
              { 0x00, 0x00, 0xB1, 0x00 },
              { 0x00, 0xB0, 0x00, 0xB0 },
              { 0xB1, 0x00, 0xB1, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0xB0, 0x00, 0xB0 },
              { 0xB1, 0x00, 0xB1, 0x00 },
              { 0x00, 0xB0, 0x00, 0x00 },
              { 0xB1, 0x00, 0x00, 0x07 },
              { 0x00, 0x00, 0x07, 0x07 },
              { 0x00, 0xB0, 0x07, 0x00 },
              { 0xB1, 0x00, 0x00, 0x00 },
              { 0x00, 0xB2, 0x00, 0x00 },
              { 0xB2, 0xB2, 0x00, 0x00 },
              { 0xB2, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x70, 0x70 },
            },
          },
          crystal = {
            image = "assets/generated/tilesets/mart.png",
            imageWidth = 128, imageHeight = 128, tilesPerRow = 16,
            border = 0,
            tilePalettes = { 1, 5, 1, 1, 1, 1, 1, 1, 3, 3, 4, 2, 1, 1, 7, 7, 1, 1, 1, 1, 1, 1, 1, 1, 6, 6, 6, 2, 7, 7, 1, 5, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 3, 1, 3, 3, 1, 1, 1, 1, 1, 1, 2, 5, 5, 5, 7, 7, 7, 7, 7, 7, 2, 2, 6, 6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 1, 1, 3, 3, 3, 3, 1, 1, 3, 3, 2, 2, 4, 4, 7, 1, 1, 1, 5, 5, 5, 7, 1, 1, 1, 4, 1, 1, 1, 5, 5, 1, 1, 1, 1, 1, 2, 4, 2, 2, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 6, 6, 6, 6, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 1, 1, 4, 1, 4, 2, 6, 6 },
            blocks = {
              { 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 },
              { 14, 15, 14, 15, 28, 29, 28, 29, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 34, 35, 34, 35, 50, 51, 50, 51 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 4, 5, 36, 37, 20, 21, 52, 53 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 36, 37, 36, 37, 52, 53, 52, 53 },
              { 34, 35, 34, 35, 50, 51, 50, 51, 36, 37, 4, 5, 52, 53, 20, 21 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 1, 1, 1, 1, 1, 1, 1, 1, 11, 11, 11, 11, 27, 27, 27, 27 },
            },
            collision = {
              { 0x07, 0x07, 0x07, 0x07 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0xB0 },
              { 0xB3, 0xB3, 0xB7, 0xB2 },
              { 0xB3, 0xB3, 0xB2, 0xB2 },
              { 0xB3, 0xB3, 0xB2, 0xB6 },
              { 0x00, 0x00, 0xB1, 0x00 },
              { 0x00, 0xB0, 0x00, 0xB0 },
              { 0xB1, 0x00, 0xB1, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0xB0, 0x00, 0xB0 },
              { 0xB1, 0x00, 0xB1, 0x00 },
              { 0x00, 0xB0, 0x00, 0x00 },
              { 0xB1, 0x00, 0x00, 0x07 },
              { 0x00, 0x00, 0x07, 0x07 },
              { 0x00, 0xB0, 0x07, 0x00 },
              { 0xB1, 0x00, 0x00, 0x00 },
              { 0x00, 0xB2, 0x00, 0x00 },
              { 0xB2, 0xB2, 0x00, 0x00 },
              { 0xB2, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x70, 0x70 },
            },
          },
        },
      },
      blocks = {
        1, 1, 1, 1, 1,
        2, 2, 2, 2, 2,
        3, 4, 5, 6, 7,
        8, 9, 10, 11, 12,
        13, 14, 15, 16, 17,
        2, 18, 19, 20, 2,
        2, 2, 21, 2, 2,
      },
      actors = {
        { name = "KC_STAGE_JUDGE", marker = "kcStageJudge",
          sprite = "SPRITE_GENTLEMAN", x = 5, y = 6, movement = 8 },
      },
    },
  },
  ECRUTEAK = {
    lobby = {
      id = "KC_ECRUTEAK_CONTEST_HALL",
      warps = {
        { x = 5, y = 9, destMap = "ECRUTEAK_CITY", destWarp = 1 },
        { x = 6, y = 9, destMap = "ECRUTEAK_CITY", destWarp = 1 },
      },
      label = "ECRUTEAK CONTEST HALL",
      song = "DANCE_THEATER",
      palette = "PALETTE_DAY",
      width = 5, height = 5,
      arrival = { x = 5, y = 8 },
      tiles = {
        id = "KC_ECRUTEAK_HALL_TILES",
        source = "TILESET_TRADITIONAL_HOUSE",
        variants = {
          gs = {
            image = "assets/generated/tilesets/traditional_house.png",
            imageWidth = 128, imageHeight = 128, tilesPerRow = 16,
            border = 0,
            tilePalettes = {
              1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 4,
              2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1,
              1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6,
              6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4,
              6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6, 8, 8, 8, 8,
              8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
              8, 8, 8, 8, 8, 8, 8, 8, 1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 1, 1,
              6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6,
              1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6,
              6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6,
              6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6,
              6, 6, 4, 6,
            },
      blocks = {
              { 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 },
              { 78, 79, 78, 79, 94, 94, 94, 94, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 15, 15, 95, 95, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 80, 80, 80, 80, 95, 95, 15, 15, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 68, 69, 2, 3, 84, 85, 18, 19, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 68, 69, 69, 70, 84, 85, 85, 86, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 2, 3, 69, 70, 18, 19, 85, 86, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 16, 16, 16, 16, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 16, 16, 16, 16, 14, 14, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 16, 16, 16, 16, 1, 1, 1, 1, 1, 1, 4, 4, 1, 1, 20, 20 },
              { 16, 16, 16, 16, 1, 1, 1, 1, 4, 4, 1, 1, 20, 20, 1, 1 },
              { 16, 16, 16, 16, 14, 1, 1, 14, 1, 1, 1, 1, 1, 1, 1, 1 },
            },
      collision = {
              { 7, 7, 7, 7 },
              { 7, 7, 0, 0 },
              { 0, 0, 0, 0 },
              { 7, 0, 0, 0 },
              { 7, 7, 0, 0 },
              { 0, 7, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 112 },
              { 0, 0, 112, 0 },
              { 0, 0, 0, 0 },
            },
    },
          crystal = {
            image = "assets/generated/tilesets/traditional_house.png",
            imageWidth = 128, imageHeight = 128, tilesPerRow = 16,
            border = 0,
            tilePalettes = {
              1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 4,
              2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1,
              1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6,
              6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4,
              6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6, 8, 8, 8, 8,
              8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
              8, 8, 8, 8, 8, 8, 8, 8, 1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 1, 1,
              6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6,
              1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6,
              6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6,
              6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6,
              6, 6, 4, 6,
            },
      blocks = {
              { 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 },
              { 78, 79, 78, 79, 94, 94, 94, 94, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 15, 15, 95, 95, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 80, 80, 80, 80, 95, 95, 15, 15, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 68, 69, 2, 3, 84, 85, 18, 19, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 68, 69, 69, 70, 84, 85, 85, 86, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 2, 3, 69, 70, 18, 19, 85, 86, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 16, 16, 16, 16, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 16, 16, 16, 16, 14, 14, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
              { 16, 16, 16, 16, 1, 1, 1, 1, 1, 1, 4, 4, 1, 1, 20, 20 },
              { 16, 16, 16, 16, 1, 1, 1, 1, 4, 4, 1, 1, 20, 20, 1, 1 },
              { 16, 16, 16, 16, 14, 1, 1, 14, 1, 1, 1, 1, 1, 1, 1, 1 },
            },
      collision = {
              { 7, 7, 7, 7 },
              { 7, 7, 0, 0 },
              { 0, 0, 0, 0 },
              { 7, 0, 0, 0 },
              { 7, 7, 0, 0 },
              { 0, 7, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 0 },
              { 0, 0, 0, 112 },
              { 0, 0, 112, 0 },
              { 0, 0, 0, 0 },
            },
    },
        },
      },
      blocks = {
        1, 1, 1, 1, 1,
        2, 2, 2, 2, 2,
        3, 4, 4, 4, 5,
        6, 7, 7, 7, 8,
        9, 10, 11, 12, 13,
      },
      actors = {
        { name = "KC_HALL_JUDGE", marker = "kcHallJudge",
          sprite = "SPRITE_GENTLEMAN", x = 4, y = 2, movement = 6 },
        { name = "KC_HALL_VENDOR", marker = "kcHallVendor",
          sprite = "SPRITE_TEACHER", x = 1, y = 9, movement = 9 },
        { name = "KC_HALL_APPRAISER", marker = "kcHallAppraiser",
          sprite = "SPRITE_BEAUTY", x = 8, y = 9, movement = 8 },
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
    -- A room the developer painted carries its OWN blocks, cut a quarter
    -- at a time from a vanilla sheet. Only numbers are ours: `image` is
    -- the player's extracted file, which Assets.resolve finds in their
    -- cache (Assets.lua:36-54), so no ROM art is redistributed.
    --
    -- tilePalettes and the border block are BAKED INTO the room above,
    -- not looked up from the running game. 0.16.0 read them off
    -- mod.game.data at load time, got nothing, and every room rendered
    -- grey with the border block papered across the screen -- a lookup
    -- that fails leaves no trace at the only moment it matters.
    -- PER ENGINE, because Gold and Crystal are not the same game's art.
    -- Their sheets share a filename and nothing else: Crystal's are
    -- 128x128 where Gold's are 128x48, with different tile numbering and
    -- different palette slots. A room baked from one renders as garbage
    -- on the other -- which is exactly what shipped in 0.16.x, painted on
    -- Gold and played on Crystal.
    --
    -- GameVersion.engine() is the right split: gold and silver share "gs",
    -- crystal is its own.
    local tilesetId = def.tileset
    if def.tiles then
      tilesetId = def.tiles.id
      -- required here: the file-scope GameVersion local is declared far
      -- below this point, so the name would be a nil global at load
      local GV = require("src.core.GameVersion")
      local engine = GV.engine and GV.engine() or "gs"
      local v = def.tiles.variants
        and (def.tiles.variants[engine] or def.tiles.variants.gs)
      if v then
        mod.content.tilesets:register(def.tiles.id, {
          id = def.tiles.id,
          image = v.image,
          imageWidth = v.imageWidth,
          imageHeight = v.imageHeight,
          tilesPerRow = v.tilesPerRow,
          blocks = v.blocks,
          collision = v.collision,
          tilePalettes = v.tilePalettes,
        })
        def.tiles.border = v.border
      else
        mod.log:warn("kc: %s has no tileset variant for engine %s",
                     def.id, tostring(engine))
      end
    end
    mod.content.maps:register(def.id, {
      id = def.id,
      label = def.label,
      generation = 2,
      tileset = tilesetId,
      width = def.width, height = def.height,
      blocks = def.blocks,
      -- a composed sheet has its border at a known index; a vanilla one
      -- keeps 0, which IS that sheet's void block
      borderBlock = (def.tiles and def.tiles.border) or 0,
      palette = def.palette,
      environment = "INDOOR",
      phoneService = false,
      -- the carpet the developer painted is the way out; its cells keep
      -- their vanilla warp collision, and these are the records that
      -- collision looks up
      objects = {}, warps = def.warps or {}, signs = {}, connections = {},
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
  -- Custom cast, from the project's canonical sprite store.
  --
  -- THE RULE (sprites/README.md): one character, one conversion, one
  -- palette, across every mod. These files are COPIED byte-for-byte from
  -- sprites/canonical/ and the palette/paletteId below come from
  -- sprites/REGISTRY.json -- they are not chosen here and must never be.
  -- This mod already got that wrong once: it converted Larry fresh from
  -- the artist's sheet and picked PAL_OW_BLUE/0 where canonical is
  -- PAL_OW_BROWN/3, so the same man would have been a different colour
  -- depending on which mod drew him. Run
  -- `python exchange/sprite_registry.py check` before shipping.
  --
  -- No gym leader or Elite Four member appears here: where the game has
  -- canon art for a character, the cast uses the GAME's sprite. Custom
  -- art is only for characters Gen 2 has none for.
  --
  -- Artists are credited in THIRD_PARTY_NOTICES.md, per sheet.
  local KC_CUSTOM_SPRITES = {
    { "SPRITE_KC_AGATHA", "agatha.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_AJ", "aj.png", "PAL_OW_GREEN", 2 },
    { "SPRITE_KC_ARCHER", "archer.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_ARIANA", "ariana.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_ASH", "ash.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_BALLGUY", "ballguy.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_BARRY", "barry.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_BEA", "bea.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_BILL", "bill.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_BREEDER", "breeder.png", "PAL_OW_GREEN", 2 },
    { "SPRITE_KC_BRENDAN", "brendan.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_CHEF", "chef.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_COLRESS", "colress.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_DAWN", "dawn.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_DUPLICA", "duplica.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_EUSINE", "eusine.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_GIOVANNI", "giovanni.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_GISELLE", "giselle.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_GLORIA", "gloria.png", "PAL_OW_GREEN", 2 },
    { "SPRITE_KC_GREEN", "green.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_HILBERT", "hilbert.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_HILDA", "hilda.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_HUGH", "hugh.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_INGO", "ingo.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_JULIANA", "juliana.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_LARRY", "larry.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_LEAF", "leaf.png", "PAL_OW_GREEN", 2 },
    { "SPRITE_KC_LEAR", "lear.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_LILLIE", "lillie.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_LOOKER", "looker.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_LORELEI", "lorelei.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_LYRA", "lyra.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_MAXIE", "maxie.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_MAY", "may.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_MICHAEL", "michael.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_MINA", "mina.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_N", "n.png", "PAL_OW_GREEN", 2 },
    { "SPRITE_KC_NATE", "nate.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_NURSE_JOY", "nurse_joy.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_OFFICER_JENNY", "officer_jenny.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_PETREL", "petrel.png", "PAL_OW_GREEN", 2 },
    { "SPRITE_KC_PIERS", "piers.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_PROTON", "proton.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_RANGER", "ranger.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_ROCKET_EXECUTIVE", "rocket_executive.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_ROSA", "rosa.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_ROXIE", "roxie.png", "PAL_OW_PINK", 4 },
    { "SPRITE_KC_RUIN_MANIAC", "ruin_maniac.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_SANTA", "santa.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_STADIUM_PLAYER", "stadium_player.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_SUZIE", "suzie.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_VOLKNER", "volkner.png", "PAL_OW_BROWN", 3 },
    { "SPRITE_KC_WALLY", "wally.png", "PAL_OW_GREEN", 2 },
    { "SPRITE_KC_WES", "wes.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_YELLOW", "yellow.png", "PAL_OW_BROWN", 3 },
  }
  for _, row in ipairs(KC_CUSTOM_SPRITES) do
    mod.content.sprites:register(row[1], {
      id = row[1],
      image = mod.path .. "/assets/" .. row[2],
      frames = 6,
      walker = true,
      spriteType = "WALKING_SPRITE",
      palette = row[3],
      paletteId = row[4],
    })
  end

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
    -- Prefer what the crowd actually gave them on stage. Falls back to
    -- a fresh roll when there was no appeal round -- the headless tests
    -- build their own judge with no kcAppealHearts, and so does a
    -- contest entered any way that skips the stage scene.
    local staged = b.trainer and b.trainer.kcAppealHearts
    if staged and #staged >= #KC_RIVALS then
      b.kcRivalHearts = {}
      for i = 1, #KC_RIVALS do b.kcRivalHearts[i] = staged[i] end
    else
      b.kcRivalHearts = kcRollRivalHearts(b.rng)
    end
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
  -- forward: the stage intro ends by starting the contest itself, and it
  -- is defined above runGoldContest. Same shape as leaveStage above.
  local runGoldContest
  local function onStageNow()
    local here = mod.world:current()
    return STAGE_DEF ~= nil and here ~= nil and here.mapId == STAGE_DEF.id
  end
  -- Where the player is put back on the street when they leave the hall.
  -- This is the DOOR the developer painted (35,4), not the old attendant's
  -- cell -- she has been removed, so landing beside her would be landing
  -- beside nothing. y+1 is the pavement square below the door.
  local entranceCell = { x = 35, y = 4 }
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

  -- ---------------------------------------------------------------
  -- The stage crowd.
  --
  -- Seat and mark cells are the developer's, given exactly; nothing here
  -- picks a position. Audience face UP toward the stage, coordinators
  -- face DOWN, and the row ends turn inward so the crowd does not read
  -- as a wall of identical backs.
  --
  -- movement is NUMERIC on Gen 2 (Npc.lua:23 MOVE): 6 STANDING_DOWN,
  -- 7 STANDING_UP, 8 STANDING_LEFT, 9 STANDING_RIGHT.
  local FACE_DOWN, FACE_UP, FACE_LEFT, FACE_RIGHT = 6, 7, 8, 9
  -- Every seat the developer marked out. The crowd is DRAWN from these
  -- rather than filling them all: 10-15 per contest keeps the density
  -- they asked for while making the room different each time.
  --
  -- Facings all point at the stage: the rows above look DOWN, the rows
  -- below look UP, and the flanking columns look inward.
  local STAGE_SEATS = {
    { x = 2, y =  2, face = FACE_DOWN   },
    { x = 3, y =  2, face = FACE_DOWN   },
    { x = 4, y =  2, face = FACE_DOWN   },
    { x = 5, y =  2, face = FACE_DOWN   },
    { x = 6, y =  2, face = FACE_DOWN   },
    { x = 7, y =  2, face = FACE_DOWN   },
    { x = 2, y =  4, face = FACE_DOWN   },
    { x = 3, y =  4, face = FACE_DOWN   },
    { x = 4, y =  4, face = FACE_DOWN   },
    { x = 5, y =  4, face = FACE_DOWN   },
    { x = 6, y =  4, face = FACE_DOWN   },
    { x = 7, y =  4, face = FACE_DOWN   },
    { x = 1, y =  5, face = FACE_RIGHT  },
    { x = 1, y =  6, face = FACE_RIGHT  },
    { x = 1, y =  7, face = FACE_RIGHT  },
    { x = 1, y =  8, face = FACE_RIGHT  },
    { x = 8, y =  5, face = FACE_LEFT   },
    { x = 8, y =  6, face = FACE_LEFT   },
    { x = 8, y =  7, face = FACE_LEFT   },
    { x = 8, y =  8, face = FACE_LEFT   },
    { x = 3, y = 10, face = FACE_UP     },
    { x = 4, y = 10, face = FACE_UP     },
    { x = 5, y = 10, face = FACE_UP     },
    { x = 6, y = 10, face = FACE_UP     },
    { x = 1, y = 12, face = FACE_UP     },
    { x = 2, y = 12, face = FACE_UP     },
    { x = 3, y = 12, face = FACE_UP     },
    { x = 6, y = 12, face = FACE_UP     },
    { x = 7, y = 12, face = FACE_UP     },
    { x = 8, y = 12, face = FACE_UP     },
  }
  -- 15-20 in the room. The FIRST dozen carry the named faces; everyone
  -- after that is drawn almost entirely from the vanilla trainers, so a
  -- bigger crowd reads as a bigger crowd rather than as more celebrities
  -- -- there are already plenty of custom characters in the mix.
  local CROWD_MIN, CROWD_MAX = 15, 20
  local CROWD_NAMED_UNTIL = 12

  -- Adjacency is computed from the seats actually CHOSEN, not a fixed
  -- index table -- the seat list changes whenever the room does, and a
  -- hardcoded pair list silently seats a "pair" on opposite walls.
  local function adjacentPairs(chosen)
    local out = {}
    for a = 1, #chosen do
      for b = a + 1, #chosen do
        local p, q = chosen[a], chosen[b]
        if math.abs(p.x - q.x) + math.abs(p.y - q.y) == 1 then
          out[#out + 1] = { a, b }
        end
      end
    end
    return out
  end

  local STAGE_COORD_CELLS = {
    { x = 4, y = 8 }, { x = 5, y = 8 }, { x = 6, y = 8 },
  }
  local STAGE_LINEUP = { x = 3, y = 8 }   -- where the player waits
  local STAGE_MARK   = { x = 4, y = 6 }   -- where the player performs

  -- Every sprite below is VANILLA Gen 2 except Larry, so the crowd
  -- carries no attribution burden at all: no conversion, no credit line,
  -- nothing to clear. Larry is the single exception and is credited.
  --
  -- Gym leaders and the Elite Four sit in BOTH pools by the developer's
  -- call -- a leader can be competing that day or just watching -- so
  -- they are drawn from one list and assigned to whichever pool needs
  -- filling.
  local CAST_GYM = {
    "WHITNEY", "FALKNER", "BUGSY", "MORTY", "CHUCK", "JASMINE", "PRYCE",
    "CLAIR", "BROCK", "MISTY", "SURGE", "ERIKA", "JANINE", "SABRINA",
    "BLAINE", "BLUE", "WILL", "KOGA", "BRUNO", "KAREN", "LANCE",
  }
  local CAST_FOLK = {
    "BIKER", "TWIN", "ROCKET", "ROCKET_GIRL", "COOLTRAINER_M", "COOLTRAINER_F", "BLACK_BELT",
    "BUG_CATCHER", "TEACHER", "OFFICER", "POKEFAN_M", "POKEFAN_F",
    "YOUNGSTER", "SUPER_NERD", "SAGE", "BIRD",
    "GENTLEMAN", "BEAUTY", "LASS", "FISHER", "SAILOR", "SWIMMER_GUY",
    "SWIMMER_GIRL", "ROCKER", "SCIENTIST", "PHARMACIST", "GRAMPS",
    "GRANNY", "CLERK", "NURSE", "GYM_GUIDE", "ELDER", "KIMONO_GIRL",
    "BILL", "OAK", "ELM", "KURT", "DAISY", "MOM", "RED", "CAL",
  }
  -- Custom characters, stored WITHOUT the "SPRITE_" prefix so they draw
  -- through exactly the same path as the vanilla pools.
  --
  -- Split by whether the character has a reason to be COMPETING. The
  -- rival set can also just be watching; the crowd set never competes.
  local CAST_CUSTOM_RIVAL = {
    "KC_STADIUM_PLAYER", "KC_DUPLICA", "KC_GISELLE", "KC_SUZIE",
    -- KC_LARRY is deliberately NOT here: he has his own once-in-a-blue-
    -- moon roll below, and listing him again would make him common.
    "KC_ASH", "KC_JULIANA", "KC_LEAF", "KC_LEAR",
    "KC_LILLIE", "KC_NATE", "KC_YELLOW", "KC_N", "KC_VOLKNER",
    "KC_BEA", "KC_BRENDAN", "KC_DAWN", "KC_GREEN", "KC_HILBERT",
    "KC_HILDA", "KC_LYRA", "KC_MICHAEL", "KC_ROSA", "KC_WES",
    "KC_BARRY", "KC_MAY", "KC_COLRESS", "KC_HUGH", "KC_LORELEI",
    "KC_MAXIE", "KC_WALLY", "KC_MINA", "KC_GLORIA", "KC_ROXIE",
    "KC_AJ", "KC_PIERS",
  }
  local CAST_CUSTOM_CROWD = {
    "KC_BREEDER", "KC_ROCKET_EXECUTIVE", "KC_CHEF", "KC_EUSINE", "KC_LOOKER",
    "KC_RANGER", "KC_SANTA", "KC_NURSE_JOY", "KC_BALLGUY", "KC_BILL",
    "KC_INGO", "KC_AGATHA", "KC_ARCHER", "KC_ARIANA", "KC_GIOVANNI",
    "KC_PETREL", "KC_PROTON", "KC_OFFICER_JENNY", "KC_RUIN_MANIAC",
  }

  -- Pairs that read as a pair when seated together. Purely cosmetic.
  local CAST_PAIRS = {
    { "TWIN", "TWIN" }, { "ROCKET", "ROCKET_GIRL" },
    { "POKEFAN_M", "POKEFAN_F" }, { "COOLTRAINER_M", "COOLTRAINER_F" },
    { "SWIMMER_GUY", "SWIMMER_GIRL" }, { "GRAMPS", "GRANNY" },
    { "RED", "BLUE" }, { "OAK", "ELM" }, { "KURT", "DAISY" },
    { "MISTY", "BROCK" }, { "KC_OFFICER_JENNY", "KC_NURSE_JOY" },
    { "KC_ASH", "KC_MAY" }, { "KC_BILL", "KC_LOOKER" },
  }

  -- Larry. The ONLY non-vanilla sprite in the cast, and the developer
  -- asked for him by name: he competes once in a blue moon rather than
  -- sitting in the crowd, so he is weighted into the coordinator draw at
  -- a low rate and never appears twice running.
  --
  -- Sheet: Bani, from the project sprite library, cropped at the
  -- inventory's verified walk box (375,53)-(391,149) and put through the
  -- documented 4-to-4 luminance pass. That mapping is not a guess about
  -- which grey is which: on Gen 2 the MID shade is the one every object
  -- palette tints as skin, so his face lands on 170, his suit on 85 (the
  -- hue slot) and hair/outline on 0. Verified frame by frame against the
  -- source before shipping.
  local LARRY = "SPRITE_KC_LARRY"
  local LARRY_ODDS = 8      -- 1 in 8 contests

  -- Seeded so a retry shows the SAME crowd: a contest the player reloads
  -- into should not quietly reshuffle its audience. Plain LCG -- the
  -- engine exposes no RNG convention for mods to share.
  local function seededRng(seed)
    local s = (seed or 1) % 2147483647
    if s <= 0 then s = s + 2147483646 end
    return function(n)
      s = (s * 16807) % 2147483647
      return (s % n) + 1
    end
  end

  local function drawFrom(pool, used, rnd)
    for _ = 1, 40 do
      local pick = pool[rnd(#pool)]
      if pick and not used[pick] then used[pick] = true return pick end
    end
    return nil
  end

  -- How many contests have been run; the crowd seed rides on it so each
  -- contest has its own crowd but a RELOAD of the same one repeats it.
  -- mod.save is an OBJECT with :get/:set, not a plain table. This read it
  -- as a field -- `mod.save.kcContestCount` -- so the write went nowhere
  -- the read could see it and the count was permanently 0. Two things
  -- broke silently: every contest drew the SAME crowd, and the lobby
  -- (count+1) could never match the stage (count), which is exactly the
  -- mismatch the developer kept seeing after I "fixed" it twice.
  local function contestCount()
    return tonumber(mod.save and mod.save:get("kcContestCount", 0)) or 0
  end
  -- A salt, re-rolled each time the player walks into the hall.
  --
  -- The contest count alone was not enough: it only advances when a
  -- contest is ACCEPTED, so restarting without finishing one reloads the
  -- same count and reseats exactly the same crowd -- which is what the
  -- developer kept seeing. Steps and play time both move while the
  -- player is walking around, so mixing them in makes each visit to the
  -- hall a different room.
  --
  -- It is SNAPSHOT, not read live: the lobby queue is drawn on entry and
  -- the stage line-up when the contest starts, and those two have to
  -- agree. Reading the step count live would let them drift apart in the
  -- few paces between the door and the desk.
  local function rollSeedSalt()
    local save = mod.game and mod.game.save
    local t = (save and save.playTime) or {}
    local salt = ((save and save.stepCount) or 0) * 7919
      + ((t.seconds or 0) * 104729) + ((t.minutes or 0) * 1299709)
      + ((t.hours or 0) * 15485863) + ((t.frames or 0) * 31)
    salt = (salt % 100003) + 7
    if mod.save then mod.save:set("kcSeedSalt", salt) end
    return salt
  end
  local function seedSalt()
    return tonumber(mod.save and mod.save:get("kcSeedSalt", 7)) or 7
  end

  local function contestSeed()
    return (contestCount() * 131) + seedSalt()
  end

  -- The seed for the contest the player is ABOUT to enter.
  --
  -- kcContestCount is advanced when the player accepts a category and is
  -- warped to the stage -- which is AFTER they have already walked into
  -- the lobby and the queue has been drawn. So the lobby must look one
  -- ahead, or it shows the previous contest's line-up and the "queue up\n-- behind the people you compete against" promise quietly breaks. It
  -- did exactly that until the developer asked whether the crowd
  -- changes between contests.
  local function nextContestSeed()
    return ((contestCount() + 1) * 131) + seedSalt()
  end

  -- The three coordinators, drawn ONCE per contest.
  --
  -- Both the lobby queue and the stage line-up call this with the same
  -- seed, so the people you queue behind are the people you compete
  -- against -- they were different sets before, which made the queue
  -- look like set dressing.
  --
  -- AT MOST ONE gym leader or Elite Four member. Three at once read as a
  -- gauntlet rather than a contest; a single famous face is the treat.
  local function drawCoordinators(rnd, used)
    local out, heavy = {}, false
    if rnd(LARRY_ODDS) == 1 then
      out[#out + 1] = LARRY
      used[LARRY] = true
    end
    while #out < #STAGE_COORD_CELLS do
      local roll = rnd(10)
      local pool
      if roll <= 5 then
        pool = CAST_CUSTOM_RIVAL
      elseif roll <= 7 and not heavy then
        pool = CAST_GYM
      else
        pool = CAST_FOLK
      end
      local pick = drawFrom(pool, used, rnd) or drawFrom(CAST_FOLK, used, rnd)
      if not pick then break end
      if pool == CAST_GYM then heavy = true end
      out[#out + 1] = "SPRITE_" .. pick
    end
    return out
  end

  -- The queue in the lobby: the same three people, on the same seed, up
  -- the right-hand wall facing LEFT. Previously three fixed NPCs, which
  -- meant the coordinators you queued behind had nothing to do with the
  -- ones you then competed against.
  local LOBBY_QUEUE_CELLS = {
    { x = 8, y = 5 }, { x = 8, y = 4 }, { x = 8, y = 3 },
  }
  local function ensureLobbyQueue(world)
    if markerExists(world, "kcCast") then return end
    -- new visit, new room. The guard above means this runs once per
    -- entry, not once per frame, so the queue does not reshuffle while
    -- the player is standing in it.
    rollSeedSalt()
    local coordinators = drawCoordinators(seededRng(nextContestSeed()), {})
    for i, cell in ipairs(LOBBY_QUEUE_CELLS) do
      local sprite = coordinators[i]
      if sprite then
        spawnMarked(HALL, {
          name = ("KC_QUEUE_%d"):format(i), sprite = sprite,
          x = cell.x, y = cell.y, movement = FACE_LEFT,
          kcCoordinator = true,
        }, "kcCast")
      end
    end
  end

  local function ensureStageCast(world)
    if markerExists(world, "kcCast") then return end
    local rnd  = seededRng(contestSeed())
    local used = {}

    local coordinators = drawCoordinators(rnd, used)
    for i, cell in ipairs(STAGE_COORD_CELLS) do
      local sprite = coordinators[i]
      if sprite then
        spawnMarked(STAGE_DEF.id, {
          name = ("KC_COORD_%d"):format(i), sprite = sprite,
          x = cell.x, y = cell.y, movement = FACE_DOWN,
          -- picks the competitor line pool rather than the spectator one
          kcCoordinator = true,
        }, "kcCast")
      end
    end

    -- Choose WHICH seats are filled. 10-15 of the 30 the developer
    -- marked out, so the hall is the same density each time but never
    -- the same shape.
    local pool = {}
    for k = 1, #STAGE_SEATS do pool[k] = STAGE_SEATS[k] end
    for k = #pool, 2, -1 do
      local m = rnd(k)
      pool[k], pool[m] = pool[m], pool[k]
    end
    local take = CROWD_MIN + rnd(CROWD_MAX - CROWD_MIN + 1) - 1
    local chosen = {}
    for k = 1, math.min(take, #pool) do chosen[k] = pool[k] end

    -- One pair sometimes sits together, in seats that are actually next
    -- to each other -- worked out from the seats CHOSEN this contest.
    local seatFor = {}
    if rnd(2) == 1 then
      local adj = adjacentPairs(chosen)
      if #adj > 0 then
        local slot = adj[rnd(#adj)]
        local pair = CAST_PAIRS[rnd(#CAST_PAIRS)]
        -- `used` matters, not just the seats: the coordinators were drawn
        -- FIRST and are already marked, so seating a pair without this
        -- check put the same character on stage and in the crowd at once.
        if pair and not used[pair[1]] and not used[pair[2]] then
          seatFor[slot[1]] = "SPRITE_" .. pair[1]
          seatFor[slot[2]] = "SPRITE_" .. pair[2]
          used[pair[1]], used[pair[2]] = true, true
        end
      end
    end
    for i, seat in ipairs(chosen) do
      local sprite = seatFor[i]
      if not sprite then
        -- The crowd is people only -- no Pokemon in the seats. Roughly a
        -- third of it is named characters (custom art or a gym leader),
        -- the rest ordinary trainers, so a famous face is a treat rather
        -- than the norm.
        local roll = rnd(10)
        local pool
        if i > CROWD_NAMED_UNTIL then
          -- the back of the room: ordinary trainers, with the occasional
          -- gym leader so it is not completely anonymous
          pool = (roll == 1) and CAST_GYM or CAST_FOLK
        else
          pool = (roll <= 2) and CAST_CUSTOM_CROWD
            or ((roll == 3) and CAST_CUSTOM_RIVAL
            or ((roll == 4) and CAST_GYM or CAST_FOLK))
        end
        local pick = drawFrom(pool, used, rnd) or drawFrom(CAST_FOLK, used, rnd)
        sprite = pick and ("SPRITE_" .. pick)
      end
      if sprite then
        spawnMarked(STAGE_DEF.id, {
          name = ("KC_AUD_%d"):format(i), sprite = sprite,
          x = seat.x, y = seat.y, movement = seat.face,
        }, "kcCast")
      end
    end
  end

  -- The walk-on.
  --
  -- queueScript cannot do this: it has exactly five verbs (start_battle,
  -- warp, text, setflag, clearflag -- WorldAPI.lua:376-415) and none of
  -- them moves anybody. The engine's own mover is World:beginMovement,
  -- which is what the script VM's `applymovement` ends up calling
  -- (World.lua:967), and object id 0 is the PLAYER (World.lua:3727). It
  -- freezes every other NPC for the duration and calls back when the
  -- walk finishes, which is exactly the Elite Four escort feel.
  --
  -- Movement bytes are cart constants (Movement.lua:13,186): step is
  -- 0x0c + direction, with down 0, up 1, left 2, right 3; 0x47 ends the
  -- stream. Written as literals rather than required, so the Gen 1 arm
  -- never pulls a Gen 2-only module in.
  local STEP_UP, STEP_RIGHT, STEP_END = 0x0d, 0x0f, 0x47

  -- 3,3 -> 4,1 goes UP FIRST on purpose: a coordinator is standing on
  -- 4,3, so stepping right out of the line-up would walk into them.
  -- Ending on the rightward step leaves the player facing 5,1, which is
  -- where the judge is.
  local STAGE_WALK = { STEP_UP, STEP_UP, STEP_RIGHT, STEP_END }

  -- ---------------------------------------------------------------
  -- The entrant, and the party while a contest is on.
  --
  -- The player picks ONE POKeMON at the desk and only that one is in the
  -- party until they come back. The rest are parked on a SAVE-LEVEL
  -- field, not a Lua local: arbitrary top-level save keys persist on both
  -- generations, so the stash travels with the save file. If the game is
  -- closed mid-contest the party is still in there and the next entry to
  -- the hall puts it back -- where a local would have been lost with the
  -- process and taken five POKeMON with it.
  local function partyOf(world)
    local save = world and world.game and world.game.save
    return save, (save and save.party) or {}
  end

  local function monLabel(game, mon)
    if not mon then return "?" end
    if mon.nickname and mon.nickname ~= "" then return mon.nickname end
    local rec = game and game.data and game.data.pokemon
      and game.data.pokemon[mon.species]
    return (rec and rec.name) or tostring(mon.species or "?")
  end

  local function stashParty(world, keep)
    local save, party = partyOf(world)
    if not (save and party[keep]) then return false end
    if save.kcPartyStash then return true end   -- already parked
    local full = {}
    for i, m in ipairs(party) do full[i] = m end
    save.kcPartyStash = full
    save.party = { party[keep] }
    return true
  end

  -- Put the party back. Safe to call any time: it is a no-op with no
  -- stash, so it can be wired to every map entry as a net rather than
  -- relying on one exit path being taken.
  local function restoreParty(world)
    local save = world and world.game and world.game.save
    if not (save and save.kcPartyStash) then return false end
    save.party = save.kcPartyStash
    save.kcPartyStash = nil
    return true
  end

  -- ---------------------------------------------------------------
  -- The appeal round, before the battle.
  --
  -- Gen 3 runs appeals as their own scene: each coordinator walks to the
  -- middle, sends the POKeMON out, the dex picture and cry play, and the
  -- crowd answers with hearts. Only after all of that does the judging
  -- proper begin. Doing it inside the battle -- which is how this mod
  -- did it -- meant the appeals were four text boxes over a battle
  -- background and the crowd may as well not have been there.
  --
  -- Every piece is an engine seam, verified rather than assumed:
  --   World:beginMovement(id, bytes, done)  walk anybody (World.lua:3826)
  --   World:showPokePic(index)              the dex picture (4037)
  --   World:playCry(index)                  the cry (7185)
  --   World:showEmote(4, id, frames)        heart bubble (6675; the
  --                                         emote order puts heart at 4)
  -- Runtime-spawned NPCs DO get an object index (addRuntimeObject
  -- assigns one), and objectEntity looks up `objectId - 1`, so an actor
  -- we spawned is addressed as def.index + 1.
  local HEART_EMOTE = 4
  -- Where a coordinator presents: the player's own mark, right beside the
  -- judge on 5,6. LANE_Y is the empty row they travel along -- the three
  -- of them stand shoulder to shoulder on y=8, so a straight run to the
  -- mark goes through a neighbour, and straight up from 5,8 walks into
  -- the judge. Out is up-across-up, back is the reverse.
  local CENTRE = { x = 4, y = 6 }
  local LANE_Y = 7

  -- What each coordinator brings out. Contest-appropriate and vanilla.
  local KC_PARTNERS = {
    "CLEFAIRY", "JIGGLYPUFF", "VULPIX", "ODDISH", "GROWLITHE", "PIKACHU",
    "MEOWTH", "PSYDUCK", "BELLSPROUT", "SEEL", "STARYU", "EEVEE",
    "MARILL", "HOPPIP", "SUNFLORA", "TOGEPI", "FLAAFFY", "SNUBBULL",
  }

  local function prettyName(sprite)
    local n = tostring(sprite):gsub("^SPRITE_KC_", ""):gsub("^SPRITE_", "")
    return (n:gsub("_", " "))
  end

  local function speciesIndexOf(name)
    local data = mod.game and mod.game.data
    local rec = data and data.pokemon and data.pokemon[name]
    return rec and rec.index
  end

  -- step bytes for a straight run: horizontal first, then vertical.
  -- 0x0c + dir (down 0, up 1, left 2, right 3), 0x47 ends (Movement.lua).
  -- vertFirst matters: the three coordinators stand SHOULDER TO SHOULDER
  -- on 4/5/6,8. Stepping sideways first walks straight into the neighbour,
  -- so they leave the line vertically and come back horizontally, and the
  -- lane they use is always clear.
  local function walkBytes(dx, dy, vertFirst)
    local out = {}
    local function horiz()
      for _ = 1, math.abs(dx) do out[#out + 1] = (dx > 0) and 0x0f or 0x0e end
    end
    local function vert()
      for _ = 1, math.abs(dy) do out[#out + 1] = (dy > 0) and 0x0c or 0x0d end
    end
    if vertFirst then vert() horiz() else horiz() vert() end
    out[#out + 1] = 0x47
    return out
  end

  -- up to the lane, across, then up to the mark (and the reverse home).
  local function legPath(fromX, fromY, toX, toY)
    local out = {}
    local function vert(n, dir)
      for _ = 1, n do out[#out + 1] = (dir > 0) and 0x0c or 0x0d end
    end
    local function horiz(n, dir)
      for _ = 1, n do out[#out + 1] = (dir > 0) and 0x0f or 0x0e end
    end
    vert(math.abs(LANE_Y - fromY), (LANE_Y > fromY) and 1 or -1)
    horiz(math.abs(toX - fromX), (toX > fromX) and 1 or -1)
    vert(math.abs(toY - LANE_Y), (toY > LANE_Y) and 1 or -1)
    out[#out + 1] = 0x47
    return out
  end

  local function objectIdOf(npc)
    local idx = npc and npc.def and npc.def.index
    return idx and (idx + 1)
  end

  -- Run a list of one-argument functions in order; each calls its `next`.
  local function runSteps(steps, done)
    local i = 0
    local function step()
      i = i + 1
      local fn = steps[i]
      if not fn then if done then done() end return end
      local ok, err = pcall(fn, step)
      if not ok then
        mod.log:warn("kc appeal step %d: %s", i, tostring(err))
        if done then done() end
      end
    end
    step()
  end

  local function castOnStage(world, wantCoordinator)
    local out = {}
    for _, npc in ipairs((world and world.npcs) or {}) do
      local d = npc.def
      if d and d.kcCast and ((d.kcCoordinator and true or false) == wantCoordinator) then
        out[#out + 1] = npc
      end
    end
    return out
  end

  -- ---------------------------------------------------------------
  -- Hearts over the crowd.
  --
  -- The engine's own emote is a SINGLE slot -- World:showEmote assigns
  -- self.emote outright (World.lua:6683) -- so asking for four in a loop
  -- just overwrites three times and one bubble draws. It also only ages
  -- in World:step, which does not run while a text box is up, so a
  -- bubble raised during dialogue hangs there until something else
  -- clears it. Both of those are exactly what showed up on device.
  --
  -- So the hearts are ours: our own list, our own clock (ticked in the
  -- core.update wrap, which runs regardless of text boxes), and drawing
  -- by handing each one to the ENGINE'S drawEmote in turn rather than
  -- blitting it here. That last part matters -- the emote goes through a
  -- daytime palette lookup and a GbcPalette pass, and blitting the sheet
  -- raw leaves the interior grey instead of white (World.lua:10345-10352
  -- calls that out as a bug they already had once).
  local kcHearts = {}

  -- A plain frame wait, so a step in the appeal can hold with nothing on
  -- screen. showText is the only other way to pause a chain, and it puts
  -- a box over the bottom third -- which is where half the crowd is.
  local kcWait = nil
  local function waitFrames(n, done) kcWait = { left = n or 60, done = done } end
  local function tickWait()
    if not kcWait then return end
    kcWait.left = kcWait.left - 1
    if kcWait.left > 0 then return end
    local done = kcWait.done
    kcWait = nil
    if done then pcall(done) end
  end

  -- What each coordinator scored in the appeal round. Filled on stage,
  -- read by the judging afterwards so the appeals actually COUNT --
  -- before this the battle re-rolled its own rival hearts and the whole
  -- scene on stage decided nothing.
  local appealHearts = {}

  local function popHearts(world, n)
    local crowd = castOnStage(world, false)
    kcHearts = {}
    if #crowd == 0 or (n or 0) <= 0 then return end
    -- spread across DISTINCT onlookers where there are enough of them, so
    -- the count is readable at a glance rather than stacking on one head
    local order, rnd = {}, seededRng(contestSeed() + n)
    for i = 1, #crowd do order[i] = crowd[i] end
    for i = #order, 2, -1 do
      local j = rnd(i)
      order[i], order[j] = order[j], order[i]
    end
    for i = 1, n do
      kcHearts[#kcHearts + 1] = {
        entity = order[((i - 1) % #order) + 1],
        delay  = (i - 1) * 6,   -- they pop in sequence, not all at once
        left   = 50,
      }
    end
  end

  local function tickHearts()
    if #kcHearts == 0 then return end
    local keep = {}
    for _, h in ipairs(kcHearts) do
      if h.delay > 0 then
        h.delay = h.delay - 1
        keep[#keep + 1] = h
      else
        h.left = h.left - 1
        if h.left > 0 then keep[#keep + 1] = h end
      end
    end
    kcHearts = keep
  end

  -- Stash-originals, never a sentinel: the World module table lives for
  -- the whole process, so an `if wrapped then return end` guard would
  -- keep a stale closure alive across a mod reload.
  do
    local okW, World = pcall(require, "src.world.gen2.World")
    if okW and type(World) == "table" and World.drawEmote then
      World._kcOriginals = World._kcOriginals or { drawEmote = World.drawEmote }
      local baseDrawEmote = World._kcOriginals.drawEmote
      World.drawEmote = function(world, s, billboard)
        local heart = world and world.emoteImages and world.emoteImages.heart
        if heart and #kcHearts > 0 then
          local saved = world.emote
          for _, h in ipairs(kcHearts) do
            if h.delay <= 0 and h.entity then
              world.emote = { image = heart, entity = h.entity, left = 1 }
              baseDrawEmote(world, s, billboard)
            end
          end
          world.emote = saved
        end
        return baseDrawEmote(world, s, billboard)
      end
    end
  end

  -- One coordinator's appeal: walk in, send out, dex picture + cry, and
  -- the crowd answers. Returns a list of steps for runSteps.
  local function appealSteps(world, npc, n)
    local sprite = npc.def and npc.def.sprite
    local who = prettyName(sprite)
    -- the partner is seeded off the contest too, so a given entrant
    -- brings the same POKeMON every time you meet that line-up
    local rnd = seededRng(contestSeed() + n * 17)
    local species = KC_PARTNERS[rnd(#KC_PARTNERS)]
    local index = speciesIndexOf(species)
    local sx, sy = npc.cellX or CENTRE.x, npc.cellY or CENTRE.y
    local id = objectIdOf(npc)
    return {
      function(next_)
        if not id then return next_() end
        world:beginMovement(id, legPath(sx, sy, CENTRE.x, CENTRE.y), next_)
      end,
      function(next_)
        -- Face the audience to present. Arriving at the mark means
        -- walking UP, so without this they announce with their back
        -- to the room.
        if id then pcall(world.turnObject, world, id, "down") end
        -- 18 columns, 2 rows. `who` is a sprite-derived name, so it gets
        -- the line to itself and the species goes on the row below.
        world:showText(("Entry No. %d!\n%s"):format(n, who), next_)
      end,
      function(next_)
        if index then
          world:showPokePic(index)
          world:playCry(index)
        end
        world:showText(("%s's\n%s!"):format(who, species), next_)
      end,
      function(next_)
        -- The crowd answers with the APPEAL SCORE, one heart each. It
        -- was a hardcoded four before, which said nothing about how the
        -- appeal actually went -- and only one ever drew, because the
        -- engine emote is a single slot. 2..6 is the existing rival
        -- band, under the player's ceiling of 8, so the field can be beaten.
        world.pokePic = nil
        local hearts = rnd(5) + 1
        appealHearts[n] = hearts
        -- Ask the room FIRST, let the hearts answer, and only then read
        -- the score. The score line used to come before the hearts, so
        -- it told you the number and the crowd then mimed it.
        world:showText("Folks, what do\nyou think?", function()
          -- the box is DOWN by the time this runs, so the hearts have the
          -- whole room to themselves -- they were popping behind it
          -- before, and half of them were under the text.
          popHearts(world, hearts)
          waitFrames(70 + hearts * 12, function()
            world:showText(("%s scores\n%d hearts!"):format(who, hearts), next_)
          end)
        end)
      end,
      function(next_)
        if not id then return next_() end
        world:beginMovement(id, legPath(CENTRE.x, CENTRE.y, sx, sy), next_)
      end,
    }
  end

  -- Set on stage entry, cleared when the announcement actually starts.
  local introArmed = false

  -- The whole opening: the judge welcomes the room, all three
  -- coordinators appeal in turn, and only then is the player called up.
  -- The battle -- the actual judging -- starts after this, when the
  -- player talks to the judge.
  local function runStageIntro(world)
    local game = mod.game
    -- save.player.name, NOT game.player.name -- the latter is the world
    -- ENTITY (position, facing, sprite), which has no name, so the
    -- fallback fired every time and the MC announced "YOU".
    local sp = game and game.save and game.save.player
    local name = (sp and sp.name) or "YOU"
    local kind = tostring(pendingContest or "CONTEST")
    appealHearts = {}
    local steps = {
      function(next_) world:showText("Hello! Let's get\nstarted with this", next_) end,
      function(next_) world:showText(("NORMAL %s\nCONTEST!"):format(kind), next_) end,
      function(next_) world:showText("These are our\ncoordinators and", next_) end,
      function(next_) world:showText("their partners.", next_) end,
    }
    for n, npc in ipairs(castOnStage(world, true)) do
      for _, fn in ipairs(appealSteps(world, npc, n)) do
        steps[#steps + 1] = fn
      end
    end
    steps[#steps + 1] = function(next_)
      world:showText("And now.. our\nnext coordinator!", next_)
    end
    steps[#steps + 1] = function(next_)
      world:showText(("Please welcome\n%s!"):format(name), next_)
    end
    -- the player walks up to the mark, same as everyone else did
    steps[#steps + 1] = function(next_)
      local ok = pcall(function()
        world:beginMovement(0, STAGE_WALK, next_)
      end)
      if not ok then
        mod.log:warn("kc walk-on failed; warping instead")
        mod.world:warpTo(STAGE_DEF.id, STAGE_MARK.x, STAGE_MARK.y, "right")
        next_()
      end
    end
    steps[#steps + 1] = function(next_)
      pcall(world.turnObject, world, 0, "down")
      -- The player presents like the other three: dex picture, cry, and
      -- the POKeMON they actually picked at the desk.
      local mine = (game.save and game.save.party and game.save.party[1])
      local myName = monLabel(game, mine)
      local myIndex = mine and speciesIndexOf(mine.species)
      if myIndex then
        world:showPokePic(myIndex)
        world:playCry(myIndex)
      end
      world:showText(("%s\nand %s!"):format(name, myName), function()
        -- and the room answers for the player too, the same beat the
        -- other three got: ask, hearts, then the number.
        world:showText("Folks, what do\nyou think?", function()
          world.pokePic = nil
          local mineRnd = seededRng(contestSeed() + 991)
          local myHearts = mineRnd(5) + 1
          popHearts(world, myHearts)
          waitFrames(70 + myHearts * 12, function()
            world:showText(("%s scores\n%d hearts!"):format(name, myHearts), next_)
          end)
        end)
      end)
    end
    -- ...then back to the line. The judging is not something the player
    -- walks over and asks for -- everyone has presented, so everyone
    -- lines up and faces the judge together, which is what makes it read
    -- as one contest rather than four separate errands.
    steps[#steps + 1] = function(next_)
      local ok = pcall(function()
        world:beginMovement(0, walkBytes(STAGE_LINEUP.x - STAGE_MARK.x,
                                        STAGE_LINEUP.y - STAGE_MARK.y, false), next_)
      end)
      if not ok then next_() end
    end
    steps[#steps + 1] = function(next_)
      -- everyone turns to the judge at once
      for _, npc in ipairs(castOnStage(world, true)) do
        local cid = objectIdOf(npc)
        if cid then pcall(world.turnObject, world, cid, "up") end
      end
      pcall(world.turnObject, world, 0, "up")
      world:showText("Now -- the\njudging!", next_)
    end
    steps[#steps + 1] = function()
      -- straight into the contest. stageJudge stays for anyone who
      -- reaches the stage some other way and talks to him.
      local kind2 = pendingContest
      if kind2 then
        pendingContest = nil
        runGoldContest(world, kind2)
      end
    end
    runSteps(steps)
  end


  -- Set when the judge takes an entry in the lobby and cleared when the
  -- contest actually starts; it is what the stage judge reads to know
  -- which of the five he is about to judge.
  local pendingContest

  -- ---------------------------------------------------------------
  -- The Goldenrod Contest Hall facade.
  --
  -- Hand-painted by the developer in the Content Editor a QUARTER BLOCK
  -- at a time, which is the entire reason this code exists. A quarter
  -- block edit cannot be named by a vanilla block id, so there is
  -- nothing a maps:patch could say: all fifteen blocks below are
  -- composed from tiles belonging to several different vanilla blocks
  -- each. Read back out of the editor project, never hand-typed.
  --
  -- Only NUMBERS are ours. Every tile id indexes the player's own
  -- extracted johto_modern sheet, which Assets.resolve finds in their
  -- cache (Assets.lua:36-54) -- no ROM art is redistributed, exactly as
  -- the halls already do it.
  --
  -- Why runtime and not map data: a map's `blocks` is a LIST, and lists
  -- replace WHOLESALE (Merge.lua:29-49). Patching Goldenrod's blocks
  -- would erase every other mod's edits to the city -- the same trap as
  -- writing a bare `objects` list. replaceBlock touches single cells and
  -- never enters the merge, so two mods can both build here.
  local KC_GOLDENROD_FACADE = {
    { bx = 16, by = 0, tiles = { 6, 6, 16, 17, 6, 6, 13, 14, 6, 6, 13, 14, 6, 6, 10, 11 }, coll = { 0x00, 0x07, 0x00, 0x07 } },
    { bx = 17, by = 0, tiles = { 17, 17, 17, 17, 14, 14, 14, 14, 14, 14, 14, 14, 11, 11, 11, 11 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 18, by = 0, tiles = { 17, 17, 17, 18, 14, 14, 14, 15, 14, 14, 14, 15, 11, 11, 11, 12 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 16, by = 1, tiles = { 5, 5, 26, 7, 5, 3, 26, 7, 90, 90, 26, 7, 74, 89, 26, 7 }, coll = { 0x00, 0x07, 0x07, 0x07 } },
    { bx = 17, by = 1, tiles = { 7, 7, 7, 7, 7, 7, 7, 7, 38, 38, 7, 7, 7, 7, 7, 7 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 18, by = 1, tiles = { 7, 7, 7, 28, 7, 7, 7, 28, 38, 38, 7, 28, 7, 7, 7, 28 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 16, by = 2, tiles = { 5, 5, 26, 7, 5, 3, 1, 2, 3, 5, 3, 5, 5, 5, 5, 5 }, coll = { 0x00, 0x07, 0x00, 0x00 } },
    { bx = 17, by = 2, tiles = { 7, 7, 55, 56, 2, 2, 57, 58, 3, 5, 3, 5, 5, 5, 5, 5 }, coll = { 0x07, 0x71, 0x00, 0x00 } },
    { bx = 18, by = 2, tiles = { 7, 7, 7, 28, 2, 2, 2, 22, 78, 79, 5, 5, 94, 95, 5, 5 }, coll = { 0x07, 0x07, 0x07, 0x00 } },
    { bx = 16, by = 3, tiles = { 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 }, coll = { 0x00, 0x00, 0x00, 0x00 } },
    { bx = 17, by = 3, tiles = { 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 }, coll = { 0x00, 0x00, 0x00, 0x00 } },
    { bx = 18, by = 3, tiles = { 5, 5, 5, 5, 5, 5, 5, 5, 16, 17, 17, 18, 10, 11, 11, 12 }, coll = { 0x00, 0x00, 0x07, 0x07 } },
    { bx = 18, by = 4, tiles = { 26, 27, 27, 28, 1, 2, 2, 22, 5, 5, 5, 5, 5, 3, 5, 5 }, coll = { 0x07, 0x07, 0x00, 0x00 } },
    { bx = 18, by = 5, tiles = { 5, 5, 3, 5, 5, 5, 5, 5, 90, 90, 90, 90, 89, 89, 89, 89 }, coll = { 0x00, 0x00, 0x07, 0x07 } },
    { bx = 19, by = 5, tiles = { 5, 5, 6, 6, 5, 5, 6, 6, 90, 90, 90, 90, 89, 89, 89, 89 }, coll = { 0x00, 0x00, 0x07, 0x07 } },
  }

  -- The tileset GAINS our blocks and never loses one: vanilla ids 0..127
  -- keep their meaning, so another mod's Goldenrod block edits still
  -- resolve to the art they meant.
  --
  -- The base offset is READ, never assumed to be 128. If another mod
  -- appended first, #blocks is already past it and a hardcoded 128 would
  -- point our placements at their tiles.
  local facadeBase = nil
  local function ensureGoldenrodFacade()
    local data = mod.game and mod.game.data
    local tsets = data and (data.gen2Tilesets or data.tilesets)
    local ts = tsets and tsets.TILESET_JOHTO_MODERN
    -- gen2Tilesets is populated at GAME construction (Game2.lua:949),
    -- which happens AFTER mods load. 0.16.0 read tileset data at load
    -- time, got nothing, and shipped grey rooms; map.entered is late
    -- enough that the table is really there.
    if not (ts and ts.blocks) then
      mod.log:warn("kc facade: johto_modern tileset unavailable")
      return
    end
    -- Check the blocks are STILL THERE rather than trusting a flag.
    -- game.data is rebuilt when a new Game is constructed (quit to menu,
    -- load a save), which re-reads tilesets.lua from disk WITHOUT our
    -- appended blocks -- while this closure survives, because module
    -- tables live for the whole process. A one-shot `if not facadeBase`
    -- then skipped the re-append and left replaceBlock pointing at block
    -- ids that no longer resolve; TileRenderer draws nothing for a nil
    -- block, so the building came back as holes in the street.
    if not (facadeBase and ts.blocks[facadeBase + 1] == KC_GOLDENROD_FACADE[1].tiles) then
      facadeBase = #ts.blocks
      ts.collision = ts.collision or {}
      for i, e in ipairs(KC_GOLDENROD_FACADE) do
        -- blocks are addressed id+1 (BorderFill.lua:79), so entry i is
        -- block id facadeBase + i - 1.
        ts.blocks[facadeBase + i] = e.tiles
        ts.collision[facadeBase + i] = e.coll
      end
    end
    -- World:restoreBlocks undoes every replaceBlock on EVERY map load
    -- (World.lua:5513) because the cart refills the block buffer from
    -- ROM -- which is why a cut tree is standing again next visit. A
    -- building is not a cut tree: re-stamp on each entry or it appears
    -- once and is gone for the rest of the session.
    for i, e in ipairs(KC_GOLDENROD_FACADE) do
      mod.world:replaceBlock(e.bx, e.by, facadeBase + i - 1)
    end
  end

  mod.events:on("map.entered", function(ev)
    local ok, err = pcall(function()
      local mapId = ev and ev.mapId
      local world = mod.world:overworld()
      -- Give the party back the moment the player is anywhere but the
      -- stage. Deliberately not tied to one exit: a contest can end by
      -- winning, losing, walking out over the carpet, or a reload, and
      -- only this catches all four. No-op when nothing is stashed.
      if not (STAGE_DEF and mapId == STAGE_DEF.id) then
        pcall(restoreParty, world)
      end
      if mapId == KCG.map then
        ensureGoldenrodFacade()
        -- The street attendant is GONE. She existed to walk the player in
        -- when the hall had no building; now it has a door at 35,4 and an
        -- NPC standing outside offering the same thing is just clutter.
        -- ensureGoldenrodAttendant is left defined but unused rather than
        -- deleted, because the Gen 1 arm still has its own attendant and
        -- ripping the shared helper out would touch that too.
      elseif mapId == HALL then
        ensureRoomActors(world, HALL_DEF)
        ensureLobbyQueue(world)
      elseif STAGE_DEF and mapId == STAGE_DEF.id then
        ensureRoomActors(world, STAGE_DEF)
        ensureStageCast(world)
        -- Only announce a player who is actually competing. Wandering in
        -- off the carpet must not call somebody to the stage.
        --
        -- ARMED, not run. map.entered fires while the warp's fade chain is
        -- still on screen, so calling the intro here put the announcement
        -- up over a blank white screen -- the player heard their name
        -- before the room existed. The core.update watcher below waits for
        -- the fade to finish and fires it then.
        if pendingContest then introArmed = true end
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

  -- Wait for the warp to finish before speaking.
  --
  -- There is no "fade complete" event -- the engine emits map.entered and
  -- player.warped, both of which land DURING the transition. What does say
  -- so is World:busy(), which stays true for the whole map-setup chain
  -- because `mapSetup ~= nil` (World.lua:1429-1435); the cart runs the
  -- load in the middle of that script with a fade on each side.
  --
  -- core.update is the only per-frame hook a mod gets
  -- (PlatformHooks.lua:11). Always call through, and only ever peek at
  -- state afterwards.
  mod.hooks:wrap("core.update", function(next_, game, dt)
    local r = next_(game, dt)
    -- Our own clock. The engine ages its emote only in World:step,
    -- which does not run while dialogue is up -- which is exactly when
    -- appeal hearts are on screen. Without this NOTHING ticks: the
    -- staggered hearts never reach delay 0 so only the first ever
    -- draws, and it never expires either. Both device symptoms were
    -- this one missing line, lost when an earlier edit threw on a
    -- later assertion and never wrote the file.
    tickHearts()
    tickWait()
    if introArmed then
      local world = mod.world:overworld()
      -- Confirm the player is STILL on the stage. introArmed is set on
      -- entry and only cleared when the intro fires, so a warp landing
      -- during the fade would otherwise announce them by name in
      -- whichever room they ended up in -- and then walk them two
      -- squares up and one right from wherever that is.
      -- Disarm only on a map we can POSITIVELY see is not the stage. A
      -- nil `current()` mid-fade means "not known yet", not "elsewhere";
      -- treating it as elsewhere would clear the flag during the very
      -- transition this watcher exists to wait out, and the player would
      -- never be announced at all.
      local here = mod.world:current()
      local elsewhere = here and here.mapId and STAGE_DEF
        and here.mapId ~= STAGE_DEF.id
      if elsewhere then
        introArmed = false
      elseif world and not world:busy() then
        introArmed = false
        local ok, err = pcall(runStageIntro, world)
        if not ok then mod.log:warn("kc stage intro: %s", tostring(err)) end
      end
    end
    return r
  end)

  -- The door the developer painted at cell 35,4. It carries COLL_DOOR
  -- (0x71) so it reads and behaves like every other Goldenrod door, but
  -- a 0x71 cell only WARPS if the map has a warp record on it, and
  -- adding one would mean patching Goldenrod's `warps` -- another LIST,
  -- another wholesale replace over every other mod's warps. So the step
  -- onto the tile is the trigger instead, and no map data is touched.
  --
  -- The cell is checked exactly, not by collision byte: 0x71 appears on
  -- every door in the city and a byte test would fire on all of them.
  local DOOR_X, DOOR_Y = 35, 4
  mod.events:on("world.stepped", function(ev)
    if not (ev and ev.mapId == KCG.map) then return end
    if ev.x ~= DOOR_X or ev.y ~= DOOR_Y then return end
    local ok, err = pcall(enterHall, mod.world:overworld())
    if not ok then mod.log:warn("kc door: %s", tostring(err)) end
  end)

  -- THE CARPET IS THE EXIT.
  --
  -- Its cells keep their vanilla warp collision, so stepping on one makes
  -- the engine look up this map's `warps` list. A Gen 2 warp record names a
  -- destination MAP and a warp NUMBER on it, though -- it cannot name a
  -- cell -- and nothing in Goldenrod warps into a hall that is not a real
  -- building. So the record points somewhere safe and this hook rewrites
  -- the landing spot to the exact cell (warp.destination,
  -- gen2/World.lua:9181): out of the lobby is beside the attendant who let
  -- you in, out of the stage is back into the lobby.
  --
  -- Failure mode is deliberately mild: if the hook never runs, the raw
  -- record still lands the player in Goldenrod (or the lobby) rather than
  -- stranding them.
  mod.hooks:wrap("warp.destination", function(next_, warped, mapId, x, y, ctx)
    local from = ctx and ctx.warp and ctx.warp.destMap
    local here = mod.world:current()
    local hereId = here and here.mapId
    if hereId == HALL then
      -- Land on the pavement BELOW the door, never on the door itself.
      -- hallReturn is where the player stood when they came in, and
      -- since the entrance is now a door tile that is the door -- so
      -- returning it verbatim put the player back on the trigger. The
      -- y+1 square was always the intended landing spot; it was just
      -- unreachable while hallReturn was non-nil.
      local back = hallReturn
      local bx = (back and back.x) or entranceCell.x
      local by = ((back and back.y) or entranceCell.y) + 1
      return (back and back.mapId) or KCG.map, bx, by
    elseif STAGE_DEF and hereId == STAGE_DEF.id then
      -- The carpet is the ONLY way off the stage now, so this path has
      -- to do what leaveStage does. It did not, and a player who walked
      -- out instead of talking to the judge kept pendingContest set --
      -- so re-entering announced them by name again for a contest they
      -- had already abandoned, with the stale category still armed.
      pendingContest = nil
      introArmed = false
      return HALL, HALL_ARRIVAL_X, HALL_ARRIVAL_Y
    end
    return next_(warped, mapId, x, y, ctx)
  end)

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

  runGoldContest = function(world, kind)
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
    -- carries the stage appeal scores into the judging
    judge.kcAppealHearts = appealHearts
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
          -- The real party screen -- the one a trade, a TM or an item
          -- uses -- rather than a list of names in a text box.
          -- World:selectPartyMon pushes Gen2PartyMenu and hands back
          -- (index, mon), with nil for a cancel.
          local _, party = partyOf(world)
          if #party == 0 then
            world:showText("You have no\nPOKeMON to enter!")
            return
          end
          world:selectPartyMon("which", function(slot)
          slot = tonumber(slot) or 0
          if slot < 1 or slot > #party then
            world:showText("Take your time.\nThe stage waits.")
            return
          end
          if not stashParty(world, slot) then
            world:showText("KC error: party\nnot available")
            return
          end
          pendingContest = kind
          -- Advance the crowd seed BEFORE the warp, so map.entered draws
          -- a new audience for this contest. Reloading back into the same
          -- contest re-reads the same count and therefore reseats exactly
          -- the same crowd, which is the point of seeding it at all.
          if mod.save then
            mod.save:set("kcContestCount", contestCount() + 1)
          end
          -- The walk out is a WARP, not a scene script. Gold scene
          -- scripts that walk the player are what stranded Colosseum
          -- visitors in a void when one stayed armed; nothing here arms
          -- anything that outlives the trip.
          world:showText(
            "Then follow me\nto the stage!",
            function()
              stageReturn = mod.world:current()
              local ok, err = mod.world:warpTo(
                -- facing DOWN, so the player stands in the line looking at
                -- the room like the other three, not at the judge's back
                STAGE_DEF.id, STAGE_DEF.arrival.x, STAGE_DEF.arrival.y, "down")
              if not ok then
                pendingContest = nil
                mod.log:warn("contest stage warp failed: %s", tostring(err))
                world:showText("KC error: stage\nentrance failed")
              end
        end)
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

  -- Turn to face whoever is talking to you.
  --
  -- NPC:scriptFace sets the drawn facing unless `fixedFacing` is set
  -- (Npc.lua:334). The cast all use STANDING_UP/DOWN/LEFT/RIGHT, none of
  -- which is in FIXED_FACING_MOVE (Npc.lua:64), so they all turn. The
  -- seat facing they were spawned with is their RESTING pose, not a lock.
  local function faceThePlayer(world, npc)
    local p = world and world.player
    if not (p and npc and npc.scriptFace) then return end
    local dx = (p.cellX or 0) - (npc.cellX or 0)
    local dy = (p.cellY or 0) - (npc.cellY or 0)
    local dir
    if math.abs(dx) > math.abs(dy) then
      dir = (dx > 0) and "right" or "left"
    else
      dir = (dy > 0) and "down" or "up"
    end
    pcall(npc.scriptFace, npc, dir)
  end

  -- Lines.
  --
  -- KC_CAST_LINES is keyed by sprite id and is where PER-CHARACTER
  -- dialogue goes as it is written -- May should not sound like a
  -- spectator, and Larry should not sound like anyone. Until a character
  -- has its own entry it falls back to the pool line below, so a cast
  -- member is never silent and adding lines never needs code.
  --
  -- 18 columns, 2 rows, per page. check_dialogue.py enforces it.
  local KC_CAST_LINES = {
    -- ["SPRITE_KC_MAY"] = { "...", "..." },
  }
  local KC_LINES_COORD = {
    "My POKeMON has\nbeen practising.",
    "I have waited all\nweek for this.",
    "Good luck out\nthere!",
    "Do not smile too\nmuch. It shows.",
    "I am next. I\nthink. Maybe.",
  }
  local KC_LINES_CROWD = {
    "The hall is packed\ntoday!",
    "I came for the\nSHEEN, honestly.",
    "That last appeal\nwas something.",
    "Shh! It is\nstarting!",
    "I have a good\nfeeling about you.",
  }

  -- Stable per-actor pick: the same person says the same thing all
  -- contest rather than a new line every A press, but different people
  -- say different things.
  local function lineFor(npc)
    local def = npc and npc.def
    local sprite = def and def.sprite
    -- `#own > 0` matters: KC_CAST_LINES is where per-character dialogue
    -- gets added, so a placeholder entry like ["SPRITE_KC_MAY"] = {} is
    -- the expected half-finished state. Without the length check `n % 0`
    -- is nan, the index returns nil, and showText(nil) throws inside
    -- talkTo's pcall -- surfacing as a generic "KC error" box rather
    -- than pointing at the empty table.
    local own = sprite and KC_CAST_LINES[sprite]
    if own and #own > 0 then
      local n = 0
      for _ in tostring(def.name or ""):gmatch(".") do n = n + 1 end
      return own[(n % #own) + 1]
    end
    local pool = (def and def.kcCoordinator) and KC_LINES_COORD or KC_LINES_CROWD
    local sum = 0
    for c in tostring((def and def.name) or "?"):gmatch(".") do
      sum = sum + string.byte(c)
    end
    return pool[(sum % #pool) + 1]
  end

  local function talkCast(world, npc)
    world:showText(lineFor(npc))
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
      or (def.kcCast and talkCast)
    )
    if not handler then
      if baseTalk then return baseTalk(world, npc) end
      return nil
    end
    -- Turn BEFORE the box opens, so the sprite is already looking at the
    -- player on the frame the text appears rather than after it closes.
    faceThePlayer(world, npc)
    local ok, err = pcall(handler, world, npc)
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
  local VERSION = "0.28.0"
  mod.exports.version = VERSION
  mod.exports.owns = {
    trainers = { "OPP_KC_JUDGE" },
    maps = { "KC_CONTEST_HALL", "KC_JOHTO_CONTEST_HALL",
             "KC_ECRUTEAK_CONTEST_HALL" },
    -- Ecruteak still borrows the vanilla TILESET_TRADITIONAL_HOUSE and
    -- owns nothing; the two Goldenrod rooms own composed sheets whose
    -- IMAGE is the player's own cache file -- ours are the block numbers.
    tilesets = { "KC_HALL_TILES", "KC_GOLDENROD_LOBBY_TILES",
                 "KC_GOLDENROD_STAGE_TILES", "KC_ECRUTEAK_HALL_TILES" },
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
  -- load banner. NOT on game.ready: Game.lua emits that while "nothing is\n-- on the stack yet" and pushes the title screen immediately after, so a
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
