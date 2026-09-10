# Kanto Contests phone and desktop checklist

**Spoilers below** for the MASTER challenge. This is the tester's list, kept in
the repository and not in the download.

Import the zip through launcher MODS, then fully quit and relaunch. Start with
Kanto Contests alone. Existing saves are supported. The two challenge switches
default on; only Honchkrow and Mismagius are bundled.

## Every game (Crystal, Gold, Silver)

1. **Goldenrod.** Find the contest hall on the street. On Crystal the door is at
   the hall's own front (35,4) with the sign at 36,5. On Gold and Silver the
   front is different: door at 29,3, sign at 30,4, and the old open ground
   beside the gym is closed. Step in, save in the lobby, step out: you should
   land on the pavement below the door, never on the door.
2. **Ecruteak, Cianwood, Blackthorn.** Same walk-in and walk-out at each. Read
   every sign post near a hall: each hall's post names it. Cianwood on Crystal
   also has the POKe SEER's sign on its own post further into town; on Gold and
   Silver there is no second post there at all.
3. **Entering.** Talk to the judge across the desk. Try an egg and a fainted
   Pokémon: both refused. Enter with a Pokémon whose moves have zero PP: all
   five appeals still play and no PP is spent. B at the move menu, B again to
   cancel, then B and A to withdraw. Party order, held items and mail intact
   afterwards.
4. **Snacks and the appraiser.** Buy a snack: category and sheen gains
   previewed, capped category warns first. The appraiser reads condition in
   words; a condition at 100 earns the matching scarf. In the PACK, scarves and
   snacks each show a description line.
5. **The circuit.** Goldenrod NORMAL, Ecruteak SUPER, Cianwood HYPER, Blackthorn
   MASTER, ranks automatic, eligibility by category win count. Crowds bigger at
   higher ranks, facing the stage, nobody in front of the steps. Rivals pick
   moves more sharply at higher ranks and ease off again lower down.
6. **Judging.** Hearts, jams, combos (COMBO READY! badge), the applause meter
   and "the crowd goes wild", final placings, then back to the lobby with the
   full party. Both HEARTS POP modes and both MOVE MENU layouts.
7. **Interrupted contest.** Save on the stage and reload, or restore an
   overworld checkpoint from mid-contest: it cancels to the right lobby with
   the whole party and its mail.

## The MASTER challenge

8. At MASTER, Fantina is one of the three coordinators, whichever category.
   Lose or withdraw, enter another category: she is back. Her sprite and
   colours match Indigo Plateau Conference.
9. Win at MASTER. Back in the lobby she approaches, faces you, says her lines,
   hands over one Dusk Stone, then walks out through the exit carpet. Another
   MASTER win does not repeat it. On a separate save with a full bag she keeps
   the stone until you make room and revisit a lobby.
10. Use the stone on Murkrow and on Misdreavus (separate copies of the save):
    the evolution animation plays (its pages auto-advance, as every stone's do
    on this engine), the new species has its sprites, icon without a square
    background, dex entry and moves, and keeps its held item and contest
    records. An Everstone holder or an unrelated Pokémon does not consume it.
11. On a separate save, turn Dusk Stone reward off before the first MASTER win:
    the challenge completes with no gift. Turn Bundled evolutions off and
    relaunch: no bundled species load, and any you already own are set aside
    with a MODS ERRS notice, then return when the switch is back on.

## Desktop only

12. Windows, macOS or Linux: open a contest in a wide window. All four
    coordinators and the whole move list stay inside the window; resize to
    1280x720 and narrower and the panel stays centred. Phones keep their
    portrait and landscape layouts.

Automated checks cover the contest arithmetic, the five-turn input flow, entry
validation, all four halls and every rank, the challenge's retries and one-time
reward, the evolutions and the species-off protection, save recovery, dialogue
width, sprite conversion and the facade block references. They do not replace
this live pass. Report the loaded version and MODS ERRS for anything that fails.
