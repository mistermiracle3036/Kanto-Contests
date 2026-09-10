-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/sequence_test.lua
--
-- The stage intro is a chain: each step gets `next_` and the chain only
-- advances when it is called. A step that forgets stalls the whole
-- sequence -- the player stands on the stage forever and the contest
-- never starts -- and nothing errors, so no other check here sees it.
--
-- That is not hypothetical: the sequence really did stop dead partway
-- through, and the symptom the developer reported was "the battle
-- doesn't start", four steps downstream of the actual fault.
local src = assert(io.open("../Kanto-Contests/main.lua")):read("*a")
local fails = 0
local function check(ok, what)
  if ok then print("  ok  " .. what) else fails = fails + 1 print("  FAIL " .. what) end
end

local intro = src:match("local function runStageIntro%(world%).-\n    runSteps%(steps%)")
check(intro ~= nil, "runStageIntro found")

-- every `function(next_)` in the chain has to hand next_ on somewhere:
-- called outright, or given to showText / beginMovement / waitFrames.
local n, stalled = 0, 0
for body in intro:gmatch("function%(next_%)(.-)\n    end") do
  n = n + 1
  if not (body:find("next_", 1, true)) then
    stalled = stalled + 1
    print(("  FAIL step %d never passes next_ on -- the chain stops here"):format(n))
  end
end
check(n > 0, ("found %d chained steps"):format(n))
check(stalled == 0, "every chained step hands next_ on")

-- the chain must END by starting the contest, not by waiting for the
-- player to go and talk to the judge
local tail = intro:match("steps%[#steps %+ 1%] = function%(%)(.-)\n    end")
check(tail ~= nil, "the chain has a final step that takes no next_")
check(tail and tail:find("runGoldContest", 1, true) ~= nil,
  "the last step starts the contest itself")
check(src:find("local runGoldContest", 1, true) ~= nil,
  "runGoldContest is forward-declared (it is defined below the intro)")

-- appealSteps builds a chain too, and that is where it actually broke.
local NL = string.char(10)
local appeal = src:match("local function appealSteps.-" .. NL .. "  end")
check(appeal ~= nil, "appealSteps found")
local an, astall = 0, 0
for body in (appeal or ""):gmatch("function%(next_%)(.-)" .. NL .. "      end") do
  an = an + 1
  if not body:find("next_", 1, true) then
    astall = astall + 1
    print(("  FAIL appeal step %d never passes next_ on"):format(an))
  end
end
check(an > 0, ("found %d appeal steps"):format(an))
check(astall == 0, "every appeal step hands next_ on")

if fails > 0 then print(("%d FAILED"):format(fails)) os.exit(1) end
print(("SEQUENCE OK: %d steps chain through and the contest auto-starts"):format(n))
