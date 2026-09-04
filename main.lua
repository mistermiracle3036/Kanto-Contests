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
-- Transcribed from pokeemerald by ChatGPT against work order
-- kanto_contests-gen3-move-data (reviewed at intake: 251/251 ids, every
-- row equal to the source TSV, every text inside 18x2). The old
-- hand-recalled KC_CATEGORY had four wrong entries and 86 missing.
-- ------------------------------------------------------------------
-- Gen 3's contest data for every Gen 1-2 move, verbatim from pokeemerald
-- (src/data/contest_moves.h). Keys are the ENGINE's move ids. See
-- briefs/GEN3_CONTEST_RULES.md for what each field means at appeal time.
--   cat      COOL | BEAUTY | CUTE | SMART | TOUGH
--   effect   key into KC_CONTEST_EFFECTS
--   starter  combo-starter id this move grants (absent = not a starter)
--   after    starter ids this move completes a combo from (absent = none)
local KC_CONTEST_MOVES = {
  ABSORB = { cat = "SMART", effect = "STARTLE_PREV_MON", after = { "GROWTH" } },
  ACID = { cat = "SMART", effect = "BADLY_STARTLE_FRONT_MON" },
  ACID_ARMOR = { cat = "TOUGH", effect = "IMPROVE_CONDITION_PREVENT_NERVOUSNESS" },
  AEROBLAST = { cat = "COOL", effect = "AFFECTED_BY_PREV_APPEAL" },
  AGILITY = { cat = "COOL", effect = "NEXT_APPEAL_EARLIER", after = { "DOUBLE_TEAM" } },
  AMNESIA = { cat = "CUTE", effect = "IMPROVE_CONDITION_PREVENT_NERVOUSNESS" },
  ANCIENTPOWER = { cat = "TOUGH", effect = "IMPROVE_CONDITION_PREVENT_NERVOUSNESS" },
  ATTRACT = { cat = "CUTE", effect = "MAKE_FOLLOWING_MONS_NERVOUS" },
  AURORA_BEAM = { cat = "BEAUTY", effect = "STARTLE_MONS_SAME_TYPE_APPEAL" },
  BARRAGE = { cat = "TOUGH", effect = "BETTER_IF_SAME_TYPE" },
  BARRIER = { cat = "COOL", effect = "AVOID_STARTLE" },
  BATON_PASS = { cat = "CUTE", effect = "MAKE_FOLLOWING_MONS_NERVOUS" },
  BEAT_UP = { cat = "SMART", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS" },
  BELLY_DRUM = { cat = "CUTE", effect = "IMPROVE_CONDITION_PREVENT_NERVOUSNESS", starter = "BELLY_DRUM" },
  BIDE = { cat = "TOUGH", effect = "AVOID_STARTLE" },
  BIND = { cat = "TOUGH", effect = "DONT_EXCITE_AUDIENCE", after = { "VICE_GRIP" } },
  BITE = { cat = "TOUGH", effect = "BADLY_STARTLE_PREV_MONS", after = { "LEER", "SCARY_FACE" } },
  BLIZZARD = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", after = { "POWDER_SNOW", "HAIL" } },
  BODY_SLAM = { cat = "TOUGH", effect = "BADLY_STARTLE_FRONT_MON" },
  BONEMERANG = { cat = "TOUGH", effect = "HIGHLY_APPEALING", starter = "BONEMERANG", after = { "BONE_CLUB", "BONE_RUSH" } },
  BONE_CLUB = { cat = "TOUGH", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", starter = "BONE_CLUB", after = { "BONEMERANG", "BONE_RUSH" } },
  BONE_RUSH = { cat = "TOUGH", effect = "HIGHLY_APPEALING", starter = "BONE_RUSH", after = { "FOCUS_ENERGY", "BONE_CLUB", "BONEMERANG" } },
  BUBBLE = { cat = "CUTE", effect = "STARTLE_PREV_MONS", after = { "RAIN_DANCE" } },
  BUBBLEBEAM = { cat = "BEAUTY", effect = "BADLY_STARTLE_PREV_MONS", after = { "RAIN_DANCE" } },
  CHARM = { cat = "CUTE", effect = "STARTLE_MONS_SAME_TYPE_APPEAL", starter = "CHARM" },
  CLAMP = { cat = "TOUGH", effect = "DONT_EXCITE_AUDIENCE", after = { "RAIN_DANCE" } },
  COMET_PUNCH = { cat = "TOUGH", effect = "BETTER_IF_SAME_TYPE" },
  CONFUSE_RAY = { cat = "SMART", effect = "SCRAMBLE_NEXT_TURN_ORDER" },
  CONFUSION = { cat = "SMART", effect = "STARTLE_PREV_MON", starter = "CONFUSION", after = { "PSYCHIC", "KINESIS", "CALM_MIND" } },
  CONSTRICT = { cat = "TOUGH", effect = "STARTLE_PREV_MON" },
  CONVERSION = { cat = "BEAUTY", effect = "BETTER_IF_SAME_TYPE" },
  CONVERSION2 = { cat = "BEAUTY", effect = "BETTER_IF_SAME_TYPE" },
  COTTON_SPORE = { cat = "BEAUTY", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION" },
  COUNTER = { cat = "TOUGH", effect = "AVOID_STARTLE_ONCE", after = { "TAUNT" } },
  CRABHAMMER = { cat = "TOUGH", effect = "AFFECTED_BY_PREV_APPEAL", after = { "RAIN_DANCE", "SWORDS_DANCE" } },
  CROSS_CHOP = { cat = "COOL", effect = "AFFECTED_BY_PREV_APPEAL", after = { "FOCUS_ENERGY" } },
  CRUNCH = { cat = "TOUGH", effect = "BADLY_STARTLE_FRONT_MON", after = { "SCARY_FACE" } },
  CURSE = { cat = "TOUGH", effect = "NEXT_APPEAL_LATER", starter = "CURSE" },
  CUT = { cat = "COOL", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS", after = { "SWORDS_DANCE" } },
  DEFENSE_CURL = { cat = "CUTE", effect = "AVOID_STARTLE_ONCE", starter = "DEFENSE_CURL" },
  DESTINY_BOND = { cat = "SMART", effect = "GREAT_APPEAL_BUT_NO_MORE_MOVES", after = { "MEAN_LOOK", "CURSE", "ENDURE" } },
  DETECT = { cat = "COOL", effect = "AVOID_STARTLE_ONCE", after = { "TAUNT" } },
  DIG = { cat = "SMART", effect = "AVOID_STARTLE" },
  DISABLE = { cat = "SMART", effect = "MAKE_FOLLOWING_MONS_NERVOUS" },
  DIZZY_PUNCH = { cat = "COOL", effect = "BADLY_STARTLE_FRONT_MON" },
  DOUBLESLAP = { cat = "TOUGH", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", after = { "POUND" } },
  DOUBLE_EDGE = { cat = "TOUGH", effect = "USER_MORE_EASILY_STARTLED", after = { "FOCUS_ENERGY", "HARDEN" } },
  DOUBLE_KICK = { cat = "COOL", effect = "BETTER_IF_SAME_TYPE" },
  DOUBLE_TEAM = { cat = "COOL", effect = "AVOID_STARTLE_ONCE", starter = "DOUBLE_TEAM" },
  DRAGONBREATH = { cat = "COOL", effect = "BADLY_STARTLE_PREV_MONS", starter = "DRAGON_BREATH", after = { "DRAGON_RAGE", "DRAGON_DANCE" } },
  DRAGON_RAGE = { cat = "COOL", effect = "BETTER_WHEN_LATER", starter = "DRAGON_RAGE", after = { "DRAGON_BREATH", "DRAGON_DANCE" } },
  DREAM_EATER = { cat = "SMART", effect = "STARTLE_PREV_MONS", after = { "HYPNOSIS", "CALM_MIND" } },
  DRILL_PECK = { cat = "COOL", effect = "HIGHLY_APPEALING", after = { "PECK" } },
  DYNAMICPUNCH = { cat = "COOL", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", after = { "FOCUS_ENERGY", "MIND_READER" } },
  EARTHQUAKE = { cat = "TOUGH", effect = "BADLY_STARTLE_PREV_MONS", starter = "EARTHQUAKE" },
  EGG_BOMB = { cat = "TOUGH", effect = "HIGHLY_APPEALING", after = { "SOFT_BOILED" } },
  EMBER = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", after = { "SUNNY_DAY" } },
  ENCORE = { cat = "CUTE", effect = "MAKE_FOLLOWING_MONS_NERVOUS" },
  ENDURE = { cat = "TOUGH", effect = "AVOID_STARTLE_ONCE", starter = "ENDURE" },
  EXPLOSION = { cat = "BEAUTY", effect = "GREAT_APPEAL_BUT_NO_MORE_MOVES" },
  EXTREMESPEED = { cat = "COOL", effect = "NEXT_APPEAL_EARLIER" },
  FAINT_ATTACK = { cat = "SMART", effect = "BETTER_IF_FIRST", after = { "FAKE_OUT", "LEER", "POUND" } },
  FALSE_SWIPE = { cat = "COOL", effect = "BADLY_STARTLE_PREV_MONS", after = { "SWORDS_DANCE" } },
  FIRE_BLAST = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", after = { "SUNNY_DAY" } },
  FIRE_PUNCH = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", starter = "FIRE_PUNCH", after = { "SUNNY_DAY", "THUNDER_PUNCH", "ICE_PUNCH" } },
  FIRE_SPIN = { cat = "BEAUTY", effect = "DONT_EXCITE_AUDIENCE", after = { "SUNNY_DAY" } },
  FISSURE = { cat = "TOUGH", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS", after = { "EARTHQUAKE" } },
  FLAIL = { cat = "CUTE", effect = "BETTER_WHEN_LATER", after = { "ENDURE" } },
  FLAMETHROWER = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", after = { "SUNNY_DAY" } },
  FLAME_WHEEL = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", after = { "SUNNY_DAY" } },
  FLASH = { cat = "BEAUTY", effect = "SHIFT_JUDGE_ATTENTION" },
  FLY = { cat = "SMART", effect = "AVOID_STARTLE" },
  FOCUS_ENERGY = { cat = "COOL", effect = "BADLY_STARTLE_PREV_MONS", starter = "FOCUS_ENERGY" },
  FORESIGHT = { cat = "SMART", effect = "WORSEN_CONDITION_OF_PREV_MONS" },
  FRUSTRATION = { cat = "CUTE", effect = "EXCITE_AUDIENCE_IN_ANY_CONTEST" },
  FURY_ATTACK = { cat = "COOL", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", after = { "HORN_ATTACK", "PECK" } },
  FURY_CUTTER = { cat = "COOL", effect = "REPETITION_NOT_BORING", after = { "SWORDS_DANCE" } },
  FURY_SWIPES = { cat = "TOUGH", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", after = { "SCRATCH" } },
  FUTURE_SIGHT = { cat = "SMART", effect = "DONT_EXCITE_AUDIENCE", after = { "PSYCHIC", "KINESIS", "CONFUSION", "CALM_MIND" } },
  GIGA_DRAIN = { cat = "SMART", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", after = { "GROWTH" } },
  GLARE = { cat = "TOUGH", effect = "BADLY_STARTLE_PREV_MONS", after = { "LEER" } },
  GROWL = { cat = "CUTE", effect = "BETTER_IF_LAST", after = { "CHARM" } },
  GROWTH = { cat = "BEAUTY", effect = "IMPROVE_CONDITION_PREVENT_NERVOUSNESS", starter = "GROWTH" },
  GUILLOTINE = { cat = "COOL", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS", after = { "VICE_GRIP" } },
  GUST = { cat = "SMART", effect = "SCRAMBLE_NEXT_TURN_ORDER" },
  HARDEN = { cat = "TOUGH", effect = "AVOID_STARTLE_ONCE", starter = "HARDEN" },
  HAZE = { cat = "BEAUTY", effect = "WORSEN_CONDITION_OF_PREV_MONS" },
  HEADBUTT = { cat = "TOUGH", effect = "STARTLE_PREV_MON", after = { "FOCUS_ENERGY" } },
  HEAL_BELL = { cat = "BEAUTY", effect = "BETTER_IF_LAST" },
  HIDDEN_POWER = { cat = "SMART", effect = "REPETITION_NOT_BORING" },
  HI_JUMP_KICK = { cat = "COOL", effect = "USER_MORE_EASILY_STARTLED", after = { "MIND_READER" } },
  HORN_ATTACK = { cat = "COOL", effect = "HIGHLY_APPEALING", starter = "HORN_ATTACK", after = { "LEER" } },
  HORN_DRILL = { cat = "COOL", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS", after = { "HORN_ATTACK" } },
  HYDRO_PUMP = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", after = { "RAIN_DANCE" } },
  HYPER_BEAM = { cat = "COOL", effect = "JAMS_OTHERS_BUT_MISS_ONE_TURN" },
  HYPER_FANG = { cat = "COOL", effect = "BADLY_STARTLE_FRONT_MON" },
  HYPNOSIS = { cat = "SMART", effect = "BADLY_STARTLE_PREV_MONS", starter = "HYPNOSIS" },
  ICE_BEAM = { cat = "BEAUTY", effect = "STARTLE_MONS_SAME_TYPE_APPEAL" },
  ICE_PUNCH = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", starter = "ICE_PUNCH", after = { "THUNDER_PUNCH", "FIRE_PUNCH" } },
  ICY_WIND = { cat = "BEAUTY", effect = "BADLY_STARTLE_PREV_MONS" },
  IRON_TAIL = { cat = "COOL", effect = "BADLY_STARTLE_FRONT_MON" },
  JUMP_KICK = { cat = "COOL", effect = "USER_MORE_EASILY_STARTLED", after = { "MIND_READER" } },
  KARATE_CHOP = { cat = "TOUGH", effect = "AFFECTED_BY_PREV_APPEAL", after = { "FOCUS_ENERGY" } },
  KINESIS = { cat = "SMART", effect = "DONT_EXCITE_AUDIENCE", starter = "KINESIS", after = { "PSYCHIC", "CONFUSION" } },
  LEECH_LIFE = { cat = "SMART", effect = "STARTLE_PREV_MON" },
  LEECH_SEED = { cat = "SMART", effect = "STARTLE_PREV_MONS" },
  LEER = { cat = "COOL", effect = "DONT_EXCITE_AUDIENCE", starter = "LEER", after = { "RAGE", "SCARY_FACE" } },
  LICK = { cat = "TOUGH", effect = "BADLY_STARTLE_FRONT_MON" },
  LIGHT_SCREEN = { cat = "BEAUTY", effect = "AVOID_STARTLE", after = { "CALM_MIND" } },
  LOCK_ON = { cat = "SMART", effect = "DONT_EXCITE_AUDIENCE", starter = "LOCK_ON" },
  LOVELY_KISS = { cat = "BEAUTY", effect = "BADLY_STARTLE_PREV_MONS" },
  LOW_KICK = { cat = "TOUGH", effect = "BADLY_STARTLE_FRONT_MON" },
  MACH_PUNCH = { cat = "COOL", effect = "NEXT_APPEAL_EARLIER" },
  MAGNITUDE = { cat = "TOUGH", effect = "BETTER_WHEN_AUDIENCE_EXCITED" },
  MEAN_LOOK = { cat = "BEAUTY", effect = "MAKE_FOLLOWING_MONS_NERVOUS", starter = "MEAN_LOOK", after = { "CURSE" } },
  MEDITATE = { cat = "BEAUTY", effect = "IMPROVE_CONDITION_PREVENT_NERVOUSNESS", after = { "CALM_MIND" } },
  MEGAHORN = { cat = "COOL", effect = "BETTER_IF_SAME_TYPE" },
  MEGA_DRAIN = { cat = "SMART", effect = "BADLY_STARTLE_FRONT_MON", after = { "GROWTH" } },
  MEGA_KICK = { cat = "COOL", effect = "HIGHLY_APPEALING", after = { "FOCUS_ENERGY", "MIND_READER" } },
  MEGA_PUNCH = { cat = "TOUGH", effect = "HIGHLY_APPEALING", after = { "FOCUS_ENERGY", "MIND_READER" } },
  METAL_CLAW = { cat = "COOL", effect = "HIGHLY_APPEALING", after = { "METAL_SOUND" } },
  METRONOME = { cat = "CUTE", effect = "REPETITION_NOT_BORING" },
  MILK_DRINK = { cat = "CUTE", effect = "BETTER_IF_SAME_TYPE" },
  MIMIC = { cat = "CUTE", effect = "APPEAL_AS_GOOD_AS_PREV_ONE" },
  MIND_READER = { cat = "SMART", effect = "DONT_EXCITE_AUDIENCE", starter = "MIND_READER" },
  MINIMIZE = { cat = "CUTE", effect = "AVOID_STARTLE_ONCE" },
  MIRROR_COAT = { cat = "BEAUTY", effect = "AVOID_STARTLE_ONCE", after = { "TAUNT" } },
  MIRROR_MOVE = { cat = "SMART", effect = "APPEAL_AS_GOOD_AS_PREV_ONE" },
  MIST = { cat = "BEAUTY", effect = "AVOID_STARTLE" },
  MOONLIGHT = { cat = "BEAUTY", effect = "QUALITY_DEPENDS_ON_TIMING", after = { "SUNNY_DAY" } },
  MORNING_SUN = { cat = "BEAUTY", effect = "QUALITY_DEPENDS_ON_TIMING", after = { "SUNNY_DAY" } },
  MUD_SLAP = { cat = "CUTE", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", starter = "MUD_SLAP", after = { "SAND_ATTACK", "MUD_SPORT", "SANDSTORM" } },
  NIGHTMARE = { cat = "SMART", effect = "BADLY_STARTLE_PREV_MONS", after = { "HYPNOSIS" } },
  NIGHT_SHADE = { cat = "SMART", effect = "STARTLE_MONS_SAME_TYPE_APPEAL" },
  OCTAZOOKA = { cat = "TOUGH", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", after = { "RAIN_DANCE", "LOCK_ON" } },
  OUTRAGE = { cat = "COOL", effect = "JAMS_OTHERS_BUT_MISS_ONE_TURN" },
  PAIN_SPLIT = { cat = "SMART", effect = "BADLY_STARTLE_FRONT_MON", after = { "ENDURE" } },
  PAY_DAY = { cat = "SMART", effect = "BETTER_WHEN_AUDIENCE_EXCITED" },
  PECK = { cat = "COOL", effect = "HIGHLY_APPEALING", starter = "PECK" },
  PERISH_SONG = { cat = "BEAUTY", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS", after = { "MEAN_LOOK", "SING" } },
  PETAL_DANCE = { cat = "BEAUTY", effect = "JAMS_OTHERS_BUT_MISS_ONE_TURN", after = { "GROWTH" } },
  PIN_MISSILE = { cat = "COOL", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION" },
  POISONPOWDER = { cat = "SMART", effect = "WORSEN_CONDITION_OF_PREV_MONS", after = { "SWEET_SCENT" } },
  POISON_GAS = { cat = "SMART", effect = "WORSEN_CONDITION_OF_PREV_MONS" },
  POISON_STING = { cat = "SMART", effect = "STARTLE_PREV_MON" },
  POUND = { cat = "TOUGH", effect = "HIGHLY_APPEALING", starter = "POUND" },
  POWDER_SNOW = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", starter = "POWDER_SNOW", after = { "HAIL" } },
  PRESENT = { cat = "CUTE", effect = "REPETITION_NOT_BORING" },
  PROTECT = { cat = "CUTE", effect = "AVOID_STARTLE", after = { "HARDEN" } },
  PSYBEAM = { cat = "BEAUTY", effect = "SCRAMBLE_NEXT_TURN_ORDER", after = { "CALM_MIND" } },
  PSYCHIC_M = { cat = "SMART", effect = "BADLY_STARTLE_PREV_MONS", starter = "PSYCHIC", after = { "KINESIS", "CONFUSION" } },
  PSYCH_UP = { cat = "SMART", effect = "BETTER_IF_SAME_TYPE" },
  PSYWAVE = { cat = "SMART", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS", after = { "CALM_MIND" } },
  PURSUIT = { cat = "SMART", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS" },
  QUICK_ATTACK = { cat = "COOL", effect = "NEXT_APPEAL_EARLIER", after = { "DOUBLE_TEAM" } },
  RAGE = { cat = "COOL", effect = "REPETITION_NOT_BORING", starter = "RAGE" },
  RAIN_DANCE = { cat = "TOUGH", effect = "BETTER_WHEN_AUDIENCE_EXCITED", starter = "RAIN_DANCE" },
  RAPID_SPIN = { cat = "COOL", effect = "AVOID_STARTLE_ONCE" },
  RAZOR_LEAF = { cat = "COOL", effect = "AFFECTED_BY_PREV_APPEAL", after = { "GROWTH" } },
  RAZOR_WIND = { cat = "COOL", effect = "AFFECTED_BY_PREV_APPEAL" },
  RECOVER = { cat = "SMART", effect = "STARTLE_MONS_SAME_TYPE_APPEAL" },
  REFLECT = { cat = "SMART", effect = "AVOID_STARTLE", after = { "CALM_MIND" } },
  REST = { cat = "CUTE", effect = "AVOID_STARTLE_ONCE", starter = "REST", after = { "BELLY_DRUM", "CHARM", "YAWN" } },
  RETURN = { cat = "CUTE", effect = "EXCITE_AUDIENCE_IN_ANY_CONTEST" },
  REVERSAL = { cat = "COOL", effect = "BETTER_IF_LAST", after = { "ENDURE" } },
  ROAR = { cat = "COOL", effect = "SCRAMBLE_NEXT_TURN_ORDER" },
  ROCK_SLIDE = { cat = "TOUGH", effect = "BADLY_STARTLE_PREV_MONS", after = { "ROCK_THROW" } },
  ROCK_SMASH = { cat = "TOUGH", effect = "BETTER_WITH_GOOD_CONDITION" },
  ROCK_THROW = { cat = "TOUGH", effect = "BETTER_IF_SAME_TYPE", starter = "ROCK_THROW" },
  ROLLING_KICK = { cat = "COOL", effect = "BADLY_STARTLE_PREV_MONS" },
  ROLLOUT = { cat = "TOUGH", effect = "DONT_EXCITE_AUDIENCE", after = { "DEFENSE_CURL", "HARDEN" } },
  SACRED_FIRE = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", after = { "SUNNY_DAY" } },
  SAFEGUARD = { cat = "BEAUTY", effect = "AVOID_STARTLE" },
  SANDSTORM = { cat = "TOUGH", effect = "SCRAMBLE_NEXT_TURN_ORDER", starter = "SANDSTORM" },
  SAND_ATTACK = { cat = "CUTE", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", starter = "SAND_ATTACK", after = { "MUD_SLAP", "SANDSTORM" } },
  SCARY_FACE = { cat = "TOUGH", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", starter = "SCARY_FACE", after = { "RAGE", "LEER" } },
  SCRATCH = { cat = "TOUGH", effect = "HIGHLY_APPEALING", starter = "SCRATCH", after = { "LEER" } },
  SCREECH = { cat = "SMART", effect = "BADLY_STARTLE_PREV_MONS" },
  SEISMIC_TOSS = { cat = "TOUGH", effect = "STARTLE_MONS_SAME_TYPE_APPEAL", after = { "FAKE_OUT" } },
  SELFDESTRUCT = { cat = "BEAUTY", effect = "GREAT_APPEAL_BUT_NO_MORE_MOVES" },
  SHADOW_BALL = { cat = "SMART", effect = "SHIFT_JUDGE_ATTENTION" },
  SHARPEN = { cat = "CUTE", effect = "IMPROVE_CONDITION_PREVENT_NERVOUSNESS" },
  SING = { cat = "CUTE", effect = "MAKE_FOLLOWING_MONS_NERVOUS", starter = "SING" },
  SKETCH = { cat = "SMART", effect = "APPEAL_AS_GOOD_AS_PREV_ONE" },
  SKULL_BASH = { cat = "TOUGH", effect = "BADLY_STARTLE_FRONT_MON" },
  SKY_ATTACK = { cat = "COOL", effect = "AFFECTED_BY_PREV_APPEAL" },
  SLAM = { cat = "TOUGH", effect = "STARTLE_MONS_SAME_TYPE_APPEAL", after = { "POUND" } },
  SLASH = { cat = "COOL", effect = "AFFECTED_BY_PREV_APPEAL", after = { "SWORDS_DANCE", "SCRATCH" } },
  SLEEP_POWDER = { cat = "SMART", effect = "BADLY_STARTLE_PREV_MONS", after = { "SWEET_SCENT" } },
  SLEEP_TALK = { cat = "CUTE", effect = "REPETITION_NOT_BORING", after = { "REST" } },
  SLUDGE = { cat = "TOUGH", effect = "BADLY_STARTLE_FRONT_MON", starter = "SLUDGE", after = { "SLUDGE_BOMB" } },
  SLUDGE_BOMB = { cat = "TOUGH", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION", starter = "SLUDGE_BOMB", after = { "SLUDGE" } },
  SMOG = { cat = "TOUGH", effect = "BADLY_STARTLE_PREV_MONS", starter = "SMOG" },
  SMOKESCREEN = { cat = "SMART", effect = "SHIFT_JUDGE_ATTENTION", after = { "SMOG" } },
  SNORE = { cat = "CUTE", effect = "HIGHLY_APPEALING", after = { "REST" } },
  SOFTBOILED = { cat = "BEAUTY", effect = "HIGHLY_APPEALING", starter = "SOFT_BOILED" },
  SOLARBEAM = { cat = "COOL", effect = "HIGHLY_APPEALING", after = { "SUNNY_DAY", "GROWTH" } },
  SONICBOOM = { cat = "COOL", effect = "BETTER_IF_SAME_TYPE" },
  SPARK = { cat = "COOL", effect = "BADLY_STARTLE_FRONT_MON", after = { "CHARGE" } },
  SPIDER_WEB = { cat = "SMART", effect = "MAKE_FOLLOWING_MONS_NERVOUS", after = { "STRING_SHOT" } },
  SPIKES = { cat = "SMART", effect = "MAKE_FOLLOWING_MONS_NERVOUS" },
  SPIKE_CANNON = { cat = "COOL", effect = "STARTLE_MON_WITH_JUDGES_ATTENTION" },
  SPITE = { cat = "TOUGH", effect = "BETTER_WHEN_LATER", after = { "CURSE" } },
  SPLASH = { cat = "CUTE", effect = "BETTER_IF_LAST" },
  SPORE = { cat = "BEAUTY", effect = "BADLY_STARTLE_PREV_MONS" },
  STEEL_WING = { cat = "COOL", effect = "BETTER_IF_SAME_TYPE" },
  STOMP = { cat = "TOUGH", effect = "BADLY_STARTLE_FRONT_MON", after = { "LEER" } },
  STRENGTH = { cat = "TOUGH", effect = "STARTLE_MONS_SAME_TYPE_APPEAL" },
  STRING_SHOT = { cat = "SMART", effect = "STARTLE_PREV_MON", starter = "STRING_SHOT" },
  STRUGGLE = { cat = "COOL", effect = "HIGHLY_APPEALING" },
  STUN_SPORE = { cat = "SMART", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS", after = { "SWEET_SCENT" } },
  SUBMISSION = { cat = "COOL", effect = "USER_MORE_EASILY_STARTLED", after = { "MIND_READER" } },
  SUBSTITUTE = { cat = "SMART", effect = "AVOID_STARTLE_ONCE" },
  SUNNY_DAY = { cat = "BEAUTY", effect = "BETTER_WHEN_AUDIENCE_EXCITED", starter = "SUNNY_DAY" },
  SUPERSONIC = { cat = "SMART", effect = "SCRAMBLE_NEXT_TURN_ORDER" },
  SUPER_FANG = { cat = "TOUGH", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS", after = { "SCARY_FACE" } },
  SURF = { cat = "BEAUTY", effect = "AFFECTED_BY_PREV_APPEAL", starter = "SURF", after = { "RAIN_DANCE", "DIVE" } },
  SWAGGER = { cat = "CUTE", effect = "BETTER_IF_FIRST" },
  SWEET_KISS = { cat = "CUTE", effect = "MAKE_FOLLOWING_MONS_NERVOUS", after = { "CHARM" } },
  SWEET_SCENT = { cat = "CUTE", effect = "BADLY_STARTLE_PREV_MONS", starter = "SWEET_SCENT" },
  SWIFT = { cat = "COOL", effect = "BETTER_IF_FIRST" },
  SWORDS_DANCE = { cat = "BEAUTY", effect = "IMPROVE_CONDITION_PREVENT_NERVOUSNESS", starter = "SWORDS_DANCE" },
  SYNTHESIS = { cat = "SMART", effect = "QUALITY_DEPENDS_ON_TIMING", after = { "SUNNY_DAY" } },
  TACKLE = { cat = "TOUGH", effect = "HIGHLY_APPEALING", after = { "DEFENSE_CURL", "LEER", "HARDEN" } },
  TAIL_WHIP = { cat = "CUTE", effect = "BETTER_IF_LAST", after = { "CHARM" } },
  TAKE_DOWN = { cat = "TOUGH", effect = "USER_MORE_EASILY_STARTLED", after = { "FOCUS_ENERGY", "HARDEN" } },
  TELEPORT = { cat = "COOL", effect = "AVOID_STARTLE", after = { "DOUBLE_TEAM", "PSYCHIC", "KINESIS", "CONFUSION" } },
  THIEF = { cat = "TOUGH", effect = "APPEAL_AS_GOOD_AS_PREV_ONES" },
  THRASH = { cat = "TOUGH", effect = "JAMS_OTHERS_BUT_MISS_ONE_TURN", after = { "RAGE" } },
  THUNDER = { cat = "COOL", effect = "STARTLE_PREV_MONS", after = { "CHARGE", "RAIN_DANCE", "LOCK_ON" } },
  THUNDERBOLT = { cat = "COOL", effect = "HIGHLY_APPEALING", after = { "CHARGE" } },
  THUNDERPUNCH = { cat = "COOL", effect = "HIGHLY_APPEALING", starter = "THUNDER_PUNCH", after = { "CHARGE", "FIRE_PUNCH", "ICE_PUNCH" } },
  THUNDERSHOCK = { cat = "COOL", effect = "HIGHLY_APPEALING", after = { "CHARGE" } },
  THUNDER_WAVE = { cat = "COOL", effect = "BADLY_STARTLE_MONS_WITH_GOOD_APPEALS", after = { "CHARGE" } },
  TOXIC = { cat = "SMART", effect = "WORSEN_CONDITION_OF_PREV_MONS" },
  TRANSFORM = { cat = "SMART", effect = "REPETITION_NOT_BORING" },
  TRIPLE_KICK = { cat = "COOL", effect = "HIGHLY_APPEALING", after = { "FOCUS_ENERGY" } },
  TRI_ATTACK = { cat = "BEAUTY", effect = "STARTLE_PREV_MONS", after = { "LOCK_ON" } },
  TWINEEDLE = { cat = "COOL", effect = "STARTLE_PREV_MON" },
  TWISTER = { cat = "COOL", effect = "SCRAMBLE_NEXT_TURN_ORDER" },
  VICEGRIP = { cat = "TOUGH", effect = "HIGHLY_APPEALING", starter = "VICE_GRIP" },
  VINE_WHIP = { cat = "COOL", effect = "HIGHLY_APPEALING", after = { "GROWTH" } },
  VITAL_THROW = { cat = "COOL", effect = "NEXT_APPEAL_LATER", after = { "FAKE_OUT" } },
  WATERFALL = { cat = "TOUGH", effect = "BETTER_IF_LAST", after = { "RAIN_DANCE" } },
  WATER_GUN = { cat = "CUTE", effect = "HIGHLY_APPEALING", after = { "RAIN_DANCE", "WATER_SPORT", "MUD_SPORT" } },
  WHIRLPOOL = { cat = "BEAUTY", effect = "DONT_EXCITE_AUDIENCE", after = { "RAIN_DANCE" } },
  WHIRLWIND = { cat = "SMART", effect = "SCRAMBLE_NEXT_TURN_ORDER" },
  WING_ATTACK = { cat = "COOL", effect = "BETTER_IF_SAME_TYPE" },
  WITHDRAW = { cat = "CUTE", effect = "AVOID_STARTLE", after = { "RAIN_DANCE" } },
  WRAP = { cat = "TOUGH", effect = "DONT_EXCITE_AUDIENCE" },
  ZAP_CANNON = { cat = "COOL", effect = "HIGHLY_APPEALING", after = { "LOCK_ON" } },
}

-- appeal/jam are Gen 3 POINTS (tens); /10 is hearts. text is the Gen 3
-- description re-fitted to Gold's box: two lines, <= 18 characters each.
local KC_CONTEST_EFFECTS = {
  AFFECTED_BY_PREV_APPEAL = { appeal = 30, jam = 0, text = "Depends on appeal\nmade just before." },
  APPEAL_AS_GOOD_AS_PREV_ONE = { appeal = 10, jam = 0, text = "Matches appeal\nmade just before." },
  APPEAL_AS_GOOD_AS_PREV_ONES = { appeal = 10, jam = 0, text = "Matches the prior\nappeals together." },
  AVOID_STARTLE = { appeal = 10, jam = 0, text = "Avoids all\nrival startles." },
  AVOID_STARTLE_ONCE = { appeal = 20, jam = 0, text = "Avoids one\nrival startle." },
  BADLY_STARTLE_FRONT_MON = { appeal = 10, jam = 40, text = "Badly startles\none just before." },
  BADLY_STARTLE_MONS_WITH_GOOD_APPEALS = { appeal = 20, jam = 10, text = "Jams strong prior\nappeals badly." },
  BADLY_STARTLE_PREV_MONS = { appeal = 10, jam = 30, text = "Badly startles\nall earlier ones." },
  BETTER_IF_FIRST = { appeal = 20, jam = 0, text = "Works great when\nperformed first." },
  BETTER_IF_LAST = { appeal = 20, jam = 0, text = "Works great when\nperformed last." },
  BETTER_IF_SAME_TYPE = { appeal = 20, jam = 0, text = "Works well after\nthe same type." },
  BETTER_WHEN_AUDIENCE_EXCITED = { appeal = 10, jam = 0, text = "Works best when\nthe crowd is loud." },
  BETTER_WHEN_LATER = { appeal = 10, jam = 0, text = "Works better the\nlater it performs." },
  BETTER_WITH_GOOD_CONDITION = { appeal = 10, jam = 0, text = "Works well with\ngood condition." },
  DONT_EXCITE_AUDIENCE = { appeal = 30, jam = 0, text = "Stops the crowd\nfrom growing loud." },
  EXCITE_AUDIENCE_IN_ANY_CONTEST = { appeal = 10, jam = 0, text = "Excites the crowd\nin any CONTEST." },
  GREAT_APPEAL_BUT_NO_MORE_MOVES = { appeal = 80, jam = 0, text = "Great appeal, but\nno more appeals." },
  HIGHLY_APPEALING = { appeal = 40, jam = 0, text = "A highly\nappealing move." },
  IMPROVE_CONDITION_PREVENT_NERVOUSNESS = { appeal = 10, jam = 0, text = "Raises condition;\nprevents nerves." },
  JAMS_OTHERS_BUT_MISS_ONE_TURN = { appeal = 40, jam = 40, text = "Jams prior rivals;\nskips next appeal." },
  MAKE_FOLLOWING_MONS_NERVOUS = { appeal = 20, jam = 0, text = "Makes later\nentrants nervous." },
  NEXT_APPEAL_EARLIER = { appeal = 30, jam = 0, text = "Next appeal moves\nearlier in line." },
  NEXT_APPEAL_LATER = { appeal = 30, jam = 0, text = "Next appeal moves\nlater in line." },
  QUALITY_DEPENDS_ON_TIMING = { appeal = 10, jam = 0, text = "Appeal quality\nvaries by timing." },
  REPETITION_NOT_BORING = { appeal = 30, jam = 0, text = "Can repeat without\nboring the JUDGE." },
  SCRAMBLE_NEXT_TURN_ORDER = { appeal = 30, jam = 0, text = "Scrambles the\nnext turn's order." },
  SHIFT_JUDGE_ATTENTION = { appeal = 30, jam = 0, text = "Shifts the JUDGE's\nattention away." },
  STARTLE_MONS_SAME_TYPE_APPEAL = { appeal = 20, jam = 10, text = "Jams prior moves\nof the same type." },
  STARTLE_MON_WITH_JUDGES_ATTENTION = { appeal = 20, jam = 10, text = "Startles one with\nthe JUDGE's focus." },
  STARTLE_PREV_MON = { appeal = 20, jam = 30, text = "Startles the one\njust before user." },
  STARTLE_PREV_MONS = { appeal = 20, jam = 20, text = "Startles all who\nappealed earlier." },
  USER_MORE_EASILY_STARTLED = { appeal = 60, jam = 0, text = "User is startled\nmore easily." },
  WORSEN_CONDITION_OF_PREV_MONS = { appeal = 30, jam = 0, text = "Lowers condition\nof prior entrants." },
}

-- Kept so every existing reader (main.lua:1167, mod.exports.categories)
-- and any other mod keep working unchanged: move id -> category string.
local KC_CATEGORY = {}
for id, row in pairs(KC_CONTEST_MOVES) do KC_CATEGORY[id] = row.cat end

-- The four Gen 3 ranks. A mon's rank in a category is one above its wins
-- there (mon.contestWins[kind]), capped at MASTER -- the Gen 3 shape, on
-- the field Kanto Ribbons already reads, so no save migration. Rivals'
-- POKeMON come in at a level per rank (developer, 2026-09-01: "consistently
-- higher as you get to harder contests"); appeals ignore level, so this is
-- cosmetic except that Mon.new hands a higher-level mon a better moveset.
local KC_RANKS = { "NORMAL", "SUPER", "HYPER", "MASTER" }
local KC_RANK_LEVEL = { NORMAL = 15, SUPER = 25, HYPER = 35, MASTER = 45 }
-- the crowd's stage hearts for a rival, lo..hi, by rank
local KC_RANK_STAGE_HEARTS = {
  NORMAL = { 1, 4 }, SUPER = { 2, 6 }, HYPER = { 4, 7 }, MASTER = { 5, 8 },
}
-- Bulbapedia: one appeal heart is worth 20 round-1 points; a stage heart
-- is scored at the same rate so the two rounds weigh the same.
local KC_STAGE_HEART_POINTS = 20

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
    -- THE HALL'S RANK (0.34.41). Gen 3 gives each town's hall one rank --
    -- Verdanturf Normal, Fallarbor Super, Slateport Hyper, Lilycove
    -- Master -- and you climb by travelling, not by picking from a menu.
    -- So the rank is a property of the BUILDING here, and the desk no
    -- longer asks. Two halls exist, so two ranks are reachable; HYPER and
    -- MASTER are waiting on their own towns (see NOTES.md).
    rank = "NORMAL",
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
    rank = "SUPER",
    lobby = {
      id = "KC_ECRUTEAK_CONTEST_HALL",
      warps = {
        { x = 4, y = 7, destMap = "ECRUTEAK_CITY", destWarp = 1 },
        { x = 5, y = 7, destMap = "ECRUTEAK_CITY", destWarp = 1 },
      },
      label = "ECRUTEAK CONTEST HALL",
      song = "DANCE_THEATER",
      palette = "PALETTE_DAY",
      width = 5, height = 4,
      arrival = { x = 4, y = 7 },
      tiles = {
        id = "KC_ECRUTEAK_HALL_TILES",
        source = "TILESET_TRADITIONAL_HOUSE",
        variants = {
          gs = {
            image = "assets/generated/tilesets/traditional_house.png",
            imageWidth = 128, imageHeight = 128, tilesPerRow = 16,
            border = 0,
            tilePalettes = {
              1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6
            },
            blocks = {
              { 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 },
              { 35, 36, 35, 36, 62, 63, 62, 63, 62, 63, 62, 63, 24, 25, 24, 25 },
              { 78, 79, 78, 79, 94, 94, 94, 94, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 78, 79, 78, 79, 94, 94, 94, 94, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 69, 70, 69, 70, 85, 86, 85, 86, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 68, 69, 2, 3, 84, 85, 18, 19, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 69, 70, 68, 69, 85, 86, 84, 85, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 69, 70, 69, 70, 85, 86, 85, 86, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 68, 69, 69, 70, 84, 85, 85, 86, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 69, 70, 2, 3, 85, 86, 18, 19, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 69, 70, 69, 70, 85, 86, 85, 86, 4, 4, 4, 4, 20, 20, 20, 20 },
            },
            collision = {
              { 0x07, 0x07, 0x07, 0x07 },
              { 0x07, 0x07, 0x07, 0x07 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x70, 0x70 },
            },
          },
          crystal = {
            image = "assets/generated/tilesets/traditional_house.png",
            imageWidth = 128, imageHeight = 128, tilesPerRow = 16,
            border = 0,
            tilePalettes = {
              1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6
            },
            blocks = {
              { 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 },
              { 35, 36, 35, 36, 62, 63, 62, 63, 62, 63, 62, 63, 24, 25, 24, 25 },
              { 78, 79, 78, 79, 94, 94, 94, 94, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 78, 79, 78, 79, 94, 94, 94, 94, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 69, 70, 69, 70, 85, 86, 85, 86, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 68, 69, 2, 3, 84, 85, 18, 19, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 69, 70, 68, 69, 85, 86, 84, 85, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 69, 70, 69, 70, 85, 86, 85, 86, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 68, 69, 69, 70, 84, 85, 85, 86, 69, 70, 68, 69, 85, 86, 84, 85 },
              { 69, 70, 2, 3, 85, 86, 18, 19, 69, 70, 69, 70, 85, 86, 85, 86 },
              { 69, 70, 69, 70, 85, 86, 85, 86, 4, 4, 4, 4, 20, 20, 20, 20 },
            },
            collision = {
              { 0x07, 0x07, 0x07, 0x07 },
              { 0x07, 0x07, 0x07, 0x07 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x70, 0x70 },
            },
          },
        },
      },
      blocks = {
        1, 2, 2, 2, 3,
        4, 5, 5, 5, 6,
        7, 8, 9, 9, 6,
        10, 9, 11, 9, 6,
      },
      actors = {
        { name = "KC_HALL_JUDGE", marker = "kcHallJudge",
          sprite = "SPRITE_GENTLEMAN", x = 4, y = 1, movement = 6 },
        { name = "KC_HALL_VENDOR", marker = "kcHallVendor",
          sprite = "SPRITE_TEACHER", x = 1, y = 7, movement = 9 },
        { name = "KC_HALL_APPRAISER", marker = "kcHallAppraiser",
          sprite = "SPRITE_BEAUTY", x = 8, y = 7, movement = 8 },
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
          sprite = "SPRITE_TWIN", x = 6, y = 6, movement = 7 },
        { name = "KC_AUD_4", marker = "kcAudience",
          sprite = "SPRITE_ROCKER", x = 7, y = 5, movement = 7 },
      },
    },
    stage = {
      id = "KC_ECRUTEAK_CONTEST_STAGE",
      warps = {
        { x = 4, y = 13, destMap = "KC_ECRUTEAK_CONTEST_HALL", destWarp = 1 },
        { x = 5, y = 13, destMap = "KC_ECRUTEAK_CONTEST_HALL", destWarp = 1 },
      },
      label = "ECRUTEAK STAGE",
      song = "DANCE_THEATER",
      palette = "PALETTE_DAY",
      width = 5, height = 7,
      arrival = { x = 3, y = 8 },
      tiles = {
        id = "KC_ECRUTEAK_STAGE_TILES",
        source = "TILESET_TRADITIONAL_HOUSE",
        variants = {
          gs = {
            image = "assets/generated/tilesets/traditional_house.png",
            imageWidth = 128, imageHeight = 128, tilesPerRow = 16,
            border = 0,
            tilePalettes = {
              1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6
            },
            blocks = {
              { 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 },
              { 78, 79, 78, 79, 94, 94, 94, 94, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 35, 36, 80, 80, 41, 42, 80, 80, 66, 67, 80, 80, 51, 52 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 35, 36, 80, 80, 41, 42, 80, 80, 66, 67, 80, 80, 51, 52, 80, 80 },
              { 80, 80, 66, 67, 80, 80, 51, 52, 80, 80, 66, 67, 80, 80, 51, 52 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 66, 67, 80, 80, 51, 52, 80, 80, 66, 67, 80, 80, 51, 52, 80, 80 },
              { 80, 80, 66, 67, 80, 80, 51, 52, 80, 80, 35, 36, 80, 80, 41, 42 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 15, 15, 95, 95 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 15, 15, 15, 15 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 95, 95, 15, 15 },
              { 66, 67, 80, 80, 51, 52, 80, 80, 35, 36, 80, 80, 41, 42, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 4, 4, 4, 4, 20, 20, 20, 20 },
            },
            collision = {
              { 0x07, 0x07, 0x07, 0x07 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x07, 0x00, 0x07 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x07, 0x00, 0x07, 0x00 },
              { 0x00, 0x07, 0x00, 0x07 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x07, 0x00, 0x07, 0x00 },
              { 0x00, 0x07, 0x00, 0x07 },
              { 0x00, 0x00, 0x07, 0x00 },
              { 0x00, 0x00, 0x07, 0x07 },
              { 0x00, 0x00, 0x00, 0x07 },
              { 0x07, 0x00, 0x07, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x70, 0x70 },
            },
          },
          crystal = {
            image = "assets/generated/tilesets/traditional_house.png",
            imageWidth = 128, imageHeight = 128, tilesPerRow = 16,
            border = 0,
            tilePalettes = {
              1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 6, 4, 4, 2, 1, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 4, 4, 2, 6, 1, 1, 6, 6, 1, 1, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 6, 6, 6, 1, 1, 6, 6, 6, 6, 2, 1, 1, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 4, 6, 6, 6, 6, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 4, 6
            },
            blocks = {
              { 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 },
              { 78, 79, 78, 79, 94, 94, 94, 94, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 35, 36, 80, 80, 41, 42, 80, 80, 66, 67, 80, 80, 51, 52 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 15, 15, 15, 15, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 35, 36, 80, 80, 41, 42, 80, 80, 66, 67, 80, 80, 51, 52, 80, 80 },
              { 80, 80, 66, 67, 80, 80, 51, 52, 80, 80, 66, 67, 80, 80, 51, 52 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 66, 67, 80, 80, 51, 52, 80, 80, 66, 67, 80, 80, 51, 52, 80, 80 },
              { 80, 80, 66, 67, 80, 80, 51, 52, 80, 80, 35, 36, 80, 80, 41, 42 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 15, 15, 95, 95 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 15, 15, 15, 15 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 95, 95, 15, 15 },
              { 66, 67, 80, 80, 51, 52, 80, 80, 35, 36, 80, 80, 41, 42, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80 },
              { 80, 80, 80, 80, 80, 80, 80, 80, 4, 4, 4, 4, 20, 20, 20, 20 },
            },
            collision = {
              { 0x07, 0x07, 0x07, 0x07 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x07, 0x00, 0x07 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x07, 0x07, 0x00, 0x00 },
              { 0x07, 0x00, 0x07, 0x00 },
              { 0x00, 0x07, 0x00, 0x07 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x07, 0x00, 0x07, 0x00 },
              { 0x00, 0x07, 0x00, 0x07 },
              { 0x00, 0x00, 0x07, 0x00 },
              { 0x00, 0x00, 0x07, 0x07 },
              { 0x00, 0x00, 0x00, 0x07 },
              { 0x07, 0x00, 0x07, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x00, 0x00 },
              { 0x00, 0x00, 0x70, 0x70 },
            },
          },
        },
      },
      blocks = {
        1, 1, 1, 1, 1,
        2, 2, 2, 2, 3,
        4, 5, 6, 7, 8,
        9, 10, 11, 12, 13,
        14, 15, 16, 17, 18,
        19, 20, 20, 20, 20,
        21, 21, 22, 21, 21,
      },

    },
  },
}

local function kcGold(mod, VERSION)
  -- The town this build's attendant leads into.
  -- WHICH HALL THE PLAYER IS IN (0.34.41).
  --
  -- These were constants pinned to one town, which is why a second hall
  -- could exist but never run a contest. They are variables now, re-aimed
  -- by useTown() whenever the player enters a hall's city, lobby or stage.
  -- Everything downstream still reads HALL / HALL_DEF / STAGE_DEF exactly
  -- as before, so the rest of the mod did not have to learn about towns.
  local TOWN = "GOLDENROD"
  local HALL_DEF = KC_HALLS[TOWN].lobby
  local STAGE_DEF = KC_HALLS[TOWN].stage      -- nil for a one-room town
  local HALL = HALL_DEF.id
  local HALL_ARRIVAL_X = HALL_DEF.arrival.x
  local HALL_ARRIVAL_Y = HALL_DEF.arrival.y

  -- Point the working set at one town. Cheap and idempotent, so it can be
  -- called on every map entry without a guard.
  local function useTown(key)
    local town = key and KC_HALLS[key]
    if not (town and town.lobby) then return false end
    TOWN = key
    HALL_DEF, STAGE_DEF = town.lobby, town.stage
    HALL = HALL_DEF.id
    HALL_ARRIVAL_X, HALL_ARRIVAL_Y = HALL_DEF.arrival.x, HALL_DEF.arrival.y
    return true
  end

  -- Which town a map belongs to: its lobby, its stage, or the city the
  -- hall stands in. Nil for anywhere else, and the caller leaves the
  -- current town alone rather than guessing.
  local CITY_OF = { GOLDENROD = "GOLDENROD_CITY", ECRUTEAK = "ECRUTEAK_CITY" }
  local function townOfMap(mapId)
    if not mapId then return nil end
    for key, town in pairs(KC_HALLS) do
      if (town.lobby and town.lobby.id == mapId)
        or (town.stage and town.stage.id == mapId)
        or CITY_OF[key] == mapId then
        return key
      end
    end
    return nil
  end

  -- The rank this hall runs. Named rather than read inline so the two
  -- readers (the desk and the coordinator draw) cannot drift.
  local function hallRank()
    return (KC_HALLS[TOWN] and KC_HALLS[TOWN].rank) or "NORMAL"
  end

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

  -- Grass in Ecruteak (0.34.36).
  --
  -- The developer painted a small patch beside the contest hall. Vanilla
  -- Ecruteak has no grass table at all -- it is a city -- so this is an
  -- addition, not an override, and `patch` folds one map into the kind's
  -- table rather than replacing it (Schemas.lua: the gen2 encounter
  -- registry is keyed by KIND, and a slot list is ORDERED, position =
  -- the roll, so it must be written whole).
  --
  -- The commons are lifted from the routes either side (38 and 37) so the
  -- patch reads as part of the neighbourhood, and the levels match them.
  -- The point of it is the three the developer asked for: the fire dog by
  -- day, MISDREAVUS at night -- normally Mt. Silver, i.e. after the
  -- Champion -- and EEVEE in the last slot, which is the 1% one.
  local function ecruteakGrass()
    local function slot(species, level) return { species = species, level = level } end
    local day = {
      slot("RATTATA", 14), slot("PIDGEY", 14), slot("GROWLITHE", 15),
      slot("GIRAFARIG", 15), slot("GROWLITHE", 16), slot("PIDGEOTTO", 16),
      slot("EEVEE", 15),
    }
    return {
      ECRUTEAK_CITY = {
        map = "ECRUTEAK_CITY",
        rates = { MORN = 25, DAY = 25, NITE = 25 },
        slots = {
          MORN = day, DAY = day,
          NITE = {
            slot("RATTATA", 14), slot("HOOTHOOT", 14), slot("MISDREAVUS", 15),
            slot("STANTLER", 15), slot("MISDREAVUS", 16), slot("NOCTOWL", 16),
            slot("EEVEE", 15),
          },
        },
      },
    }
  end
  do
    local ok, err = pcall(function()
      mod.content.encounters:patch("grass", ecruteakGrass())
    end)
    if not ok then mod.log:warn("kc ecruteak grass: %s", tostring(err)) end
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
    { "SPRITE_KC_DAWN", "dawn.png", "PAL_OW_PINK", 4 },
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
    { "SPRITE_KC_STADIUM_BOY", "stadium_boy.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_STADIUM_GIRL", "stadium_girl.png", "PAL_OW_RED", 0 },
    -- Alt COSTUMES. Registered so they exist for later, deliberately NOT
    -- in any cast pool: they are the same person in a different outfit,
    -- Each draws on its OWN OBJ palette -- green on PAL_OW_GREEN, blue on
    -- PAL_OW_BLUE, Dawn spring on PAL_OW_PINK and winter on RED -- so it reads
    -- in the overworld. The art is near-identical to the base (a costume
    -- differs by a few shading pixels at 16x16); the palette is what
    -- carries it.
    { "SPRITE_KC_DAWN_WINTER", "dawn_winter.png", "PAL_OW_RED", 0 },
    { "SPRITE_KC_BRENDAN_GREEN", "brendan_green.png", "PAL_OW_GREEN", 2 },
    { "SPRITE_KC_BRENDAN_BLUE", "brendan_blue.png", "PAL_OW_BLUE", 1 },
    { "SPRITE_KC_MAY_GREEN", "may_green.png", "PAL_OW_GREEN", 2 },
    { "SPRITE_KC_MAY_BLUE", "may_blue.png", "PAL_OW_BLUE", 1 },
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
  -- ------------------------------------------------------------------
  -- THE JUDGING is the Gen 3 appeal round, run by contest_engine.lua.
  -- The battle UI is the input device: the player's FIGHT pick is their
  -- appeal for the turn, then all four contestants resolve in turn order
  -- and the round is narrated as battle messages. The APPEAL meter is
  -- display only -- it drains by the player's hearts -- and the winner is
  -- decided at the end of turn 5 by round-1 + 2 x appeals.
  -- ------------------------------------------------------------------
  local KCE
  do
    local src = mod:read("contest_engine.lua")
    if src then
      local chunk, compileErr = load(src, "@" .. mod.path .. "/contest_engine.lua")
      if chunk then
        local ok, result = pcall(chunk)
        if ok then KCE = result
        else mod.log:error("contest_engine.lua failed to run: %s", tostring(result)) end
      else
        mod.log:error("contest_engine.lua did not compile: %s", tostring(compileErr))
      end
    else
      mod.log:error("contest_engine.lua missing from %s -- reinstall the mod", mod.path)
    end
  end
  -- ...and the screen that shows it: Gen 3's appeal-round layout, a screen
  -- of its own pushed over the world. The Gold battle wraps below stay --
  -- they are how a contest USED to be judged, and any battle carrying a
  -- kcContest trainer still goes through them -- but runGoldContest no
  -- longer starts one, so in play they are never reached.
  local KCS
  do
    local src = mod:read("contest_screen.lua")
    if src then
      local chunk, compileErr = load(src, "@" .. mod.path .. "/contest_screen.lua")
      if chunk then
        local ok, result = pcall(chunk)
        if ok then KCS = result
        else mod.log:error("contest_screen.lua failed to run: %s", tostring(result)) end
      else
        mod.log:error("contest_screen.lua did not compile: %s", tostring(compileErr))
      end
    else
      mod.log:error("contest_screen.lua missing from %s -- reinstall the mod", mod.path)
    end
  end

  -- Gen 3 condition is 0..30 in tens; the mod's contest stats are 0..100.
  local function kcConditionBand(mon, kind)
    local c = kcCondition(mon)
    local v = (c and c[KC_STAT_KEY[kind]]) or 0
    if v >= 90 then return 30 elseif v >= 60 then return 20
    elseif v >= 30 then return 10 end
    return 0
  end

  -- 18 columns: a rival's name shares a row with a verb, so clip it
  local function short(name)
    name = tostring(name or "?")
    if #name > 10 then name = name:sub(1, 10) end
    return name
  end

  local function meterMax(meter)
    return meter.maxHp or (meter.stats and meter.stats.hp) or meter.hp or 1
  end

  -- The four contestants and the engine state for one judging. `info` is
  -- what the stage hands over (the same fields runGoldContest puts on the
  -- judge trainer): kcRank, kcAppealHearts, kcRivals, kcPlayerName.
  -- Shared by the contest screen (the live path) and the battle host (the
  -- headless harness), so both judge the same field the same way.
  local function buildContestState(data, kind, info, entrant, rng)
    local rank = info.kcRank or "NORMAL"
    -- the stage's number when there was a stage (kcPlayerHearts, the same
    -- kcIntroHearts the crowd showed); computed here only for a headless
    -- judging with no stage before it
    local hearts = info.kcPlayerHearts or kcIntroHearts(entrant, kind, rank)
    local staged = info.kcAppealHearts or {}
    local rivals = info.kcRivals or {}
    local Mon = require("src.battle.gen2.Mon")
    local lvl = KC_RANK_LEVEL[rank] or KC_RANK_LEVEL.NORMAL
    local contestants = {
      { name = info.kcPlayerName or "YOU", mon = entrant,
        round1 = hearts * KC_STAGE_HEART_POINTS,
        condition = kcConditionBand(entrant, kind), ai = "player" },
    }
    for i = 1, 3 do
      local r = rivals[i] or KC_RIVALS[i]
      local mon = r.species and Mon.new(data, r.species, r.level or (lvl + rng(-2, 2)))
      if not mon then
        -- no species on record (headless tests, or a stage skipped): a
        -- plain mon with one ordinary move, so the round still runs
        mon = { moves = { { id = "POUND", pp = 20 } } }
      end
      local h = staged[i] or rng(2, 6)
      contestants[#contestants + 1] = {
        name = r.name, mon = mon, round1 = h * KC_STAGE_HEART_POINTS,
        condition = 0, ai = rank,
      }
    end
    local state = KCE.new({
      contest = kind, moves = KC_CONTEST_MOVES, effects = KC_CONTEST_EFFECTS,
      rng = rng, contestants = contestants,
    })
    return state, hearts
  end

  local function buildContest(b)
    local kind = tostring(inContest(b))
    local state, hearts = buildContestState(b.data, kind, b.trainer, b.player, b.rng)
    b.kcHearts = hearts
    b.kcState = state
    return state
  end

  local function applyGoldIntro(b)
    if not inContest(b) or b.kcIntroDone then return end
    b.kcIntroDone = true
    local entrant, meter = b.player, b.enemy
    if not (entrant and meter) then return end
    if not KCE then
      b:emit({ kind = "message", text = "KC error: no\ncontest engine" })
      return
    end
    local s = buildContest(b)
    local kind = s.contest
    b:emit({ kind = "message", text = "The stage scores\nare in!" })
    for i = 2, 4 do
      local c = s.c[i]
      b:emit({ kind = "message",
        text = ("%s:\n%d hearts."):format(short(c.name), c.round1 / KC_STAGE_HEART_POINTS) })
    end
    local hearts = b.kcHearts or 0
    local scarf = KC_SCARF_BY_CATEGORY[kcScarfCategory(entrant)]
    if scarf and scarf.category == kind then
      b:emit({ kind = "message", text = ("%s\nshines!"):format(scarf.name) })
    end
    if hearts <= 0 then
      b:emit({ kind = "message", text = "You: the crowd\nwas silent..." })
      return
    end
    b:emit({ kind = "message",
             text = ("You: %d %s!"):format(hearts, hearts == 1 and "heart" or "hearts") })
    local dmg = math.max(1, math.floor(
      meterMax(meter) * KC_INTRO_METER_FRACTION * hearts / 8))
    b:dealDamage(entrant, meter, dmg, { effectiveness = 10 })
  end

  -- one contestant's events -> battle messages (18 cols x 2 rows each)
  local function narrate(b, s, ci, moveId, ev)
    local me = short(s.c[ci].name)
    local def = b:moveDef(moveId)
    local mv = (def and def.name) or tostring(moveId or "?")
    for _, e in ipairs(ev) do
      local k, t = e.kind, nil
      if k == "used" then t = ("%s used\n%s!"):format(me, mv)
      elseif k == "skipped" then t = ("%s is\ncatching breath."):format(me)
      elseif k == "no_more" then t = ("%s has\nnothing left!"):format(me)
      elseif k == "attention" then t = ("The judge eyes\n%s."):format(me)
      elseif k == "combo" then t = "A combo!\nThe judge beams!"
      elseif k == "startled" then
        t = ("%s loses\n%d hearts!"):format(short(s.c[e.who].name), math.floor(e.jam / 10))
      elseif k == "missed" then t = "It fell flat."
      elseif k == "repeat" then t = ("Same move again.\n-%d hearts"):format(e.penalty / 10)
      elseif k == "too_nervous" then t = ("%s froze!\nToo nervous."):format(me)
      elseif k == "nervous" then t = ("%s looks\nnervous..."):format(short(s.c[e.who].name))
      elseif k == "attention_lost" then
        -- dialogue-ok: %s is short(), at most 10 glyphs -> 18
        t = ("The judge\nignores %s"):format(short(s.c[e.who].name))
      elseif k == "condition_up" then t = ("%s looks\nsharper!"):format(me)
      elseif k == "condition_lost" then t = ("%s looks\nrattled."):format(short(s.c[e.who].name))
      elseif k == "crowd_up" then t = "The crowd\nwarms up!"
      elseif k == "crowd_wild" then t = "The crowd goes\nwild! +6 hearts!"
      elseif k == "crowd_down" then t = "That did not\ngo over well."
      elseif k == "crowd_frozen" then t = "The crowd stays\nquiet."
      elseif k == "scored" then
        local h = e.hearts or 0
        if h >= 0 then t = ("%s scores\n%d hearts!"):format(me, h)
        else t = ("%s: %d\nhearts..."):format(me, h) end
      end
      if t then b:emit({ kind = "message", text = t }) end
    end
  end

  local function finishContest(b)
    local s = b.kcState
    if not s or b.over then return end
    local final = KCE.final(s)
    b:emit({ kind = "message", text = "The judge tallies\nthe scores..." })
    local place
    for _, r in ipairs(final) do
      -- dialogue-ok: place is 3 glyphs, short() is at most 10 -> 15
      b:emit({ kind = "message",
        text = ("%s: %s\n%d points"):format(KC_PLACES[r.place], short(s.c[r.who].name), r.total) })
      if r.who == 1 then place = r.place end
    end
    b.kcPlace = place
    -- dialogue-ok: %s is a placement, three glyphs
    b:emit({ kind = "message", text = ("You place %s\nof 4!"):format(KC_PLACES[place] or "4th") })
    b:endBattle(place == 1 and "win" or "run")
  end

  local function goldAppeal(b, attacker, meter, moveId)
    applyGoldIntro(b)
    local s = b.kcState
    if not s then return end
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
    -- Gold's move announcement and the public event stay; the move's own
    -- effect list is never reached (this replaces useMove wholesale)
    b.moveEvent = b:emit({ kind = "move", side = b:sideOf(attacker),
      move = moveId, text = ("%s\nused %s!"):format(name, def.name or moveId) })
    if Runtime.wants("battle.move_used") then
      Runtime.emit("battle.move_used", {
        battle = b, user = attacker, target = meter, move = def,
        moveId = moveId, side = b:sideOf(attacker), isCalled = false,
      })
    end

    local order = KCE.beginTurn(s)
    b.kcRound = s.turn
    b:emit({ kind = "message", text = ("Appeal %d of %d!"):format(s.turn, KCE.TURNS) })
    for slot = 0, KCE.CONTESTANTS - 1 do
      local ci = order[slot]
      local id = (ci == 1) and moveId or KCE.chooseMove(s, ci)
      local ev = KCE.appeal(s, ci, id)
      narrate(b, s, ci, id, ev)
    end
    local standings = KCE.endTurn(s)
    mod.log:info("contest turn %d: %s appeal %d, total %d, rank %d",
                 s.turn, tostring(moveId), s.c[1].appeal, s.c[1].total, standings[1].rank)

    -- the meter is the player's hearts, drawn as damage on the stand-in
    local hearts = KCE.hearts(s.c[1].appeal)
    local maxhp = meterMax(meter)
    if hearts > 0 then
      local dmg = math.max(1, math.floor(maxhp * hearts / 40))
      if (meter.hp or 0) - dmg < 1 then dmg = math.max(0, (meter.hp or 1) - 1) end
      if dmg > 0 then
        b:dealDamage(attacker, meter, dmg, { effectiveness = 10, move = def, moveId = moveId })
      end
    elseif hearts < 0 then
      meter.hp = math.min(maxhp, (meter.hp or 0) + math.floor(maxhp * -hearts / 40))
    end
    if s.turn < KCE.TURNS then
      -- dialogue-ok: %s is a placement, three glyphs
      b:emit({ kind = "message",
        text = ("You stand %s\nafter %d."):format(KC_PLACES[standings[1].rank] or "4th", s.turn) })
    else
      finishContest(b)
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
  -- ------------------------------------------------------------------
  -- CONTEST MOVES: a fourth summary page, between MOVES (green) and the
  -- stats page (blue) -- Gen 3's "CONTEST MOVES" screen on Gold's summary.
  -- Each move's category, its appeal and jam as hearts, and the effect
  -- text for the move under the cursor.
  --
  -- Kanto Ribbons already wraps this screen's update and takes the WRAP
  -- edge (A/right on BLUE, left on PINK) for its own page. Two mods on the
  -- same edge collide -- whichever wraps last wins and the other page never
  -- opens -- so this one takes the OTHER free edge: right off GREEN, left
  -- off BLUE. The two sets of conditions are disjoint, so they compose in
  -- either wrap order; tests/summary_page_test.lua installs a Ribbons-shaped
  -- wrapper after this one and checks both still fire.
  --
  -- Extended IN PLACE rather than pushed as a separate screen (the Ribbons
  -- route): the upper half -- picture, name, level, the page dots -- is the
  -- summary's own and should stay put while the lower half changes, which
  -- is exactly how the stock pages work. page == 4 is a value the stock code
  -- never produces; every method that would fall through to PINK for an
  -- unknown page is wrapped below.
  --
  -- Up/down move the cursor between the four moves on THIS page (Gen 3's
  -- move screen scrolls the same way); party switching is one page left.
  -- ------------------------------------------------------------------
  local okSum, Gen2Summary = pcall(require, "src.ui.gen2.SummaryMenu")
  if okSum and type(Gen2Summary) == "table" and Gen2Summary.update then
    local Chrome = require("src.ui.gen2.Chrome")
    local Font = require("src.render.Font")
    Gen2Summary._kcOriginals = Gen2Summary._kcOriginals or {}
    local O = Gen2Summary._kcOriginals
    O.update = O.update or Gen2Summary.update
    O.placements = O.placements or Gen2Summary.placements
    O.drawPanel = O.drawPanel or Gen2Summary.drawPanel
    O.drawPageIndicators = O.drawPageIndicators or Gen2Summary.drawPageIndicators
    O.lowerColors = O.lowerColors or Gen2Summary.lowerColors
    local GREEN = Gen2Summary.GREEN_PAGE or 2
    local BLUE = Gen2Summary.BLUE_PAGE or 3
    local KC_PAGE = 4
    Gen2Summary.KC_CONTEST_PAGE = KC_PAGE
    -- Its own colour, between MOVES' green and the stats page's blue: the
    -- contest panel's yellow (developer: "its own color").
    local TINT = { 255, 232, 150 }
    local SQUARE = { { 255, 255, 255 }, { 255, 232, 150 }, { 255, 204, 96 }, { 0, 0, 0 } }
    -- text is printed THROUGH this palette, the way a tinted tilemap screen
    -- prints: colour 0 (the tint) is painted behind the string and the
    -- glyph is mapped through it. Plain Chrome.print left every string on
    -- a white cell on device -- reported with a screenshot -- while the
    -- stock pages' text sat cleanly on their tint.
    local PAL = { TINT, TINT, TINT, { 0, 0, 0 } }
    local PINK_SQUARE = (Gen2Summary.PAGE_PALETTES or {})[1]
    local GREEN_SQUARE = (Gen2Summary.PAGE_PALETTES or {})[GREEN]
    local BLUE_SQUARE = (Gen2Summary.PAGE_PALETTES or {})[BLUE]

    local function isEgg(mon) return type(mon) == "table" and mon.isEgg == true end
    local function onPage(self)
      return self.page == KC_PAGE and not self.moveDetail and not isEgg(self.mon)
    end
    local function cursorOf(self)
      local n = math.max(1, #self:moveList())
      local c = self.kcCursor or 1
      if c < 1 then c = 1 elseif c > n then c = n end
      self.kcCursor = c
      return c
    end
    local function rowFor(id)
      local row = id and KC_CONTEST_MOVES[id]
      local fx = row and KC_CONTEST_EFFECTS[row.effect]
      return row, fx
    end

    -- 8x6 hearts, drawn as pixels: Gold's font has no heart glyph
    -- (briefs: gold-charmap-symbols), and a mod sprite sheet is more than
    -- 48 pixels deserve. Appeal hearts are solid, jam hearts hollow.
    local HEART = {
      "01100110", "11111111", "11111111", "01111110", "00111100", "00011000",
    }
    local HEART_HOLLOW = {
      "01100110", "10011001", "10000001", "01000010", "00100100", "00011000",
    }
    local function drawHeart(px, py, hollow)
      local G = love.graphics
      G.setColor(0, 0, 0, 1)
      local bits = hollow and HEART_HOLLOW or HEART
      for r = 1, #bits do
        local line = bits[r]
        for c = 1, #line do
          if line:sub(c, c) == "1" then G.rectangle("fill", px + c - 1, py + r, 1, 1) end
        end
      end
    end
    local function drawHearts(count, tx, ty, hollow)
      for i = 1, math.min(8, count) do drawHeart((tx + i - 1) * 8, ty * 8, hollow) end
    end

    -- Text for the lower half; hearts and the cursor are drawn, not placed.
    -- Rows 8-17 are the page (StatsScreen_LoadGFX clears 10 rows). 20 tiles:
    -- cursor at 0, category padded to 6 at col 1, name at col 8 (12 max).
    Gen2Summary.kcContestPlacements = function(self)
      local out = {}
      local function put(text, x, y) out[#out + 1] = { text = text, x = x, y = y } end
      put("CONTEST MOVES", 1, 8)
      local moves = self:moveList()
      for slot = 1, 4 do
        local entry = moves[slot]
        local y = 8 + slot
        if entry then
          local row = rowFor(entry.id)
          local cat = row and row.cat or "----"
          put(cat:sub(1, 6), 1, y)
          put(tostring(self:moveName(entry) or entry.id):sub(1, 12), 8, y)
        else
          put("-", 8, y)
        end
      end
      local cur = moves[cursorOf(self)]
      local _, fx = rowFor(cur and cur.id)
      put("APPEAL", 1, 13)
      put("JAM", 1, 14)
      if fx then
        if (fx.appeal or 0) <= 0 then put("-", 8, 13) end
        if (fx.jam or 0) <= 0 then put("-", 8, 14) end
        local text = tostring(fx.text or "")
        local a, b = text:match("^(.-)\n(.*)$")
        put(a or text, 1, 15)
        if b then put(b, 1, 16) end
      elseif cur then
        put("No contest data.", 1, 15)
      end
      return out
    end

    Gen2Summary.update = function(self, dt)
      local input = self.game and self.game.input
      if input and not self.moveDetail and not isEgg(self.mon) then
        if self.page == KC_PAGE then
          self:stepPicAnim()
          local n = math.max(1, #self:moveList())
          if input:wasPressed("b") then self:close()
          elseif input:wasPressed("left") then self.page = GREEN
          elseif input:wasPressed("right") or input:wasPressed("a") then self.page = BLUE
          elseif input:wasPressed("up") then self.kcCursor = (cursorOf(self) - 2) % n + 1
          elseif input:wasPressed("down") then self.kcCursor = cursorOf(self) % n + 1
          end
          return
        elseif self.page == GREEN and (input:wasPressed("right") or input:wasPressed("a")) then
          -- A walks the same path as right (stock A on GREEN went straight
          -- to BLUE, skipping this page -- reported from device)
          self.page = KC_PAGE; self.kcCursor = 1
          return
        elseif self.page == BLUE and input:wasPressed("left") then
          self.page = KC_PAGE; self.kcCursor = 1
          return
        end
      end
      return O.update(self, dt)
    end

    Gen2Summary.placements = function(self)
      if not onPage(self) then return O.placements(self) end
      local out = self:upperPlacements()
      for _, e in ipairs(self:kcContestPlacements()) do out[#out + 1] = e end
      return out
    end

    Gen2Summary.lowerColors = function(self)
      if self.page ~= KC_PAGE then return O.lowerColors(self) end
      return { TINT, TINT, TINT, { 0, 0, 0 } }
    end

    -- Four dots in READING order -- pink, green, contest, blue -- so the
    -- squares match the path right/A walk (the contest page sits third;
    -- 0.33.0 drew it as a fourth dot after blue, which lied about the order).
    -- Drawn whole rather than chained: the stock routine places blue at 17.
    Gen2Summary.drawPageIndicators = function(self)
      self:drawPageSquare(13, 5, self.page == 1, PINK_SQUARE)
      self:drawPageSquare(15, 5, self.page == GREEN, GREEN_SQUARE)
      self:drawPageSquare(17, 5, self.page == KC_PAGE, SQUARE)
      self:drawPageSquare(19, 5, self.page == BLUE, BLUE_SQUARE)
    end

    Gen2Summary.drawPanel = function(self)
      if not onPage(self) then return O.drawPanel(self) end
      local wasBattle = Font.useBattleExtra(true)
      Chrome.clear()
      self:drawPageBackground()
      self:drawUpperHalf()
      for _, e in ipairs(self:kcContestPlacements()) do
        Chrome.printThrough(e.text, e.x, e.y, PAL)
      end
      local moves = self:moveList()
      local c = cursorOf(self)
      if moves[c] then
        -- through the page palette like the text, or it sits on a white cell
        Chrome.cursorThrough(0, 8 + c, PAL)
        local _, fx = rowFor(moves[c].id)
        if fx then
          drawHearts(math.floor((fx.appeal or 0) / 10), 8, 13, false)
          drawHearts(math.floor((fx.jam or 0) / 10), 8, 14, true)
        end
      end
      Font.useBattleExtra(wasBattle)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end

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
      -- goldAppeal ends the contest itself after the fifth appeal; this
      -- is the net for a turn that got there some other way
      if b.kcState and b.kcState.turn >= KCE.TURNS then
        finishContest(b)
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
  -- assigned in the Lines block far below (cast_lines.lua is loaded
  -- there); declared here so talkAudience, defined early, can call it
  local lineFor
  local function talkAudience(world, npc)
    world:showText(lineFor(world, npc or { def = { name = "ring" } }))
  end

  local function markerExists(world, marker)
    for _, actor in ipairs((world and world.npcs) or {}) do
      if actor.def and actor.def[marker] then return true end
    end
    return false
  end

  -- BEGIN KC_VANILLA_PALETTE (generated by tests/gen_vanilla_palettes.py -- do not edit)
  -- sprite -> PAL_NPC value (8 + PAL_OW index): the colour vanilla
  -- actually shows, for every sheet whose default vanilla never uses.
  local KC_VANILLA_PALETTE = {
    BIRD = 11,  -- sheet RED, vanilla BROWN
    BRUNO = 11,  -- sheet RED, vanilla BROWN
    CAPTAIN = 9,  -- sheet BROWN, vanilla BLUE
    CHUCK = 11,  -- sheet RED, vanilla BROWN
    CLAIR = 9,  -- sheet RED, vanilla BLUE
    DIGLETT = 11,  -- sheet RED, vanilla BROWN
    EKANS = 9,  -- sheet RED, vanilla BLUE
    JANINE = 9,  -- sheet RED, vanilla BLUE
    JASMINE = 8,  -- sheet GREEN, vanilla RED
    JYNX = 11,  -- sheet RED, vanilla BROWN
    KAREN = 8,  -- sheet BLUE, vanilla RED
    KOGA = 9,  -- sheet BROWN, vanilla BLUE
    LINK_RECEPTIONIST = 10,  -- sheet RED, vanilla GREEN
    LUGIA = 9,  -- sheet RED, vanilla BLUE
    MACHOP = 9,  -- sheet RED, vanilla BLUE
    MISTY = 8,  -- sheet BLUE, vanilla RED
    MOLTRES = 11,  -- sheet RED, vanilla BROWN
    ODDISH = 10,  -- sheet RED, vanilla GREEN
    POLIWAG = 9,  -- sheet RED, vanilla BLUE
    RAIKOU = 11,  -- sheet RED, vanilla BROWN
    ROCKET_GIRL = 8,  -- sheet BROWN, vanilla RED
    SURGE = 11,  -- sheet GREEN, vanilla BROWN
    SWIMMER_GIRL = 10,  -- sheet BLUE, vanilla GREEN
    SWIMMER_GUY = 8,  -- sheet BLUE, vanilla RED
  }
  -- END KC_VANILLA_PALETTE

  local function spawnMarked(mapId, def, marker)
    local actor = {}
    for key, value in pairs(def) do actor[key] = value end
    actor[marker] = true
    -- A vanilla sprite's colour on the cart is the object_event's own
    -- palette field, which overrides the sheet's default (engine
    -- Palettes.objectPaletteId; pokecrystal AddMapObject). A spawn with
    -- no palette gets the sheet default -- and for 24 sheets that is a
    -- colour vanilla never shows (Jasmine green, Misty blue, Koga
    -- brown). So pass the colour the game actually uses (REQUESTS row
    -- 11). Custom KC_* sheets carry their own palette in registration
    -- and are not in the table; an explicit def.palette always wins.
    if actor.palette == nil and type(actor.sprite) == "string" then
      local base = actor.sprite:match("^SPRITE_(.+)$")
      local pal = base and KC_VANILLA_PALETTE[base]
      if pal then actor.palette = pal end
    end
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
    "YOUNGSTER", "SUPER_NERD", "SAGE",
    -- no BIRD: on Gold/Crystal SPRITE_BIRD is a red bird POKEMON (the
    -- Pidgey-style walker, OverworldSprites[77]), not a Bird Keeper. It
    -- sat in the seats until 0.34.16 -- the developer saw it -- and the
    -- rule below says the crowd is people only.
    -- no SWIMMER_GUY / SWIMMER_GIRL: those sprites are drawn mid-stroke,
    -- so on a carpet they look like they are swimming across the floor.
    "GENTLEMAN", "BEAUTY", "LASS", "FISHER", "SAILOR",
    "ROCKER", "SCIENTIST", "PHARMACIST", "GRAMPS",
    -- no vanilla NURSE (REQUESTS row 7, developer's call 2026-09-02): her
    -- sheet is 16x48 -- down, down-step, side -- with NO up frame, so in a
    -- FACE_UP seat she faced the wrong way. The crowd's nurse is the mod's
    -- KC_NURSE_JOY, a real 6-frame walker, already in CAST_CUSTOM_CROWD.
    "GRANNY", "CLERK", "GYM_GUIDE", "ELDER", "KIMONO_GIRL",
    "BILL", "OAK", "ELM", "KURT", "DAISY", "MOM", "RED", "CAL",
  }
  -- Custom characters, stored WITHOUT the "SPRITE_" prefix so they draw
  -- through exactly the same path as the vanilla pools.
  --
  -- Split by whether the character has a reason to be COMPETING. The
  -- rival set can also just be watching; the crowd set never competes.
  local CAST_CUSTOM_RIVAL = {
    -- KC_DUPLICA / KC_GISELLE / KC_SUZIE were benched 0.34.x for being
    -- RGB-mode PNGs. That was never a defect: the engine's bake reads the
    -- RED channel only (SpriteRenderer.lua getObpImage; GbcPalette.lua),
    -- and their pixels are the same four greys as every mode-L sheet.
    -- Back in as of 0.34.16 -- REQUESTS row 8, developer confirmed.
    "KC_DUPLICA", "KC_GISELLE", "KC_SUZIE",
    "KC_STADIUM_BOY", "KC_STADIUM_GIRL",
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
    -- KC_BALLGUY was the "red blob" of 0.34.15 (seat (1,8), seed 24618,
    -- named by tests/seat_replay.py): his PNG carried a tRNS chunk that
    -- made shade 0 transparent, and the engine keeps alpha-0 pixels
    -- transparent BEFORE it classifies shades (SpriteRenderer.lua
    -- getObpImage), so his outline and legs never drew. Canonical was
    -- repaired by the checker (REQUESTS row 10, 2026-09-02) and this copy
    -- is byte-identical to it again; he is back as of 0.34.21.
    -- tests/asset_png_check.py fails on that chunk from now on.
    "KC_BREEDER", "KC_ROCKET_EXECUTIVE", "KC_CHEF", "KC_EUSINE", "KC_LOOKER",
    "KC_RANGER", "KC_SANTA", "KC_NURSE_JOY", "KC_BALLGUY", "KC_BILL",
    "KC_INGO", "KC_AGATHA", "KC_ARCHER", "KC_ARIANA", "KC_GIOVANNI",
    "KC_PETREL", "KC_PROTON", "KC_OFFICER_JENNY", "KC_RUIN_MANIAC",
  }

  -- Sprites whose vanilla sheet is 16x48 -- three frames, DOWN only, no
  -- back and no side (crystal + gold sprites.lua: STANDING_SPRITE). They
  -- can only ever face the camera, so a FACE_UP / LEFT / RIGHT seat would
  -- draw them facing down (REQUESTS row 7, the nurse). Checked against
  -- every name in every pool: these are the only three.
  local STAND_ONLY = { KAREN = true, WILL = true, NURSE = true }

  -- Pairs that read as a pair when seated together. Purely cosmetic.
  local CAST_PAIRS = {
    { "TWIN", "TWIN" }, { "ROCKET", "ROCKET_GIRL" },
    { "POKEFAN_M", "POKEFAN_F" }, { "COOLTRAINER_M", "COOLTRAINER_F" },
    { "GRAMPS", "GRANNY" },
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

  -- BEGIN KC_COORD_RULES (generated by tests/gen_coordinator_rules.py from briefs/CONTEST_COORDINATORS.md -- do not edit)
  -- sprite -> what the developer decided on the worksheet: the contest
  -- types this coordinator may enter (absent = any) and the POKeMON they
  -- always bring (absent = their pool).
  local KC_COORD_RULES = {
    SPRITE_KC_ASH = { kinds = { "COOL", "TOUGH", "SMART" } },
    SPRITE_KC_WES = { kinds = { "COOL", "TOUGH" } },
    SPRITE_KC_COLRESS = { kinds = { "SMART", "BEAUTY" } },
    SPRITE_KC_AJ = { kinds = { "TOUGH" } },
    SPRITE_KC_PIERS = { kinds = { "COOL", "CUTE", "BEAUTY" } },
    SPRITE_WHITNEY = { kinds = { "CUTE", "BEAUTY" }, signature = { "MILTANK" } },
    SPRITE_FALKNER = { kinds = { "COOL" }, signature = { "PIDGEOTTO" } },
    SPRITE_CHUCK = { kinds = { "TOUGH" } },
    SPRITE_MISTY = { kinds = { "BEAUTY", "CUTE", "TOUGH" } },
    SPRITE_SURGE = { kinds = { "COOL", "TOUGH" } },
    SPRITE_ERIKA = { kinds = { "BEAUTY", "SMART", "TOUGH" }, signature = { "VILEPLUME" } },
    SPRITE_BLUE = { signature = { "BLASTOISE", "ALAKAZAM", "ARCANINE" } },
    SPRITE_BIKER = { kinds = { "COOL", "TOUGH" } },
    SPRITE_TWIN = { kinds = { "CUTE", "SMART" } },
    SPRITE_ROCKET = { kinds = { "COOL", "TOUGH" } },
    SPRITE_ROCKET_GIRL = { kinds = { "BEAUTY", "TOUGH" } },
    SPRITE_BLACK_BELT = { kinds = { "TOUGH", "COOL" } },
    SPRITE_SUPER_NERD = { kinds = { "SMART" } },
    SPRITE_BEAUTY = { kinds = { "COOL", "BEAUTY", "CUTE" } },
    SPRITE_ROCKER = { kinds = { "COOL", "TOUGH", "SMART" } },
    SPRITE_SCIENTIST = { kinds = { "SMART" } },
  }
  -- END KC_COORD_RULES

  -- May this pool name compete in a contest of `kind`? No rule, or no
  -- kind asked (the lobby queue is drawn before the category is picked),
  -- means yes. Pool names are the sprite id without SPRITE_.
  local function allowedFor(pick, kind)
    if not kind then return true end
    local rule = KC_COORD_RULES["SPRITE_" .. tostring(pick)]
    if not (rule and rule.kinds) then return true end
    for _, k in ipairs(rule.kinds) do if k == kind then return true end end
    return false
  end

  -- `kind` (optional) skips picks the worksheet keeps out of this
  -- contest type. A SKIPPED pick is not marked used; the pick that is
  -- returned is.
  local function drawFrom(pool, used, rnd, kind)
    for _ = 1, 40 do
      local pick = pool[rnd(#pool)]
      if pick and not used[pick] and allowedFor(pick, kind) then used[pick] = true return pick end
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
    if mod.save then
      mod.save:set("kcSeedSalt", salt)
    end
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
  -- How many FAMOUS FACES (a custom rival, or a gym leader / Elite Four
  -- member) the three coordinators include, as cumulative percent for
  -- 0, 1, 2 and 3 of them. Keyed by the RANK THIS HALL RUNS (0.34.41).
  -- It used to key off the highest rank the player had ever entered,
  -- snapshotted on lobby entry because the desk could raise it between
  -- the queue draw and the stage draw; one hall, one rank closes that
  -- window and the snapshot is gone. Retuned 0.34.29 from three
  -- independent d10 slot rolls (which put two rivals AND Surge in a
  -- first NORMAL contest -- reported from device): a NORMAL-only player
  -- mostly meets one famous face, sometimes two, rarely three.
  local KC_NAMED_FACES = {
    NORMAL = { 10, 75, 95, 100 },
    SUPER  = {  5, 55, 90, 100 },
    HYPER  = {  0, 35, 80, 100 },
    MASTER = {  0, 20, 65, 100 },
  }
  local function rankIndex(r)
    for i, k in ipairs(KC_RANKS) do if k == r then return i end end
    return 1
  end

  local function drawCoordinators(rnd, used)
    -- tests/seat_replay.py mirrors this call for call -- keep them in step
    -- The hall's own rank (0.34.41): one building, one rank, so the
    -- lobby queue and the stage line-up read the same row by
    -- construction.
    local dist = KC_NAMED_FACES[hallRank()] or KC_NAMED_FACES.NORMAL
    local roll, named = rnd(100), 3
    for n = 0, 3 do
      if roll <= dist[n + 1] then named = n break end
    end
    local out, heavy = {}, false
    if rnd(LARRY_ODDS) == 1 then
      out[#out + 1] = LARRY
      used[LARRY] = true
      named = math.max(0, named - 1)        -- Larry is a famous face too
    end
    while #out < #STAGE_COORD_CELLS do
      local pool
      if named > 0 then
        named = named - 1
        -- a famous face is a custom rival 7 times in 10, a leader or
        -- E4 member 3 -- and never more than one of those per contest
        if not heavy and rnd(10) <= 3 then pool = CAST_GYM else pool = CAST_CUSTOM_RIVAL end
      else
        pool = CAST_FOLK
      end
      local pick = drawFrom(pool, used, rnd) or drawFrom(CAST_FOLK, used, rnd)
      if not pick then break end
      if pool == CAST_GYM then heavy = true end
      out[#out + 1] = "SPRITE_" .. pick
    end
    -- the famous faces were drawn first; shuffle so they do not always
    -- stand in the same spot
    for i = #out, 2, -1 do
      local j = rnd(i)
      out[i], out[j] = out[j], out[i]
    end
    return out
  end

  -- The queue in the lobby: the same three people, on the same seed, up
  -- the right-hand wall facing LEFT. Previously three fixed NPCs, which
  -- meant the coordinators you queued behind had nothing to do with the
  -- ones you then competed against.
  -- ---------------------------------------------------------------
  -- The quest hook (briefs/KANTO_CONTESTS_QUEST_HOOKS.md, approved
  -- 2026-09-02). Another mod may write `save.kcCastPlan` to put its own
  -- characters in coordinator slots, and reads `save.kcLastContest` /
  -- the `mod.kanto_contests.result` event afterwards. Data only: this
  -- mod never checks whether such a mod is installed, and a plan it
  -- cannot honour is ignored WHOLE (never a half-applied line-up).
  local function castPlan()
    local save = mod.game and mod.game.save
    local p = save and save.kcCastPlan
    return type(p) == "table" and p or nil
  end
  -- Apply the plan's slots to a drawn line-up. Returns nil when applied
  -- (or when there is no plan), else the reason it was ignored.
  -- `kind` is nil for the lobby queue, which is drawn before the
  -- category is chosen, so a plan scoped to `kinds` still shows there.
  local function applyCastPlan(world, coordinators, kind)
    local plan = castPlan()
    if not plan or type(plan.slots) ~= "table" then return nil end
    if plan.hall and plan.hall ~= TOWN then return "hall" end
    if kind and type(plan.kinds) == "table" and #plan.kinds > 0 then
      local ok = false
      for _, k in ipairs(plan.kinds) do if k == kind then ok = true end end
      if not ok then return "kinds" end
    end
    local sprites = world and world.sprites
    for slot, entry in pairs(plan.slots) do
      local n = tonumber(slot)
      if not (n and n >= 1 and n <= #STAGE_COORD_CELLS and type(entry) == "table") then return "slot" end
      if type(entry.sprite) ~= "string" or (sprites and not sprites[entry.sprite]) then return "sprite" end
    end
    for slot, entry in pairs(plan.slots) do coordinators[tonumber(slot)] = entry.sprite end
    return nil
  end
  -- what the stage applied, for castName / appealSteps / the result
  local stagePlan, stagePlanIgnored = nil, nil
  local function stagePlanSlot(n)
    local slots = stagePlan and stagePlan.slots
    local e = slots and (slots[n] or slots[tostring(n)])
    return type(e) == "table" and e or nil
  end

  local LOBBY_QUEUE_CELLS = {
    { x = 8, y = 5 }, { x = 8, y = 4 }, { x = 8, y = 3 },
  }
  -- Remove every cast member this mod spawned on the CURRENT map. Runtime
  -- objects live in the map's object list for the whole session, so a
  -- `markerExists` guard alone meant the first queue and the first stage
  -- cast of a session were the only ones ever drawn: after a win the
  -- same three stood in the lobby however many times the player left and
  -- came back (reported from device, 0.34.31). Ids are the engine's own
  -- "<map>_obj_<index>" (World:removeRuntimeObject); collect first, since
  -- each removal rebuilds the live list.
  local function clearCast(world, mapId)
    local ids = {}
    for _, npc in ipairs((world and world.npcs) or {}) do
      local d = npc.def
      if d and d.kcCast and d.runtime and d.index then
        ids[#ids + 1] = mapId .. "_obj_" .. d.index
      end
    end
    for _, id in ipairs(ids) do pcall(mod.world.removeNpc, mod.world, id) end
    return #ids
  end

  local function ensureLobbyQueue(world)
    -- Every entry is a new queue: whoever stood there is cleared and the
    -- line is drawn again for the NEXT contest (the count advanced when
    -- the last one started, so the seed is new). map.entered fires once
    -- per entry, not once per frame, so the queue does not reshuffle
    -- while the player is standing in it.
    clearCast(world, HALL)
    rollSeedSalt()
    local coordinators = drawCoordinators(seededRng(nextContestSeed()), {})
    applyCastPlan(world, coordinators, nil)
    for i, cell in ipairs(LOBBY_QUEUE_CELLS) do
      local sprite = coordinators[i]
      if sprite then
        -- KAREN and WILL (STAND_ONLY) have no side frame: asked to face
        -- left they drew facing down (code review), so they face the
        -- camera on purpose instead
        local base = tostring(sprite):match("^SPRITE_(.+)$")
        spawnMarked(HALL, {
          name = ("KC_QUEUE_%d"):format(i), sprite = sprite,
          x = cell.x, y = cell.y,
          movement = (base and STAND_ONLY[base]) and FACE_DOWN or FACE_LEFT,
          kcCoordinator = true,
        }, "kcCast")
      end
    end
  end

  -- Set when the judge takes an entry in the lobby and cleared when the
  -- contest actually starts; it is what the stage judge reads to know
  -- which of the five he is about to judge.
  local pendingContest
  -- ...and at which rank; NORMAL when the menu was skipped.
  local pendingRank
  -- The category is ALSO kept in the save (kcPendingKind, 0.34.30): the
  -- stage's type-limit swap reads it, and after a reload pendingContest
  -- is nil, which used to draw the unswapped line-up (code review).
  local function clearPendingContest()
    pendingContest = nil
    if mod.save then mod.save:set("kcPendingKind", false) end
  end


  -- which contest the stage cast standing there was drawn for; a reload
  -- into the same contest keeps it (same seed either way), a new contest
  -- clears and redraws
  local stageCastFor = nil
  local function ensureStageCast(world)
    if markerExists(world, "kcCast") and stageCastFor == contestCount() then return end
    clearCast(world, STAGE_DEF.id)
    stageCastFor = contestCount()
    local rnd  = seededRng(contestSeed())
    local used = {}

    local coordinators = drawCoordinators(rnd, used)

    -- Is a cell somewhere a spectator can stand? The seat table was written
  -- against GOLDENROD's stage, and Ecruteak's has pillars where that one
  -- has open floor, so some seats would put a person inside a wall.
  --
  -- ONLY 0x07 (plain solid) is rejected, and that distinction is the whole
  -- point. The first cut of this tested "walkable", which sounds right and
  -- is wrong: 18 of Goldenrod's 30 seats sit on 0xB0-0xB3 (the
  -- wall-FACING cells), because the audience is meant to stand at the rail
  -- looking in -- so a walkability test would have quietly cut that
  -- crowd from 30 to 12. Measured before trusting it: Goldenrod is
  -- 0x00 x12 + 0xB0-B3 x18, Ecruteak is 0x00 x16 + 0x07 x14.
  --
  -- Quadrant order is TL, TR, BL, BR (LayeredMap/BorderFill).
  local function seatUsable(def, x, y)
    if not (def and def.blocks and def.tiles) then return true end
    local GV = require("src.core.GameVersion")
    local engine = GV.engine and GV.engine() or "gs"
    local v = def.tiles.variants
      and (def.tiles.variants[engine] or def.tiles.variants.gs)
    local coll = v and v.collision
    if not coll then return true end
    local bx, by = math.floor(x / 2), math.floor(y / 2)
    local id = def.blocks[by * def.width + bx + 1]
    if not id then return false end
    local quad = coll[id + 1]                 -- blocks are addressed id + 1
    if not quad then return false end
    local q = (y % 2) * 2 + (x % 2) + 1
    return (quad[q] or 0) ~= 0x07            -- everything but a plain wall
  end

  -- Choose WHICH seats are filled. 10-15 of the 30 the developer
    -- marked out, so the hall is the same density each time but never
    -- the same shape.
    local pool = {}
    for k = 1, #STAGE_SEATS do
      local seat = STAGE_SEATS[k]
      if seatUsable(STAGE_DEF, seat.x, seat.y) then pool[#pool + 1] = seat end
    end
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
        -- a DOWN-only sheet cannot sit anywhere but a seat facing down;
        -- the pick stays marked used and the seat draws again from folk
        -- (tests/seat_replay.py mirrors this exactly -- keep them in step)
        if pick and STAND_ONLY[pick] and seat.face ~= FACE_DOWN then
          pick = drawFrom(CAST_FOLK, used, rnd)
        end
        sprite = pick and ("SPRITE_" .. pick)
      end
      if sprite then
        spawnMarked(STAGE_DEF.id, {
          name = ("KC_AUD_%d"):format(i), sprite = sprite,
          x = seat.x, y = seat.y, movement = seat.face,
        }, "kcCast")
      end
    end

    -- The worksheet's type limits (0.34.28, reworked 0.34.30 after code
    -- review). The queue in the lobby is drawn before the player picks a
    -- category, so it cannot filter; the stage draws the SAME three and
    -- then swaps out anyone the developer keeps out of this contest type
    -- -- a MISTY in the queue for a COOL contest turns out to have been
    -- queueing for a different one. Rules of the swap:
    --   * it runs AFTER the seats are drawn from `rnd` and uses its own
    --     rng and its own copy of `used` (everyone seated included), so
    --     the crowd is identical to a no-swap draw of the same seed and
    --     tests/seat_replay.py needs no swap step;
    --   * the replacement comes from the SAME pool class as the evicted
    --     coordinator (leader for leader, rival for rival, folk for
    --     folk), so the famous-face count and the one-leader cap hold;
    --   * the category comes from the save when pendingContest is nil
    --     (a reload onto the stage), so the line-up is the one the
    --     player saw before saving.
    do
      local kind = pendingContest or (mod.save and mod.save:get("kcPendingKind")) or nil
      if kind then
        local swapRnd = seededRng(contestSeed() + 555)
        local usedAll = {}
        for k, v in pairs(used) do usedAll[k] = v end
        local function inList(list, name)
          for _, n in ipairs(list) do if n == name then return true end end
          return false
        end
        for i, sprite in ipairs(coordinators) do
          local pick = tostring(sprite):match("^SPRITE_(.+)$")
          if pick and not allowedFor(pick, kind) then
            local same = (inList(CAST_GYM, pick) and CAST_GYM)
              or (inList(CAST_CUSTOM_RIVAL, pick) and CAST_CUSTOM_RIVAL)
              or CAST_FOLK
            local sub = drawFrom(same, usedAll, swapRnd, kind)
              or drawFrom(CAST_FOLK, usedAll, swapRnd, kind)
            if sub then coordinators[i] = "SPRITE_" .. sub end
          end
        end
      end
    end
    -- the quest hook's plan, last: it outranks the draw and the swap
    do
      local kind = pendingContest or (mod.save and mod.save:get("kcPendingKind")) or nil
      stagePlanIgnored = applyCastPlan(world, coordinators, kind)
      stagePlan = (castPlan() and not stagePlanIgnored) and castPlan() or nil
    end
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
  -- Ranks a mon may enter in a category: NORMAL always, then one more per
  -- win there. Wins live on mon.contestWins[kind] (the Ribbons contract).
  local function eligibleRanks(mon, kind)
    local wins = (mon and mon.contestWins and mon.contestWins[kind]) or 0
    local out = {}
    for i = 1, math.min(#KC_RANKS, wins + 1) do out[i] = KC_RANKS[i] end
    return out
  end
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
  -- Who each coordinator brings. Keyed by sprite id; anyone without an
  -- entry falls back to KC_PARTNERS below, which is why the generic
  -- trainers do not need listing.
  --
  -- Contest-appropriate rather than competitive: these are the POKeMON
  -- a character would show off, not the one they would fight with. Every
  -- name is checked against the player's own extracted data by
  -- tests/partner_test.lua -- an unknown species silently shows no dex
  -- picture and plays no cry, which is exactly the kind of failure that
  -- reaches a device looking like nothing happened.
  local KC_PARTNER_POOLS = {
    -- Trainer classes bring what their class brings. This is most of the
    -- field: 55 of the 95 coordinator-eligible characters had no pool and
    -- all drew from the same 18, which is why the same few POKeMON kept
    -- turning up contest after contest.
    SPRITE_TEACHER     = { "CHIKORITA", "HOOTHOOT", "SENTRET", "MARILL" },
    SPRITE_BUG_CATCHER = { "CATERPIE", "WEEDLE", "LEDYBA", "PARAS" },
    SPRITE_FISHER      = { "MAGIKARP", "GOLDEEN", "POLIWAG", "CHINCHOU" },
    SPRITE_SAILOR      = { "TENTACOOL", "KRABBY", "WOOPER", "HORSEA" },
    SPRITE_BLACK_BELT  = { "MACHOP", "MANKEY", "TYROGUE", "HITMONLEE" },
    SPRITE_BIKER       = { "KOFFING", "GRIMER", "VOLTORB", "MAGNEMITE" },
    SPRITE_ROCKER      = { "VOLTORB", "ELECTABUZZ", "MAGNEMITE", "PIKACHU" },
    SPRITE_SCIENTIST   = { "PORYGON", "MAGNEMITE", "DITTO", "ELEKID" },
    SPRITE_PHARMACIST  = { "CHANSEY", "BLISSEY", "ODDISH", "TANGELA" },
    SPRITE_NURSE       = { "CHANSEY", "CLEFAIRY", "BLISSEY", "TOGEPI" },
    SPRITE_OFFICER     = { "GROWLITHE", "ARCANINE", "HOUNDOUR", "SNUBBULL" },
    SPRITE_BEAUTY      = { "VULPIX", "PERSIAN", "BELLOSSOM", "FURRET" },
    SPRITE_LASS        = { "CLEFAIRY", "JIGGLYPUFF", "SENTRET", "HOPPIP" },
    SPRITE_TWIN        = { "PICHU", "CLEFFA", "IGGLYBUFF", "TOGEPI" },
    SPRITE_YOUNGSTER   = { "RATTATA", "SPEAROW", "SENTRET", "GEODUDE" },
    SPRITE_SUPER_NERD  = { "GRIMER", "MAGNEMITE", "PORYGON", "VOLTORB" },
    SPRITE_SAGE        = { "BELLSPROUT", "HOOTHOOT", "NATU", "GASTLY" },
    SPRITE_BIRD        = { "PIDGEY", "SPEAROW", "HOOTHOOT", "NATU" },
    SPRITE_GENTLEMAN   = { "GROWLITHE", "PERSIAN", "FURRET", "MEOWTH" },
    SPRITE_POKEFAN_M   = { "PIKACHU", "CLEFAIRY", "MEOWTH", "SNUBBULL" },
    SPRITE_POKEFAN_F   = { "JIGGLYPUFF", "MARILL", "SKIPLOOM", "TOGEPI" },
    SPRITE_COOLTRAINER_M = { "SANDSLASH", "PRIMEAPE", "SEADRA", "KINGLER" },
    SPRITE_COOLTRAINER_F = { "NIDORINA", "STARMIE", "JYNX", "BELLOSSOM" },
    SPRITE_GRAMPS      = { "SLOWPOKE", "GEODUDE", "DUNSPARCE", "SUDOWOODO" },
    SPRITE_GRANNY      = { "MEOWTH", "CLEFAIRY", "SLOWPOKE", "MARILL" },
    SPRITE_CLERK       = { "PORYGON", "MEOWTH", "PIDGEY", "MAGNEMITE" },
    SPRITE_GYM_GUIDE   = { "MACHOP", "GEODUDE", "RATTATA", "PIDGEY" },
    SPRITE_ELDER       = { "BELLSPROUT", "HOOTHOOT", "ONIX", "GASTLY" },
    SPRITE_KIMONO_GIRL = { "EEVEE", "VAPOREON", "FLAREON", "ESPEON" },
    SPRITE_ROCKET      = { "KOFFING", "GRIMER", "RATTATA", "ZUBAT" },
    SPRITE_ROCKET_GIRL = { "EKANS", "ZUBAT", "MEOWTH", "GRIMER" },
    -- named vanilla faces
    SPRITE_BILL        = { "EEVEE", "PORYGON", "ABRA", "DITTO" },
    SPRITE_OAK         = { "BULBASAUR", "CHARMANDER", "SQUIRTLE", "TAUROS" },
    SPRITE_ELM         = { "CHIKORITA", "CYNDAQUIL", "TOTODILE", "TOGEPI" },
    SPRITE_KURT        = { "PINECO", "HERACROSS", "SPINARAK", "SUDOWOODO" },
    SPRITE_DAISY       = { "EEVEE", "JIGGLYPUFF", "PERSIAN", "CLEFAIRY" },
    SPRITE_MOM         = { "CLEFAIRY", "MARILL", "MEOWTH", "TOGEPI" },
    SPRITE_RED         = { "PIKACHU", "CHARIZARD", "LAPRAS", "SNORLAX" },
    SPRITE_CAL         = { "TOTODILE", "CYNDAQUIL", "CHIKORITA", "SENTRET" },
    -- remaining custom cast
    SPRITE_KC_STADIUM_BOY  = { "TAUROS", "SNORLAX", "RHYDON", "KANGASKHAN" },
    SPRITE_KC_STADIUM_GIRL = { "GENGAR", "STARMIE", "NIDOQUEEN", "LAPRAS" },
    SPRITE_KC_GISELLE  = { "CUBONE", "PERSIAN", "NIDORINA", "CLEFAIRY" },
    SPRITE_KC_SUZIE    = { "VULPIX", "NINETALES", "GROWLITHE", "PERSIAN" },
    SPRITE_KC_JULIANA  = { "SENTRET", "HOPPIP", "MARILL", "PIKACHU" },
    SPRITE_KC_LILLIE   = { "CLEFAIRY", "VULPIX", "CHANSEY", "TOGEPI" },
    SPRITE_KC_NATE     = { "TOTODILE", "SANDSHREW", "PIDGEY", "MAGNEMITE" },
    SPRITE_KC_BRENDAN  = { "CYNDAQUIL", "GEODUDE", "MARILL", "SPEAROW" },
    SPRITE_KC_HILBERT  = { "CHIKORITA", "CYNDAQUIL", "TOTODILE", "SENTRET" },
    SPRITE_KC_HILDA    = { "MEOWTH", "DROWZEE", "MAREEP", "AIPOM" },
    SPRITE_KC_MICHAEL  = { "EEVEE", "UMBREON", "ESPEON", "TEDDIURSA" },
    SPRITE_KC_WES      = { "UMBREON", "ESPEON", "SNEASEL", "MURKROW" },
    SPRITE_KC_BARRY    = { "TOTODILE", "PIDGEY", "HERACROSS", "SNEASEL" },
    SPRITE_KC_HUGH     = { "TOTODILE", "SANDSHREW", "MAREEP", "SNEASEL" },
    SPRITE_KC_MINA     = { "CLEFAIRY", "SMOOCHUM", "JIGGLYPUFF", "TOGEPI" },
    SPRITE_KC_ROXIE    = { "KOFFING", "GRIMER", "ZUBAT", "VOLTORB" },
    SPRITE_KC_AJ       = { "SANDSHREW", "MACHOP", "MANKEY", "GEODUDE" },
    -- Johto leaders
    SPRITE_FALKNER  = { "PIDGEY", "PIDGEOTTO", "HOOTHOOT" },
    SPRITE_BUGSY    = { "SCYTHER", "BUTTERFREE", "LEDYBA" },
    SPRITE_WHITNEY  = { "MILTANK", "CLEFAIRY", "JIGGLYPUFF" },
    SPRITE_MORTY    = { "GASTLY", "HAUNTER", "MISDREAVUS" },
    SPRITE_CHUCK    = { "MACHOP", "PRIMEAPE", "POLIWRATH" },
    SPRITE_JASMINE  = { "MAGNEMITE", "STEELIX", "AMPHAROS" },
    SPRITE_PRYCE    = { "SEEL", "DEWGONG", "SWINUB" },
    SPRITE_CLAIR    = { "DRATINI", "DRAGONAIR", "HORSEA" },
    -- Kanto leaders
    SPRITE_BROCK    = { "GEODUDE", "ONIX", "GRAVELER" },
    SPRITE_MISTY    = { "STARYU", "STARMIE", "PSYDUCK" },
    SPRITE_SURGE    = { "PIKACHU", "RAICHU", "ELECTRODE" },
    SPRITE_ERIKA    = { "ODDISH", "GLOOM", "TANGELA" },
    SPRITE_JANINE   = { "EKANS", "ARBOK", "KOFFING" },
    SPRITE_SABRINA  = { "ABRA", "KADABRA", "DROWZEE" },
    SPRITE_BLAINE   = { "GROWLITHE", "PONYTA", "MAGMAR" },
    SPRITE_BLUE     = { "EEVEE", "PIDGEOT", "GROWLITHE" },
    -- Elite Four
    SPRITE_WILL     = { "NATU", "XATU", "JYNX" },
    SPRITE_KOGA     = { "VENONAT", "VENOMOTH", "GRIMER" },
    SPRITE_BRUNO    = { "HITMONLEE", "HITMONCHAN", "ONIX" },
    SPRITE_KAREN    = { "UMBREON", "MURKROW", "VULPIX" },
    SPRITE_LANCE    = { "DRATINI", "DRAGONAIR", "CHARIZARD" },
    -- custom cast
    SPRITE_KC_MAY      = { "CYNDAQUIL", "MEOWTH", "BUTTERFREE" },
    SPRITE_KC_DAWN     = { "TOTODILE", "CLEFAIRY", "PIKACHU" },
    SPRITE_KC_LYRA     = { "MARILL", "CHIKORITA", "TOGEPI" },
    SPRITE_KC_ROSA     = { "CHIKORITA", "SENTRET", "MAREEP" },
    SPRITE_KC_ASH      = { "PIKACHU", "BULBASAUR", "CHARMANDER" },
    SPRITE_KC_YELLOW   = { "PIKACHU", "CLEFAIRY", "OMANYTE" },
    SPRITE_KC_LEAF     = { "BULBASAUR", "JIGGLYPUFF", "VULPIX" },
    SPRITE_KC_GREEN    = { "BLASTOISE", "NIDOQUEEN", "CLEFABLE" },
    SPRITE_KC_WALLY    = { "ABRA", "KADABRA", "ODDISH" },
    SPRITE_KC_LARRY    = { "PIDGEY", "SLOWPOKE", "DUNSPARCE" },
    SPRITE_KC_LORELEI  = { "SEEL", "DEWGONG", "SHELLDER" },
    SPRITE_KC_MAXIE    = { "SLUGMA", "MAGCARGO", "GROWLITHE" },
    SPRITE_KC_N        = { "UMBREON", "MEOWTH", "DROWZEE" },
    SPRITE_KC_COLRESS  = { "MAGNEMITE", "PORYGON", "MAGNETON" },
    SPRITE_KC_VOLKNER  = { "ELEKID", "RAICHU", "JOLTEON" },
    SPRITE_KC_PIERS    = { "MURKROW", "SNEASEL", "HOUNDOUR" },
    SPRITE_KC_LEAR     = { "SLOWPOKE", "PERSIAN", "CHANSEY" },
    SPRITE_KC_DUPLICA  = { "DITTO", "CLEFAIRY", "JIGGLYPUFF" },
    SPRITE_KC_BEA      = { "MACHOP", "HITMONLEE", "SCYTHER" },
    SPRITE_KC_GLORIA   = { "MAREEP", "CYNDAQUIL", "HOPPIP" },
  }

  local KC_PARTNERS = {
    "CLEFAIRY", "JIGGLYPUFF", "VULPIX", "ODDISH", "GROWLITHE", "PIKACHU",
    "MEOWTH", "PSYDUCK", "BELLSPROUT", "SEEL", "STARYU", "EEVEE",
    "MARILL", "HOPPIP", "SUNFLORA", "TOGEPI", "FLAAFFY", "SNUBBULL",
  }

  local function prettyName(sprite)
    local n = tostring(sprite):gsub("^SPRITE_KC_", ""):gsub("^SPRITE_", "")
    return (n:gsub("_", " "))
  end

  -- Personal names for the generic trainer classes (0.34.27), so a
  -- coordinator drawn as "a LASS" is somebody. Chosen by the developer
  -- from the suite's MASTER IDEA INDEX; every one is a reference, kept
  -- beside the name so later dialogue can be flavoured to it. The record
  -- (and the parked names) is briefs/CONTEST_CLASS_NAMES.md -- change
  -- both together. 7 glyphs at most: the judging panel gives a trainer
  -- 7 next to a 10-letter POKeMON.
  local KC_CLASS_NAMES = {
    YOUNGSTER     = { "LUCAS", "HAL" },                     -- MOTHER 3; Infinite Jest
    BUG_CATCHER   = { "ELLIOT", "NESS", "TIM" },            -- E.T.; EarthBound; Jurassic Park
    LASS          = { "KIKI", "GERTIE", "SALLY" },          -- Kiki's Delivery Service; E.T.; Mad Men
    TWIN          = { "MEI", "DINAH" },                     -- Totoro; Asteroid City
    TEACHER       = { "JUNE", "MARIA" },                    -- Asteroid City; The Sound of Music
    SUPER_NERD    = { "NEDRY", "PEMULIS", "TELLER" },       -- Jurassic Park; Infinite Jest; Oppenheimer
    SCIENTIST     = { "OPPIE", "GRANT", "WU" },             -- Oppenheimer; Jurassic Park x2
    PHARMACIST    = { "DOC", "CASSARD" },                   -- Inherent Vice; Umbrellas of Cherbourg
    OFFICER       = { "GORDON", "MORETTI", "GARBER" },      -- Batman; Dog Day Afternoon; Pelham 123
    BLACK_BELT    = { "TOMMY", "BRUCE", "FURIO" },          -- Raging Bull; Batman; The Sopranos
    BIKER         = { "JAKE", "WALTER", "SLATER" },         -- Raging Bull; The Big Lebowski; Dazed and Confused
    ROCKET        = { "PAULIE", "FREDO", "SAL" },           -- The Sopranos; The Godfather; Dog Day Afternoon
    ROCKET_GIRL   = { "MEADOW", "MARTA", "JANICE" },        -- The Sopranos; Knives Out; The Sopranos
    COOLTRAINER_M = { "ROGER", "BATOU", "JECHT" },          -- North by Northwest; Ghost in the Shell; FFX blitzball
    COOLTRAINER_F = { "MOTOKO", "KATE", "RIKKU" },          -- Ghost in the Shell; Hawkeye; FFX
    SAILOR        = { "AHAB", "NEMO", "TIDUS" },            -- Moby-Dick; 20,000 Leagues; FFX blitzball
    FISHER        = { "QUINT", "NORMAN", "MANOLIN" },       -- Jaws; A River Runs Through It; Old Man and the Sea
    ROCKER        = { "COSMO", "DON", "TOM" },              -- Singin' in the Rain x2; Nashville
    BEAUTY        = { "HOLLY", "LINA", "JESSICA" },         -- Tiffany's; Singin' in the Rain; Roger Rabbit
    POKEFAN_M     = { "HOWARD", "DONNY", "BEANE" },         -- Uncut Gems; The Big Lebowski; Moneyball
    POKEFAN_F     = { "KATHY", "CONNIE", "KAY" },           -- Singin' in the Rain; The Godfather x2
    GENTLEMAN     = { "LYNDON", "ELI", "BLANC" },           -- Barry Lyndon; Righteous Gemstones; Knives Out
    GRAMPS        = { "VITO", "HARLAN", "FYODOR" },         -- The Godfather; Knives Out; Karamazov
    GRANNY        = { "ZENIBA", "YUBABA", "SARABI" },       -- Spirited Away x2; The Lion King
    SAGE          = { "ZOSIMA", "JIGO", "ALYOSHA" },        -- Karamazov; Princess Mononoke; Karamazov
    ELDER         = { "RAFIKI", "KAMAJI", "OKKOTO" },       -- The Lion King; Spirited Away; Princess Mononoke
    KIMONO_GIRL   = { "SAN", "LIN", "SEORAE" },             -- Princess Mononoke; Spirited Away; Decision to Leave
    CLERK         = { "HULOT", "EMERY", "MO" },             -- PlayTime; Umbrellas of Cherbourg; WALL-E
    GYM_GUIDE     = { "PETE", "OPAL", "ART" },              -- Moneyball; Nashville; Moneyball
  }

  -- The name a coordinator goes by: a class gets one of its names, fixed
  -- for this contest and slot (seeded, so the lobby queue, the stage and
  -- the judging all agree); named vanilla sprites and KC_* customs keep
  -- prettyName.
  local function castName(sprite, slot)
    local planned = slot and stagePlanSlot(slot)
    if planned and planned.name then return tostring(planned.name):sub(1, 7) end
    local base = tostring(sprite):match("^SPRITE_(.+)$")
    local names = base and KC_CLASS_NAMES[base]
    if not names or #names == 0 then return prettyName(sprite) end
    return names[((contestSeed() + (slot or 0) * 7) % #names) + 1]
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
  -- true while the crowd's hearts are popping: World.busy() (wrapped below)
  -- reads it and the player stays put until the score is read
  local kcHoldPlayer = false

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
  -- the player's own stage hearts (kcIntroHearts, shown by the crowd), so
  -- the judging starts from the number the room actually saw
  local stagePlayerHearts = nil

  -- who the three coordinators were, so the judging fights the same
  -- people the stage introduced (it used to fight PIPER/REX/FIONA
  -- whoever was actually standing there)
  local stageRivals = {}

  -- The table both quest-hook events carry and save.kcLastContest stores
  -- (briefs/KANTO_CONTESTS_QUEST_HOOKS.md). Plain data: functions are
  -- added by the emitter AFTER the save copy is taken. `final` is
  -- E.final's rows (who = contestant index, 1 = the player).
  local function contestPayload(place, final)
    local game = mod.game
    local save = game and game.save
    local mine = save and save.party and save.party[1]
    local out = {
      count = contestCount(), seed = contestSeed(), hall = TOWN,
      kind = pendingContest or (mod.save and mod.save:get("kcPendingKind")) or nil,
      rank = pendingRank or "NORMAL",
      place = place,
      entrant = mine and { species = mine.species, nick = mine.nickname or mine.name,
                           stageHearts = stagePlayerHearts } or nil,
      coordinators = {},
      planTag = stagePlan and stagePlan.tag or nil,
      planIgnored = stagePlanIgnored,
    }
    if final then
      out.final = {}
      for _, r in ipairs(final) do out.final[r.who] = r.total end
    end
    for n = 1, #STAGE_COORD_CELLS do
      local r = stageRivals[n]
      if r then
        local c = { sprite = r.sprite, name = r.name, species = r.species,
                    planned = r.planned, stageHearts = appealHearts[n] }
        if final then
          for _, row in ipairs(final) do if row.who == n + 1 then c.place = row.place end end
        end
        out.coordinators[n] = c
      end
    end
    return out
  end
  -- test-only handles (tests/quest_hooks_test.lua); not a contract
  mod.exports._test = {
    applyCastPlan = applyCastPlan,
    contestPayload = contestPayload,
    -- the harness has no live game: give the mod a stub one to read from
    setSave = function(t) mod.game = mod.game or {}; mod.game.save = t end,
  }

  -- Frames between one heart and the next in AROUND ROOM mode. Long
  -- enough to read each one and hear its ding as a separate event.
  local HEART_GAP = 12
  local function heartMode()
    local v = mod.options and mod.options:get("heart_pop")
    if v ~= "burst" then return "seq" end
    return "burst"
  end
  -- How long the appeal holds while n hearts pop -- the call sites used to
  -- hardcode 70 + n * 12, which only fits the burst timing.
  local function heartsHold(n)
    if heartMode() == "burst" then return 70 + n * 12 end
    return 30 + (n - 1) * HEART_GAP + 50 + 20
  end

  local function popHearts(world, n)
    local mode = heartMode()
    -- The crowd claps as its hearts go up, in either mode --
    -- coordinators' and the player's alike. SFX_KC_APPLAUSE is
    -- klankbeeld's clip; with no clip registered Sound.play is a silent
    -- no-op. (0.34.19-0.34.23 rang a ding per heart in AROUND ROOM mode
    -- instead; the developer preferred just the applause, 0.34.24.)
    local data = world and world.game and world.game.data
    if data and (n or 0) > 0 then
      local okS, Sound = pcall(require, "src.core.Sound")
      if okS and Sound and Sound.play then pcall(Sound.play, data, "SFX_KC_APPLAUSE") end
    end
    local crowd = castOnStage(world, false)
    kcHearts = {}
    if #crowd == 0 or (n or 0) <= 0 then return end
    local order = {}
    for i = 1, #crowd do order[i] = crowd[i] end
    if mode == "seq" then
      -- A walk round the room: seats sorted by their angle about the
      -- performer's mark, clockwise from the top-left corner (screen y
      -- grows downward, so increasing atan2 IS clockwise on screen).
      -- Ties broken by id so the same crowd always walks the same way.
      local cx, cy = STAGE_MARK.x + 0.5, STAGE_MARK.y + 0.5
      local function ringAngle(npc)
        local a = math.atan2((npc.cellY or cy) - cy, (npc.cellX or cx) - cx)
        a = a + 3 * math.pi / 4          -- top-left corner reads as zero
        if a < 0 then a = a + 2 * math.pi end
        return a
      end
      table.sort(order, function(p, q)
        local ap, aq = ringAngle(p), ringAngle(q)
        if ap ~= aq then return ap < aq end
        return tostring(p.id) < tostring(q.id)
      end)
      -- n hearts over the ring, every k-th seat, so the walk covers the
      -- whole room rather than bunching in one corner
      local step = math.max(1, math.floor(#order / n))
      for i = 1, n do
        kcHearts[#kcHearts + 1] = {
          entity = order[(((i - 1) * step) % #order) + 1],
          delay  = (i - 1) * HEART_GAP,
          -- each stays up until the walk is over, so the last frame
          -- shows every heart at once and the count can be read
          left   = (n - i) * HEART_GAP + 50,
        }
      end
      return
    end
    -- ALL AT ONCE (0.34.18): spread across DISTINCT onlookers where there
    -- are enough of them, so the count is readable at a glance rather
    -- than stacking on one head
    local rnd = seededRng(contestSeed() + n)
    for i = #order, 2, -1 do
      local j = rnd(i)
      order[i], order[j] = order[j], order[i]
    end
    for i = 1, n do
      kcHearts[#kcHearts + 1] = {
        entity = order[((i - 1) % #order) + 1],
        delay  = (i - 1) * 6,   -- a quick stagger, read as one burst
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
      -- While the crowd's hearts pop there is no text box up, so nothing
      -- froze the player and they could wander off the line mid-appeal
      -- (reported from device). World:stepBody gates player input on
      -- World:busy(), so the hold is one more term in it -- the same way
      -- the engine freezes the world for a rod cast or a tree shake.
      World._kcOriginals.busy = World._kcOriginals.busy or World.busy
      local baseBusy = World._kcOriginals.busy
      World.busy = function(world)
        if kcHoldPlayer then return true end
        return baseBusy(world)
      end
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
    local who = castName(sprite, n)
    -- the partner is seeded off the contest too, so a given entrant
    -- brings the same POKeMON every time you meet that line-up
    local rnd = seededRng(contestSeed() + n * 17)
    -- the worksheet's signature POKeMON first (they ALWAYS bring one of
    -- these, 0.34.28); else their own pool; else the general one
    local rule = sprite and KC_COORD_RULES[sprite]
    local pool = (rule and rule.signature)
      or (sprite and KC_PARTNER_POOLS[sprite]) or KC_PARTNERS
    if #pool == 0 then pool = KC_PARTNERS end
    local species = pool[rnd(#pool)]
    local planned = stagePlanSlot(n)
    local level = nil
    if planned and planned.species and speciesIndexOf(planned.species) then
      species = planned.species
      level = tonumber(planned.level)
    end
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
        local band = KC_RANK_STAGE_HEARTS[pendingRank or "NORMAL"]
                     or KC_RANK_STAGE_HEARTS.NORMAL
        local hearts = band[1] + rnd(band[2] - band[1] + 1) - 1
        appealHearts[n] = hearts
        stageRivals[n] = { name = who, species = species, sprite = sprite,
                           level = level, planned = planned and true or nil }
        -- Ask the room FIRST, let the hearts answer, and only then read
        -- the score. The score line used to come before the hearts, so
        -- it told you the number and the crowd then mimed it.
        world:showText("Folks, what do\nyou think?", function()
          -- the box is DOWN by the time this runs, so the hearts have the
          -- whole room to themselves -- they were popping behind it
          -- before, and half of them were under the text.
          -- hold the player for the whole pop: no box is up, so nothing
          -- else would (reported from device -- they could walk off the line)
          kcHoldPlayer = true
          popHearts(world, hearts)
          waitFrames(heartsHold(hearts), function()
            kcHoldPlayer = false
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

  -- (pendingContest / pendingRank are declared ABOVE ensureStageCast now:
  --  the stage line-up reads the category to apply the worksheet's type
  --  limits, and a read above a `local` is a silent nil -- scope_test.)

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
    local rank = pendingRank or "NORMAL"
    appealHearts = {}
    stageRivals = {}
    stagePlayerHearts = nil     -- never carry a previous contest's number
    local steps = {
      function(next_) world:showText("Hello! Let's get\nstarted with this", next_) end,
      -- dialogue-ok: rank and category are both at most 6 glyphs -> 13
      function(next_) world:showText(("%s %s\nCONTEST!"):format(rank, kind), next_) end,
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
          -- The crowd's number for the player is the Gen 3 introduction
          -- score -- condition, sheen, scarf -- NOT a roll. This was
          -- mineRnd(5)+1 while the judging silently used kcIntroHearts,
          -- so a dull TEDDIURSA drew 4-5 hearts on stage and then went
          -- LAST in the appeal order (both reported from device). One
          -- number now, computed here and handed on as kcPlayerHearts.
          local myHearts = mine and kcIntroHearts(mine, pendingContest or "COOL",
                                                  pendingRank or "NORMAL") or 0
          stagePlayerHearts = myHearts
          popHearts(world, myHearts)
          waitFrames(heartsHold(myHearts), function()
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
      -- The quest hook's MID-CONTEST pause: between the introduction round
      -- and the judging. A listener that sets payload.hold = true takes
      -- the stage here (the player and the cast are in the line-up) and
      -- calls payload.resume() when its scene is done; nobody holding,
      -- the chain goes straight on. resume() is idempotent.
      local payload = contestPayload(nil, nil)
      payload.beat = "intro_done"
      local resumed = false
      payload.resume = function()
        if resumed then return end
        resumed = true
        world:showText("Now -- the\njudging!", next_)
      end
      local ok = pcall(mod.events.emit, mod.events, "mod.kanto_contests.intro_done", payload)
      if not ok or not payload.hold then payload.resume() end
    end
    steps[#steps + 1] = function()
      -- straight into the contest. stageJudge stays for anyone who
      -- reaches the stage some other way and talks to him.
      local kind2 = pendingContest
      if not kind2 then
        mod.log:warn("kc: intro finished with no pending contest")
        -- mod.log has no console on iOS, so this failure was SILENT:
        -- the announcement ended and the player just stood there. Same
        -- visible channel the throw case below uses.
        world:showText("KC error: no\ncontest picked")
        return
      end
      clearPendingContest()
      local rank2 = pendingRank or "NORMAL"
      -- If this throws, runSteps swallows it and the player is left
      -- standing on the stage with nothing happening -- which is exactly
      -- how the last failure presented. Say so.
      local ok, err = pcall(runGoldContest, world, kind2, rank2)
      if not ok then
        mod.log:warn("kc: contest failed to start: %s", tostring(err))
        world:showText("KC error: the\ncontest failed")
      end
    end
    runSteps(steps)
  end


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

  -- ---------------------------------------------------------------
  -- The ECRUTEAK CITY facade (0.34.36).
  --
  -- Painted by the developer in the Content Editor, read back by
  -- tests/read_editor_facade.lua. Same idea as the Goldenrod facade
  -- above -- compose blocks the vanilla tileset does not have, append
  -- them, stamp them on every map entry -- with one difference that
  -- matters.
  --
  -- WHY THIS ONE STORES REFERENCES, NOT TILE IDS. Goldenrod's entries
  -- carry 16 baked tile numbers. That is safe there only by luck: none
  -- of its blocks draws from a vanilla block whose definition differs
  -- between the two games. Ecruteak's do -- SIX of these 22 compose from
  -- TILESET_JOHTO blocks 36/38/40/41/46/47, which are among 18 that
  -- differ, and the two games' sheets are not even the same size (Gold
  -- 128x48, Crystal 128x128 -- the same split the ROOMS loop above
  -- already handles with per-engine variants). Baking Crystal's numbers
  -- would draw Gold the wrong pictures.
  --
  -- So `q` is FOUR (vanilla block id, quadrant) PAIRS -- top-left,
  -- top-right, bottom-left, bottom-right -- and the 16 tiles are built
  -- from the LIVE tileset at map.entered. Correct on both games by
  -- construction, and no per-engine variant needed.
  local KC_ECRUTEAK_FACADE = {
    { bx = 2, by = 7, q = { 44, 0, 44, 0, 44, 2, 44, 3 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 3, by = 7, q = { 44, 0, 44, 0, 44, 3, 45, 3 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 6, by = 7, q = { 42, 0, 42, 0, 4, 0, 4, 1 }, coll = { 0x07, 0x07, 0x00, 0x00 } },
    { bx = 7, by = 7, q = { 2, 0, 3, 0, 2, 0, 2, 0 }, coll = { 0x00, 0x18, 0x00, 0x00 } },
    { bx = 8, by = 7, q = { 2, 0, 3, 0, 4, 0, 4, 1 }, coll = { 0x00, 0x18, 0x00, 0x00 } },
    { bx = 9, by = 7, q = { 2, 0, 42, 0, 2, 0, 2, 0 }, coll = { 0x00, 0x07, 0x00, 0x00 } },
    { bx = 10, by = 7, q = { 42, 0, 1, 0, 3, 0, 1, 3 }, coll = { 0x07, 0x00, 0x18, 0x00 } },
    { bx = 6, by = 8, q = { 4, 2, 4, 3, 1, 2, 1, 2 }, coll = { 0x00, 0x00, 0x00, 0x00 } },
    { bx = 7, by = 8, q = { 2, 0, 2, 0, 1, 2, 1, 2 }, coll = { 0x00, 0x00, 0x00, 0x00 } },
    { bx = 8, by = 8, q = { 4, 2, 4, 3, 1, 2, 1, 3 }, coll = { 0x00, 0x00, 0x00, 0x00 } },
    { bx = 9, by = 8, q = { 3, 0, 3, 0, 1, 2, 1, 3 }, coll = { 0x18, 0x18, 0x00, 0x00 } },
    { bx = 10, by = 8, q = { 3, 0, 1, 1, 1, 2, 1, 3 }, coll = { 0x18, 0x00, 0x00, 0x00 } },
    { bx = 5, by = 9, q = { 44, 2, 44, 3, 38, 0, 38, 1 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 6, by = 9, q = { 45, 2, 45, 2, 38, 1, 38, 1 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 7, by = 9, q = { 45, 2, 45, 2, 38, 1, 38, 1 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 8, by = 9, q = { 45, 3, 1, 3, 47, 1, 1, 3 }, coll = { 0x07, 0x00, 0x07, 0x00 } },
    { bx = 5, by = 10, q = { 40, 0, 36, 3, 38, 2, 47, 2 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 6, by = 10, q = { 36, 3, 41, 0, 47, 2, 47, 2 }, coll = { 0x07, 0x07, 0x07, 0x07 } },
    { bx = 7, by = 10, q = { 41, 0, 41, 0, 46, 3, 47, 2 }, coll = { 0x07, 0x07, 0x71, 0x07 } },
    { bx = 8, by = 10, q = { 41, 1, 1, 3, 47, 3, 1, 3 }, coll = { 0x07, 0x00, 0x07, 0x00 } },
    { bx = 7, by = 11, q = { 1, 0, 71, 3, 1, 2, 1, 3 }, coll = { 0x00, 0x07, 0x00, 0x00 } },
    { bx = 10, by = 13, q = { 2, 0, 2, 1, 71, 3, 2, 3 }, coll = { 0x00, 0x00, 0x07, 0x00 } },
  }

  local ECRU_MAP = "ECRUTEAK_CITY"
  local ECRU_HALL_DEF = KC_HALLS.ECRUTEAK and KC_HALLS.ECRUTEAK.lobby
  -- the door the developer painted, and the pavement square below it
  local ECRU_DOOR_X, ECRU_DOOR_Y = 14, 21
  -- the two signs: the city's own text moved to the new post, and the
  -- hall's name where the old post used to stand
  local ECRU_SIGNS = {
    -- dialogue-ok: 13 / 17 then 14 / 17
    ["20,27"] = "ECRUTEAK CITY\nA Historical City"
      .. "\fWhere the Past\nMeets the Present",
    -- dialogue-ok: 13 / 12
    ["15,22"] = "ECRUTEAK CITY\nCONTEST HALL",
  }

  local ecruFacadeBase = nil

  -- Build one composed block's 16 tiles from the tileset in play.
  -- Quadrant q of a block covers the 2x2 tile square at
  -- ((q//2)*2, (q%2)*2) inside its 4x4 grid (BorderFill/LayeredMap).
  local function ecruTiles(entry, ts)
    local tiles = {}
    for ty = 0, 3 do
      for tx = 0, 3 do
        local qi = math.floor(ty / 2) * 2 + math.floor(tx / 2)
        local srcBlock, q = entry.q[qi * 2 + 1], entry.q[qi * 2 + 2]
        local blk = ts.blocks[srcBlock + 1]
        local idx = (math.floor(q / 2) * 2 + (ty % 2)) * 4
          + ((q % 2) * 2 + (tx % 2)) + 1
        tiles[#tiles + 1] = (blk and blk[idx]) or 0
      end
    end
    return tiles
  end

  local function ensureEcruteakFacade()
    local data = mod.game and mod.game.data
    local tsets = data and (data.gen2Tilesets or data.tilesets)
    local ts = tsets and tsets.TILESET_JOHTO
    -- as with Goldenrod: gen2Tilesets exists only after the Game is
    -- built, which is why this runs on map.entered and not at load
    if not (ts and ts.blocks) then
      mod.log:warn("kc facade: johto tileset unavailable")
      return
    end
    -- THE BORDER RULE. Block id 0 in a map grid does not mean "tileset
    -- block 0" -- it means "draw the map header's border block"
    -- (BorderFill.blockFor). So a stamp must never write 0, and a
    -- composed block must never be given id 0. Appending starts at
    -- #ts.blocks, which is 128 for TILESET_JOHTO, and the guard below
    -- refuses to stamp rather than trusting that. Read, never hardcoded:
    -- another mod may have appended here first.
    if not (ecruFacadeBase
        and ts.blocks[ecruFacadeBase + 1]
        and ts.blocks[ecruFacadeBase + 1].kcEcruteak) then
      if #ts.blocks < 1 then
        mod.log:warn("kc facade: johto tileset is empty; refusing to stamp block 0")
        return
      end
      ecruFacadeBase = #ts.blocks
      ts.collision = ts.collision or {}
      for i, e in ipairs(KC_ECRUTEAK_FACADE) do
        local tiles = ecruTiles(e, ts)
        -- a marker on our own block, so the re-append check above can
        -- tell OUR block from whatever a rebuilt game.data left behind
        tiles.kcEcruteak = true
        ts.blocks[ecruFacadeBase + i] = tiles
        ts.collision[ecruFacadeBase + i] = e.coll
      end
    end
    for i, e in ipairs(KC_ECRUTEAK_FACADE) do
      local id = ecruFacadeBase + i - 1
      -- the same rule again at the point of use: never stamp the void
      if id > 0 then mod.world:replaceBlock(e.bx, e.by, id) end
    end
  end

  local function enterEcruteakHall(world)
    if not ECRU_HALL_DEF then return end
    hallReturn = mod.world:current()
    if world and world.playSfxNamed then
      pcall(world.playSfxNamed, world, "Sfx_EnterDoor", 31)
    end
    local ok, err = mod.world:warpTo(ECRU_HALL_DEF.id,
      ECRU_HALL_DEF.arrival.x, ECRU_HALL_DEF.arrival.y, "up")
    if not ok then
      mod.log:warn("ecruteak hall warp failed: %s", tostring(err))
      world:showText("KC error: hall\nentrance failed")
    end
  end

  mod.events:on("map.entered", function(ev)
    local ok, err = pcall(function()
      local mapId = ev and ev.mapId
      local world = mod.world:overworld()
      -- Aim the working set at whichever hall this map belongs to BEFORE
      -- anything below reads HALL / STAGE_DEF. A map that is no hall's
      -- leaves the current one alone.
      useTown(townOfMap(mapId))
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
      elseif mapId == ECRU_MAP then
        ensureEcruteakFacade()
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
    -- The facade door is a stepped-on cell, not a vanilla warp tile, so
    -- the engine never plays its door sound for it. Play the same one
    -- (World.lua WARP_SFX_NAME: "Sfx_EnterDoor", id 31 as the fallback).
    if world and world.playSfxNamed then
      pcall(world.playSfxNamed, world, "Sfx_EnterDoor", 31)
    end
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

  -- Ecruteak's door, the same way: the painted cell carries COLL_DOOR but
  -- the map has no warp RECORD there, and adding one would mean patching
  -- the map's `warps` LIST, which replaces wholesale and would erase any
  -- other mod's. An exact-cell step trigger costs nothing and collides
  -- with nobody.
  mod.events:on("world.stepped", function(ev)
    if not (ev and ev.mapId == ECRU_MAP) then return end
    if ev.x ~= ECRU_DOOR_X or ev.y ~= ECRU_DOOR_Y then return end
    local ok, err = pcall(enterEcruteakHall, mod.world:overworld())
    if not ok then mod.log:warn("kc ecruteak door: %s", tostring(err)) end
  end)

  -- The two signs.
  --
  -- The hall covers the cell the city's own sign event sits on, so its
  -- text would be unreachable; the developer moved the sign post to
  -- 20,27 and put a second one at 15,22 for the hall. A sign is a
  -- bgEvent, and a map's bgEvents are a LIST (same wholesale-replace
  -- trap as warps), so instead this answers the A press: world.interacted
  -- reports the faced cell and says "none" when nothing there claimed it,
  -- which is exactly a painted-on sign with no event behind it.
  mod.events:on("world.interacted", function(ev)
    if not (ev and ev.mapId == ECRU_MAP and ev.kind == "none") then return end
    local line = ECRU_SIGNS[tostring(ev.x) .. "," .. tostring(ev.y)]
    if not line then return end
    local world = mod.world:overworld()
    if world then pcall(world.showText, world, line) end
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
    elseif ECRU_HALL_DEF and hereId == ECRU_HALL_DEF.id then
      -- out of the Ecruteak hall onto the pavement below its door, never
      -- onto the door itself (that cell is the way back in)
      return ECRU_MAP, ECRU_DOOR_X, ECRU_DOOR_Y + 1
    elseif STAGE_DEF and hereId == STAGE_DEF.id then
      -- The carpet is the ONLY way off the stage now, so this path has
      -- to do what leaveStage does. It did not, and a player who walked
      -- out instead of talking to the judge kept pendingContest set --
      -- so re-entering announced them by name again for a contest they
      -- had already abandoned, with the stale category still armed.
      clearPendingContest()
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

  -- The judging screen. Registered once; runGoldContest pushes it with the
  -- engine state already built, and it calls back with the placing.
  -- The crowd's roar when the applause meter fills. Registered only when
  -- the file is actually in the mod, so a build without it stays silent
  -- rather than logging a bad sfx def every contest. The developer sources
  -- or records the clip (it must be cleared for use); drop it in as
  -- assets/applause.ogg and this picks it up. contest_screen.lua plays
  -- "SFX_KC_APPLAUSE" the first frame a wild line is on screen.
  -- assets/applause.wav: from 0.34.11, Freesound #189831 by klankbeeld
  -- (Creative Commons Attribution -- the required credit line is in
  -- THIRD_PARTY_NOTICES.md, verbatim): the opening with the yell layered
  -- over the clapping from 3 s, mono, bitcrushed to 2 bits at ~2.8 kHz
  -- effective. WAV rather than OGG because the clip was made
  -- with numpy alone (no encoder on the build machine) and LOVE decodes
  -- PCM WAV natively. An .ogg of the same name is accepted too.
  do
    local clip
    for _, name in ipairs({ "assets/applause.wav", "assets/applause.ogg" }) do
      local okA, body = pcall(function() return mod:read(name) end)
      if okA and body then clip = name break end
    end
    if clip then
      local okR, err = pcall(function()
        -- Sound.newFileSource hands `file` to love.audio.newSource as-is, so
        -- it must be the LOVE-resolvable form: mod.assets:path joins it onto
        -- mod.path exactly as mod.assets:image does for love.graphics.newImage.
        mod.content.sfx:register("SFX_KC_APPLAUSE", { file = mod.assets:path(clip) })
      end)
      if not okR then mod.log:warn("kc applause sfx: %s", tostring(err)) end
    end
  end

  mod.content.screens:register("KantoContestStage", {
    new = function(game, opts)
      return KCS.new({
        engine = KCE, state = opts.state, game = game,
        kind = opts.kind, rank = opts.rank,
        moveMenu = opts.moveMenu,
        onDone = function(place, final)
          game.stack:pop()
          if opts.onDone then opts.onDone(place, final) end
        end,
      })
    end,
  })

  runGoldContest = function(world, kind, rank)
    local game = world.game
    rank = rank or "NORMAL"
    if not (KCE and KCS) then
      world:showText("KC error: no\ncontest engine")
      return
    end
    local entrant
    for _, mon in ipairs((game.save and game.save.party) or {}) do
      if not mon.isEgg and (mon.hp or 0) > 0 then entrant = mon break end
    end
    if not entrant then
      world:showText("KC error: no\nentrant")
      return
    end
    local sp = game.save and game.save.player
    local info = {
      kcRank = rank, kcAppealHearts = appealHearts, kcRivals = stageRivals,
      kcPlayerName = (sp and sp.name) or "YOU",
      kcPlayerHearts = stagePlayerHearts,
    }
    -- the engine wants rng(lo, hi) / rng(n); seededRng gives 1..n, so wrap
    -- it, seeded off this contest so a replay judges the same field
    local base = seededRng(contestSeed() + 977)
    local function contestRng(lo, hi)
      if hi == nil then return base(lo or 1) end
      if hi < lo then lo, hi = hi, lo end
      return lo + base(hi - lo + 1) - 1
    end
    local ok, state = pcall(buildContestState, game.data, kind, info, entrant, contestRng)
    if not ok then
      mod.log:warn("kc contest build failed: %s", tostring(state))
      world:showText("KC error: the\ncontest failed")
      return
    end
    local function pushJudging()
    mod.ui.push(game, "KantoContestStage", {
      state = state, kind = kind, rank = rank,
      moveMenu = mod.options:get("move_menu") or "full",
      onDone = function(place, final)
        -- the gym theme played into the judging; the hall gets its own
        -- song back before the closing line is read
        pcall(world.playMapMusic, world)
        -- Off the stage and back to the lobby afterwards, win or lose:
        -- the routine is over, so standing on an empty stage is not an
        -- ending. Nested in the closing line's callback so the box is
        -- read before the screen moves.
        local function backToLobby()
          if onStageNow() then leaveStage(world) end
        end
        -- the quest hook: record (unless the plan says this contest does
        -- not count), write the result to the save, then tell listeners
        -- BEFORE the closing line so a scene can start right here
        local plan = stagePlan
        local record = not (plan and plan.record == false)
        local won = place == 1
        if won and record then
          entrant.contestWins = entrant.contestWins or {}
          entrant.contestWins[kind] = (entrant.contestWins[kind] or 0) + 1
          -- Trophy Case (0.34.35): Gen 3 hangs a Master-rank winner's
          -- portrait in the museum; here the trophy is a case key. The
          -- reader fails safe on an uncatalogued key (nothing is drawn),
          -- so this writes whether or not Trophy Case is installed --
          -- the contract in exchange/CONTRACTS.md (kc-trophies).
          if game.save then
            game.save.trophyUnlocks = game.save.trophyUnlocks or {}
            game.save.trophyUnlocks["kanto_contests:debut"] = true
            if rank == "MASTER" then
              game.save.trophyUnlocks["kanto_contests:master_" .. tostring(kind):lower()] = true
            end
          end
        end
        if won then pendingRank = nil end
        local result = contestPayload(place, final)
        result.recorded = won and record
        if game.save then game.save.kcLastContest = result end
        local payload = {}
        for k, v in pairs(result) do payload[k] = v end
        payload.beat = "result"
        local resumed = false
        -- a holder finishes with resume("lobby") to be walked out, or
        -- resume("stage") / resume() to be left where they are
        payload.resume = function(where)
          if resumed then return end
          resumed = true
          if where == "lobby" then backToLobby() end
        end
        local ok = pcall(mod.events.emit, mod.events, "mod.kanto_contests.result", payload)
        if ok and payload.hold then return end
        -- nobody held: the plan's closing, else this mod's own
        local closing = plan and plan.closing
        if closing == "stage" then return end
        if closing == "lobby" then backToLobby() return end
        if not won then
          world:showText("Not quite this\ntime. Practice!", backToLobby)
          return
        end
        -- dialogue-ok: %s is a contest category, six glyphs at most
        world:showText(("Magnificent!\nTruly %s!"):format(kind), backToLobby)
      end,
    })
    end
    -- An important battle's opening, before the judging (0.34.25): the
    -- gym-leader theme starts and the cart's trainer-battle transition
    -- runs -- the triple flash and the wipe (Gen2BattleTransition;
    -- PlayBattleMusic runs BEFORE DoBattleTransition on the cart too,
    -- which is why the song is already going while the screen flashes).
    -- Equal levels pick the plain trainer wipe. If the transition cannot
    -- take the screen (no map up, a headless run) the judging comes
    -- straight in, exactly as before.
    pcall(function()
      local Music = require("src.core.Music")
      Music.play(game.data, "Music_JohtoGymBattle", true, { reason = "battle" })
    end)
    local lvl = KC_RANK_LEVEL[rank] or KC_RANK_LEVEL.NORMAL
    local pushed = false
    local okT, took = pcall(world.pushBattleTransition, world,
      { player = { level = lvl }, enemy = { level = lvl } }, { trainer = true },
      function()
        if not pushed then pushed = true; pushJudging() end
      end)
    if not (okT and took) and not pushed then pushed = true; pushJudging() end
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
          local function proceed(rank)
          pendingRank = rank
          pendingContest = kind
          if mod.save then mod.save:set("kcPendingKind", kind) end
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
                clearPendingContest()
                mod.log:warn("contest stage warp failed: %s", tostring(err))
                world:showText("KC error: stage\nentrance failed")
              end
        end)
          end -- proceed
          -- NO RANK MENU any more (0.34.41): this hall runs one rank, so
          -- the only question is whether this POKeMON has earned it. The
          -- ladder is unchanged -- a mon may enter one rank above its wins
          -- in the category -- it is just checked instead of offered.
          local want = hallRank()
          local elig = eligibleRanks(party[slot], kind)
          local allowed = false
          for _, r in ipairs(elig) do if r == want then allowed = true end end
          if allowed then
            proceed(want)
          else
            -- the party is already parked: give it back before refusing
            restoreParty(world)
            local need = KC_RANKS[math.max(1, rankIndex(want) - 1)]
            -- dialogue-ok: rank names are six glyphs at most
            world:showText(("This hall runs\n%s rank."):format(want),
              function()
                world:showText(("Win a %s\ncontest first."):format(need))
              end)
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
        clearPendingContest()
        runGoldContest(world, kind, pendingRank or "NORMAL")
      end)
  end

  leaveStage = function(world)
    clearPendingContest()
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
  -- cast_lines.lua is DATA (written by a design order): characters by
  -- sprite id, classes by class, generic pools; each holds contexts
  -- queue / stage / won / lost / crowd. Loaded like contest_engine.lua;
  -- if it fails to load the one-line fallback below keeps the cast
  -- talking rather than silent.
  local KC_LINES = nil
  do
    local okR, src = pcall(function() return mod:read("cast_lines.lua") end)
    if okR and src then
      local chunk, err = load(src, "@" .. mod.path .. "/cast_lines.lua")
      if chunk then
        local ok, result = pcall(chunk)
        if ok and type(result) == "table" then KC_LINES = result
        else mod.log:warn("cast_lines.lua: %s", tostring(result)) end
      else mod.log:warn("cast_lines.lua: %s", tostring(err)) end
    end
  end
  KC_LINES = KC_LINES or { characters = {}, classes = {}, pools = {} }
  local FALLBACK_LINE = "Good luck out\nthere!"

  -- Which context an actor is spoken to in.
  local function lineContext(world, def)
    if not def.kcCoordinator then return "crowd" end
    local save = mod.game and mod.game.save
    local last = save and save.kcLastContest
    -- a coordinator spoken to after THIS contest's judging
    if last and last.count == contestCount() and last.place then
      return last.place == 1 and "won" or "lost"
    end
    local mapId = world and world.map and world.map.id
    if STAGE_DEF and mapId == STAGE_DEF.id then return "stage" end
    return "queue"
  end

  -- Stable per-actor pick: the same person says the same thing all
  -- contest rather than a new line every A press, but different people
  -- say different things. Most specific pool with lines wins:
  -- character -> class -> generic.
  lineFor = function(world, npc)
    local def = npc and npc.def or {}
    local sprite = def.sprite
    local ctx = lineContext(world, def)
    local base = sprite and tostring(sprite):match("^SPRITE_(.+)$")
    local function pick(pool)
      if type(pool) ~= "table" or #pool == 0 then return nil end
      local sum = contestSeed()
      for c in tostring(def.name or "?"):gmatch(".") do sum = sum + string.byte(c) end
      return pool[(sum % #pool) + 1]
    end
    local ch = sprite and KC_LINES.characters and KC_LINES.characters[sprite]
    local cl = base and KC_LINES.classes and KC_LINES.classes[base]
    local pools = KC_LINES.pools or {}
    -- a won/lost context falls back to stage, then queue, before the
    -- generic pools do the same
    local order = { ctx }
    if ctx == "won" or ctx == "lost" then order[#order + 1] = "stage" end
    if ctx ~= "crowd" then order[#order + 1] = "queue" end
    for _, source in ipairs({ ch, cl, pools }) do
      for _, c in ipairs(order) do
        local line = source and pick(source[c])
        if line then return line end
      end
    end
    return FALLBACK_LINE
  end

  local function talkCast(world, npc)
    world:showText(lineFor(world, npc))
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
  local VERSION = "0.34.43"
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
    -- 0.34.19: how the crowd's hearts pop in the first round. AROUND ROOM
    -- walks them round the seats one at a time with a ding each; ALL AT
    -- ONCE is exactly 0.34.18 (a quick stagger under the applause). The
    -- option IS the revert -- flip it in the mod manager, no rebuild.
    -- Entries are POSITIONAL: [1] display, [2] stored.
    { key = "heart_pop", type = "choice", label = "HEARTS POP",
      default = "seq",
      choices = { { "AROUND ROOM", "seq" }, { "ALL AT ONCE", "burst" } } },
    -- 0.34.26: FULL INFO puts the move list where the panels are and a
    -- card about the highlighted move in the text box; CLASSIC is the
    -- 0.34.25 menu (the list in the text box, panels showing).
    { key = "move_menu", type = "choice", label = "MOVE MENU",
      default = "full",
      choices = { { "FULL INFO", "full" }, { "CLASSIC", "classic" } } },
  })

  -- shared read-only exports, meaningful on both generations
  -- the quest hook's call-style side: the last result, and the hook
  -- version a listener can check (briefs/KANTO_CONTESTS_QUEST_HOOKS.md)
  mod.exports.questHooks = 1
  mod.exports.lastContest = function()
    local save = mod.game and mod.game.save
    return save and save.kcLastContest or nil
  end
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
