# Changelog

## 0.9.1
Still an **ALPHA / proof of concept** — one COOL contest, one hall, one
judge.

**Updating from 0.8.2?** The headline is the Introduction Round (0.9.0,
below): before your first appeal the audience now scores your POKeMON's
condition as **0-8 hearts**, and hearts become a head start of up to 35%
of the appeal meter. Feeding snacks finally pays off in the contest
itself. This release adds housekeeping on top:

- The mod now carries a proper **MIT licence** (`LICENSE`), a
  `THIRD_PARTY_NOTICES.md` stating what is original and what is
  inspired-by, and a Credits section in the README. To be explicit about
  the one binary this mod ships: `assets/contest_tiles.png` is three
  8x8 flat-colour tiles drawn programmatically for the Contest Hall —
  original to this mod, covered by the MIT licence.
- Fixed a squeezed line when feeding a snack: "ate the" ran into the
  snack's name across the line break. The article moved down a line, so
  it now reads "ELECTABUZZ ate / the SPICY SNACK!".

## 0.9.0
**The Introduction Round.** Condition finally does something: before your
first appeal, the audience scores your POKeMON on looks alone.

- After the judge takes his seat, the audience holds up **0 to 8 hearts**.
  The score counts the contest's own condition in full, the two
  neighbouring conditions at half weight, and half of sheen -- so a
  specialised POKeMON beats a generalist, but no feeding is wasted.
- Hearts become a **head start on the appeal meter**, up to 35% of it,
  drained before your first move so you can watch it happen. A pampered
  POKeMON needs three matched appeals where an unfed one needs four.
- An unfed POKeMON gets silence from the audience and no head start.
  Appeals still decide everything -- that's the design.
- All four rank threshold rows (Normal/Super/Hyper/Master) ship in the
  data now, but only Normal is reachable until ranks arrive.

## 0.8.2
Still an **ALPHA / proof of concept** — one COOL contest, one hall, one
judge. This release adds the first half of contest condition.

**Updating from 0.7.5?** Everything below is new to you.

- **PokeSnacks.** Every POKeMON now has a hidden contest condition in each
  of the five categories. Five snacks raise them: SPICY (COOL), DRY
  (BEAUTY), SWEET (CUTE), BITTER (SMART), SOUR (TOUGH). Use one from the
  BAG on any POKeMON for +20 to that condition.
- **Sheen is a lifetime limit.** Each snack also adds 10 sheen, and at 100
  a POKeMON won't eat another — ten snacks each, ever. Enough to max two
  categories and never all five, so a contest POKeMON is one you chose to
  specialise.
- **A snack stall in the Contest Hall** sells all five at ¥500 each, over
  a normal shop counter — buy as many as you like, and sell them back.
- **An appraiser in the hall** reads any POKeMON's condition back to you
  in words rather than numbers, and comments on how well looked after it
  is.
- Condition and sheen live on the POKeMON itself, so they survive boxing,
  evolution, trading and saving.
- **Condition does nothing in a contest yet.** The Introduction Round that
  spends it is the next update — feeding now is not wasted.
- **Fixed:** in the widescreen battle layout the appeal meter was missing
  entirely, so there was no way to see how a contest was going. The judge
  and the meter both show there now. (The contest-specific dressing —
  the APPEAL label, the hidden level, the category in the move list — is
  still classic-layout only.)

Behaviour is identical to the 0.8.1 test build; only this changelog
differs.

## 0.8.1
- **The snack vendor is a proper shop now.** All five snacks listed at
  once with their prices, buy as many as you like at a time, and a QUIT
  option instead of having to say no to every flavour in turn. It's the
  game's own mart counter, so it behaves exactly like one -- including
  selling snacks back.
- Better words in two places. A POKeMON that can't eat any more now says
  it has had plenty, rather than being "too sheeny" -- nothing in the game
  ever told you sheen was a thing. And the appraiser describes how well
  looked after a POKeMON is instead of the texture of its coat, with the
  top remark hinting that a glowing POKeMON is also a full one.

## 0.8.0
**PokeSnacks.** Contest condition is now a thing your POKeMON has, and you
raise it by feeding them.

- Five snacks, one per contest category: SPICY (COOL), DRY (BEAUTY), SWEET
  (CUTE), BITTER (SMART), SOUR (TOUGH). Use one from the BAG on any
  POKeMON: **+20 to that condition, +10 sheen.**
