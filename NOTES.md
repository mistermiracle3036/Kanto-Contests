# Parked / revisit later

Things deliberately left open, so they don't get quietly settled by
whoever touches the file next.

## Wording and numbers to reassess

- **Appraiser tier names** — `dull / promising / impressive / radiant`
  and the four sheen phrases are PROVISIONAL. They live in `KC_TIERS` and
  `KC_SHEEN_LINES` in `main.lua`, deliberately in one place each so
  renaming is a single edit.
- **Snack price** — 500 is an opening guess (`KC_SNACK_PRICE`).
- **Snack strength** — +20 condition, +10 sheen (`KC_SNACK_CONDITION`,
  `KC_SNACK_SHEEN`). Ten snacks per mon ever is the intended scarcity:
  two categories maxable, never all five. Don't soften without deciding
  to.
- **Jam tuning** (30% chance / 8% heal / cap 2) once slice 4 lands and
  gets real playtests.

## Known rough edges

- ~~The vendor is an ask-chain~~ **Fixed in 0.8.1**: the vendor pushes
  the engine's own `ShopMenu` (`ShopMenu.new(game, stock, onQuit)`,
  ShopMenu.lua:152) with a literal stock array. That is the same screen
  `Commands.open_mart` opens for ROM marts, so mod items need nothing
  special and BUY/SELL/QUIT, the quantity selector and the money box all
  come for free.
- **Contest HUD is classic-layout only.** The widescreen layout shows the
  judge and the appeal meter but not the contest dressing (APPEAL label
  row, hidden level, no `HP:` label, category box in the move list).
  `WideBattle`'s `drawHUDs`/`drawTextArea` are file-local and unreachable
  from a mod; the level could in principle be hidden by keeping
  `shownStatus` set, but the engine resets it every menu-phase frame
  (`BattleState.lua:1833`), so it would mean wrapping `update`.

## Engine findings worth not rediscovering

- **Bag pockets are not the engine's.** The items schema has no `pocket`
  field and the engine has one flat bag. The pockets seen on device come
  from the third-party Modern Bag mod (read v1.5.2 source, 2026-08-10).
  Its `pocketFor(id, def)` decides, in order: `def.machine` -> TM HM;
  **`def.ball`** -> BALLS; a hardcoded X-item list -> BATTLE; a hardcoded
  vanilla-medicine list -> MEDICINE; then for modded records an inference
  on `def.effect` AS A STRING matching HEAL/REVIVE/MEDIC/VITAMIN/ETHER/
  ELIX/CANDY/PP_UP -> MEDICINE; `def.keyItem` or `tossable == false` ->
  KEY ITEMS; else OTHER.
  - This is why custom BALLS sort correctly with no coordination: they
    set the real `ball` schema field. Documented in its README too.
  - Snacks land in OTHER, which is where they belong -- that pocket is
    defined as "everything not covered above", and snacks are not
    medicine.
  - Getting them into MEDICINE would mean setting `effect` to a string
    containing e.g. VITAMIN. But the engine validates `effect` as
    `f.id("item_effects")`, so it would ALSO need an item_effects record
    registered purely to make the reference resolve -- re-entering the
    dead registry (below) to satisfy another mod's heuristic. Declined
    deliberately.
  - Modern Bag exports `pocketFor` read-only. There is no registry for
    declaring a pocket and no override, so any placement trick is an
    inference that its next version may change.

- **`mod.content.item_effects` is a dead registry in 0.1.75.** It
  validates and merges into `data.item_effects`, and nothing ever reads
  it — the only references in the whole engine are the schema entry
  (`Schemas.lua:750`) and a test asserting the merge. There is no
  item-use hook either. The snacks therefore replace
  `ItemEffects.use` and `ItemEffects.needsTarget` directly
  (stash-originals, like every other wrapper here).
  - `ItemEffects.needsTarget` (`ItemEffects.lua:75`) is a hardcoded id
    list and ignores the items schema's own `needsTarget` field, so that
    field is dead too.
  - **A later engine WILL likely wire it, and our approach survives that.**
    zeak6464's Gen1Recomp-Content-Editor fork already does: its
    `ItemEffects.use` dispatches `data.item_effects[itemDef.effect]` at
    the TOP of the function, before the stock id tables, calling
    `effect.use(data, save, itemId, target, battle, moveIndex, ow)` and
    returning its (result, messages) tuple -- with `effect.battle ==
    false` / `effect.field == false` as refusal gates. Because that
    dispatch lives INSIDE `ItemEffects.use`, and our wrapper returns for
    snack ids without ever calling the original, a wired engine cannot
    double-apply. The earlier worry was that dispatch might happen
    OUTSIDE use(); the natural implementation puts it inside.
  - So if upstream wires it, migrating snacks to the real registry is
    small: our per-snack logic already returns the right tuple shape.
    Register the effect, point `items.effect` at it, drop the two
    wrappers. Do NOT do both at once.
  - That fork also reads `itemDef.ball` in `ItemEffects.use`, which
    0.1.75 does not -- 0.1.75 needs the `ItemEffects.BALLS[id] = true`
    poke that snag_quest does. Another sign it is ahead of 0.1.75.
  - Caution for the editor's own output: its "Heal HP" and "Status cure"
    item templates emit `item_effects` records, which do nothing on
    0.1.75. Editor-authored healing items would not heal for our players.
