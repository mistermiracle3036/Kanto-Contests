# Kanto Contests

By **Mister Miracle** ([@mistermiracle3036](https://github.com/mistermiracle3036)).

Five contest categories, rival coordinators, snacks and scarves, with a four-rank circuit in Johto. **0.37.6 is a development preview awaiting the final phone checks in TESTING.md.**

## Install and update

Download the mod ZIP from [Releases](../../releases/latest), then choose launcher **MODS → Import mod .zip**. On iOS, delete any older downloaded copy from Files first. Fully quit and relaunch. For updates, tap the mod's “vX.Y.Z available” entry, choose **Update**, then fully quit and relaunch. Test builds are supplied separately and may be newer than the public release.

No other mod is required. Development and automated integration testing use the current local engine source with a 0.2.24 compatibility stamp. The manifest retains the existing 0.1.75 lower bound for legacy compatibility; the full new Johto feature set has not been verified on that oldest engine. Use a current engine for this preview.

## Johto contest circuit

| Hall | Rank | Required wins by this Pokémon in this category |
|---|---|---|
| Goldenrod | NORMAL | 0 |
| Ecruteak | SUPER | 1 |
| Cianwood | HYPER | 2 |
| Blackthorn | MASTER | 3 |

Enter the contest building and speak to the lobby judge across the counter. Choose COOL, BEAUTY, CUTE, SMART or TOUGH, then choose one healthy Pokémon with a learned move. The hall selects the rank automatically. Wins at any rank count toward eligibility; winning each preceding rank is not required. Actual rank victories are recorded separately for ribbons.

The introduction scores condition with up to eight audience hearts. Three other coordinators perform alongside you. The judging round lasts five turns, with move appeal, jams, combos, nervousness, turn order and audience excitement affecting the result. The move information card explains the highlighted move. Contest appeals do not spend battle PP and learned moves remain usable at zero PP. Press B at the move menu, then A to confirm withdrawal or B to keep performing.

Results return you to the lobby and restore your full party in its original order. The lobby draws new coordinators for the next contest; they use pre-contest dialogue. The completed contest's win/loss reactions belong to its stage cast. Reloading an interrupted contest cancels it safely; it does not resume halfway through an appeal. The rest of the party, mail, held items and the entrant's saved data are restored.

## Snacks, condition and sheen

Snacks cost 500 each. SPICY raises COOL, DRY raises BEAUTY, SWEET raises CUTE, BITTER raises SMART and SOUR raises TOUGH. Each adds up to 20 condition and 10 sheen, with both capped at 100.

**Condition is preparation for a category. Sheen is the lifetime feeding limit.** A Pokémon can eat ten snacks in total, enough to maximize two categories. The vendor previews the gains and asks before feeding. Feeding a capped category raises only sheen; a warning appears first.

Introduction scoring uses the selected condition, half of each of its two neighboring conditions, half of sheen, and a matching scarf bonus. Higher ranks require more preparation. With COOL 100 and sheen 100, HYPER gives seven introduction hearts; COOL 100 and sheen 50 gives five. A well-chosen ten-snack plan plus a matching scarf can earn eight MASTER hearts. The same preparation earns fewer introduction hearts at higher ranks: a score of 71–80 gives seven NORMAL hearts but two HYPER hearts. Appraiser words such as “impressive” describe a condition stat, not a rank-specific heart count. The applause meter during move appeals uses the same category/excitement rules at every rank. Appeal strategy still matters after the introduction.

## Scarves and ribbons

The appraiser reads condition and awards a scarf when a condition reaches 100. Red is COOL, blue BEAUTY, pink CUTE, green SMART and yellow TOUGH. A matching scarf adds 20 introduction-score points. In Gen 2, give it through the normal party ITEM menu; in Gen 1, use it from the bag.

[Kanto Ribbons](https://github.com/mistermiracle3036/kanto_ribbons) is optional. Kanto Contests records category wins in `mon.contestWins` and actual rank wins in `mon.contestRanks`; the Ribbons mod displays its supported awards, including existing wins after it is installed. Use a version supporting per-rank contest ribbons; local integration source reviewed for this build was Ribbons 0.23.0. Grand Hall, Trainer Journey and Trophy Case are also optional.

## Fantina's MASTER challenge

Fantina occupies one coordinator slot in your first eligible MASTER challenge. If you lose or withdraw, she returns on later attempts, even if you change category. The first victory against her completes the challenge for that save. Non-recording quest exhibitions do not count.

After the result, Fantina approaches you in the lobby and gives **one Dusk Stone**. If the bag is full, make space and revisit a contest lobby to collect it. This is one reward across all categories, not one per Pokémon or category. Existing saves begin this new challenge on their next MASTER attempt.

Use the stone from the bag on **Murkrow → Honchkrow** or **Misdreavus → Mismagius**. It follows the normal evolution animation and is consumed only when evolution completes. An Everstone prevents it. The stone supports either evolution; one rewarded stone means choosing one Pokémon.

The two species and their required support are bundled from Polished Crystal and Expanded Species. No additional download or species-framework mod is required. This is not a full replacement Pokédex: only these two evolutions are added. Fantina uses Blaklyte's commissioned walker with the updated colors from Indigo Conference 1.1.55.

## Options

| Option | Default | Effect |
|---|---|---|
| Dusk Stone reward | On | Award the stone for the first Fantina MASTER victory. Turning it off before winning completes the challenge without a stone. |
| Bundled evolutions | On | Register Honchkrow, Mismagius and their support. Turn off for another dex expansion, then fully quit and relaunch. |
| HEARTS POP | AROUND ROOM | Choose sequential audience reactions or ALL AT ONCE. |
| MOVE MENU | FULL INFO | Choose the move information card or CLASSIC menu. |
| Show load banner | On | Display the loaded version. |

With Bundled evolutions off, this mod adds neither species nor evolution patches. The Dusk Stone can use another pack's uniquely named HONCHKROW or MISMAGIUS; if neither is available, it has no effect and is retained. Turn the reward off too if you do not want the item. Both switches are independent.

If you already own one of the bundled species when switching it off, the mod keeps the affected Pokémon safely out of the active party/boxes until the species is enabled again. Their data and mail are retained; a MODS ERRS notice explains this. Leave Kanto Contests installed for that protection to run. It does not migrate Pokémon to a different pack's species IDs.

## Red, Blue and Yellow

The original Celadon contest remains available through the little girl's invitation. Its older battle-based judging uses five appeals to fill the judge's meter. Johto's four-hall circuit, Fantina challenge, Dusk Stone and bundled evolutions apply to Gen 2. Gen 1 uses its existing contest behavior; this preview does not claim identical features between generations.

## Compatibility and feedback

This mod adds contest rooms, modifies their town entrances and wraps contest-specific engine behavior. It retains quest hooks for optional companion mods. The bundled species use namespaced IDs `KC_HONCHKROW` and `KC_MISMAGIUS`; the item is `KC_DUSK_STONE`. It does not add wild encounters for the new evolutions. Because enabled species affect game content, this package is marked as affecting link compatibility.

See [FAQ](FAQ.md), [Changelog](CHANGELOG.md), [phone test checklist](TESTING.md), and [third-party notices](THIRD_PARTY_NOTICES.md). Report problems through [GitHub Issues](../../issues), including the loaded mod version, game edition, engine version, other enabled mods and MODS ERRS output.
