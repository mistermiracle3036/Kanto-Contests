# Kanto Contests 0.37.6 phone test

Import `kanto_contests-0.37.6.zip` through launcher MODS, then fully quit and relaunch. Start with Kanto Contests alone. Existing saves are supported. The two new switches default on; only Honchkrow and Mismagius are bundled.

Before entering, talk to the waiting coordinators. After a win or loss, the newly drawn lobby coordinators should talk about the next contest, including after leaving and reentering a hall.

1. Enter a contest with a healthy Pokemon whose moves have zero PP. Complete five appeals; no PP should be spent. Try B at the move menu, B to cancel withdrawal, then B followed by A to withdraw. Check all six party members, their order and held items afterward.
2. Try an egg and a fainted Pokemon at the desk. Both should be rejected before entering the stage.
3. Use the snack vendor. Confirm the category gain, sheen gain and permanent-choice prompt. At a capped condition, check the warning and decline; money and sheen should remain unchanged.
4. Progress through Goldenrod NORMAL, Ecruteak SUPER, Cianwood HYPER and Blackthorn MASTER. Ranks are automatic; eligibility uses category win counts. Verify Ecruteak's counter and stage, Cianwood's roof rock removal and corrected introduction hearts.
5. At MASTER, Fantina should be one of three coordinators. Lose or withdraw, then enter another category you qualify for: she should appear again. During the gift conversation, the player should face Fantina. Check her commissioned Fantina sprite in the lobby, introduction and reward approach; its colors should match Indigo Conference.
6. Win MASTER. After returning to the lobby, Fantina should approach and give one Dusk Stone. On a separate test save, fill the bag first: she should keep the stone, then give it after you make room and revisit a lobby. Further wins must not duplicate it.
7. Use the stone on Murkrow or Misdreavus. Check the normal evolution animation, new front/back sprites, shiny colors where applicable, party icon (both frames, with no square background), summary, dex entry, moves, held item and contest records. The other evolution can be tested from a separate copy of the save. An egg, unrelated Pokemon or Everstone holder should not consume the stone.
8. On a separate save, turn Dusk Stone reward off before the first MASTER win. Fantina's challenge should complete without a gift. Turn Bundled evolutions off and fully relaunch: no bundled species should load. Existing affected Pokemon should be protected, then return intact when you reenable the option and relaunch. A compatible external dex expansion can supply the stone's target instead; test that combination before using it on a main save.
9. Save/relaunch on the stage and restore an overworld checkpoint from during a contest. The interrupted contest should cancel to the correct lobby with the complete party and its mail restored.
10. Check audience facing and heart restoration in both HEARTS POP modes, both MOVE MENU layouts and both phone orientations. Finally test the intended optional companion mods and ribbon awards.

Automated checks cover contest arithmetic, five-turn input flow, entry validation, four hall ranks, cross-category Fantina retries, one-time/full-bag rewards, native evolutions, save recovery and the species-off behavior. They do not replace this live iPhone animation/input check. Report the loaded version and MODS ERRS for failures.