- **`Commands.show_text` and `Commands.ask` block on their own** — they
  push the box and call `runner:yield()` internally
  (`Commands.lua:137-141`). Yielding again after them parks the runner
  with nothing to resume it. `Screens.push` does NOT yield, so the party
  picker does need an explicit yield/resume pair.
- **Text box is 18 glyphs per line with no wrapping.** Nicknames cap at
  10 (`BattleState.lua:4437`) and the longest snack name is 12
  (`BITTER SNACK`), so a name and a snack name can never share a line.
  `scratchpad/textcheck.py`-style auditing caught two real overflows in
  this slice.

## Gen 2 / Gold assessment (2026-08-11, engine 0.1.78)

The standing direction is Gold-first with Red backfill, so this is where
the next big feature gets designed. Findings from gen2check + reading the
Gold source; per-file line refs are to the 0.1.78 tree.

**This is a parallel implementation, not a port.** A Gold boot never
loads `src/battle/BattleState.lua` or `src/inventory/ItemEffects.lua`, so
every wrapper this mod is built from lands on modules nothing
instantiates -- silently absent, not broken. gen2check findings (MK402
Commands, MK404 newTrainer, MK409 'PartyMenu', MK405 tryRun) are the
visible tip of that.

Verified seams a Gold build CAN use:
- `World:startBattle(opts)` (gen2/World.lua:5776) -- takes
  `trainer`/`wild`/`battleType`, pushes `Gen2BattleState`. A judge battle
  is constructible. The instrumentation (appeal scoring, meter, no-EXP)
  must be rebuilt against `src/battle/gen2/Battle.lua` +
  `src/ui/gen2/BattleState.lua`.
- `world.interacted` event exists on Gold (gen2/World.lua:7273); the
  kind="none" fall-through is the dialogue route -- the Gen 1
  map_scripts talk pattern is dead there.
- Gold has a native `BATTLETYPE_CONTEST` -- the National Park
  Bug-Catching Contest (`World:tryContestEncounter`,
  gen2/World.lua:4124). Different mechanic (catch-and-judge), but it
  makes the Park the natural Johto venue candidate.

Verified blocks:
- **Vendor:** `gen2Marts` has no mod-facing registry and `ShopMenu` is a
  Gen 1 screen. Blocked on the engine; watch each release for a marts
  registry.
- **Custom maps:** registry targets are Gen 1 data tables;
  Gen2Compat's DATA_RENAMES routes *reads* (maps -> gen2Maps) but whether
  mod-registered maps MERGE into gen2Maps is unverified. Verify before
  planning a Gold hall map.
- **Snacks on Gold:** Gen 2 has its own pack/item path; the
  ItemEffects.use wrapper does not exist there. Needs its own seam
  audit.

