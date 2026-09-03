-- Kanto Contests -- what the cast says when spoken to.
--
-- DATA ONLY. Loaded by main.lua the way contest_engine.lua is (mod:read +
-- load); returns one table. Lines are picked by main.lua's lineFor(): the
-- most specific pool that has lines wins --
--   characters[<sprite id>][<context>]  ->  classes[<class>][<context>]
--   ->  pools[<context>]
-- and within a pool the pick is stable per actor per contest (the same
-- person keeps saying the same thing), so every pool wants VARIETY: aim
-- for 6-12 lines per generic context and 2-4 per character context.
--
-- Contexts:
--   queue  a coordinator in the lobby line, before the contest
--   stage  a coordinator standing in the stage line-up
--   won    a coordinator spoken to after the judging when the PLAYER won
--   lost   ...when the player did not win
--   crowd  anyone in the seats
--
-- Every page is at most 2 lines of 18 glyphs; "\n" starts the second line;
-- "\f" starts a new page. tests/check_dialogue.py lints this file. No
-- apostrophes or quotation marks (the font has neither); . , ! ? - only.
--
-- This file is written by a design order (exchange/work-orders/
-- kanto_contests-cast-dialogue.md); the pools below are the 0.34.x
-- placeholders it replaces. Character voices: briefs/CONTEST_CLASS_NAMES.md
-- says what every named class coordinator is a reference to.
return {
  characters = {
    -- ["SPRITE_KC_MAY"] = { queue = { ... }, stage = { ... }, won = { ... }, lost = { ... }, crowd = { ... } },
  },
  classes = {
    -- LASS = { queue = { ... } },   -- keyed by the class (the sprite id without SPRITE_)
  },
  pools = {
    queue = {
      "My POKeMON has\nbeen practising.",
      "I have waited all\nweek for this.",
      "Good luck out\nthere!",
      "Do not smile too\nmuch. It shows.",
      "I am next. I\nthink. Maybe.",
    },
    stage = {
      "My POKeMON has\nbeen practising.",
      "Good luck out\nthere!",
      "Do not smile too\nmuch. It shows.",
    },
    won = {
      "You earned that.\nWell done.",
      "Next time. I mean\nit.",
    },
    lost = {
      "Better luck next\ntime!",
      "Practice makes\nperfect, they say.",
    },
    crowd = {
      "The hall is packed\ntoday!",
      "I came for the\nSHEEN, honestly.",
      "That last appeal\nwas something.",
      "Shh! It is\nstarting!",
      "I have a good\nfeeling about you.",
      "Go on! Dazzle\nus, newcomer!",
    },
  },
}
