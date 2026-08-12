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

**The open design question (developer's call, asked 2026-08-11, not yet
answered):** where do Contests live on a Gold boot? Gold's Kanto is
post-game. Candidates: National Park (Gold's own contest venue,
mid-game), Celadon post-game, or another Johto city (Goldenrod is the
R/S-faithful pick). Do not build until answered.

Meanwhile: new Gen 1 slices (scarves, rivals) should reach for
`mod.game`/`mod.world`/hooks over `require("src.script.Commands")`
wherever a seam exists, so they don't deepen the MK402 debt.

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
