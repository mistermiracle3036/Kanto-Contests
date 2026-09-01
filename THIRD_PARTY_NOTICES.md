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
  - **Blaklyte** — N, Nurse_Joy
  - **CyUzi** — BallGuy
  - **KiravelSoul** — Volkner
  - **KIRB/YOSHI** — bea
  - **MOLLY** — brendan, dawn, hilbert, hilda, lyra, michael, rosa, stadium_player, wes
  - **Molly** — Green
  - **NolanKrawczak** — Barry, May
  - **RoyalGuard** — Bill, Colress, Hugh, Lorelei, Maxie, Wally
  - **Santiago Speedpaints (Rojimenez)** — mina
  - **artist not recorded here — see the Indigo Plateau Conference notices** — ingo
  - **SirWhibbles** — agatha, archer, ariana, giovanni, petrel, proton, rocket_executive, rocket_grunt_f, rocket_grunt_m
  - **TeamHistoryWaffles** — Gloria, Officer_Jenny, Ruin Maniac
  - **tharkka (commissioned)** — roxie
  - **TheBrawlUnit** — aj
  - **Yogurcomics (commissioned)** — piers
  Every other character in the contest hall — the gym leaders, the
  Elite Four and the ordinary trainers in the seats — is drawn from the
  player's own game and is not redistributed here.
- **gen1recomp** â€” this mod targets the
  [gen1recomp](https://github.com/bryanthaboi/gen1recomp) engine (mod
  API 2) and reaches engine internals under the `engine_internals`
  permission: contests run as instrumented battles, so it wraps several
  `BattleState` methods and `ItemEffects.use` in memory at runtime.
- **Kanto Ribbons** â€” optional integration. This mod records contest
  wins as `mon.contestWins`, a per-category count on the PokÃ©mon that
  won; Kanto Ribbons (0.18.0+) reads that field to award contest
  ribbons, including retroactively. No code is shared, and neither mod
  requires the other.
- The contest system reimagined here is inspired by the Generation III
  Contests of the official games (Ruby/Sapphire) â€” the appeal
  categories, the opposed-category pairs, the condition and sheen
  mechanics, and the introduction-round scoring follow that design. No
  assets or data from those games are included. All tile art
  (`assets/contest_tiles.png`) is original to this mod: three 8x8
  flat-colour tiles (wall, floor, stage rug) drawn programmatically for
  the Contest Hall.
- This mod is released under the MIT licence (see `LICENSE`). That
  licence covers this mod's own code and its original art only â€” it
  makes no claim over ROM-derived material or Nintendo trademarks,
  neither of which this mod contains or could relicense.
- PokÃ©mon and all related names are trademarks of Nintendo / Creatures
  Inc. / GAME FREAK inc. This mod contains no ROM data or copyrighted
  assets; it is a fan-made script mod and requires the user's own game
  copy via gen1recomp.
