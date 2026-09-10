-- Kanto Contests -- complete contest-cast dialogue.
--
-- DATA ONLY. Loaded by main.lua with mod:read + load. The most specific
-- nonempty pool wins: character, then class, then generic pool. Picks
-- remain stable per actor per contest.
--
-- Contexts: queue before the contest, stage in the line-up, won after
-- the player wins, lost after the player does not win, crowd in seats.
-- Every page is at most two rows of 18 glyphs. \n starts row two and
-- \f starts a new page.
return {
  characters = {
    ["SPRITE_KC_DUPLICA"] = {
      queue = {
        "DITTO knows the\nroutine. Mostly.",
        "We match moods,\nnot just faces.",
      },
      stage = {
        "JUDGE, meet the\nother JUDGE!",
        "Do not blink.\fWe may both\nchange.",
      },
      won = {
        "You saw the trick.\nVery impressive.",
        "That was no copy.\fIt was all yours.",
      },
      lost = {
        "We need new act.\nThat one got stuck",
        "DITTO says your\nstyle is tricky.",
      },
    },
    ["SPRITE_KC_GISELLE"] = {
      queue = {
        "Preparation makes\nluck unnecessary.",
        "My form is already\nabove average.",
      },
      stage = {
        "Watch carefully.\nThis is technique.",
        "The JUDGE will\nnotice precision.",
      },
      won = {
        "Your result was\nquite sound.",
        "I will revise my\nopinion of you.",
      },
      lost = {
        "Do not mistake\nthis for a lesson.",
        "You need polish.\fA great deal.",
      },
    },
    ["SPRITE_KC_SUZIE"] = {
      queue = {
        "A calm POKeMON\nalways shines.",
        "Care comes before\ncompetition.",
      },
      stage = {
        "Easy now, partner.\nEnjoy the crowd.",
        "Good condition\nspeaks for itself.",
      },
      won = {
        "Your bond showed.\nThat won the room.",
        "Such lovely care.\fWell done.",
      },
      lost = {
        "Your POKeMON tried\nso earnestly.",
        "Gentle care will\nhelp next time.",
      },
    },
    ["SPRITE_KC_STADIUM_BOY"] = {
      queue = {
        "Big crowd today.\nThat suits me.",
        "I trained for\nthe bright stage.",
      },
      stage = {
        "Let the main event\nbegin right now!",
        "Power and timing.\nThat is my game.",
      },
      won = {
        "You took the title\nwith real style.",
        "A worthy finish.\fI salute it.",
      },
      lost = {
        "A tough field.\nCome back strong.",
        "One loss builds\nthe next victory.",
      },
    },
    ["SPRITE_KC_STADIUM_GIRL"] = {
      queue = {
        "I came prepared\nfor every turn.",
        "Pressure makes\ngood form sharper.",
      },
      stage = {
        "Eyes up, partner.\nOwn this stage.",
        "Precision wins\nthe loudest crowd.",
      },
      won = {
        "Excellent work.\nNo notes from me.",
        "You made the hard\npart look easy.",
      },
      lost = {
        "Study the order.\nYour turn comes.",
        "You have skill.\nRefine the finish.",
      },
    },
    ["SPRITE_KC_ASH"] = {
      queue = {
        "A contest is not\na battle. Got it.",
        "PIKACHU says we\ncan do this!",
      },
      stage = {
        "All right, buddy!\nShow your best!",
        "Win the crowd\none move at a time",
      },
      won = {
        "That was awesome!\nYou earned it!",
        "Your POKeMON and\nyou were in sync!",
      },
      lost = {
        "We both go back\nand train harder!",
        "Next time, give it\neverything again!",
      },
    },
    ["SPRITE_KC_JULIANA"] = {
      queue = {
        "I packed snacks\nand three plans.",
        "Every new contest\nis an adventure!",
      },
      stage = {
        "Come on, partner!\nLet us sparkle!",
        "New stage look.\nSame big smile!",
      },
      won = {
        "You were amazing!\nI learned a lot.",
        "That win belongs\nin your story.",
      },
      lost = {
        "Rough day?\fWe keep exploring!",
        "Next page will be\nbetter than this.",
      },
    },
    ["SPRITE_KC_LEAF"] = {
      queue = {
        "My partner likes\na quiet warmup.",
        "No rush. The best\nmoments grow.",
      },
      stage = {
        "Soft steps first.\nThen surprise all.",
        "Let nature set\nthe pace for us.",
      },
      won = {
        "You bloomed at\nthe right moment.",
        "That was a lovely\nperformance.",
      },
      lost = {
        "Give it time.\fSkill keeps\ngrowing.",
        "Your next appeal\nmay be the one.",
      },
    },
    ["SPRITE_KC_LEAR"] = {
      queue = {
        "You may watch me\nset the standard.",
        "The finest stage\ndeserves my time.",
      },
      stage = {
        "JUDGE, prepare\nto be impressed.",
        "A royal entrance\nneeds no warning.",
      },
      won = {
        "You exceeded my\nexpectations.",
        "Enjoy the honor\nof besting me.",
      },
      lost = {
        "The crowd is hard\nto train.",
        "Return when your\nstyle has matured.",
      },
    },
    ["SPRITE_KC_LILLIE"] = {
      queue = {
        "My POKeMON feels\na little nervous.",
        "We will be brave\ntogether.",
      },
      stage = {
        "It is all right.\nI am beside you.",
        "One gentle appeal.\nWe can do that.",
      },
      won = {
        "You gave everyone\nsuch confidence.",
        "That was\nbeautiful. Truly.",
      },
      lost = {
        "We can all improve\nat our own pace.",
        "Please do not lose\nheart over this.",
      },
    },
    ["SPRITE_KC_NATE"] = {
      queue = {
        "I checked every\nmove twice.",
        "We are ready for\nwhatever comes.",
      },
      stage = {
        "Steady now.\fShow them\nour work.",
        "Clean and bold.\nThat is the plan.",
      },
      won = {
        "You made every\nturn count.",
        "Strong result.\fYou earned it.",
      },
      lost = {
        "Take what worked.\nBuild from there.",
        "The next contest\ncan go your way.",
      },
    },
    ["SPRITE_KC_YELLOW"] = {
      queue = {
        "My POKeMON likes\nthe happy crowd.",
        "We do not need\nto be loud.",
      },
      stage = {
        "Just be yourself.\nThey will feel it.",
        "A quiet heart can\nfill this room.",
      },
      won = {
        "Your POKeMON is\nproud of you.",
        "I could feel your\ntrust from here.",
      },
      lost = {
        "Your partner still\nbelieves in you.",
        "Rest together.\fThen try again.",
      },
    },
    ["SPRITE_KC_N"] = {
      queue = {
        "The POKeMON here\nhave much to say.",
        "Your partner asks\nyou to breathe.",
      },
      stage = {
        "Listen closely. It\nis their appeal.",
        "Crowd hears sound.\nI hear intent.",
      },
      won = {
        "Your POKeMON says\nthe win felt warm.",
        "That bond cannot\nbe calculated.",
      },
      lost = {
        "Your partner says\nthis is not over.",
        "No score can erase\nwhat they felt.",
      },
    },
    ["SPRITE_KC_VOLKNER"] = {
      queue = {
        "Maybe this crowd\nhas some spark.",
        "Wake me when the\nmeter moves.",
      },
      stage = {
        "There. That charge\nfeels promising.",
        "Give me one appeal\nworth watching.",
      },
      won = {
        "You woke the room.\nAnd me.",
        "That finish had\nreal voltage.",
      },
      lost = {
        "The spark faded.\nFind it again.",
        "You need a sharper\njolt next time.",
      },
    },
    ["SPRITE_KC_BEA"] = {
      queue = {
        "Breath is steady.\nMind is clear.",
        "Each move has\nclear purpose.",
      },
      stage = {
        "Take your stance.\nDo not waver.",
        "Control creates\ntrue strength.",
      },
      won = {
        "Your discipline\nwas best today.",
        "A clean victory.\nYou earned respect",
      },
      lost = {
        "Accept the result.\nThen improve.",
        "Resolve is built\nafter hard days.",
      },
    },
    ["SPRITE_KC_BRENDAN"] = {
      queue = {
        "The road here was\ngood practice.",
        "New crowd, new\ntest. I like it.",
      },
      stage = {
        "Let us make this\nworth the trip!",
        "The best route is\nstraight to bold.",
      },
      won = {
        "You found the best\nway through.",
        "Great work!\fThat was an\nadventure.",
      },
      lost = {
        "A setback is just\nanother trail.",
        "We will both find\na better route.",
      },
    },
    ["SPRITE_KC_DAWN"] = {
      queue = {
        "No need to worry.\nWe came polished.",
        "Every detail is\nalready in place.",
      },
      stage = {
        "Watch the timing.\nThen we shine.",
        "Grace looks easy\nafter real work.",
      },
      won = {
        "That was flawless.\nAlmost unfair.",
        "You stayed calm.\nI am impressed.",
      },
      lost = {
        "Do not rush back.\nFix small things.",
        "Your idea was\ngood. Refine it.",
      },
    },
    ["SPRITE_KC_GREEN"] = {
      queue = {
        "Try to keep up.\nI dislike waiting.",
        "I know exactly\nwhat they want.",
      },
      stage = {
        "Watch this once.\nNo repeats.",
        "The crowd is mine.\nFor now.",
      },
      won = {
        "Fine. You were\nbetter this time.",
        "Enjoy it while the\nsurprise lasts.",
      },
      lost = {
        "That look again?\fTrain smarter.",
        "You almost made\nthis interesting.",
      },
    },
    ["SPRITE_KC_HILBERT"] = {
      queue = {
        "A clear purpose\nkeeps us steady.",
        "Truth shows in\nhow we perform.",
      },
      stage = {
        "No empty gestures.\nMean every move.",
        "Stand for the bond\nthat led us here.",
      },
      won = {
        "Your result spoke\nfor itself.",
        "An honest victory.\nWell earned.",
      },
      lost = {
        "Keep your ideal.\nRefine the method.",
        "One result cannot\ndefine your path.",
      },
    },
    ["SPRITE_KC_HILDA"] = {
      queue = {
        "I like a crowd\nwith some energy.",
        "We did not come\nto blend in.",
      },
      stage = {
        "Make it bold!\nMake it ours!",
        "No timid steps.\fHit the spotlight!",
      },
      won = {
        "You owned that\nroom. Nicely done.",
        "That finish had\nserious style.",
      },
      lost = {
        "Shake it off.\fCome back louder.",
        "You have more fire\nthan that result.",
      },
    },
    ["SPRITE_KC_LYRA"] = {
      queue = {
        "Wrong snacks again\nThat is on me.",
        "Three lists ready!\nOne may be useful.",
      },
      stage = {
        "Smile, partner!\nWe planned this!",
        "Was our combo\nfirst or second?",
      },
      won = {
        "You were great!\nI took notes.",
        "That win looked\nso much like you.",
      },
      lost = {
        "We can compare\nnotes after this.",
        "Next time I will\npack good snacks.",
      },
    },
    ["SPRITE_KC_MICHAEL"] = {
      queue = {
        "Quiet room. I can\nwork with that.",
        "My partner and I\nknow the signal.",
      },
      stage = {
        "No wasted steps.\nMove when ready.",
        "Let the POKeMON\ntake the focus.",
      },
      won = {
        "Clean work.\nYou deserved it.",
        "You stayed calm\nthrough it all.",
      },
      lost = {
        "Keep moving. One\nloss is nothing.",
        "The next stage\nwill feel easier.",
      },
    },
    ["SPRITE_KC_ROSA"] = {
      queue = {
        "Every appeal needs\na little music.",
        "I can hear the\nopening already!",
      },
      stage = {
        "Places, partner!\nThe show begins!",
        "Turn this room\ninto our chorus!",
      },
      won = {
        "That was a finale!\nBravo!",
        "You found the beat\nand never lost it.",
      },
      lost = {
        "A quiet ending\nneeds a new song.",
        "Take a bow anyway.\nYou gave a show.",
      },
    },
    ["SPRITE_KC_WES"] = {
      queue = {
        "We are ready.\nThat is enough.",
        "Crowds do not\nchange the plan.",
      },
      stage = {
        "Stay sharp.\nMove on my mark.",
        "One look. One move\nNo hesitation.",
      },
      won = {
        "You were better.\nRespect.",
        "That win was\nclean. Keep it.",
      },
      lost = {
        "Bad score.\nNot the end.",
        "Learn the pattern.\nBreak it next.",
      },
    },
    ["SPRITE_KC_BARRY"] = {
      queue = {
        "You are late!\fFine, I was early.",
        "Five turns planned\nin five seconds!",
      },
      stage = {
        "Go, go, go! The\ncrowd is waiting!",
        "Fast entrance!\nFaster appeal!",
      },
      won = {
        "How did you win\nthat quickly?",
        "Great job!\fI still want\na fine.",
      },
      lost = {
        "No slowing down!\nTry again soon!",
        "You owe yourself\na faster comeback!",
      },
    },
    ["SPRITE_KC_MAY"] = {
      queue = {
        "I get nervous.\nThat means I care.",
        "We practised hard.\nI hope it shows.",
      },
      stage = {
        "Ready, partner?\nLet us do our best",
        "Feel the crowd.\fNow trust\nthe move.",
      },
      won = {
        "You were brilliant\nI mean it.",
        "That win showed\nhow far you came.",
      },
      lost = {
        "Do not give up.\nI have been there.",
        "One contest cannot\nhide your growth.",
      },
    },
    ["SPRITE_KC_COLRESS"] = {
      queue = {
        "I optimized our\nappeal sequence.",
        "The crowd is a\nuseful variable.",
      },
      stage = {
        "Begin the trial.\nRecord all hearts.",
        "Your response will\ntest my model.",
      },
      won = {
        "Fascinating.\fYou broke\nthe model.",
        "Your bond produced\nsuperior results.",
      },
      lost = {
        "The data suggests\na small revision.",
        "Your potential\ncan be measured.",
      },
    },
    ["SPRITE_KC_HUGH"] = {
      queue = {
        "My partner gave\nall to train.",
        "I will not waste\ntheir effort.",
      },
      stage = {
        "Show your grit!\nI am right here!",
        "No holding back.\nProtect this turn.",
      },
      won = {
        "You fought for\nevery heart.",
        "Your partner had\nthe best support.",
      },
      lost = {
        "Stay angry at\nthe weak result.",
        "Use that fire\nto return strong.",
      },
    },
    ["SPRITE_KC_LORELEI"] = {
      queue = {
        "Composure decides\nmore than volume.",
        "A cool head keeps\nthe form clean.",
      },
      stage = {
        "Let the room hush.\nNow begin.",
        "Precision can feel\nlike winter air.",
      },
      won = {
        "You never slipped.\nImpressive.",
        "Graceful victory.\nTreasure it.",
      },
      lost = {
        "Let no cold result\nlinger.",
        "Refine your form.\nReturn composed.",
      },
    },
    ["SPRITE_KC_MAXIE"] = {
      queue = {
        "Each outcome needs\na grand design.",
        "I have mapped each\nturn precisely.",
      },
      stage = {
        "Rise to the plan!\nShape the room!",
        "The stage submits\nto clear purpose.",
      },
      won = {
        "Your ambition\novercame my plan.",
        "A surprise peak.\nWell climbed.",
      },
      lost = {
        "Your foundation\nneeds more work.",
        "Think on a larger\nscale next time.",
      },
    },
    ["SPRITE_KC_WALLY"] = {
      queue = {
        "I am nervous.\fThat is all right.",
        "We made it here.\nThat matters.",
      },
      stage = {
        "One breath now.\nThen our best.",
        "I can do this.\fWe can do this.",
      },
      won = {
        "You stayed calm.\nI want that poise.",
        "Your win gives me\ncourage too.",
      },
      lost = {
        "Please try again.\nI know you can.",
        "A hard result can\nmake us stronger.",
      },
    },
    ["SPRITE_KC_MINA"] = {
      queue = {
        "The colors here\nfeel almost awake.",
        "I may paint this\nfeeling later.",
      },
      stage = {
        "Hold that pose.\nNo, the other one.",
        "Make the appeal\nlook like a dream.",
      },
      won = {
        "Your colors filled\nthe whole room.",
        "That was art.\fKeep the ribbon.",
      },
      lost = {
        "The picture needs\nanother layer.",
        "No worry.\fBlank space\ncan help.",
      },
    },
    ["SPRITE_KC_GLORIA"] = {
      queue = {
        "This looks like a\nproper challenge!",
        "My partner is\nready for this.",
      },
      stage = {
        "Come on, then!\nGive them a show!",
        "Big smile, pal!\nOur turn starts!",
      },
      won = {
        "What a victory!\nYou were grand!",
        "You made that look\nbrilliantly easy.",
      },
      lost = {
        "Chin up!\fThere is\nmore ahead.",
        "A loss today makes\na story tomorrow.",
      },
    },
    ["SPRITE_KC_ROXIE"] = {
      queue = {
        "The crowd needs\na louder pulse.",
        "My POKeMON knows\nthe whole set.",
      },
      stage = {
        "Count us in!\nThen turn it up!",
        "Hit hard, partner!\nMake the meter pop",
      },
      won = {
        "You took the show.\nGood for you.",
        "That finish rocked\nNo argument.",
      },
      lost = {
        "Your beat slipped.\nFind it again.",
        "Do not fade out.\fCome back loud.",
      },
    },
    ["SPRITE_KC_AJ"] = {
      queue = {
        "No shortcuts. We\ntrain every day.",
        "My partner can\ntake any pressure.",
      },
      stage = {
        "Toughen up! Show\nthem the work!",
        "No tricks needed.\nJust perfect form.",
      },
      won = {
        "You trained\nharder. It showed.",
        "A strong result.\nRespect earned.",
      },
      lost = {
        "That was too soft.\nTrain and return.",
        "Your partner needs\nclear direction.",
      },
    },
    ["SPRITE_KC_PIERS"] = {
      queue = {
        "No bright smile.\nThe song is enough",
        "Keep the polish.\nI brought a pulse.",
      },
      stage = {
        "No cheers needed.\nJust hear this.",
        "Low, sharp beat.\nThat is the set.",
      },
      won = {
        "You hit the last\nnote perfectly.",
        "Good show.\fDo not make\nme grin.",
      },
      lost = {
        "Bad nights happen.\nWrite a new verse.",
        "Chase no cheers.\nFind your sound.",
      },
    },
    ["SPRITE_KC_LARRY"] = {
      queue = {
        "I was asked to\nfill a spare slot.",
        "This is overtime.\nI will be brief.",
      },
      stage = {
        "All right, pal.\nLet us finish.",
        "A normal appeal\nshould be enough.",
      },
      won = {
        "You won. Good.\fCan I leave now?",
        "Efficient work.\nCongratulations.",
      },
      lost = {
        "Same paperwork.\nEither way.",
        "You did your part.\nGet some lunch.",
      },
    },
    ["SPRITE_WHITNEY"] = {
      stage = {
        "Cute always wins!\nJust watch us!",
        "MILTANK, smile!\nWe have this!",
      },
      won = {
        "No fair!\fYou were too good!",
        "Fine. Nice win.\fDo not gloat.",
      },
      lost = {
        "Do not cry!\fI mean me,\nnot you.",
        "You nearly had it.\nNearly!",
      },
    },
    ["SPRITE_FALKNER"] = {
      stage = {
        "We rise with\nmeasured grace.",
        "Watch the wings.\nThey never falter.",
      },
      won = {
        "Your form carried\nyou above us.",
        "A worthy victory.\nStand proud.",
      },
      lost = {
        "A fall teaches\nthe shape of wind.",
        "Train your rhythm.\nThen rise again.",
      },
    },
    ["SPRITE_BUGSY"] = {
      stage = {
        "This routine shows\nyears of research!",
        "Every small motion\nhas a purpose.",
      },
      won = {
        "Amazing!\fI need to\nstudy that.",
        "Your appeal showed\na new pattern.",
      },
      lost = {
        "Do not worry.\fDiscovery\ntakes time.",
        "Try a new order.\nSee what changes.",
      },
    },
    ["SPRITE_MORTY"] = {
      stage = {
        "The outcome shifts\njust out of sight.",
        "I have seen one\npossible ending.",
      },
      won = {
        "The vision cleared\nYou stood above.",
        "Your bond altered\nwhat I foresaw.",
      },
      lost = {
        "This path closed.\nAnother remains.",
        "Look beyond the\nscore before you.",
      },
    },
    ["SPRITE_CHUCK"] = {
      stage = {
        "HAH!\fA contest of grit!",
        "Our appeal hits\nlike a great wave!",
      },
      won = {
        "You broke through!\nExcellent!",
        "That victory had\nreal force!",
      },
      lost = {
        "Stand back up!\nTest continues!",
        "More training!\nMore heart!",
      },
    },
    ["SPRITE_JASMINE"] = {
      stage = {
        "We will try our\nvery best.",
        "Quiet strength can\nstill shine.",
      },
      won = {
        "Your POKeMON was\nwonderful.",
        "Such a gentle win.\nCongratulations.",
      },
      lost = {
        "Please do not be\ntoo discouraged.",
        "Your bond is clear\nKeep trusting it.",
      },
    },
    ["SPRITE_PRYCE"] = {
      stage = {
        "Experience keeps\nthe footing sure.",
        "A steady heart\noutlasts nerves.",
      },
      won = {
        "You kept balance\nthrough each turn.",
        "A deserved result.\nRemember it.",
      },
      lost = {
        "Cold results pass.\nLessons remain.",
        "Patience shapes\nyour next try.",
      },
    },
    ["SPRITE_CLAIR"] = {
      stage = {
        "Try not to look\noverwhelmed.",
        "Our elegance is\nbeyond dispute.",
      },
      won = {
        "You expect praise?\fFine. Well done.",
        "That result was\nalmost worthy.",
      },
      lost = {
        "Do not sulk.\fTrain until proud.",
        "You lacked command\nof the stage.",
      },
    },
    ["SPRITE_BROCK"] = {
      stage = {
        "A firm base makes\na strong routine.",
        "We will not be\nshaken up here.",
      },
      won = {
        "Your foundation\nwas best today.",
        "Solid work.\fYou earned this.",
      },
      lost = {
        "Build from this.\nDo not crumble.",
        "Rough edges can\nbecome strength.",
      },
    },
    ["SPRITE_MISTY"] = {
      stage = {
        "Try to keep pace!\nWe move fast.",
        "Beauty needs bite.\nWatch closely.",
      },
      won = {
        "You caught the\nperfect current.",
        "Nice win!\fDo not get smug.",
      },
      lost = {
        "You lost the flow.\nFind it next time.",
        "A little nerve\nwould help you.",
      },
    },
    ["SPRITE_SURGE"] = {
      stage = {
        "Get ready, pal!\nRoom will spark!",
        "We bring the shock\nand the style!",
      },
      won = {
        "What a blast!\nYou lit it up!",
        "You earned it,\nsoldier!",
      },
      lost = {
        "No power?\fCharge up\nand return!",
        "Stand tall, pal!\nNext one is yours!",
      },
    },
    ["SPRITE_ERIKA"] = {
      stage = {
        "A calm bloom needs\nno command.",
        "Let each motion\nopen in its time.",
      },
      won = {
        "Talent bloomed\nbeautifully.",
        "A lovely victory.\nWell tended.",
      },
      lost = {
        "Even flowers rest\nbetween blooms.",
        "Give your skill\nlight and time.",
      },
    },
    ["SPRITE_JANINE"] = {
      stage = {
        "You may not see\nour appeal coming.",
        "A soft step hides\na sharp finish.",
      },
      won = {
        "You read every\nfeint correctly.",
        "A clean victory.\nImpressive.",
      },
      lost = {
        "Your guard slipped\nTrain your focus.",
        "Next time, watch\nthe quiet moments.",
      },
    },
    ["SPRITE_SABRINA"] = {
      stage = {
        "The crowd may turn\nI have seen it.",
        "No words needed.\nWatch.",
      },
      won = {
        "You changed the\noutcome I foresaw.",
        "Your will is clear\nYou deserved it.",
      },
      lost = {
        "This result was\nonly one future.",
        "Focus. Return.\fThe path remains.",
      },
    },
    ["SPRITE_BLAINE"] = {
      stage = {
        "Quiz time!\fWhat wins a crowd?",
        "Answer quickly!\nOur turn is hot!",
      },
      won = {
        "Correct!\fYour answer\nwas style!",
        "You solved every\nturn. Well done!",
      },
      lost = {
        "Wrong answer?\fStudy and retry!",
        "Next question may\nfit you better.",
      },
    },
    ["SPRITE_BLUE"] = {
      stage = {
        "Smell that?\fThe crowd\nis ready.",
        "Try not to slow\nmy entrance down.",
      },
      won = {
        "You beat the best.\nEnjoy the feeling.",
        "Not bad at all.\fFor you.",
      },
      lost = {
        "You need more than\none clever move.",
        "Come back when you\ncan own the room.",
      },
    },
    ["SPRITE_WILL"] = {
      stage = {
        "The stage awaits\na grand illusion.",
        "I shall reveal\nperfect control.",
      },
      won = {
        "You broke a veil.\nMagnificent.",
        "A stunning result.\nTake your bow.",
      },
      lost = {
        "The vision dimmed.\nIt can return.",
        "Refine your will.\nCrowd will bend.",
      },
    },
    ["SPRITE_KOGA"] = {
      stage = {
        "Silence. Observe.\nThen strike.",
        "A hidden rhythm\nguides the appeal.",
      },
      won = {
        "You saw the gap.\nWell done.",
        "Clean. Decisive.\nThe win is yours.",
      },
      lost = {
        "Your focus broke.\nRestore it.",
        "Failure is smoke.\nPass through it.",
      },
    },
    ["SPRITE_BRUNO"] = {
      stage = {
        "Strength begins\nwith discipline.",
        "Body and spirit\nmove as one.",
      },
      won = {
        "Your resolve was\ngreater today.",
        "A true victory.\nYou earned it.",
      },
      lost = {
        "Accept the result.\nTrain again.",
        "A stronger heart\nwill rise from it.",
      },
    },
    ["SPRITE_KAREN"] = {
      stage = {
        "Strong or weak?\nNot the point.",
        "Show your love\nfor your partner.",
      },
      won = {
        "You won your way.\nThat matters most.",
        "Your chosen style\ncarried the day.",
      },
      lost = {
        "A score tells not\nthe whole story.",
        "Use favorites.\fWin your own way.",
      },
    },
    ["SPRITE_LANCE"] = {
      stage = {
        "A proud bond needs\na worthy stage.",
        "Let every heart\nanswer courage.",
      },
      won = {
        "Your spirit rose\nabove the field.",
        "A noble victory.\nGuard it well.",
      },
      lost = {
        "Stand again.\fCourage survives.",
        "Train with purpose\nReturn with pride.",
      },
    },
  },
  classes = {
    YOUNGSTER = {
      queue = {
        "The world feels\nbigger from here.",
        "I know the score.\nI think.",
      },
      stage = {
        "No adults needed.\nI can handle this.",
        "This is my turn\nto be the hero.",
      },
    },
    BUG_CATCHER = {
      queue = {
        "We met in\nthe tall grass.",
        "We found a bond.\nThat was enough.",
      },
      stage = {
        "Small wings can\nfill a whole room.",
        "Stay very still.\fNow watch this.",
      },
    },
    LASS = {
      queue = {
        "Delivery made.\fNow for my turn.",
        "Home wished me\ngood luck.",
      },
      stage = {
        "A clean entrance\nis half the trick.",
        "Smile for them.\nThen surprise all.",
      },
    },
    TWIN = {
      queue = {
        "We practised this\nunder the trees.",
        "Same sky today.\nDifferent routine.",
      },
      stage = {
        "One step together.\nOne step apart.",
        "Two ideas made\none good appeal.",
      },
    },
    TEACHER = {
      queue = {
        "Begin at the top.\nKeep proper time.",
        "Every good appeal\nhas a lesson.",
      },
      stage = {
        "Posture, please.\fYes, even now.",
        "Let the rhythm\ncarry the class.",
      },
    },
    SUPER_NERD = {
      queue = {
        "No loose ends.\nAlmost.",
        "I ran the numbers.\nMost look safe.",
      },
      stage = {
        "Observe the order.\nIt is deliberate.",
        "Chaos is merely\nbad accounting.",
      },
    },
    SCIENTIST = {
      queue = {
        "The result should\nbe revealing.",
        "I have a theory\nabout the crowd.",
      },
      stage = {
        "Data starts now.\nReact freely.",
        "A strong response!\nMost informative.",
      },
    },
    PHARMACIST = {
      queue = {
        "Careful blends\nraise condition.",
        "Calm and exact.\nThat is my method.",
      },
      stage = {
        "The balance is\njust about right.",
        "No rush now.\nMeasure timing.",
      },
    },
    OFFICER = {
      queue = {
        "Keep the aisle\nclear, please.",
        "I have seen\nstranger plans.",
      },
      stage = {
        "All eyes forward.\nProceed in order.",
        "This appeal is\nunder control.",
      },
    },
    BLACK_BELT = {
      queue = {
        "Discipline first.\nApplause follows.",
        "No mask can hide\npoor form.",
      },
      stage = {
        "A steady stance.\nA sudden finish.",
        "Strength obeys\nperfect timing.",
      },
    },
    BIKER = {
      queue = {
        "My wheels are out.\nMy grit is not.",
        "Mark me down?\fNot a chance.",
      },
      stage = {
        "The floor can be\nour open road.",
        "No brakes now.\fLet it roll!",
      },
    },
    ROCKET = {
      queue = {
        "A grand contest\nneeds ambition.",
        "Keep your eyes\non your own score.",
      },
      stage = {
        "My offer may win\nthe crowd.",
        "Respect the plan.\fIt has family.",
      },
    },
    ROCKET_GIRL = {
      queue = {
        "I came to win.\nThat is the story.",
        "Smile sweetly.\fPlan sharply.",
      },
      stage = {
        "Soft step first.\nThen the sting.",
        "Pretty can still\nbe dangerous.",
      },
    },
    COOLTRAINER_M = {
      queue = {
        "The stage is a\ncareful operation.",
        "No ghost here.\nOnly skill.",
      },
      stage = {
        "Read the field.\nMove with purpose.",
        "My final form\nstarts right now.",
      },
    },
    COOLTRAINER_F = {
      queue = {
        "Read the pattern.\nThen break it.",
        "My aim is clear.\nMy style is mine.",
      },
      stage = {
        "No wasted motion.\nNo borrowed pose.",
        "I chose this line.\nNow I own it.",
      },
    },
    SAILOR = {
      queue = {
        "Crowd like a sea.\nI know the tide.",
        "A long voyage ends\nat one good stage.",
      },
      stage = {
        "Hold the course!\nTide is rising.",
        "Wind at our backs.\nAppeal ahead!",
      },
    },
    FISHER = {
      queue = {
        "Patience catches\nthe finest moment.",
        "The water is calm.\nA bite will come.",
      },
      stage = {
        "Wait for the pull.\fNow set the hook!",
        "A small ripple\ncan turn the tide.",
      },
    },
    ROCKER = {
      queue = {
        "Give me a beat. I\nwill give a show.",
        "The rain can wait.\nOur song cannot.",
      },
      stage = {
        "Hit the high note!\nMove the crowd!",
        "One clean rhythm.\nNo second take.",
      },
    },
    BEAUTY = {
      queue = {
        "A little sparkle\ngoes a long way.",
        "The camera loves\na clean entrance.",
      },
      stage = {
        "Every eye is ours.\nDo not waste it.",
        "Glow first.\fLet words follow.",
      },
    },
    POKEFAN_M = {
      queue = {
        "I studied every\nnumber twice.",
        "Value is where\nothers miss it.",
      },
      stage = {
        "Smart choices win\nthe long game.",
        "Trust the record.\fThen trust heart.",
      },
    },
    POKEFAN_F = {
      queue = {
        "I know my cue.\nI know my partner.",
        "Family came to\nsee us perform.",
      },
      stage = {
        "Step into light.\nThe song is ours.",
        "We stay together.\nThat is our charm.",
      },
    },
    GENTLEMAN = {
      queue = {
        "A measured bow\nsets the tone.",
        "Every detail has\nits proper place.",
      },
      stage = {
        "Composure, please.\nWe have arrived.",
        "A mystery solved\nwith simple grace.",
      },
    },
    GRAMPS = {
      queue = {
        "The old ways still\ndraw applause.",
        "I know every face\nin this room.",
      },
      stage = {
        "Listen closely.\nAge knows timing.",
        "Family pride needs\ngood form.",
      },
    },
    GRANNY = {
      queue = {
        "A warm meal and\na firm lesson.",
        "Even the proud\nmust learn.",
      },
      stage = {
        "I have two faces.\nBoth expect grace.",
        "Stand tall, dear.\fThe room is yours.",
      },
    },
    SAGE = {
      queue = {
        "Stillness can make\na strong appeal.",
        "The answer arrives\nwhen noise fades.",
      },
      stage = {
        "One quiet move.\nMany thoughts.",
        "Desire less.\fPerform better.",
      },
    },
    ELDER = {
      queue = {
        "Listen to the room\nbefore moving.",
        "Old bones know\ngood timing.",
      },
      stage = {
        "The circle turns.\nWe stand firm.",
        "Young ones roar.\nWe will endure.",
      },
    },
    KIMONO_GIRL = {
      queue = {
        "Grace is fierce\nwhen it must be.",
        "A quiet step can\nhold every eye.",
      },
      stage = {
        "Silk over steel.\nBeauty over fear.",
        "The room is still.\nNow we begin.",
      },
    },
    CLERK = {
      queue = {
        "Everything is\nin its place.",
        "A clean display\nhelps the work.",
      },
      stage = {
        "No clutter today.\nOnly the appeal.",
        "Polish the moment.\nLeave no trace.",
      },
    },
    GYM_GUIDE = {
      queue = {
        "Here is the plan.\nMake turns count.",
        "I can explain\nthe whole contest.",
      },
      stage = {
        "Watch the meter!\nThis is the time!",
        "Good form so far.\nNow finish strong.",
      },
    },
  },
  pools = {
    queue = {
      "My POKeMON is\nready. Am I?",
      "I drew a late\nplace in line.",
      "Good luck!\fYou may need it.",
      "The waiting is\nworse than stage.",
      "One deep breath.\nThen another.",
      "I packed snacks.\nToo many snacks.",
      "That crowd sounds\nready for us.",
      "Do combos count\nif I forget them?",
      "My hands are calm.\nMostly.",
      "After you. No,\nafter me.",
    },
    stage = {
      "The JUDGE is here.\nStand straight.",
      "Hear that crowd?\fThey came for us.",
      "Five turns.\nMake them matter.",
      "My first appeal\nsets the tone.",
      "The lights make\nmy knees wobble.",
      "Condition first.\nThen confidence.",
      "Watch the meter.\nIt loves drama.",
      "I know my combo.\fI hope.",
      "This floor feels\nvery far away.",
      "Ready, partner?\nShow them.",
    },
    won = {
      "You read the crowd\nbetter than I did.",
      "That final appeal\nsettled it.",
      "I had a plan.\fYours was better.",
      "Your POKeMON shone\nso brightly.",
      "I will remember\nthat combo.",
      "No excuses.\nExcellent work.",
      "My score was good.\nYours was better.",
      "The JUDGE saw it.\nSo did I.",
      "That was your day.\nEnjoy it!",
      "Back to practice.\nCongratulations!",
    },
    lost = {
      "You nearly had it.\nKeep going.",
      "The crowd turned.\nYou stayed calm.",
      "Today was rough.\nTomorrow is open.",
      "Your next combo\nwill land.",
      "More SHEEN may tip\nthe score.",
      "Do not stop now.\fYou belong here.",
      "JUDGE was stern.\nYou will adjust.",
      "One weak appeal\ncan be repaired.",
      "Your POKeMON has\nreal stage charm.",
      "We both learned\fsomething today.",
    },
    crowd = {
      "Packed hall today!\nI saved this seat.",
      "That POKeMON has\nwonderful SHEEN.",
      "Did you see that?\fWhat an appeal!",
      "I traded my shift\nto watch this.",
      "The JUDGE frowned.\nThe crowd did not.",
      "My kid wants to\nenter someday.",
      "I came for snacks.\fI stayed for this.",
      "A combo can wake\nthe whole room.",
      "Quiet now.\nNext turn starts.",
      "I like your style!\fKeep it going!",
    },
  },
}