- **Sheen is a lifetime limit.** At 100 the POKeMON refuses to eat any
  more, so it is ten snacks per POKeMON ever -- enough to max two
  categories, never all five. Choosing what a POKeMON is *for* is the
  point.
- **A snack vendor** in the Contest Hall sells all five at 500 each
  (tunable -- see NOTES.md).
- **An appraiser** in the hall reads any POKeMON's condition in words
  rather than numbers, and describes the shine of its coat. The wording is
  provisional and kept in one table for easy reassessment.
- Condition and sheen live on the POKeMON itself, so they survive
  boxing, evolution, trading and saving, exactly like contest wins.
- Condition does nothing in a contest **yet** -- the Introduction Round
  that spends it is the next slice. Feeding now is not wasted.
- New `NOTES.md` records what is parked, what is provisional, and the
  engine findings behind this slice.

## 0.7.6
- The appeal meter now shows in the widescreen battle layout. The mod
  pinned `showEnemyTrainer` for the whole contest "for anything else that
  reads it" -- and the widescreen HUD reads exactly that flag to decide
  whether to draw the enemy panel, with no way for the mod to intervene
  (its draw functions are file-local, unreachable from a mod). The pin
  turned out to be unnecessary even on classic: the draw wrapper that
  keeps the judge on screen sets the flag itself for each frame, on both
  layouts. Widescreen contests now show the judge and the meter; the
  classic-only dressing (APPEAL label, hidden level, no HP:) is still
  absent there, which the README now states accurately.

## 0.7.5
**First public release — this is an ALPHA / proof of concept.** One COOL
contest, one hall, one judge. It is playable and stable, but it is a
fraction of what Contests should be and things will change between
versions. Bug reports and "that move is in the wrong category" are exactly
what this release is for.

- Says so where you'll actually see it: the mod is listed as "Kanto
  Contests (Alpha)" and the load banner reads ALPHA rather than "ready",
  for anyone who installs from a link and never sees this page.
- The launcher can offer in-app updates again now that there is a public
  repository and a real release for it to point at.
- README rewritten: how appeals are scored, what works, and what is
  honestly not there yet -- only the COOL contest, no PokeSnacks, no
  ranks, and a contest HUD drawn for the classic battle layout only.
- Kanto Ribbons 0.18.0+ is optional. With it, a COOL win earns the Cool
  Ribbon; without it contests are unchanged and the judge doesn't mention
  ribbons. Wins are stored on the POKeMON either way, so installing it
  later still awards ribbons for contests already won.

## 0.7.4
- The appeal meter loses the leftover `:`. Closing the bar in 0.7.2 meant
  keeping the tile that carries both the colon and the bar's left cap;
  the colon half is now painted over, so the cap sits straight against
  the meter with nothing in front of it.
- The judge stops mentioning ribbons when Kanto Ribbons isn't installed.
  Losing or withdrawing still said "not quite ribbon material yet",
  dangling a prize that doesn't exist in that install -- the same rule his
  victory line already follows. With the ribbons mod present he says it as
  before.

## 0.7.3
- The judge now promises a COOL RIBBON rather than a "CONTEST RIBBON".
  Kanto Ribbons awards one ribbon per contest category, so the COOL
  contest earns the Cool Ribbon by name.
- The check for whether Kanto Ribbons is installed now fails safe. It asks
  whether the mod is *missing* instead of whether it is present, so if the
  check itself is ever skipped the judge falls back to the plain
  compliment. Before, a skipped check left the win flag standing and he
  would announce a ribbon that was never awarded.

## 0.7.2
- The appeal meter is closed at both ends again. Removing the `HP:` label
  also removed the bar's left cap -- they share one tile -- which was
  invisible until the meter drained to empty and the line just stopped. A
  small `:` sits where the label was; that is how vanilla looks whenever
  the move-select box covers the `HP`.
- Contests award no EXP, for real this time. A second guard now blocks the
  award at the engine function itself rather than only at the hook inside
  it, so it holds regardless of what else is installed.
- "A fair appeal" is now "A COOL move, but it works." The old wording read
  as a verdict rather than the middle rung, so it was impossible to tell
  whether it meant good or bad. The three outcomes now read as a ladder:
  delighted for a matching category, a polite nod for an off-category
  move, a frown for one of the two clashing categories (which scores
  nothing).
- The prize line no longer promises a ribbon "in a future update". Ribbons
  arrived in 0.7.0, and the judge announces one himself a moment later.

