# Changelog

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
