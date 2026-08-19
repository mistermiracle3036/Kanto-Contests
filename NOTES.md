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
