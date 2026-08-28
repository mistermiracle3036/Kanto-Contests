# Kanto Contests

> **ALPHA — proof of concept.** Five contests, two halls, no ranks yet.
> It is playable and it is stable, but it is a fraction of what Contests
> should be, and things will change between versions. Feedback and bug
> reports are the point of releasing it this early.

Ruby/Sapphire-style Pokemon Contests, rebuilt for Kanto on gen1recomp.

Talk to the little girl in Celadon City and she'll show you the way to the
new Contest Hall. Inside, the judge runs all five contests: pick the one
you want to enter, then use five appeals to fill his meter. Every move is
scored on its **contest category** rather than its damage.

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

## Contest scarves

The appraiser awards a scarf after seeing a Pokemon with a condition category
maxed at 100. Each matching scarf adds 20 points before the audience converts
condition into Introduction hearts.

| Scarf | Contest |
|---|---|
| RED SCARF | COOL |
| BLUE SCARF | BEAUTY |
| PINK SCARF | CUTE |
| GREEN SCARF | SMART |
| YELLOW SCARF | TOUGH |

In Crystal, give the scarf to a Pokemon with the normal party **ITEM** menu.
In Kanto, use the scarf from the bag and choose the Pokemon that will wear it.

## Crystal development preview

The current test build has an early Crystal development path. A Contest
attendant stands in Goldenrod City and leads into the mod's own Contest
Hall. Each town's hall is built from that town's own materials -- the
Goldenrod one is a Department Store room, tiled floor and shelving, with
the judge presiding behind a service counter -- but the layout is the
same everywhere: an audience watching, and the rival coordinators waiting
in line with the fourth place left open for you.
Inside, the judge runs all five contests; a vendor sells all five PokeSnack
flavors and feeds the chosen Pokemon immediately, and an appraiser reads
condition and fullness.

Version 0.10.4 adds the Kanto Introduction Round, contest-specific opening
language, a hidden judge level, and the same no-switching/no-items routine.
Version 0.10.7 also gives Gen 2 a clean contest victory: completing the APPEAL
meter ends the performance without fainting the hidden stand-in or awarding
trainer prize money.

Version 0.10.8 replaces the temporary custom portrait with Crystal's native
**Gentleman** battle front. It is the direct Gen 2 equivalent of Red's
Gentleman judge and matches Gentleman Preston, the Olivine Lighthouse trainer
with two Growlithe.

## What works today

- The Celadon entrance, the Contest Hall, and all five contests end to end
- All 165 moves carry a contest category
- Appeal scoring, the five-appeal limit, win/lose/withdraw
- PokeSnacks, contest condition and sheen, with a vendor and an appraiser
- Five earned contest scarves and their Introduction-round bonus
- Three rival coordinators in each hall: scored in the Introduction Round,
  taking a turn of their own after each of your appeals, able to jam your
  routine from the second appeal on, and ranked against you at the end
- The Introduction Round: condition scored as hearts, cashed in as a
  head start on the appeal meter
- Wins recorded on the POKeMON itself, so they survive boxing, evolution
  and trading

## What isn't there yet

- No ranks (Normal/Super/Hyper/Master) yet. Every contest is the same
  difficulty whichever category you pick -- though from 0.12.0 the three
  rival coordinators can jam your routine and win back part of the meter.
- **Only the Cool Ribbon exists to be won.** All five contests record their
  win, but Kanto Ribbons has artwork for the Cool Ribbon only, so the other
  four award nothing yet. They will award retroactively once it draws them
  — the wins are already in your save.
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
  simply doesn't mention ribbons. Wins are recorded per category either way,
  so installing Kanto Ribbons later — or updating it once it has the other
  four ribbons — awards them for contests you already won.

## Compatibility

Takes over the Celadon City little girl's dialogue, keeping her vanilla
line if you decline. Adds its own map, tileset and trainer class, all
namespaced. No other mod's territory is touched.

## Credits

- Contest design based on the Generation III Contests of Pokemon
  Ruby/Sapphire; no assets or data from those games are included.
- All tile art (`assets/contest_tiles.png`) is original to this mod.

- Built for [gen1recomp](https://github.com/bryanthaboi/gen1recomp) by
  bryanthaboi.
- [Kanto Ribbons](https://github.com/mistermiracle3036/kanto_ribbons)
  integration: this mod records wins on the Pokémon; that mod awards the
  ribbons.
- Released under the MIT licence (see `LICENSE`); scope details in
  `THIRD_PARTY_NOTICES.md`.
- Pokémon and all related names are trademarks of Nintendo / Creatures
  Inc. / GAME FREAK inc. This is a fan-made mod containing no ROM data.