## 0.7.1
- No more "check failed" in the mod manager. The manifest was pointing the
  launcher's auto-updater at a repository that is still private and has no
  published release, so the check could only ever fail -- a red error on a
  mod that was loading and running perfectly. The pointer comes back when
  the repo goes public and has a real release to offer.

## 0.7.0
- Winning a contest now records the win on the POKeMON that performed, so
  Kanto Ribbons can award it a CONTEST RIBBON. The record lives on the mon
  itself, which means it survives boxing, evolution and trading -- and it
  is kept per category (COOL/BEAUTY/CUTE/SMART/TOUGH), so more contest
  types and per-category ribbons later need no change to an existing save.
- The judge no longer says "Ribbons come in the next update!". He promises
  a CONTEST RIBBON when Kanto Ribbons is installed and gives a plain
  compliment when it isn't, rather than announcing a ribbon that would
  never turn up. Checked when you talk to him, not at load, so install
  order cannot get it wrong.

## 0.6.0
- Text no longer runs off the right edge of the box. A battle message is not
  a dialogue box: it pages on `\v`, not on `\f`, so every `\f` page break
  this mod wrote was landing mid-line and the rest of the sentence was
  clipped. Contest text is now split into one message per page, which is
  what the engine's own trainer-defeat path does.
- The judge no longer wants to FIGHT you. The intro rewrite has never once
  fired -- it matched "wants to" and the real line breaks as "wants\nto" --
  so the COOL CONTEST announcement finally appears.
- APPEAL sits one row lower, tucked just above the meter instead of
  floating over the gap the hidden level left behind.

## 0.5.0
- The appeal meter is no longer labelled `HP:`. It's an appeal meter.
- The move list now shows each move's CONTEST CATEGORY where a battle shows
  its type, so you can pick an appeal without memorising the table.
- One POKeMON, one routine: PkMn and ITEM are refused during a contest.
  RUN still works and is now a clean withdrawal from the stage -- vanilla
  would have told you there's no running from a trainer battle.
- Contests award no EXP. Winning ran through the ordinary victory path and
  paid out a full trainer share (1638 EXP off one contest); a contest is a
  performance, not a fight. Real battles are untouched.
- The judge's reactions now end on the category line, so it's still on
  screen while the box waits for you instead of scrolling past.
- The winner's line no longer overflows the text box.

## 0.4.0
- Appeal scoring is in. Every player move in a contest is now a pure appeal:
  no accuracy roll, no type chart, no side effects (Growl no longer lowers the
  judge's stats -- it's a CUTE appeal). Matching the contest category drains
  25% of the appeal meter, neutral moves 10%, and the contest's two opposed
  categories score nothing and draw a frown.
- All 165 Gen 1 moves carry their Gen 3 contest category (best-effort data --
  report any move that feels miscategorized).
- Five-appeal limit: empty the meter in 5 moves or the judge shakes his head
  and the contest ends -- as a clean exit, no blackout, no prize.
- The judge's commentary counts your appeals; the prize-money line now reads
  as contest flavor.
- Appeal meter is now backed by a lv30 CHANSEY (never visible): scoring is in
  fractions of max HP, so this only makes the bar drain smoothly instead of
  vanishing to one Machoke hit.

## 0.3.0
- The judge's Pokemon is never visible: the pic layer now draws the judge for
  the whole contest, including through the send-out (v0.2 showed CLEFAIRY
  during the player's own send-out, since the intro queue is already built by
  the time the mod can react to it).
- The appeal meter no longer shows a level.
- Contest language replaces battle language: the intro, the judge's send-out
  and the appeal-meter faint all read as contest events now.

## 0.2.0
- Appeal meter: the judge's HP bar now stays visible while his portrait is on
  screen (drawHUDs suppresses the enemy HUD whenever a trainer pic holds the
  mon slot; a contest clears that flag for the draw only). Labelled APPEAL.
- Load banner moved to first map entry: game.ready fires before anything is on
  the stack and the title screen replaced it, so it never appeared.
- Declining the Celadon girl now shows her real vanilla line. MapScripts.baseTalk
  only covers hand-ported engine scripts and she has none, so the fallback now
  resolves her ROM text the same way showMapText does.

## 0.1.0
- First testable slice: Contest Hall map + tileset, Celadon entrance via the
  little girl (vanilla dialogue preserved on decline), COOL contest judge.
- Contest runs as a battle vs the judge; the judge's portrait stays on screen
  after the intro and the judge never attacks ("watching intently").
- Load banner option (default ON) prints the mod version on game ready.
