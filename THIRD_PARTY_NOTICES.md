# Third-party notices

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
  mechanics, and the introduction-round scoring follow that design. No
  assets or data from those games are included. All tile art
  (`assets/contest_tiles.png`) is original to this mod: three 8x8
  flat-colour tiles (wall, floor, stage rug) drawn programmatically for
  the Contest Hall.
- This mod is released under the MIT licence (see `LICENSE`). That
  licence covers this mod's own code and its original art only — it
  makes no claim over ROM-derived material or Nintendo trademarks,
  neither of which this mod contains or could relicense.
- Pokémon and all related names are trademarks of Nintendo / Creatures
  Inc. / GAME FREAK inc. This mod contains no ROM data or copyrighted
  assets; it is a fan-made script mod and requires the user's own game
  copy via gen1recomp.