**Venue decided 2026-08-11: GOLDENROD CITY** (developer's call). The
0.10.0 spike stands the attendant there.

**0.10.0 spike facts (all source-verified at 0.1.78):**
- Entry branches on `GameVersion.generation()` BEFORE any Gen 1 require
  executes -- on Gold an executed require of an unserved Gen 1 module is
  a loader ERROR, not a silent no-op. The test harness injects
  loader.generation without setting GameVersion.current, so
  `tests/gen_gate_test.lua` sets both, the way a real boot does.
- The judge is a PLAIN TRAINER TABLE handed to `world:startBattle`
  (Battle.new reads opts.trainer directly, enemyParty from trainer.party;
  trainer.attributes optional). The table's identity doubles as the
  contest marker: hooks check `b.trainer.kcContest` -- no registry, no
  battle.started race.
- Dialogue: `OverworldController.talkTo` via the facade (backed; a true
  return suppresses the built-in path). `World:showText(text, cb)` and
  `World:askYesNo(onChoose)` are the box seams; askYesNo rides the
  standing box, the Vm's own pattern.
- Attendant: `mod.world:spawnNpc` works on Gold (WorldAPI gen2:146 ->
  addRuntimeObject). SPRITE_TEACHER verified in gen2 sources. Her x,y is
  a TODO/CONFIRM first guess.
- `battle.damage` hook returns (damage, info); info.effectiveness = 10
  suppresses effectiveness text. `battle.enemy_action` returning nil is
  passed through unwrapped (Battle.lua:3870) -- TODO/CONFIRM a nil enemy
  move resolves as "no action" on a real boot.
- gen2check still FAILS statically -- it cannot see the runtime branch,
  so the Gen 1 arm's requires still report. The headless dual-gen load
  test is the actual gate; a real Gold boot is the remaining one.

**A building on Gold -- assessed 2026-08-11, seams verified at 0.1.78:**
- `WorldAPI:warpTo(mapId,x,y,facing)` warps into ANY map in world.maps
  (gen2/WorldAPI.lua:55). Borrowing an existing Goldenrod interior is
  therefore viable today: attendant dialogue -> warpTo -> dress the room
  with runtime NPCs; the house's own door exits back into Goldenrod.
  GOLDENROD_PP_SPEECH_HOUSE (4x4, a nothing house) is the candidate;
  avoid HAPPINESS_RATER (a beloved NPC lives there). Hiding vanilla
  occupants via toggleObject is PERSISTENT (visibility IS the event
  flag) -- prefer leaving them be or picking an empty room.
- `world.maps` is one mutable table per run (addRuntimeObject already
  appends into defs), so CLONING an interior def under a new key and
  warping to it looks possible: same tileset/palette/blockdata pointers,
  own objects, exit warp rewritten to a Goldenrod door cell. Warp-dest
  field shape still unread -- one contract to verify before building.
- An EXTERIOR building can in principle be painted: `changeBlock` is the
  CUT/WHIRLPOOL buffer edit, undone on every map reload (World.lua:2014)
  so it re-applies on map.entered like runtime NPCs; block ids can be
  read off a real Goldenrod building at runtime (Map:blockId) and
  stamped elsewhere, bringing that block's own collision. The door needs
  a def.warps row PLUS a poke into the live map's _warpAt index -- it is
  built once at Map.new (Map.lua:34-37) and never re-read.
Recommended order: borrow (A) -> prove the loop -> then exterior paint +
cloned interior (C+B) as the owned hall.

**Still deferred on Gold** (engine-blocked or unread seams): vendor (no
gen2Marts registry), snacks in the bag (no Gold ItemEffects seam),
appraiser (Gold party-picker unread), custom hall map (mod-map merge into
gen2Maps unverified), Introduction Round (no pre-battle drain seam read).

**0.10.1 findings (first Gold test round + headless repro):**
- The engine substitutes STRUGGLE for a nil enemy action
  (Battle.lua:4144, the cart's dry-mon rule) -- the judge WILL act each
  turn and there is no skip seam. Harmless (our damage hook zeroes both
  directions) but noisy; capped at five by the appeal limit. A message/
  skip seam is the polish-pass want.
- `Battle:emit({kind="message", text=...})` (Battle.lua:365) is the Gold
  message channel a hook can reach -- the judge's reactions ride it.
- Five-appeal limit: `Battle:endBattle("run")` from a battle.turn_ended
  listener is the clean loss exit; verified headlessly.
- **Status moves never reach battle.damage on Gold** -- they execute
  their real effect and score nothing, silently. Gen 1 converts every
  move at performMove; Gold has no equivalent seam read yet. Real gap,
  polish pass.
- The headless repro (scratchpad kc_gold_battle_repro.lua pattern:
  fixtures cribbed from tests/gen2_battle_end_test.lua, real mod loaded
  via T.sdk.loadMod, real Battle driven with takeTurn) proved scoring
  correct before any device round -- keep using it.

**0.1.79 re-check (2026-08-12):** every seam above and in the building
assessment re-verified against the new tree -- warpTo/replaceBlock/
spawnNpc, changeBlock, addRuntimeObject, _warpAt, startBattle, askYesNo,
showText, talkToWrapper all present; the dual-gen load test passes
unchanged. Two openings from the engine brief worth acting on later:
- **The Gold vendor may be un-blockable without waiting for a registry:**
  Too Many Balls stocks Gold shelves by appending directly to
  `data.gen2Marts` at game.ready, and the checker verified all four facts
  that workaround rests on still hold at 0.1.79. For snacks the extra
  question is whether MOD-REGISTERED ITEMS exist on a Gold boot at all
  (the items registry's gen2 target is unread) -- investigate that
  before copying the pattern.
- **`mod.datetime` is new** (read-only, option-formatted date/time).
  Gold is time-of-day driven; contest flavor (evening contests, a
  day-limited schedule) becomes possible without touching internals.

Meanwhile: new Gen 1 slices (scarves, rivals) should reach for
`mod.game`/`mod.world`/hooks over `require("src.script.Commands")`
wherever a seam exists, so they don't deepen the MK402 debt.

## Verifying a Gold spawn cell WITHOUT a device round trip

0.10.0 guessed the attendant's cell and shipped her inside a wall; the
Gold test could only report "unreachable". The cell is checkable from
here, and this is the procedure:

```lua
-- from the engine checkout, luajit:
local Perm = require("src.world.gen2.Permissions")
local D = [[C:/Users/dwitt/AppData/Roaming/pokemon-love2d/gold/data/generated/]]
local maps, tilesets = dofile(D.."maps.lua"), dofile(D.."tilesets.lua")
local m, ts = maps["GOLDENROD_CITY"], nil
ts = tilesets[m.tileset]
-- cell -> block -> quad
local b = m.blocks[math.floor(cy/2)*m.width + math.floor(cx/2) + 1]
local byte = ts.collision[b+1][(cy%2)*2 + (cx%2) + 1]
Perm.isWalkable(byte)   -- 0x00 walkable, 0x07 wall
```

Measured facts for GOLDENROD_CITY: 20x18 blocks = 40x36 cells, 14 vanilla
objects, 15 warps. **(14,14) is 0x07, a wall** -- that was the bug.
**(22,8) is 0x00**, three approach tiles (S/W/E) with a wall north, no
vanilla object or warp within a cell: the attendant's home.

Two more Gold NPC facts confirmed the same pass:
- **`movement` is NUMERIC on Gen 2**, not Gen 1's "STAY" string --
  `Npc.lua`'s MOVE table, `STANDING_DOWN = 6`. Every vanilla Goldenrod
  object uses a number (7, 2, 8, 5, ...).
- **The `talkTo` seam DOES work for a mod-spawned NPC.** Assigning
  `OverworldController.talkTo` on Gold lands on the Gen2Compat facade and
  `Gen2Compat.talkToWrapper()` returns it, so `World:interactBody`
  dispatches into the mod -- verified by loading the mod headlessly and
  reading the wrapper back. The `world.interacted` kind="none"
  fall-through is a valid alternative, not the only route; the Gen 1
  `map_scripts`/`text = TEXT_*` pattern remains dead.

Always report the cell finally used (`mod.log:info` on desktop, or the
[ERRS] screen on iOS): a silent fallback is how a mod ends up documenting
a spot that never worked.

## For future audits: the four "Gen 1 sites on Gold" are behind a branch

A checker brief (2026-08-14, engine 0.1.85) reported four sites taking the
Gen 1 path on Gold: `BattleState.newTrainer` (~:1091), the
`src.script.Commands` require (~:1203), the `"PartyMenu"` screen id
(~:1229) and the `tryRun` override (~:916). **All four are below the
generation branch at ~:456 and never execute on a Gold boot.** The brief
said plainly it read the sites without tracing control flow; `gen2check`
has the same blind spot, being a static scan.

Verified, not asserted: `tests/gen_gate_test.lua` loads the mod through
the production loader on BOTH generations and asserts zero boot errors,
plus an explicit assertion that `src.script.Commands` never leaks past the
branch. That assertion was negative-controlled -- injecting a require
above the branch makes it fail with exactly the engine's message
("requires src.script.Commands, which a Gen 2 game never runs"), so it is
detecting the real condition rather than passing vacuously.

Why `src.script.Commands` is the canary specifically: engine 0.1.85's
`GEN1_ONLY_MODULES` (Loader.lua) also lists `src.battle.BattleState`, but
Gen2Compat SERVES that one, so it could never file the error either way.
Commands is served by nothing, so it is the honest test.

**What the brief got right and still stands:** 0.1.85 made this class of
failure player-visible (boot error feed, not a log line), which matters
because iOS has no log; and declaring `games: gen1+gen2` while the Gold
path is unverified is the real risk. That risk is about DEVICE testing,
not these four sites.

**Open Gold question the brief raised that is genuinely unanswered:**
whether `"ShopMenu"` resolves on Gold. Moot today -- that push is in the
Gen 1 arm -- but it becomes real the moment the Gold vendor is built, so
check it then rather than trusting gen2check's silence.

## Roadmap after slice 1

Slices agreed with the developer, one release each:

2. ~~Introduction Round~~ **Shipped in 0.9.0.** `kcIntroHearts` computes
   the score, `b.kcHearts` carries the result for slice 4's rivals, and
   the head-start fraction lives in `KC_INTRO_METER_FRACTION`. Scarf
   bonus is the one missing term (slice 3).
3. **Scarves** — five worn items setting `mon.kcScarf`, +20 intro points
   when matching. Never sold; granted by other mods through an exported
   `giveScarf`. Needs `mod.exports.scarves` + `giveScarf(save, category)`.
4. **Rivals and Jam** — three rival coordinators per contest, hearts
   announced at the intro, and a chance per round from round 2 that a
   rival jams and heals the judge's meter.

Unscheduled: blender-style minigame; ranks + per-category ribbons via
kanto_ribbons.

## 0.11.0 findings

- **`kanto_ribbons` gates per RIBBON, not per mod.** Its `syncContest`
  awards on `mon.contestWins[CATEGORY]` but only when `inCatalog(id)` --
  and its `ribbons.lua` catalog has COOL and nothing else, so a BEAUTY win
  writes the save field and awards nothing until that mod draws the icon.
  So "is Kanto Ribbons installed" stopped being the same question as "can
  the judge promise a ribbon". `ribbons_missing` now reads the other mod's
  exported `catalog` through `mod.find(...).exports` (Loader.lua:1428-1434)
  and asks about the category actually being judged. Any surprise in
  another mod's exports falls through to "no promise", which is the safe
  direction. A brief for the four remaining icons is in briefs/.
- **The Gen 1 script VM passes LITERAL arguments only**, so a `show_text`
  row cannot name the category the player just chose -- which is how five
  rows of the judge's script came to say COOL. Category-aware lines go
  through the `kanto_contests:judge_line` command instead.
- **`ListMenu` pops itself on CANCEL but not on CHOOSE** (ListMenu.lua:196
  and :218 vs :223). Popping in both arms takes the overworld off the stack
  behind the menu. `PartyMenu` is not the same shape, so the appraiser's
  pattern cannot be copied blindly.
- **`tests/check_dialogue.py` is a corrected fork.** The Johto-Quest-Pack
  original converts only `\n` and leaves `\f` in the string as text, so
  every page-broken line reads as one over-width row -- 30 findings on this
  file, nearly all false. Ours splits `\f` into pages first, then `\n`/`\v`
  into rows, and knows that only `\v` and `\f` wait for a button. It also
  honours a `-- dialogue-ok: <reason>` marker, because the width pass
  assumes a `%s` is a 10-glyph nickname and several here are six-glyph
  category names.
  - It found four REAL over-length pages that had shipped, the worst being
    the Johto hall's four-row "would you like to go inside?" -- the player
    saw the question with the subject already scrolled away.
  - **Battle messages cannot use `\f`.** `startMessage` splits on `[\n\v]`
    only, so an over-long battle line becomes a second `sayNext`, never a
    page break.
- **Harness flake, not a mod defect:** the first `luajit` run right after
  writing main.lua sometimes reports every version as `state = nil` (the
  loader never discovers the mod), and is green on every re-run. Seen three
  times on Windows, never reproducible with `touch` or a rewrite.
  `gen_gate_test.lua` now prints what the loader did discover, so a
  recurrence explains itself instead of showing a bare nil.

## 0.12.0 findings

- **The Gold overworld ask pattern is NESTED, never sequential.**
  `askYesNo` called on the line after `showText` finds no stayed box
  (that only exists once the last page finishes typing) and takes its
  fallback: it pushes a second, INSTANT box holding only `lastText`'s
  final page, over the first box while it is still typing. The player
  answers on the duplicate, then the original box is revealed underneath
  and must be paged through again. The 0.11.0 device report -- "not
  showing full text" and "lines weirdly repeated" -- was both halves of
  this one call shape. The engine's own pattern is
  `showText(text, function() askYesNo(...) end)` (World.lua:5903).
- **The Gold battle box CUTS, it does not scroll.** `printMessage` wraps
  to two 18-tile rows and drops the rest (gen2/BattleState.lua:3636-3639,
  "cut rather than spilling"). Any battle emit that can wrap past two
  rows loses its tail silently -- five shipped judge lines did, including
  the whole five-appeal verdict. Battle emits also have no `\f`: a page
  break is a SECOND emit. The dialogue scanner cannot see these (they are
  single-line literals with no marker), so keep battle emits short by
  construction.
- **Jam heals step the bar instead of animating.** Both arms write
  `meter hp` directly because the damage paths are damage-only; the HUD
  redraws from hp so the value is right but the bar jumps. Cosmetic.
  If it grates on device, the fix is a negative-damage event shim, not a
  bigger heal.
- **Jam tuning is provisional** (30% per round in rounds 2..4, 8% heal,
  cap 2 -- constants at the top of main.lua). Revisit after real
  playtests; the cap and the round-1 exemption are design decisions, the
  percentages are guesses.

## Making the hall look better -- assessment (2026-08-27)

Both halls are bare rooms: Johto is 10x10 cells of one floor block, Kanto
8x8. Three options, cheapest first:

1. **People and layout only (done in 0.12.0).** The three rival
   coordinators now stand in both halls. Zero art risk.
2. **Borrow a vanilla interior tileset for the Johto hall.** The map
   record's `tileset` field is a plain id; pointing it at a vanilla
   interior tileset (the Goldenrod Dept. Store floors, the Game Corner)
   would buy real walls, counters and plants for free. UNVERIFIED whether
   a mod-registered gen2 map may reference a vanilla tileset id -- Hidden
   Grottos shipped a private tileset, so nothing proves the cross
   reference. Verify OFFLINE first: load the imported cache, point a
   scratch map def at TILESET_GAME_CORNER, and walk `Permissions` over
   the result exactly like the attendant-cell check -- no device round
   needed until it renders.
3. **Extend the private tilesets with contest dressing** (stage platform,
   red carpet, rope line, poster wall). Full control, most work: the
   Johto tiles are authored in-code as explicit pixel blocks, the Kanto
   ones live in assets/contest_tiles.png (Pillow is installed). A stage
   row behind the judge plus a carpet strip down the middle column is the
   highest-value minimum.

Recommendation: verify 2 with the cache renderer; if the cross-reference
holds, do 2 for Johto and a small 3 for Kanto's stage row. If it does
not, do 3 on both with the same two elements.

## 0.13.0: the Emerald stage room (and what remains for the look)

Direction from the developer mid-0.12.0-test, with Emerald screenshots:
keep the GEN 3 contest presentation -- the stage room (audience ring on a
ledge, judging machine, emblem mid-stage, contestants lined up until
their turn) and, ideally, the Gen 3 exterior building.

Done here: the interior, as mod-owned trueColor tiles
(assets/johto_hall_tiles.png, generated Emerald-palette blocks; the
generator lives in the session scratchpad, regenerate rather than
hand-edit). Geometry + every actor approach verified offline by
scratchpad/verify_hall.lua. Facts that held it together:

- Block tile order is ROW-MAJOR 4x4 (Map.tileAt, gen2/Map.lua:234):
  block[(ty%4)*4+(tx%4)+1]. The sheet is one block per 128px row,
  tilesPerRow=16, so block i's tiles are ids 16i..16i+15.
- Runtime NPCs may stand on SOLID cells (the audience ring does), but a
  SERVICE npc must keep a walkable approach cell -- the first services
  draft put vendor/appraiser on the outer dark row and they were
  unreachable, caught by the verifier, never on device.
- Whether a talk lands on an NPC standing on a solid ledge cell faced
  from the stage is UNVERIFIED -- the audience is scenery first, so
  either answer is fine. Do not put anything load-bearing on it.

NOT done -- the exterior. The Gen 3 tent-roofed Contest Hall building on
the Goldenrod street needs either (a) new blocks appended to
TILESET_JOHTO_MODERN via a tilesets patch plus replaceBlock writes on
GOLDENROD_CITY -- both mechanisms exist (WorldAPI:replaceBlock,
gen2/WorldAPI.lua:282; the imported-cache workflow can verify the block
swap offline) but a shared city tileset patch risks every Johto map if
the block ids collide with another mod, or (b) keeping the street
attendant as the entrance and accepting no facade. Option (a) is real
work with a real blast radius; decide with the developer before starting
it.

## 0.13.1 correction: vanilla tiles only for the hall

The 0.13.0 generated-art tileset was rejected on sight ("ugly, didn't
translate at all to gen 2 style"). Standing rule from it: reference
screenshots from other generations are LAYOUT direction, never art
direction -- build rooms from vanilla Gen 2 blocks, and reach for custom
tiles only when the developer asks for custom art in so many words. The
cross-reference of a mod map onto a vanilla tileset works exactly as the
superseded theatre draft measured: `tileset = "TILESET_TRADITIONAL_HOUSE"`
resolves through the merged gen2 table at runtime, shows as a KNOWN
unresolved reference in the ROM-free sandbox, and the id + full geometry
are verified against both imported caches by scratchpad/verify_hall.lua.

## 0.13.2: room size and rival presence

Both from the same device round.

- **"Room is too big."** 6x7 blocks (12x14 cells) was the theatre's own
  footprint, and three identical floor rows is what made it read as empty.
  Now 5x5 blocks / 10x10 cells: back wall, stage, lip+stairs, ONE floor
  row, doorway. The cast is dense enough to read as a room with people in
  it. Rule of thumb for a mod interior: size the floor to the cast, not to
  the reference map.
- **"Doesn't feel like they are doing much."** Correct, and the numbers
  say why: the rivals had exactly two beats -- one intro announcement and
  a 30%-per-round jam -- so a median contest showed them once. They now
  take a turn after every player appeal, rotating by
  `(kcRound - 1) % #KC_RIVALS`, so all three appear in any contest that
  runs three rounds. One per round, not three: three extra boxes a round
  is a wall of text between your own appeals.
- **Placement** closes the loop -- the rival scores existed but were
  invisible, which is its own kind of "not doing much". Player and rivals
  score in ONE currency (kcAppealPoints: 25 match / 10 neutral / 0 opposed;
  rival reactions 3-18), hearts worth 3 apiece on both sides, so the
  Introduction Round now affects the final standing and not just the head
  start. Filling the meter is 1st outright.
- Tuning is provisional like the jam numbers: if rivals feel too strong or
  too weak, KC_RIVAL_REACTIONS' score column is the dial.

## 0.14.0: one hall per town, in that town's materials

KC_HALLS (file scope, above kcGold) is now the single description of a
hall: id, label, tileset, song, size, arrival cell, blocks, actors. The
Gold arm registers every entry and drives the attendant from the one it
names in `TOWN`. Adding a town is a table entry plus an attendant cell --
no new mechanism.

Every hall keeps the same GRAMMAR because a contest is the same event
everywhere: stage / barrier with a way up at each end / floor with the
coordinator line / entry strip. Only the vocabulary changes, and the
vocabulary is always the town's own vanilla blocks.

- **GOLDENROD = TILESET_MART.** The dept-store block run 0x0C/0x0D/0x0E is
  a service counter, and its collision 0x90 is COUNTER: not walkable, but
  it DOUBLES an A press's reach (Permissions.lua:136-140 ->
  World:facingObjectCell, gen2/World.lua:7825), and `World:npcAt` walks
  the runtime NPC list -- so a SPAWNED judge standing behind a counter is
  talked to across it. Verified by reading both functions before building
  on it, and the verifier now counts a counter as a valid approach.
  Left/right wall columns are 0x07 / 0x20; plain floor 0x04; back wall
  0x03.
- **AVOID the 0x7x collision blocks in TILESET_MART** (0x01, 0x02, 0x05,
  0x06, 0x18, 0x19, 0x1E, 0x1F, 0x25, 0x2A): those are WARP CARPETS
  (Permissions CARPET_DIR). Our halls declare no warps -- the receptionist
  is the way out -- so a carpet block would be a warp tile with no warp
  record. Not tested, deliberately not risked.
- **ECRUTEAK = TILESET_TRADITIONAL_HOUSE**, the 0.13.2 room kept whole. No
  attendant leads there yet; it costs nothing until warped to.
- scratchpad/verify_hall.lua now walks EVERY hall on EVERY cache, and
  gen_gate_test's KNOWN list needs a row per borrowed tileset id -- that
  list is the one thing that could hide a typo'd tileset behind a green
  test, so run the verifier first when adding a town.

## 0.15.0: a hall is a LOBBY plus a STAGE

Developer, after 0.14.0: "the room now feels like the contest lobby not
the stage. we needed the lobby but next when you talk to the judge to
start a contest he should lead you to a stage where the other
coordinators are." Correct diagnosis -- what 0.14.0 built is a lobby, and
it should stay one.

KC_HALLS[town] is now `{ lobby = {...}, stage = {...} }`; a town with no
`stage` performs where it stands, which is every version before this one,
so ECRUTEAK stays valid untouched.

Flow: lobby judge takes the entry and picks the category -> "follow me"
-> warpTo the stage (`pendingContest` carries the category) -> stage judge
reads it, no second menu -> contest -> back to the lobby from inside the
closing line's callback, win or lose.

- **The trip is a WARP, never a scene script.** Gold scene scripts that
  walk the player are what stranded Colosseum visitors in a void when one
  stayed armed; nothing here arms anything that outlives the trip.
- **`leaveStage` is forward-declared** -- runGoldContest ends by calling
  it and is defined above the lobby judge that sends the player out. A
  plain `local function` later in the chunk would have been a nil global
  at call time, the same trap judge_line hit in 0.11.0.
- **Where the player is is derived, not remembered:** `onStageNow()` asks
  `mod.world:current()` rather than trusting a flag, so a contest started
  any other way still ends correctly.
- **The stage is never a trap:** a receptionist by the door returns to the
  lobby, and a stage judge with no `pendingContest` says to enter at the
  desk rather than starting something unasked.
- **GOLDENROD stage = TILESET_RADIO_TOWER.** 0x0A equipment banks flank an
  open centre column and that gap is the way up -- the same "barrier with
  a way through" as the lobby counter and Ecruteak's stage lip. Its 0x1F /
  0x20 edge columns happen to be potted plants, which dresses the sides
  for free. AVOID 0x07 there: warp carpet, and these rooms declare no
  warps.

## 0.15.1 (unshipped) / 0.15.2: finding the stage's vocabulary

Developer, on 0.15.0's stage: remove the shelves (the 0x0A equipment
banks -- they read as store shelving) and make more of a stage. The
replacement is the Gen 3 structure in the Radio Tower's own vocabulary:
the 1F broadcast desk run (0x05 0x26 0x2B 0x26 0x2E -- long bench, left
cap, console at centre) spans the room as the judges' bench; the judge
stands behind it on a strip only he occupies; the WHOLE floor below is
the performance stage the coordinator line stands on.

- Bench collision (identical both caches): upper cells walkable, lower
  cells COUNTER except 0x05's solid left cap -- so the behind-bench strip
  is sealed to walking and the judge is spoken to across the bench with
  the doubled A-press reach, same as the lobby counter.
- 0x1F / 0x20 side columns: OUTER cell is a solid potted plant, INNER
  cell is walkable floor -- so audience stands ON the floor against the
  plants, and the floor is 8 cells wide, not 6.
- The judge NPC spawns onto the sealed strip; runtime objects place
  anywhere, reachability is only a player concern. The verifier's
  counter-reach rule proves he is talkable.

0.15.1's bench never shipped: the developer saw the preview and called it
a front desk, which it was -- a long counter with someone behind it IS
reception grammar in these games, whatever the room around it says. The
lesson generalises: **judge the preview by what the furniture means in
the game's own visual language, not by what the room is named.** Radio
Tower vocabulary only speaks office; no arrangement of it was going to
read as a stage.

0.15.2 is TILESET_GAME_CORNER -- Goldenrod's actual show floor -- and its
0x09 block is the thing itself: a raised dais whose decorated skirt is a
stage front. Facts that make it work (identical both caches):

- 0x09 skirt cells are COUNTER collision, so the judge on the dais is
  spoken to from the performance floor across the skirt (doubled A-press
  reach) AND the dais is walkable on top -- a plain 0x01 at the row's
  east end is the open way up. Both approaches verified.
- 0x19 seat clusters are WALKABLE: the audience sits actual seats.
- 0x12 twin palms are solid dressing; 0x1A's single palm is walkable
  (odd but true) -- avoided for that reason.
- Song: GOLDENROD_GAME_CORNER's own track.
- KNOWN list: TILESET_RADIO_TOWER row swapped for TILESET_GAME_CORNER;
  no map references the Radio Tower any more.

## Editing rooms in the Content Editor (the kc_layout bridge)

Set up 2026-08-31 at the developer's request, on the pattern the Olivine
agent proved with `oc_layout`.

- Bridge project: `C:\Users\dwitt\ce-trial\mods\kc_layout`, seeded with all
  three current rooms so the editor opens on what is shipping, not a blank
  grid. **NEVER install kc_layout as a real mod** -- it would double-register
  the room ids against kanto_contests.
- Launch: `C:\Users\dwitt\ce-trial\ContentEditor.bat`. Its prefs already say
  mode=imported, lastVersion=gold, recompRoot=%APPDATA%\pokemon-love2d, so it
  reads the real Gold cache and no staging step is needed.
- Read back: `luajit ../Kanto-Contests/tests/read_editor_layout.lua` from the
  engine checkout. Prints each room's `blocks` array formatted for KC_HALLS
  AND walks the geometry -- floor connectivity included, which is the class
  of bug (unreachable NPC, room cut in two) that has cost this mod device
  rounds before. Lives in tests/ so it never ships.
- **Only `blocks` is transplanted.** The hall cast is runtime-spawned by
  `spawnNpc`, not map objects, so anything placed in the editor's object
  layer is ignored -- do not spend time on NPCs there. Actor cells are still
  chosen in main.lua and proven by verify_hall.lua.

### The exterior, and the trap in it

`LayeredMap.ownedMap` copies a VANILLA map into the project with
`_isNew = false`, and `emitVerb` then emits `maps:patch` for it -- so
GOLDENROD_CITY can be painted in the editor.

**Do not take the editor's patch output.** That record carries a bare
`objects` list, and lists REPLACE wholesale (Merge.lua:29-49), so applying it
would erase every other mod's NPCs on Goldenrod and the vanilla ones with
them -- the exact failure CLAUDE.md opens by warning about. Instead run
`read_editor_layout.lua GOLDENROD_CITY`, which diffs the painted map against
the cache and prints only the CHANGED blocks as `mod.world:replaceBlock(bx,
by, block)` calls (WorldAPI:replaceBlock, gen2/WorldAPI.lua:282). Those are
per-block, touch nothing else, and are applied on `map.entered` next to the
attendant spawn.

### Why the editor could not open a Gold room (fixed 2026-08-31)

Symptom: every room reported "map tileset is unavailable: TILESET_*",
and reloading Gold did not help.

Cause was NOT the project or the prefs. `ce-trial`'s pinned copy of the
engine predates an upstream fix: Gold's extractor emits no
`text_pointers` and no `trainer_headers` (the Gen 1 pointer/header tables
have no Gold counterpart -- Gen2Compat.DATA_UNBACKED says so), but that
copy's `Data:load()` lists both as REQUIRED and calls `error()` when a
required module is missing. So the whole Gold data load threw, the editor
was left with no Gold tables, and every `TILESET_*` id missed.

Engine v0.2.4 already fixes this with
`GEN2_OPTIONAL = { text_pointers, trainer_headers, field }`, substituting
empty tables on Gen 2 -- and its comment names this exact case ("Empty
tables are enough for seedDefaults / the editor"). Backported into
`ce-trial/runtime/gen1recomp/src/core/Data.lua` AND the
`.content-editor-runtime` copy, both marked BACKPORTED.

Two traps around this, both hit while diagnosing:
- **The prep script re-stages `.content-editor-runtime` from source**, so
  a patch applied only to the runtime copy vanishes. Patch BOTH (that is
  also how the previous session's debug tap was lost).
- **`loadfile` from a Windows luajit cannot open an MSYS `/c/...` path**
  and returns a parse-looking failure, which reads as "I broke the file"
  when nothing is wrong. Pass `C:/...` paths.
