# Changelog

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
