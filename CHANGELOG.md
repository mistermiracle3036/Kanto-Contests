# Changelog

## 0.34.27

- Coordinators drawn from the ordinary trainer classes have names now:
  a LASS is KIKI, GERTIE or SALLY, a SAILOR is AHAB, NEMO or TIDUS, and
  so on for every class -- two or three each, the same one for a given
  contest from the lobby queue through the judging.

## 0.34.26

- Picking a move looks like Ruby/Sapphire now: the four moves take
  the place of the score panels (name and category, a green name
  when it would combo with your last move, grey when it is out of
  PP), and the text box becomes a card about the highlighted move --
  its appeal hearts, any jam, its combo role, and what its effect
  does. The panels come back the moment you have chosen.
- Revert switch: MODS > Kanto Contests > MOVE MENU > CLASSIC.

## 0.34.25

- Your Pokemon's stage hearts now come from its condition, sheen and
  scarf -- the same score the judging uses -- instead of a random roll.
  A dull Pokemon draws few hearts and a pampered one draws many, and
  what the crowd showed is what decides the first appeal order (most
  hearts goes first, as in Ruby/Sapphire). Before, the stage rolled one
  number and the judging quietly used another.
- Long names fit: MISDREAVUS and friends no longer lose their last
  letter on the judging panels or in the commentary.
- Picking a move clicks, the same sound as the battle menu.
- "Now -- the judging!" opens like a big battle: the gym-leader theme
  starts and the screen flashes and wipes before the appeals. The hall's
  own music returns afterwards.

## 0.34.24

- No more ding. The first-round hearts still pop one at a time round
  the room, and the crowd applauds over them, as it did before the
  ding was tried. HEARTS POP still offers ALL AT ONCE.

## 0.34.23

- The heart ding is very tinny now, like a bell through a tiny
  speaker, at the same pitch as before. It is the mod's own sound
  (a synthesized pulse-wave bell), not the game's ting any more.

## 0.34.22

- Gym leaders and Elite Four in the crowd wear their real colours:
  Jasmine red not green, Misty red not blue, Koga blue not brown, and
  so on for eleven sprites whose sheet default the game never shows.
  Each seat now carries the same palette override the game's own maps
  use for that character.
