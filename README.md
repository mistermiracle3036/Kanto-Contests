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

## PokeSnacks and condition

Every POKeMON has a hidden **contest condition** in each of the five
categories, plus a **sheen** value. Feeding a snack raises one condition
by 20 and sheen by 10.

| Snack  | Raises |
|---|---|
| SPICY  | COOL   |
| DRY    | BEAUTY |
| SWEET  | CUTE   |
| BITTER | SMART  |
| SOUR   | TOUGH  |

**Sheen is a lifetime cap.** At 100 sheen a POKeMON won't eat another
snack, ever — ten snacks per POKeMON in total. That's enough to max two
categories and never all five, so a contest POKeMON is a POKeMON you
chose to specialise.

Two people in the Contest Hall help: a **vendor** sells all five snacks,
and an **appraiser** will read any POKeMON's condition back to you in
words rather than numbers.

Condition pays off in the **Introduction Round**: before your first
appeal, the audience scores the entrant on looks alone and holds up
**0–8 hearts**. The score counts the contest's own condition in full,
the two neighbouring conditions at half weight, and half of sheen — so a
specialised POKeMON beats a generalist, but nothing is wasted. Hearts
convert into a head start on the appeal meter, up to 35% of it: a
pampered POKeMON needs three good appeals where an unfed one needs four.
The audience stays silent for an unfed entrant — appeals still decide
everything.

## What works today

- The Celadon entrance, the Contest Hall, and the COOL contest end to end
- All 165 moves carry a contest category
- Appeal scoring, the five-appeal limit, win/lose/withdraw
- PokeSnacks, contest condition and sheen, with a vendor and an appraiser
- The Introduction Round: condition scored as hearts, cashed in as a
  head start on the appeal meter
- Wins recorded on the POKeMON itself, so they survive boxing, evolution
  and trading

## What isn't there yet

- **Only the COOL contest.** BEAUTY, CUTE, SMART and TOUGH are not in.
- No ranks (Normal/Super/Hyper/Master), no scarves, no rival
  coordinators yet.
- **The contest HUD is polished for the classic battle layout.** In the
  widescreen layout the judge and the appeal meter both show, but the
  contest dressing is missing: the meter reads as an ordinary status
  panel (level and HP label included) and the move list shows types
  instead of contest categories.
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
