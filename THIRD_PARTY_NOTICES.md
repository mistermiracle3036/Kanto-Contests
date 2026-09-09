# Third-party notices


- **Contest cast overworld sprites** — the custom characters in the
  contest hall use the project's canonical sprite assets, copied
  byte-for-byte from the shared store and registered with the palette
  recorded there, so a character looks the same in every mod that uses
  them. Sheets that are visual SUBSTITUTES are credited as the sheet,
  never as bespoke art of the character they stand in for. Art by:
  - **ArtsyAlraune** — breeder
  - **Bani** — Ash, Chef, Eusine, Larry, Leaf, Lear, Looker, Nate, Ranger, Yellow, juliana, lillie, santa
  - **Bani (visual substitute)** — duplica, giselle, suzie
  - **Blaklyte** — N, Nurse_Joy, ingo; **fantina** (commissioned, the same
    sheet Indigo Plateau Conference 1.1.55 ships, in her approved colour)
  - **CyUzi** — BallGuy
  - **KiravelSoul** — Volkner
  - **KIRB/YOSHI** — bea
  - **MOLLY** — brendan, dawn, hilbert, hilda, lyra, michael, rosa, stadium_player, wes
  - **Molly** — Green
  - **NolanKrawczak** — Barry, May
  - **RoyalGuard** — Bill, Colress, Hugh, Lorelei, Maxie, Wally
  - **Santiago Speedpaints (Rojimenez)** — mina
  - **SirWhibbles** — agatha, archer, ariana, giovanni, petrel, proton, rocket_executive
  - **TeamHistoryWaffles** — Gloria, Officer_Jenny, Ruin Maniac
  - **tharkka (commissioned)** — roxie
  - **TheBrawlUnit** — aj
  - **Yogurcomics (commissioned)** — piers
  - From **Polished Crystal** (used with per-asset attribution retained,
    as in the Indigo Plateau Conference notices), overworld sheets only:
    - **Kuroko Aizawa** — artist, cheryl, engineer
    - **Kuroko Aizawa / JaceDeane** — ivy
    - **bloodless (BloodlessNS)** — buck, maylene, veteran_m
    - **isamuakai01** — cynthia, steven
    - **SCMidna / Freeline** — marley, mira, riley
    - **Kage** — walker
    - **Pyro** — tamer
    - **FrenchOrange** — boarder
    - **mauvesea** — mary
  - **EeVeeEe1999** (DeviantArt, free to use with credit) — captain,
    exterminator, slot_maniac
  Twenty-five of these sheets ship in the main colour the developer
  approved for the character (sprites/canonical_color, 2026-09-08). That
  is the same artist's art with one colour applied; the credit is
  unchanged.
  Every other character in the contest hall — the gym leaders, the
  Elite Four and the ordinary trainers in the seats — is drawn from the
  player's own game and is not redistributed here.
- **gen1recomp** — this mod targets the
  [gen1recomp](https://github.com/bryanthaboi/gen1recomp) engine (mod
  API 2) and reaches engine internals under the `engine_internals`
  permission: contests run as instrumented battles, so it wraps several
  `BattleState` methods and `ItemEffects.use` in memory at runtime.
- **Kanto Ribbons** — optional integration. This mod records contest
  wins as `mon.contestWins`, a per-category count on the Pokémon that
  won; Kanto Ribbons (0.18.0+) reads that field to award contest
  ribbons, including retroactively. No code is shared, and neither mod
  requires the other.
- The contest system reimagined here is inspired by the Generation III
  Contests of the official games (Ruby/Sapphire) — the appeal
  categories, the opposed-category pairs, the condition and sheen
  mechanics, and the introduction-round scoring follow that design. The contest move/effect data is transcribed from pokeemerald; the mod supplies its own Lua implementation. All tile art
  (`assets/contest_tiles.png`) is original to this mod: three 8x8
  flat-colour tiles (wall, floor, stage rug) drawn programmatically for
  the Contest Hall.
- This mod is released under the MIT licence (see `LICENSE`). That
  licence covers this mod's own code and its original art only — it
  makes no claim over ROM-derived material or Nintendo trademarks,
  which this mod cannot relicense.
- Pokémon and all related names are trademarks of Nintendo / Creatures
  Inc. / GAME FREAK inc. This mod contains no ROM image; its bundled third-party artwork is credited above and below; it is a fan-made script mod and requires the user's own game
  copy via gen1recomp.
- `assets/applause.wav` is derived from "audience clap yell outdoor 02" by
  **klankbeeld**, Freesound sound #189831
  (https://freesound.org/s/189831/), used under its Creative Commons
  **Attribution** licence. The author's required credit, verbatim and with
  the direct link they ask for:

  **sound from http://www.freesound.org/people/klankbeeld/**

  Edited for the mod: two 2.6-second passages of the same recording layered
  on top of each other -- the opening (from 0.25 s, the crowd's rise and the
  yell) and the clapping from 3.0 s, the latter raised to sit just under the
  former -- mixed to mono and run through a bitcrusher: resampled to
  11025 Hz with every sample held twice (about 5.5 kHz effective),
  soft-clipped, reduced to 8 amplitude levels (3-bit), and the last 0.6
  seconds faded after the reduction. The original is 8.8 seconds,
  stereo, 48 kHz, 24-bit. (0.34.8-0.34.10 shipped a different clip,
  Freesound #478411 by thaighaudio, CC0; it is no longer included.)

## Polished Crystal species in 0.37.0

Honchkrow and Mismagius artwork and data are adapted from Polished Crystal by Rangi42 and contributors: https://github.com/Rangi42/polishedcrystal . Source revision: `79db6f5c5e048bf191ac586a5e2197ce33e7001f`.

Upstream CREDITS.md credits **bloodless (BloodlessNS)** for Honchkrow and **bloodless with SoupPotato** for Mismagius. General sprite/icon contributors include Blue Emerald, solo993, Chamber, Lake, Neslug and Pikachu25; individual icon artists are not identified by that source. Original artwork remains the work of its credited creators and is not relicensed as this mod's original art.

Files used for each species: `gfx/pokemon/<species>/{front.png,back.png,normal.pal,shiny.pal}`, `gfx/icons/<species>.png`, `data/pokemon/base_stats/<species>.asm`, `data/pokemon/evos_attacks.asm`, and `data/pokemon/dex_entries.asm`. The first front frame is compiled at native 56x56; back sprites remain 48x48 and icons 16x32. Indexed grayscale compilation does not redraw or resize the sprites. Palette channels are converted from RGB5 to RGB8. Faithful base stats are used; later-generation moves absent from the engine and abilities are omitted. Native Murkrow/Misdreavus cries are referenced at runtime, not bundled as audio.

## Expanded Species support

`species_support.lua` adapts the registration metadata, Pokédex/icon/palette setup and missing-species save protection from **Expanded Species 0.7.0**, by Mister Miracle, under the MIT license. The copyright and permission notice is included in `LICENSE`. Encounter, fishing, trainer, trade and form systems are not included. The adapter protects only the two Kanto Contests species and does not replace other providers' records.
