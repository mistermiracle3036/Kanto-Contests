# Kanto Contests

> **ALPHA — proof of concept.** One contest type, one hall, one judge.
> It is playable and it is stable, but it is a fraction of what Contests
> should be, and things will change between versions. Feedback and bug
> reports are the point of releasing it this early.

Ruby/Sapphire-style Pokemon Contests, rebuilt for Kanto on gen1recomp.

Talk to the little girl in Celadon City and she'll show you the way to the
new Contest Hall. Inside, the judge runs a COOL contest: you have five
appeals to fill his meter, and every move is scored on its **contest
category** rather than its damage.

## How a contest works

Each of your POKeMON's moves has a contest category — COOL, BEAUTY, CUTE,
SMART or TOUGH — shown in place of the type when you pick a move.

| Move's category | Result |
|---|---|
| Matches the contest | A perfect appeal — fills a quarter of the meter |
| Neither matching nor clashing | Still works — fills a tenth |
| One of the contest's two clashing categories | Nothing, and the judge frowns |

Fill the meter within five appeals to win. Run out and the judge shakes
his head — no blackout, no penalty. You can withdraw with RUN at any time.

It is a performance, not a fight: no accuracy rolls, no type chart, no
side effects (GROWL will not lower anything), no EXP, and no switching or
items — the POKeMON you walk on stage with performs the whole routine.

## What works today

- The Celadon entrance, the Contest Hall, and the COOL contest end to end
- All 165 moves carry a contest category
- Appeal scoring, the five-appeal limit, win/lose/withdraw
- Wins recorded on the POKeMON itself, so they survive boxing, evolution
  and trading

## What isn't there yet

- **Only the COOL contest.** BEAUTY, CUTE, SMART and TOUGH are not in.
- **No PokeSnacks or condition**, no ranks (Normal/Super/Hyper/Master).
- **Classic battle layout only.** The contest HUD — the judge staying on
  screen, the APPEAL meter, the category box — is drawn for the standard
  layout. In the widescreen battle layout the contest still plays, but it
  will look like an ordinary battle.
- Contest categories are best-effort Gen 3 data. If a move feels
  miscategorised, say so — each one is a one-line fix.

## Requires

- **gen1recomp 0.1.75+**
- **[Kanto Ribbons](https://github.com/mistermiracle3036/kanto_ribbons)
  0.18.0+** — optional. Install it and winning a COOL contest awards the
  Cool Ribbon. Without it, contests play exactly the same and the judge
  simply doesn't mention ribbons. Wins are still recorded, so installing
  Kanto Ribbons later awards ribbons for contests you already won.

## Compatibility

Takes over the Celadon City little girl's dialogue, keeping her vanilla
line if you decline. Adds its own map, tileset and trainer class, all
namespaced. No other mod's territory is touched.

## Credits

Contest design based on Pokemon Ruby/Sapphire. Built for
[gen1recomp](https://github.com/bryanthaboi/gen1recomp).
