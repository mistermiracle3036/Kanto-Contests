# Contests

By **Mister Miracle** ([@mistermiracle3036](https://github.com/mistermiracle3036)).

Pokémon Contests for Crystal, Gold and Silver on [gen1recomp](https://github.com/bryanthaboi/gen1recomp): five categories, a four-hall rank circuit across Johto, rival coordinators drawn from a cast of well over a hundred, a live crowd, snacks and scarves, and a judging round played by the Ruby and Sapphire rules.

![The judging screen: the applause meter maxed, "The crowd goes wild! 6 hearts!"](docs/applause_wild.png)

## Install and update

Download the mod ZIP from [Releases](../../releases/latest), then choose launcher **MODS → Import mod .zip**. On iOS, delete any older downloaded copy from Files first. Fully quit and relaunch. For updates, tap the mod's “vX.Y.Z available” entry, choose **Update**, then fully quit and relaunch.

No other mod is required. Use a current engine; the manifest keeps an old lower bound for compatibility, but the Johto circuit has only been tested on recent releases.

## The circuit

Each hall runs one rank. You climb by travelling, and a hall takes your entry once the Pokémon you bring has the wins it asks for in that category.

| Hall | Rank | Wins needed, this Pokémon, this category |
|---|---|---|
| Goldenrod | NORMAL | 0 |
| Ecruteak | SUPER | 1 |
| Cianwood | HYPER | 2 |
| Blackthorn | MASTER | 3 |

Wins at any rank count toward eligibility; you do not have to win each rank in order. The rank you actually won at is recorded separately, for ribbons.

| Goldenrod | Ecruteak | Cianwood | Blackthorn |
|---|---|---|---|
| ![Goldenrod's contest hall on the street](docs/goldenrod_street.jpg) | ![Ecruteak's contest hall](docs/ecruteak_street.jpg) | ![Cianwood's contest hall](docs/cianwood_street.jpg) | ![Blackthorn's contest hall](docs/blackthorn_street.jpg) |
| ![The Goldenrod lobby](docs/goldenrod_lobby.jpg) | ![The Ecruteak lobby](docs/ecruteak_lobby.jpg) | ![The Cianwood lobby](docs/cianwood_lobby.jpg) | ![The Blackthorn lobby](docs/blackthorn_lobby.jpg) |
| ![The Goldenrod stage](docs/goldenrod_stage.jpg) | ![The Ecruteak stage](docs/ecruteak_stage.jpg) | ![The Cianwood stage](docs/cianwood_stage.jpg) | ![The Blackthorn stage](docs/blackthorn_stage.jpg) |

Each hall is a real building on its town's street, with its own lobby and stage. The crowd grows with the rank, and each town draws its own kind of crowd: Whitney and the department-store staff in Goldenrod, sages and a Kimono Girl in Ecruteak, sailors and the black belts in Cianwood, the dragon clan in Blackthorn. Nobody is locked to one town, so anyone can turn up anywhere.

## Entering a contest

Talk to the judge across the lobby desk. Pick a category, then one healthy Pokémon that knows a move. You queue up behind the three coordinators you are about to face; they talk, and the crowd talks back.

| | |
|---|---|
| ![The desk: "Which contest will you enter?"](docs/desk.png) | ![The five categories](docs/contest_menu.png) |

## The introduction round

Everyone walks on and is announced in turn. Each Pokémon's picture goes up, and the crowd answers with hearts, one seat at a time, up to eight. Hearts come from how well the Pokémon is prepared: its condition in the category, half of each neighbouring condition, half of its sheen, and a bonus for a matching scarf. Higher ranks want more.

| | |
|---|---|
| ![The four on stage: "Welcome, everyone! The stage is set."](docs/intro_stage.png) | ![Hearts popping over the crowd](docs/intro_hearts.png) |
| ![Larry's Dunsparce is announced](docs/intro_sendout.png) | !["KRIS scores 8 hearts!"](docs/intro_score.png) |

The picture on stage is in colour in that third shot because the optional [Pokeball Colors](https://github.com/mistermiracle3036/Pokeball-Colors) mod was installed; without it the game draws it in its own palette.

## Judging

Five turns. Each turn every coordinator picks a move, and the move's contest data decides what happens: how many hearts it appeals for, whether it jams the previous performer, whether it starts a combo or finishes one for double hearts, whether it makes the ones after it nervous or scrambles next turn's order. The move card shows all of that for the highlighted move before you commit. Fill the applause meter and the crowd goes wild for a bonus. Appeals do not spend battle PP. B withdraws, with a confirmation.

| | |
|---|---|
| ![The judge opens the NORMAL COOL contest](docs/judging_start.png) | ![The move card: appeal and jam hearts and the effect line](docs/move_card.png) |
| ![COMBO READY! after a starter](docs/combo_ready.png) | ![An appeal lands and the panel fills with hearts](docs/appeal.png) |
| ![The applause meter maxed: WILD!!](docs/applause_wild.png) | !["You place 1st of 4!"](docs/results.png) |

The rivals get sharper the higher you go: at NORMAL they pick at random, at SUPER they favour their category, at HYPER they finish their combos, at MASTER they play the best move they have. Go back down a rank and they ease off again.

Results return you to the lobby with your full party in its original order. Reloading a save made mid-contest cancels the contest cleanly rather than resuming halfway through an appeal.

## Snacks, condition and sheen

The lobby seller has five flavours at 500 each. SPICY raises COOL, DRY raises BEAUTY, SWEET raises CUTE, BITTER raises SMART and SOUR raises TOUGH, each by up to 20 condition and 10 sheen, both capped at 100.

**Condition is preparation for a category. Sheen is the lifetime feeding limit.** A Pokémon can eat ten snacks in total, enough to max out two categories, so specialise. The seller previews the gain and asks before you spend, and warns when a category is already full.

| | |
|---|---|
| ![The snack seller: five flavours](docs/snacks_1.png) | ![The flavour menu at 500 each](docs/snacks_2.png) |
| ![The appraiser: "I can read contest condition."](docs/appraiser_1.png) | !["COOL: radiant, BEAUTY: dull"](docs/appraiser_2.png) |

The appraiser next to the seller reads a Pokémon's condition in words. Her words describe a stat, not a heart count; the same preparation earns fewer introduction hearts at higher ranks.

## Scarves and ribbons

When a condition reaches 100 the appraiser awards the matching scarf: red for COOL, blue BEAUTY, pink CUTE, green SMART, yellow TOUGH. Held or worn through the party ITEM menu, a scarf adds 20 to the introduction score in its category.

[Kanto Ribbons](https://github.com/mistermiracle3036/kanto_ribbons) is optional. This mod records category wins and rank wins on the Pokémon; Ribbons reads them and shows the ribbons, including for wins made before it was installed.

| |
|---|
| ![Kanto Ribbons' page: Cool Ribbon, Cool Super, Cool Hyper, Cool Master](docs/ribbons.png) |

Grand Hall, Trainer Journey and Trophy Case are also optional companions.

## The MASTER challenge

A traveler from a far-off region is eager to see you compete. If you can beat them and place first in a MASTER contest, you will be rewarded.

<details>
  <summary>Spoiler warning</summary>

  !["A little gift from home."](docs/master_gift_2.png)

  The full account, including what the reward does and the two Pokémon involved, is in **[docs/MASTER_CHALLENGE.md](docs/MASTER_CHALLENGE.md)**.

</details>

## Options

In the launcher under MODS → Contests → OPTIONS.

| Option | Default | Effect |
|---|---|---|
| HEARTS POP | AROUND ROOM | Audience hearts one seat at a time, or ALL AT ONCE. |
| MOVE MENU | FULL INFO | The move card, or a CLASSIC four-move menu. |

<details>
  <summary>Spoiler warning: the MASTER challenge's switches</summary>

| Option | Default | Effect |
|---|---|---|
| Dusk Stone reward | On | Award the stone for the first MASTER win against her. Off before that win completes the challenge without it. |
| Bundled evolutions | On | Register HONCHKROW and MISMAGIUS. Turn off to use another dex expansion's, then fully quit and relaunch. |

What each does to a save, and what happens if the mod is removed, is in [docs/MASTER_CHALLENGE.md](docs/MASTER_CHALLENGE.md).
</details>

## Red, Blue and Yellow

On Red, Blue and Yellow this mod is the original Celadon contest, reached through the little girl's invitation, with its older five-appeal judging meter. It is unchanged. Everything above, the Johto circuit and all that comes with it, is Gen 2 only.

## Compatibility and feedback

This mod adds its own rooms, places a building on four town maps, and wraps contest-specific engine behaviour. It carries hooks for optional companion mods and does not add wild encounters. Because it can add species to a save, it is marked as affecting link compatibility.

**A note on other mods:** Goldenrod, Ecruteak, Cianwood and Blackthorn are edited to fit the contest halls, so this mod may conflict with another mod that edits those overworld maps. If you hit one, open an issue naming the other mod; I will always work on a compatibility patch if asked.

See the [FAQ](FAQ.md), the [Changelog](CHANGELOG.md) and the [third-party notices](THIRD_PARTY_NOTICES.md). Report problems through [GitHub Issues](../../issues) with the loaded mod version, game edition, engine version, other enabled mods and the MODS ERRS output.

## Credits

The contest hall's custom cast is drawn by a lot of people, and every sheet is used with permission or under its licence, copied unchanged from the project's shared sprite store. Overworld walkers by **Bani** (Ash, Chef, Eusine, Larry, Leaf, Lear, Looker, Nate, Ranger, Yellow, Juliana, Lillie, Santa; and the Duplica, Giselle and Suzie sheets, which stand in for those characters), **Blaklyte** (N, Nurse Joy, Ingo), **SirWhibbles** (Agatha, Archer, Ariana, Giovanni, Petrel, Proton, the Rocket executive), **RoyalGuard** (Bill, Colress, Hugh, Lorelei, Maxie, Wally), **MOLLY** (Brendan, Dawn, Hilbert, Hilda, Lyra, Michael, Rosa, the stadium players, Wes), **Molly** (Green), **TeamHistoryWaffles** (Gloria, Officer Jenny, the Ruin Maniac), **NolanKrawczak** (Barry, May), **ArtsyAlraune** (the Breeder), **CyUzi** (Ball Guy), **KiravelSoul** (Volkner), **KIRB/YOSHI** (Bea), **Santiago Speedpaints** (Mina), **TheBrawlUnit** (AJ), **tharkka** (Roxie, commissioned) and **Yogurcomics** (Piers, commissioned).

From **Polished Crystal**, with each artist's credit kept: **Kuroko Aizawa** (the Artist, Cheryl, the Engineer; Ivy with **JaceDeane**), **bloodless** (Buck, Maylene, the Veteran), **isamuakai01** (Cynthia, Steven), **SCMidna and Freeline** (Marley, Mira, Riley), **Kage** (the Walker), **Pyro** (the Tamer), **FrenchOrange** (the Boarder) and **mauvesea** (DJ Mary). The Captain, the Exterminator and the Slot Maniac are by **EeVeeEe1999**, free to use with credit. One more commissioned walker, and the two Pokémon that come with the MASTER challenge, are credited in [docs/MASTER_CHALLENGE.md](docs/MASTER_CHALLENGE.md) so as not to spoil it here.

The applause is cut from "audience clap yell outdoor 02" by **klankbeeld** on Freesound, under Creative Commons Attribution: sound from http://www.freesound.org/people/klankbeeld/. The contest rules, move data and effects follow Generation III's, transcribed from the pokeemerald disassembly; no assets from those games are included. Gym leaders, the Elite Four and every ordinary trainer in the seats are drawn by your own game and are not redistributed. Full per-file detail is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Screenshots are from the iOS and Windows builds of gen1recomp running Pokémon Crystal.