- The heart ding drops another octave (two below the game's ting now).
  It runs at quarter speed, so it rings a little longer too.

## 0.34.21

- Ball Guy is back in the crowd, with his outline: the shared sprite
  was repaired, so the red blob is a proper Ball Guy now.

## 0.34.20

- The heart ding is an octave lower. Same sound, half the pitch; the
  game's own ting elsewhere is unchanged.

## 0.34.19

- First-round hearts now walk round the room one at a time, clockwise
  from the top-left, with a short ding (the game's own glass ting) for
  each, and every heart stays up until the walk is done so the count
  still reads at the end. While they walk there is no applause -- the
  game has one sound channel and the dings would cut it off.
- Revert switch: MODS > Kanto Contests > HEARTS POP. ALL AT ONCE is
  0.34.18's behaviour exactly, applause included. No rebuild needed.

## 0.34.18

- The applause is 0.34.12's, exactly as it was -- the developer's
  pick. The EQ tried in 0.34.17 is dropped.

## 0.34.17

- The applause goes back to 0.34.12's -- the one that was closest to
  right -- with one change on top: the lows and mids are a little
  quieter and the top end a touch brighter, so it sounds tinnier, like
  it is coming out of a small speaker. Same loudness as before.

## 0.34.16

- The red blob in the audience is gone. It was Ball Guy: his sprite
  file marks black as transparent, so the game drew him with no
  outline and no legs -- just the red dome and body. He sits out of
  the crowd until the shared sprite is repaired.
- No more birds in the seats. The crowd is people only; the entry
  meant as a bird keeper was actually a bird POKEMON on Gold and
  Crystal.
- The nurse in the crowd always faces the right way now. The game's own
  nurse sprite can only face the camera, so she was looking down from a
  seat that faced the stage; the crowd's nurse is now the mod's own,
  who can face any way. Karen and Will, who share that limitation,
  only take seats that face the camera.
- Duplica, Giselle and Suzie are back in the contest crowd.

## 0.34.15

- The applause loses the chime. 0.34.14's extra crush rang a high note
  (a third above the crowd's yell) that was not in the recording; the
  crush now comes from harder clipping instead, so it is as crunchy and
  still trails off slowly, without the tone.

## 0.34.14

- The applause: one notch more crushed, and it trails off more slowly.

## 0.34.13

- The applause is crushed harder still and a touch quieter.

## 0.34.12

- The applause is thicker and crunchier: the crowd's yell layered over
  its own clapping, run through a heavier bitcrusher.

## 0.34.11

- A new applause recording with voices in it -- a crowd that claps and
  yells rather than politely applauds. Credited in THIRD_PARTY_NOTICES.md
  as its author requires.

## 0.34.10

- The applause runs a little longer and dies away instead of stopping
  short, and it is a touch louder.

## 0.34.9

- The crowd applauds on stage too: the clap plays as the hearts go up
  for each coordinator's appeal, and for yours.

## 0.34.8
The crowd has a voice.

- When the applause meter fills and the crowd goes wild, you hear them:
  a short burst of applause, cut and crunched down to Game Boy fidelity
  from a public-domain recording (credited in THIRD_PARTY_NOTICES.md).

## 0.34.7

- The applause clip, once added, is looked for inside the mod's own folder.
  (0.34.6 pointed at the wrong place; nothing was audible either way yet.)

## 0.34.6

- When the crowd goes wild, the APPLAUSE box shows it: all five dots lit,
  the whole box flashing, and WILD!! in place of the label, for as long
  as the lines about it are on screen. Before, the meter had already
  emptied by the time the message appeared.
- The meter now shows the level as it stood for the appeal being read,
  not the live value.
- Ready for an applause sound: drop a cleared clip in as
  `assets/applause.ogg` and the roar plays with the flash. Without the
  file nothing changes.
- The CONTEST MOVES page's cursor sits on the page colour like the text.

## 0.34.5
The CONTEST MOVES page, tidied.

- Its text sits on the page colour like every other summary page,
  instead of on white cells.
- It has its own colour -- the contest panel's yellow -- and the page
  dots read pink, green, yellow, blue in the order you actually visit
  them. The contest page is third; the stats page is fourth.
- A follows that path too: MOVES -> CONTEST MOVES -> stats, the same as
  the right arrow. Before, A skipped the contest page.

## 0.34.4

- You stay put while the crowd's hearts pop for a coordinator on stage.
  You could walk off the line mid-appeal before.
- Held upright, the contest screen is shorter, so the coordinators' panel
  sits clear of the on-screen controls instead of under the D-pad.

## 0.34.3
Three small things from the first look.

- The Goldenrod Contest Hall's door plays the door sound on the way in.
- Your POKeMON stands on the stage while you choose your move, instead
  of an empty stage.
- The APPLAUSE meter stays up for the whole of an appeal that moved the
  crowd, alongside the line that says so, instead of vanishing after a
  moment. (How it works: a move of the contest's own type fills one dot,
  a move the crowd dislikes empties one; when the fifth dot would fill,
  the crowd goes wild for +6 hearts and the meter resets.)

## 0.34.2

- The stage is plain white, like a Gold battle, instead of Gen 3's green.

## 0.34.1
Plays upright again.

- The contest screen no longer needs the phone on its side. Held
  upright, the four coordinators sit below the stage instead of beside
  it -- one line each with the POKeMON's name and the coordinator's, the
  hearts underneath and the standing bar to the right. Turn the phone
  and it goes back to the side-by-side layout.

## 0.34.0
The judging looks like a contest now.

- The appeal round has its own screen, laid out like Ruby/Sapphire's:
  the four coordinators down the right with their POKeMON's name, their
  own name, this turn's hearts, and a bar showing where they stand; the
  judge at his desk; and whoever is appealing shown on stage.
- When another coordinator appeals you see their POKeMON, hear its cry,
  and watch the move -- Gold's own move animation plays on the stage.
- The APPLAUSE meter appears when the crowd reacts.
- No HP bars, no APPEAL stand-in POKeMON: the meter is the hearts.
- "Appeal no. N! Which move?" opens a move menu with each move's contest
  category beside it.

## 0.33.0
A CONTEST MOVES page in the summary.

- Open any POKeMON's summary and press right from the MOVES page. Each
  move's contest category is listed; move the cursor with up and down to
  see that move's appeal hearts, jam hearts, and what it does in a
  contest. Right again is the stats page, left is MOVES.
- Sits alongside Kanto Ribbons' page, which stays where it was (past the
  stats page).

## 0.32.0
Every move has its contest data now.

- All 251 moves carry their Ruby/Sapphire contest category, appeal and
  effect, so the appeal round is complete: moves that startle the
  entrants before you, moves that work best first or last, moves that
  hold the judge's attention and the combos that cash it in, moves that
  make the next entrants nervous, and the ones that excite or calm the
  crowd.
- Four moves change category to match Gen 3 -- DOUBLESLAP and LICK are
  TOUGH, DIZZY PUNCH and STRUGGLE are COOL -- and the 86 Gen 2 moves that
  had no data (and so all counted as TOUGH) have their proper categories.
- Rivals use their effects too, and at higher ranks they finish the
  combos they start.

## 0.31.0
The judging is a real appeal round now.

- Contests follow the Ruby/Sapphire rules. Four coordinators take five
  turns each; every move is worth a set number of hearts, the crowd warms
  to moves that suit the contest and goes wild when it gets excited enough,
  repeating a move costs more each time, and the winner is whoever has the
  most points from the stage round plus double their appeal hearts.
- The three coordinators you met on stage are the three you compete
  against. They bring their own POKeMON, choose their own moves, and their
  scores from the stage carry into the judging.
- Ranks. Winning a category with a POKeMON opens the next rank for it:
  NORMAL, then SUPER, HYPER and MASTER. Higher ranks bring stronger rivals
  with better-trained POKeMON. If more than one rank is open, the counter
  asks which.
- Your contest condition counts for more the better it is, and a scarf in
  the right colour still shines.
- Move effects (startling rivals, combos, and so on) arrive with the next
  update once every move's contest data is in; for now every move appeals
  plainly in its category.

## 0.30.4
The judging actually starts.

- The announcer names the contest properly. He was saying "NORMAL
  CONTEST CONTEST" instead of "NORMAL COOL CONTEST".
- After "Now -- the judging!" the battle begins, instead of leaving you
  standing on the stage with nothing happening.

Both were the same fault: the mod noted which of the five contests you
had entered, but the announcement was written above the place that note
was kept, so it read an empty one. The title fell back to the word
"CONTEST", and the judging had no contest to start.

If it ever does fail again it now says so on screen rather than only in
a log that phones cannot show.

## 0.30.3

- DAWN's spring and winter outfits are pink and red.

## 0.30.2

- DAWN wears her proper colours: blue in spring, pink in winter.

## 0.30.1

- The alternate outfits are actually green and blue now, rather than
  three near-identical versions of the same person.

## 0.30.0
Nobody is on a bicycle any more.

- Dawn, Brendan and May are off their bikes too, which completes the
  set -- eleven guests had the wrong half of their artwork.
- The two POKeMON STADIUM trainers are both here now, a boy and a girl,
  each with their own POKeMON.
- Their alternate outfits are in the mod but not in the crowd, so you
  will not see the same person twice.

## 0.29.2
Seven guests got off their bikes.

- Green, Hilda, Hilbert, Lyra, Michael, Rosa and Wes were riding
  bicycles around the contest hall. Their artwork had been cut from the
  wrong half of the sheet.

## 0.29.1
Everyone brings their own.

- Every coordinator now has their own POKeMON, trainer classes
  included -- a BUG CATCHER brings a CATERPIE, a FISHER a MAGIKARP.
  Before, most of the field drew from one short list, which is why the
  same few kept appearing.
- Three guests are sitting out until their artwork is fixed; they were
  the ones showing up as a coloured blob.

## 0.29.0
Coordinators bring their own POKeMON.

- Each familiar face now enters something that suits them -- Whitney a
  MILTANK, Morty a GASTLY, Misty a STARYU -- instead of anything at
  random.
- Swimmers no longer turn up in the hall. They are drawn mid-stroke, so
  they looked like they were swimming across the carpet.

## 0.28.1

- The judging starts on its own after the line-up, and says so if it
  ever cannot.

## 0.28.0
Your entrant, properly.

- Pick your POKeMON from the real party screen, the one a trade or a TM
  uses.
- Your POKeMON gets its picture, its cry and the crowd's hearts, the
  same as the other coordinators. None of that was appearing.
- Your party is given back when you leave the hall. It was not being
  restored at all.

## 0.27.1
The crowd answers before the score is read.

- The MC asks the room what they think, the hearts go up, and only then
  is the score announced.

## 0.27.0
You enter a POKeMON, and the MC knows your name.

- Pick which POKeMON you are entering at the desk. It is the only one
  with you until you leave the hall.
- The MC calls you by name and shows your POKeMON like everyone else's.
- You stand in the line facing the room, the same as the other
  coordinators.
- The text box clears before the crowd's hearts, so you can see all of
  them.

## 0.26.1
A different room every time you walk in.

- Restarting a contest without finishing it no longer brings back the
  same coordinators and the same crowd. Every visit to the hall draws
  a fresh room.

## 0.26.0
Everyone competes together.

- After you present, you walk back to the line and every coordinator
  turns to the judge with you. The judging starts there and then --
  no walking over to ask for it.

## 0.25.1
A fuller house, and coordinators who present properly.

- The hall no longer tiles itself across the edges of the screen.
- Fifteen to twenty in the crowd, with the back of the room filled by
  ordinary trainers so a bigger audience reads as a crowd rather than a
  reunion.
- Each coordinator walks up beside the judge to present, turns to face
  the room, and goes back to their place.

## 0.25.0
The new contest stage.

- The stage is a raised platform now, and the stairs at its front
  corners are the only way up onto it.
- The crowd is drawn from thirty possible places around the hall, ten
  to fifteen of them filled each contest, everyone facing the stage.
- The judge, the coordinators' line and your mark all moved onto the
  platform.

## 0.24.2
The hearts really do appear and fade now.

- All of an appeal's hearts pop across the audience one after another
  and then fade. Before, only the first ever appeared and it stayed on
  screen while you walked around afterwards.

## 0.24.1
The crowd's hearts are the score now.

- Each appeal gets as many hearts as it earned, popping across the
  audience one after another, instead of a single heart that hung
  around until the next coordinator.
- Those hearts are what the judging uses, so what happens on stage
  decides the placings.

## 0.24.0
The appeal round happens on stage now.

- Before any judging starts, the MC welcomes the room and each
  coordinator walks to the middle in turn, sends out their POKeMON,
  and the crowd answers with hearts. You are called up last.
- Every contest really does draw a different crowd now, and the
  coordinators queueing in the hall really are the ones you face --
  both were broken by the same bug and neither ever worked.

## 0.23.3
Five fixes from a code review.

- Leaving the Contest Hall now puts you on the pavement outside instead
  of standing in the doorway.
- Walking off the stage without competing no longer leaves the contest
  armed, so you are not announced again for one you abandoned.
- The hall keeps its building after you load a save.
- Nobody gets announced in the wrong room.

## 0.23.2

- The two Rocket Grunts now use Gold's own grunt sprites instead of custom
  copies. They looked almost identical to the originals, and the copies had
  a cut edge on one frame that the real ones do not.
- Lorelei's sprite was missing nearly half her width from the side and
  back views -- the original crop sliced her down one edge. Re-cut from the
  artist's sheet; 205 pixels of her come back.

## 0.23.1
The queue really is the field now.

- The coordinators waiting in the hall are genuinely the ones you are
  about to face. In 0.23.0 they were still a contest behind, so the
  queue and the stage rarely agreed.

## 0.23.0
Walk in through your own front door.

- The woman who used to walk you into the Contest Hall is gone. The hall
  has a door now, so you just go in.
- The stairs on the stage floor no longer turn you around -- they were
  never stairs, and should never have grabbed you.
- The coordinators queueing in the hall are the ones you actually compete
  against, instead of three strangers.
- At most one Gym Leader or Elite Four member enters a contest at a time.
  Three at once made it a gauntlet.
- Ariana's sprite no longer looks sliced down one side. Her side-facing
  frames had been cut two pixels too narrow when the art was first
  converted, which flattened her hair into a straight vertical line. She
  is re-cut from the artist's own sheet and now matches it exactly.

## 0.22.3

- Reverted nine sprites to the untouched canonical art. Agatha, Brendan,
  Dawn, Lance, May, Michael, Nurse Joy, Santa and Wes had been nudged a
  pixel sideways to satisfy an alignment rule that turned out not to exist:
  vanilla Gold walkers actually range from 6.5 to 9.0, so the sprites were
  never off in the first place. They now look exactly as the artists drew
  them, and identical to the same characters in every other mod.
- The genuine fix from 0.22.2 stays. Nine sheets really did carry stray
  pixels bled in from the neighbouring sprite on the source sheet, and
  those are still stripped.

## 0.22.2
The stray pixel beside the guests.

- Some guests had a loose pixel floating to their right and stood a
  little off their square -- a stray piece of the sprite next to them,
  caught when the art was first cut out. Cleaned up, and they line up
  properly now.

## 0.22.1
Eight guests were standing off their square.

- Ariana, Giovanni, Archer, Petrel, Proton and the Team Rocket grunts
  were drawn a pixel or two too far left, so they did not line up with
  anyone else and their side view looked cut off. They stand straight
  now.

## 0.22.0
The hall queue, and people who look at you.

- The contest hall queue now lines the right-hand wall, facing in, and
  you come in one step further left.
- Everyone in the hall and on the stage turns to face you when you talk
  to them, and has something to say.
- The announcer waits for you to actually be on the stage before calling
  your name, instead of talking over the doorway.

## 0.21.0
A crowd, rival coordinators, and a walk-on.

- The contest stage has an audience now: twelve seats and three rival
  coordinators, drawn fresh for each contest, so the room is never quite
  the same twice.
- Over fifty guest characters can turn up, competing or watching --
  familiar faces from across the series alongside the gym leaders and
  the Elite Four. Friends sometimes sit together.
- You line up with the other coordinators and get called to the stage by
  name, walking up on your own like a Gauntlet challenger.
- Larry competes once in a blue moon.
- The same contest always draws the same crowd, so reloading one does
  not reshuffle the room.

## 0.20.0
The Contest Hall has a building in Goldenrod.

- The hall is a real building on the Goldenrod street now, drawn from
  the developer's own layout, with a door you walk into instead of only
  an attendant to talk to. The attendant is still there.
- The building is stamped a cell at a time rather than by rewriting the
  city's map data, so other mods that change Goldenrod keep working.

## 0.19.1
Talk to the judge over his desk.

- The desk is a proper counter again, so you stand at it and speak across
  rather than walking around the end.

## 0.19.0
The boulders are gone and the carpet is the way out.

- **Those rocks were mine.** The "receptionist" I stood by each exit uses a
  sprite that is a person in Gold and a **boulder** in Crystal -- same name,
  different art, the same trap as the tilesets. Both are removed.
- **You leave on the carpet now.** Step onto the carpet by the door and you
  are put back where you belong: out of the lobby beside the attendant who
  showed you in, out of the stage back into the lobby.
- Every room is rebuilt from your latest save.

## 0.18.1
The missing rows are back.

- The top of every room was being drawn as empty void -- the row the judge
  stands on and the wall behind him. The game reads block number 0 in a map
  as "use the void block", not as the first block of the room's own tiles,
  and the rooms numbered their blocks from 0. Every room now starts its
  numbering at 1 and keeps 0 for the void, which is what the game expects.

## 0.18.0
The halls are finally right on Crystal.

- **Every room is rebuilt from the latest editor pass**, and built for
  the game you actually play. Gold and Crystal ship different tile art
  under the same filenames, so rooms laid out against Gold's tiles came
  out as nonsense on Crystal -- which is what the last few builds were.
  Each room now carries the right tiles for each game and picks at
  startup.
- All three halls -- the Goldenrod lobby, the stage, and Ecruteak --
  are hand-laid, and every character in them is verified to stand on
  solid ground and be reachable.

## 0.17.0
All three rooms are the hand-painted ones now.

- **The Ecruteak hall is hand-built too**, from the latest pass in the
  editor -- so every Contest Hall in the mod is now laid out by hand
  rather than assembled out of whole blocks.
- **Fixed the wrong tiles on the stage's edge.** One block on the right
  of the performance floor was drawing the wrong pieces; it is the
  corrected one from the editor now.

## 0.16.2
The new rooms are in colour, and stay inside their walls.

- **They were rendering in grey.** A room built out of custom blocks has
  to carry its own note of which colour set each tile takes; that note was
  being looked up from the running game and was coming back empty, so
  every tile fell back to the same flat palette. It is written into the
  mod now.
- **The room was tiling across the whole screen.** The block the game
  repeats *outside* a room was pointing at the first block of the new
  room -- the back wall -- instead of the void, so the wall papered
  everything. Both rooms now carry a proper edge block.

## 0.16.1
You can talk to the judge over his desk again.

- The map editor has no way to paint a counter, so the lobby desk came
  back as a plain wall and you had to walk around it. It is a proper
  counter again: you stand at it and talk across, the way you would to
  any clerk.

## 0.16.0
The Goldenrod rooms are hand-built now.

- **The lobby and the stage were laid out by hand in a map editor**
  rather than assembled by me out of whole vanilla blocks. Both rooms are
  now built a quarter-block at a time, which is a lot more control than
  stamping whole ones -- and they still add nothing to the download: the
  rooms are lists of numbers pointing into the tiles your own game
  already has.
- **In the lobby, the judge's counter came back as a solid desk**, since
  the editor cannot paint a counter -- fixed in 0.16.1 above.
- **The stage is rebuilt around its new shape**: a way in along the
  bottom, a divider with two openings, and the performance floor beyond
  it. The coordinators line up across that floor with your place beside
  them, and the audience watches from the entrance.

Ecruteak still has its single room and no entrance of its own; a lobby
for it is the next piece.

## 0.15.2
The stage is a raised dais with a proper stage front.

- Third dressing for this room, and the right one. The equipment banks
  read as shelving; the broadcast bench read as a front desk. The stage
  is now built from the **Game Corner** -- Goldenrod's own show floor:
  a **raised dais spans the room, with a decorated skirt for a stage
  front**, and the judge presides up on it. Perform from the floor in
  front of the dais, or walk up its open end and join him on it.
- **The audience sits show-floor seats** at the corners, palms dress
  stage left, and the room plays the Game Corner's music.

## 0.15.0
The judge leads you out to a stage.

- **A contest hall is two rooms now.** The room you walk into is a
  **lobby** -- the counter you enter at, the snack vendor, the appraiser,
  the coordinators waiting their turn. It always read as a lobby, and a
  contest was being held in it.
- **Enter a contest and the judge takes you to the stage.** Pick your
  category at the counter, he says to follow him, and you come out in
  Goldenrod's own **Radio Tower studio** -- broadcast equipment banked
  either side of an open floor, monitors along the back wall. Goldenrod
  would televise a contest, and now it does.
- **The other coordinators are already up there**, lined up and facing
  the stage, waiting their turn like you. Walk up the centre and speak to
  the judge when you are ready to perform -- so you get a moment to look
  at the place and at who you are up against.
- **You are shown back to the lobby afterwards**, win or lose, instead of
  being left standing on an empty stage. A receptionist by the stage door
  will take you back early if you change your mind.

Ecruteak's hall is still one room until it gets an entrance of its own.

## 0.14.0
Every town's Contest Hall is built out of that town's own materials.

- **The Goldenrod hall now looks like Goldenrod.** It was wearing
  Ecruteak's Dance Theatre -- wood, tatami, a raised stage -- while
  standing in the middle of Johto's big modern city. It is now the
  Department Store's room: tiled floor, shelving down both walls, windows
  along the back, and a long service counter that the judge presides
  behind. You talk to him across the counter, the way you talk to a clerk.
- **The Ecruteak hall is kept whole**, wood and tatami and all, ready for
  when Ecruteak gets its own entrance. It is no longer the room every town
  has to share.
- Each hall plays the music of the room it is dressed as.

Every hall is the same room underneath -- a stage, a barrier with a way up
at each end, the coordinator line, an entry strip -- so a contest reads the
same wherever you enter one. Only the materials change.

## 0.13.2
A smaller hall, and rival coordinators who actually compete.

- **The hall is much smaller.** It was a big empty room with the cast
  spread thin across it -- three identical floor rows where one does the
  job. The whole hall is now about a screen: you come in the door and the
  coordinator line is right there in front of you, with the stage and the
  judge above it.
- **The rivals take their turns now.** Before, they were introduced once
  and then only reappeared if they happened to jam you -- so a whole
  contest could go by with them doing nothing at all. Now one of them
  performs after every appeal of yours, rotating, and the judge reacts to
  each: all three are seen and scored in every contest.
- **Contests end with a placement.** Fill the meter and you place 1st. Run
  out of appeals and the judge ranks you against the other three on what
  everyone actually scored -- your appeals and your Introduction Round
  hearts against theirs. Placing 2nd of 4 after a strong routine now reads
  very differently from placing 4th.

## 0.13.1
The hall keeps the Emerald layout but wears Gold's own tiles.

0.13.0 drew its own Emerald-palette tile art and it didn't belong in a
Gen 2 game -- the Emerald screenshots were layout inspiration, not an art
direction. The room is now built entirely from the Ecruteak Dance
Theatre's vanilla tiles: the scroll-hung back wall, the dark stage boards
with a stair at each end, tatami floor with cushion seating, and the
proper doorway. What stays from Emerald is the blocking -- the judge on
stage, the audience watching from the floor, the coordinator line at the
floor's edge with the fourth place open for you, and the theatre's
performance music.

Everything in 0.13.0's entry below otherwise stands.

## 0.13.0
The Johto hall becomes the Emerald stage room.

**Updating from 0.8.2?** That was the last public release, and a lot has
landed since. The short version:

- **All five contests** (0.11.0), picked at the judge, wins recorded per
  category.
- **Contests came to Johto** (0.10.x): a Contest Hall in Goldenrod on
  Gold, Silver and Crystal.
- **Rival coordinators** (0.12.0): PIPER, REX and FIONA are scored before
  you in the Introduction Round and can jam your routine mid-contest.
- **PokeSnacks** (0.8.0), **the Introduction Round** (0.9.0), **earned
  contest scarves** (0.10.9), plus a long list of text-box fixes.

New in 0.13.0 specifically:

- **The Johto Contest Hall is rebuilt as the Gen 3 contest stage.** Styled
  on Emerald's stage room: a pale stage ringed by an audience standing at
  the ledge, the judging machine at the top, the golden performance emblem
  mid-stage, and striped steps up from the entrance. All-new tile art in
  the Emerald palette.
- **The other coordinators wait in line.** PIPER, REX and FIONA hold the
  contestant line at the bottom edge of the stage -- with the fourth place
  in the line left open for you. When it is your turn, step up to the
  emblem and speak to the judge.
- **A live audience.** Seven spectators ring the stage. The judge's music
  is now the Dance Theatre's performance theme rather than the city theme.
- The vendor, appraiser and receptionist now work the entry hall below
  the steps.

## 0.12.0
Rival coordinators.

**Updating from 0.8.2?** That was the last public release, and a lot has
landed since. The short version:

- **All five contests** (0.11.0): COOL, BEAUTY, CUTE, SMART and TOUGH. You
  pick which to enter at the judge, and wins are recorded per category.
- **Contests came to Johto** (0.10.x): Gold, Silver and Crystal have their
  own Contest Hall in Goldenrod City.
- **PokeSnacks and contest condition** (0.8.0), **the Introduction Round**
  (0.9.0), **earned contest scarves** (0.10.9), MIT license and credits
  (0.9.1).
- And new in this version: **rival coordinators** -- read on.

New in 0.12.0 specifically:

- **Three rival coordinators enter every contest.** PIPER, REX and FIONA
  wait their turn in both Contest Halls -- talk to them -- and in the
  Introduction Round the judge scores their entrants before yours, so your
  hearts land as the answer to theirs.
- **Rivals can jam your routine.** From the second appeal on, a rival may
  cut in and win back part of the judge's attention -- the appeal meter
  recovers a little. It can happen at most twice a contest, and never on
  the appeal that just filled the meter: a jam pressures the rounds you
  have left, it never steals a win you already sealed.
- **The judge's lines actually fit the box now.** The Johto battle box
  shows two rows and cuts anything longer; several reactions ran to three.
  "The judge is delighted!", "The judge frowns." and -- worst of all -- the
  entire verdict after your fifth appeal were being cut off. Every battle
  line is now split to fit, so nothing is lost.
- **Questions wait for you now.** In the Johto hall, the yes/no prompt used
  to appear over the text while it was still typing, showing only the last
  page -- and after answering, the same text played again underneath. Both
  the "text cut off" and the "lines repeated" reports came from this one
  bug, and both are fixed.

## 0.11.0
All five contests.

**Updating from 0.8.2?** That was the last public release, and a lot has
landed since. The short version:

- **There are five contests now**, not one: COOL, BEAUTY, CUTE, SMART and
  TOUGH. You pick which one to enter when you talk to the judge.
- **Contests came to Johto.** Gold, Silver and Crystal have their own
  Contest Hall in Goldenrod City, with its own judge, snack vendor and
  appraiser. An attendant on the main street shows you in.
- **PokeSnacks and contest condition** (0.8.0): five flavours, each raising
  one category. A POKeMON can only eat so many ever, so you choose what it
  is good at.
- **The Introduction Round** (0.9.0): before the appeals, the judge sizes
  your POKeMON up. Condition becomes audience hearts, and hearts become a
  head start on the appeal meter.
- **Contest scarves** (0.10.9): the appraiser gives you a scarf when a
  POKeMON maxes a category. A matching scarf is worth 20 points in the
  Introduction Round. Scarves are earned, never sold.
- The mod is MIT licensed with full credits (0.9.1).

New in 0.11.0 specifically:

- **Choose your contest.** The judge asks which of the five you are
  entering, as a list you pick from -- not five yes/no questions in a row.
  Every part of the contest already understood all five categories: the
  appeal scoring, the clashing-category penalty, the Introduction Round's
  hearts and the scarf bonus were all computed per category and then only
  ever told COOL. Now they are told what you picked.
- **Wins are recorded per category**, so a BEAUTY win is a BEAUTY win.
  Kanto Ribbons has understood all five since it added contest ribbons, and
  awards the ones it has artwork for -- so the other four light up there as
  soon as that mod draws them, including for contests you have already won.
- **The judge only promises a ribbon it can actually give.** It used to ask
  whether Kanto Ribbons was installed; now it asks whether that mod has the
  ribbon for *this* contest, so it can never dangle a prize that will not
  arrive.
- **Text-box fixes.** Several lines ran to three or four rows on a box that
  shows two and only waits for a button on a real page break, so the top of
  the message scrolled away before it could be read. The Johto hall's "would
  you like to go inside?" was the worst: you saw the question and never saw
  what it was about. Also fixed the judge's closing lines and two overlong
  rows.

## 0.10.9
Contest scarves, moved ahead of coordinator opponents.

- Added RED, BLUE, PINK, GREEN and YELLOW SCARVES for COOL, BEAUTY, CUTE,
  SMART and TOUGH. A matching scarf adds 20 points to the Introduction Round.
- The appraiser awards a category's scarf when shown a Pokemon with that
  condition maxed at 100. Scarves are earned, never sold.
- Crystal uses its native held-item flow: give the scarf to a Pokemon through
  the party ITEM menu. Gen 1 has no held items, so using a scarf from the bag
  records it as that Pokemon's worn contest accessory.
- Published `scarves`, `wornScarf` and `giveScarf(save, category)` exports
  so future coordinator and reward mods can share the same accessories safely.

## 0.10.8
Crystal-native judge portrait.

- Replaced the temporary Vest + Glasses portrait with Crystal's native
  **GENTLEMAN** battle front. This is the direct Gen 2 counterpart to Red's
  Gentleman contest judge and the class used by Gentleman Preston in Olivine
  Lighthouse, whose party is two Growlithe.
- The native judge remains in the opponent picture box for the whole routine;
  Crystal's ordinary trainer-slide event is suppressed only for contests.
- Removed the rejected custom portrait from the mod package and its active
  documentation. The historical 0.10.5/0.10.6 notes remain below.

## 0.10.7
Johto Contest Hall and clean contest victory.

- Filling the Gold APPEAL meter now ends the contest before Gold's normal
  faint resolver. The hidden Chansey stand-in no longer faints, the judge is
  never announced as defeated, and no trainer prize money is awarded.
- Goldenrod's outdoor attendant now leads into an owned indoor Contest Hall,
  built through the private Gen 2 map/tileset/runtime-object pattern proven by
  Hidden Grottos 0.1.3. The hall has its own judge and exit attendant.
- A hall vendor sells all five PokeSnack flavors for 500 and feeds the chosen
  Pokemon immediately. A hall appraiser reads all five condition categories
  and fullness using the same wording and saved fields as Kanto.

## 0.10.6
Updated Gold judge portrait.

- Replaced the temporary Indigo Conference 1.1.26 portrait with the corrected
  **Vest + Glasses** battle front from Indigo Plateau Conference 1.1.27. The
  detached palette-reference block is gone; the 56x56 portrait itself is not
  clipped or resized.
- Recorded the recovered source and permission: battle portrait by
  **JustinNuggets (Substitube)**, free to use with credit. The judge art is no
  longer blocked by missing attribution.

## 0.10.5
Private Gold judge-art test.

- Replaced Chansey's visible battle sprite with Indigo Conference 1.1.26's
  **Vest + Glasses** portrait. The proven Conference pattern changes only the
  already-created contest UI, so no shared Gold trainer class or ordinary
  battle is repainted; Chansey remains invisibly behind the appeal meter.
- The opponent send-out is now a judge entrance: no Chansey ball animation or
  cry. Judge presentation and withdrawal text refer to the judge throughout.
  Missing art produces a visible `KC error` line instead of silently falling
  back.
- **Private test restriction:** Indigo Conference records this probe portrait
  as missing durable artist/source attribution. It must be replaced or have
  its credits recovered before any public Kanto Contests release.

## 0.10.4
Gold contest-flow parity pass, following the first successful full device
round on 0.10.3.

- **Chansey is the visible judge, not a levelled opponent.** Its level and
  gender are hidden, the lone trainer-party ball row is removed, and the
  opening now says that the contest is beginning and the entrant is taking
  the stage instead of challenging the player to a battle.
- **The Introduction Round now runs on Gold.** The entrant's condition and
  sheen use the same Kanto scoring table, announce 0-8 audience hearts, and
  visibly convert into up to a 35% head start on the appeal meter.
- **One POKeMON, one routine now holds on Gold:** POKeMON and ITEM are refused
  without spending a turn. RUN explicitly withdraws with contest language
  before Gold's normal trainer-battle escape refusal can fire.
- Expanded the ROM-free Gold regression test to cover the Introduction Round,
  hidden judge level/gender, menu refusals, and clean withdrawal.

## 0.10.3
Gold core-rules pass, now device-verified end to end on Gold.

- **Status moves are appeals now.** Every move selected by the entrant goes
  through the same contest-only path before Gold can run its battle effect:
  THUNDER WAVE can fill the COOL meter but cannot paralyze the judge, GROWL
  can appeal but cannot lower a stat, and damaging moves cannot hit twice.
- **The judge no longer uses STRUGGLE between appeals.** Gold substitutes
  STRUGGLE when an opponent has no usable move even after the mod requests no
  enemy action; the contest path now suppresses that fallback cleanly.
- Added a ROM-free Gold battle regression test for effect suppression, meter
  scoring, PP use, judge reactions and the silent judge turn.

## 0.10.2
Gold spike round three. Still **not Gold-verified** end to end -- do not
merge until a Gold round passes.

- **The Contest attendant can be reached now.** She was standing inside a
  wall: the cell 0.10.0 guessed for her is solid, so the player could
  never face her and the "talk to her" step was unreachable. She now
  stands on the main street with her back to a building, on a cell
  measured against the game's own map data rather than guessed.
- **She also stands still properly.** Her movement was written in Gen 1's
  vocabulary, which means nothing on Gold; it is Gold's now.
- If her spot is ever blocked, she steps to the nearest free one instead
  of vanishing -- and the game log always names the cell she actually
  took, so a misplacement can never hide again.
- Re-entering Goldenrod no longer risks stacking a second attendant on
  the same spot.

## 0.10.1
Gold spike round two, from the first Gold test report. Still **not
Gold-verified** -- do not merge until a Gold round passes.

- **The judge reacts on Gold now.** The first test read as "nobody can
  damage anybody", and half of that was working-as-designed but mute: an
  opposed-category move (TACKLE is TOUGH, and TOUGH clashes with COOL)
  scores zero on purpose, but Gold had no reaction text saying so. The
  judge now comments on every appeal -- delighted / polite nod / frown --
  and counts appeals, through the battle's own message channel.
- **The five-appeal limit works on Gold**: after the fifth appeal the
  judge shakes his head and the contest ends cleanly, no blackout. This
  also caps the known rough edge of the meter mon Struggling on its turn
  (harmless -- it deals and takes nothing -- but noisy; the engine
  substitutes STRUGGLE for an empty enemy action and there is no skip
  seam yet).
- **Desktop diagnostics**: every scored appeal logs one line (move,
  category, score) so a PC Gold run shows exactly what each appeal did.
- Verified headlessly by driving the real mod through Gold's real battle
  logic: a COOL move drains 25%, an opposed move scores 0 with the frown
  line, five appeals end in a clean "run" exit. Known real gap on Gold:
  **status moves never reach the damage seam**, so they silently score
  nothing -- listed in NOTES.md for the polish pass.

## 0.10.0
**First Gold arm — a Goldenrod spike, NOT Gold-tested yet.** The manifest
now declares `games: ["gen1", "gen2"]`, which is a claim of having been
tested there; that claim is only true after a real Gold boot passes. **Do
not merge this to main until the Gold test round comes back clean.**

- On a Gold boot, a Contest attendant stands in **Goldenrod City** (her
  exact spot is a first guess — moving her is a two-number edit). Talk to
  her, say yes, and the COOL contest runs as a judge battle: appeals
  scored by contest category (match 25% / neutral 10% / opposed nothing),
  the judge never acts, no EXP, and a win records on the POKeMON exactly
  like Kanto's hall does.
- Built Gold-first per the standing direction: the Gold arm rides the
  generation-agnostic battle hooks (`battle.accuracy`, `battle.damage`,
  `battle.enemy_action`) and `mod.world` seams — no Gen 1 internals.
- Deliberately not in the spike (engine-blocked or deferred, see
  NOTES.md): the vendor, snacks in the bag, the appraiser, the custom
  hall map, the Introduction Round, and the five-appeal limit. On Gold
  the contest ends by win or by RUN.
- On Red/Blue/Yellow **nothing changes**: the Gen 1 arm is byte-for-byte
  the 0.9.1 behaviour, now behind a generation branch. Verified by a new
  headless test (`tests/gen_gate_test.lua`) that loads the mod under both
  generations and asserts a clean load on each.
- Known and accepted: `gen2check` still reports the Gen 1 arm's requires
  (it is a static scan and cannot see the runtime branch). The headless
  load test is the truth check.

## 0.9.1
Still an **ALPHA / proof of concept** — one COOL contest, one hall, one
judge.

**Updating from 0.8.2?** The headline is the Introduction Round (0.9.0,
below): before your first appeal the audience now scores your POKeMON's
condition as **0-8 hearts**, and hearts become a head start of up to 35%
of the appeal meter. Feeding snacks finally pays off in the contest
itself. This release adds housekeeping on top:

- The mod now carries a proper **MIT licence** (`LICENSE`), a
  `THIRD_PARTY_NOTICES.md` stating what is original and what is
  inspired-by, and a Credits section in the README. To be explicit about
  the one binary this mod ships: `assets/contest_tiles.png` is three
  8x8 flat-colour tiles drawn programmatically for the Contest Hall —
  original to this mod, covered by the MIT licence.
- Fixed a squeezed line when feeding a snack: "ate the" ran into the
  snack's name across the line break. The article moved down a line, so
  it now reads "ELECTABUZZ ate / the SPICY SNACK!".

## 0.9.0
**The Introduction Round.** Condition finally does something: before your
first appeal, the audience scores your POKeMON on looks alone.

- After the judge takes his seat, the audience holds up **0 to 8 hearts**.
  The score counts the contest's own condition in full, the two
  neighbouring conditions at half weight, and half of sheen -- so a
  specialised POKeMON beats a generalist, but no feeding is wasted.
- Hearts become a **head start on the appeal meter**, up to 35% of it,
  drained before your first move so you can watch it happen. A pampered
  POKeMON needs three matched appeals where an unfed one needs four.
- An unfed POKeMON gets silence from the audience and no head start.
  Appeals still decide everything -- that's the design.
- All four rank threshold rows (Normal/Super/Hyper/Master) ship in the
  data now, but only Normal is reachable until ranks arrive.

## 0.8.2
Still an **ALPHA / proof of concept** — one COOL contest, one hall, one
judge. This release adds the first half of contest condition.

**Updating from 0.7.5?** Everything below is new to you.

- **PokeSnacks.** Every POKeMON now has a hidden contest condition in each
  of the five categories. Five snacks raise them: SPICY (COOL), DRY
  (BEAUTY), SWEET (CUTE), BITTER (SMART), SOUR (TOUGH). Use one from the
  BAG on any POKeMON for +20 to that condition.
- **Sheen is a lifetime limit.** Each snack also adds 10 sheen, and at 100
  a POKeMON won't eat another — ten snacks each, ever. Enough to max two
  categories and never all five, so a contest POKeMON is one you chose to
  specialise.
- **A snack stall in the Contest Hall** sells all five at ¥500 each, over
  a normal shop counter — buy as many as you like, and sell them back.
- **An appraiser in the hall** reads any POKeMON's condition back to you
  in words rather than numbers, and comments on how well looked after it
  is.
- Condition and sheen live on the POKeMON itself, so they survive boxing,
  evolution, trading and saving.
- **Condition does nothing in a contest yet.** The Introduction Round that
  spends it is the next update — feeding now is not wasted.
- **Fixed:** in the widescreen battle layout the appeal meter was missing
  entirely, so there was no way to see how a contest was going. The judge
  and the meter both show there now. (The contest-specific dressing —
  the APPEAL label, the hidden level, the category in the move list — is
  still classic-layout only.)

Behaviour is identical to the 0.8.1 test build; only this changelog
differs.

## 0.8.1
- **The snack vendor is a proper shop now.** All five snacks listed at
  once with their prices, buy as many as you like at a time, and a QUIT
  option instead of having to say no to every flavour in turn. It's the
  game's own mart counter, so it behaves exactly like one -- including
  selling snacks back.
- Better words in two places. A POKeMON that can't eat any more now says
  it has had plenty, rather than being "too sheeny" -- nothing in the game
  ever told you sheen was a thing. And the appraiser describes how well
  looked after a POKeMON is instead of the texture of its coat, with the
  top remark hinting that a glowing POKeMON is also a full one.

## 0.8.0
**PokeSnacks.** Contest condition is now a thing your POKeMON has, and you
raise it by feeding them.

- Five snacks, one per contest category: SPICY (COOL), DRY (BEAUTY), SWEET
  (CUTE), BITTER (SMART), SOUR (TOUGH). Use one from the BAG on any
  POKeMON: **+20 to that condition, +10 sheen.**
- **Sheen is a lifetime limit.** At 100 the POKeMON refuses to eat any
  more, so it is ten snacks per POKeMON ever -- enough to max two
  categories, never all five. Choosing what a POKeMON is *for* is the
  point.
- **A snack vendor** in the Contest Hall sells all five at 500 each
  (tunable -- see NOTES.md).
- **An appraiser** in the hall reads any POKeMON's condition in words
  rather than numbers, and describes the shine of its coat. The wording is
  provisional and kept in one table for easy reassessment.
- Condition and sheen live on the POKeMON itself, so they survive
  boxing, evolution, trading and saving, exactly like contest wins.
- Condition does nothing in a contest **yet** -- the Introduction Round
  that spends it is the next slice. Feeding now is not wasted.
- New `NOTES.md` records what is parked, what is provisional, and the
  engine findings behind this slice.

## 0.7.6
- The appeal meter now shows in the widescreen battle layout. The mod
  pinned `showEnemyTrainer` for the whole contest "for anything else that
  reads it" -- and the widescreen HUD reads exactly that flag to decide
  whether to draw the enemy panel, with no way for the mod to intervene
  (its draw functions are file-local, unreachable from a mod). The pin
  turned out to be unnecessary even on classic: the draw wrapper that
  keeps the judge on screen sets the flag itself for each frame, on both
  layouts. Widescreen contests now show the judge and the meter; the
  classic-only dressing (APPEAL label, hidden level, no HP:) is still
  absent there, which the README now states accurately.

## 0.7.5
**First public release — this is an ALPHA / proof of concept.** One COOL
contest, one hall, one judge. It is playable and stable, but it is a
fraction of what Contests should be and things will change between
versions. Bug reports and "that move is in the wrong category" are exactly
what this release is for.

- Says so where you'll actually see it: the mod is listed as "Kanto
  Contests (Alpha)" and the load banner reads ALPHA rather than "ready",
  for anyone who installs from a link and never sees this page.
- The launcher can offer in-app updates again now that there is a public
  repository and a real release for it to point at.
- README rewritten: how appeals are scored, what works, and what is
  honestly not there yet -- only the COOL contest, no PokeSnacks, no
  ranks, and a contest HUD drawn for the classic battle layout only.
- Kanto Ribbons 0.18.0+ is optional. With it, a COOL win earns the Cool
  Ribbon; without it contests are unchanged and the judge doesn't mention
  ribbons. Wins are stored on the POKeMON either way, so installing it
  later still awards ribbons for contests already won.

## 0.7.4
- The appeal meter loses the leftover `:`. Closing the bar in 0.7.2 meant
  keeping the tile that carries both the colon and the bar's left cap;
  the colon half is now painted over, so the cap sits straight against
  the meter with nothing in front of it.
- The judge stops mentioning ribbons when Kanto Ribbons isn't installed.
  Losing or withdrawing still said "not quite ribbon material yet",
  dangling a prize that doesn't exist in that install -- the same rule his
  victory line already follows. With the ribbons mod present he says it as
  before.

## 0.7.3
- The judge now promises a COOL RIBBON rather than a "CONTEST RIBBON".
  Kanto Ribbons awards one ribbon per contest category, so the COOL
  contest earns the Cool Ribbon by name.
- The check for whether Kanto Ribbons is installed now fails safe. It asks
  whether the mod is *missing* instead of whether it is present, so if the
  check itself is ever skipped the judge falls back to the plain
  compliment. Before, a skipped check left the win flag standing and he
  would announce a ribbon that was never awarded.

## 0.7.2
- The appeal meter is closed at both ends again. Removing the `HP:` label
  also removed the bar's left cap -- they share one tile -- which was
  invisible until the meter drained to empty and the line just stopped. A
  small `:` sits where the label was; that is how vanilla looks whenever
  the move-select box covers the `HP`.
- Contests award no EXP, for real this time. A second guard now blocks the
  award at the engine function itself rather than only at the hook inside
  it, so it holds regardless of what else is installed.
- "A fair appeal" is now "A COOL move, but it works." The old wording read
  as a verdict rather than the middle rung, so it was impossible to tell
  whether it meant good or bad. The three outcomes now read as a ladder:
  delighted for a matching category, a polite nod for an off-category
  move, a frown for one of the two clashing categories (which scores
  nothing).
- The prize line no longer promises a ribbon "in a future update". Ribbons
  arrived in 0.7.0, and the judge announces one himself a moment later.

## 0.7.1
- No more "check failed" in the mod manager. The manifest was pointing the
  launcher's auto-updater at a repository that is still private and has no
  published release, so the check could only ever fail -- a red error on a
  mod that was loading and running perfectly. The pointer comes back when
  the repo goes public and has a real release to offer.

## 0.7.0
- Winning a contest now records the win on the POKeMON that performed, so
  Kanto Ribbons can award it a CONTEST RIBBON. The record lives on the mon
  itself, which means it survives boxing, evolution and trading -- and it
  is kept per category (COOL/BEAUTY/CUTE/SMART/TOUGH), so more contest
  types and per-category ribbons later need no change to an existing save.
- The judge no longer says "Ribbons come in the next update!". He promises
  a CONTEST RIBBON when Kanto Ribbons is installed and gives a plain
  compliment when it isn't, rather than announcing a ribbon that would
  never turn up. Checked when you talk to him, not at load, so install
  order cannot get it wrong.

## 0.6.0
- Text no longer runs off the right edge of the box. A battle message is not
  a dialogue box: it pages on `\v`, not on `\f`, so every `\f` page break
  this mod wrote was landing mid-line and the rest of the sentence was
  clipped. Contest text is now split into one message per page, which is
  what the engine's own trainer-defeat path does.
- The judge no longer wants to FIGHT you. The intro rewrite has never once
  fired -- it matched "wants to" and the real line breaks as "wants\nto" --
  so the COOL CONTEST announcement finally appears.
- APPEAL sits one row lower, tucked just above the meter instead of
  floating over the gap the hidden level left behind.

## 0.5.0
- The appeal meter is no longer labelled `HP:`. It's an appeal meter.
- The move list now shows each move's CONTEST CATEGORY where a battle shows
  its type, so you can pick an appeal without memorising the table.
- One POKeMON, one routine: PkMn and ITEM are refused during a contest.
  RUN still works and is now a clean withdrawal from the stage -- vanilla
  would have told you there's no running from a trainer battle.
- Contests award no EXP. Winning ran through the ordinary victory path and
  paid out a full trainer share (1638 EXP off one contest); a contest is a
  performance, not a fight. Real battles are untouched.
- The judge's reactions now end on the category line, so it's still on
  screen while the box waits for you instead of scrolling past.
- The winner's line no longer overflows the text box.

## 0.4.0
- Appeal scoring is in. Every player move in a contest is now a pure appeal:
  no accuracy roll, no type chart, no side effects (Growl no longer lowers the
  judge's stats -- it's a CUTE appeal). Matching the contest category drains
  25% of the appeal meter, neutral moves 10%, and the contest's two opposed
  categories score nothing and draw a frown.
- All 165 Gen 1 moves carry their Gen 3 contest category (best-effort data --
  report any move that feels miscategorized).
- Five-appeal limit: empty the meter in 5 moves or the judge shakes his head
  and the contest ends -- as a clean exit, no blackout, no prize.
- The judge's commentary counts your appeals; the prize-money line now reads
  as contest flavor.
- Appeal meter is now backed by a lv30 CHANSEY (never visible): scoring is in
  fractions of max HP, so this only makes the bar drain smoothly instead of
  vanishing to one Machoke hit.

## 0.3.0
- The judge's Pokemon is never visible: the pic layer now draws the judge for
  the whole contest, including through the send-out (v0.2 showed CLEFAIRY
  during the player's own send-out, since the intro queue is already built by
  the time the mod can react to it).
- The appeal meter no longer shows a level.
- Contest language replaces battle language: the intro, the judge's send-out
  and the appeal-meter faint all read as contest events now.

## 0.2.0
- Appeal meter: the judge's HP bar now stays visible while his portrait is on
  screen (drawHUDs suppresses the enemy HUD whenever a trainer pic holds the
  mon slot; a contest clears that flag for the draw only). Labelled APPEAL.
- Load banner moved to first map entry: game.ready fires before anything is on
  the stack and the title screen replaced it, so it never appeared.
- Declining the Celadon girl now shows her real vanilla line. MapScripts.baseTalk
  only covers hand-ported engine scripts and she has none, so the fallback now
  resolves her ROM text the same way showMapText does.

## 0.1.0
- First testable slice: Contest Hall map + tileset, Celadon entrance via the
  little girl (vanilla dialogue preserved on decline), COOL contest judge.
- Contest runs as a battle vs the judge; the judge's portrait stays on screen
  after the intro and the judge never attacks ("watching intently").
- Load banner option (default ON) prints the mod version on game ready.
