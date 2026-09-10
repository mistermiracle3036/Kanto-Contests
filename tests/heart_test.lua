-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/heart_test.lua
--
-- The appeal hearts shipped broken TWICE and neither compile nor any
-- other test here could see it, because both failures were about
-- lifecycle rather than syntax:
--
--   1. the engine's emote is a single slot, so a loop of showEmote calls
--      draws exactly one bubble;
--   2. our replacement needs its own clock, and the one line that ticks
--      it was lost when an edit threw on a later assertion and never
--      wrote the file. Without the tick, staggered hearts never reach
--      delay 0 -- so ONLY THE FIRST draws, and it never expires. That is
--      precisely what the developer saw: one heart, hanging around while
--      walking the map.
--
-- So this asserts both the wiring and the behaviour.
local src = assert(io.open("../Kanto-Contests/main.lua")):read("*a")
local fails = 0
local function check(ok, what)
  if ok then print("  ok  " .. what)
  else fails = fails + 1 print("  FAIL " .. what) end
end

-- ---- wiring: the clock must be driven from the per-frame hook --------
local upd = src:match('mod%.hooks:wrap%("core%.update".-\n  end%)')
check(upd ~= nil, "core.update wrap exists")
check(upd and upd:find("tickHearts()", 1, true) ~= nil,
  "tickHearts() is CALLED inside the core.update wrap")
check(src:find("local function tickHearts", 1, true) ~= nil,
  "tickHearts is defined")
-- and it must be defined BEFORE the wrap, or it is a nil global there
local defAt = src:find("local function tickHearts", 1, true)
local useAt = src:find('mod%.hooks:wrap%("core%.update"')
check(defAt and useAt and defAt < useAt,
  "tickHearts is an upvalue of the wrap, not a nil global")
-- the single-slot engine call must NOT come back
check(src:find("world:showEmote(", 1, true) == nil
      and src:find("pcall(world.showEmote", 1, true) == nil,
  "no direct showEmote calls (single slot draws one bubble only)")

-- ---- behaviour: replay the model the mod uses -----------------------
-- popHearts stages delay = (i-1)*6 and left = 50; tickHearts counts the
-- delay down first, then the lifetime, dropping expired entries.
local function pop(n)
  local t = {}
  for i = 1, n do t[i] = { delay = (i - 1) * 6, left = 50 } end
  return t
end
local function tick(hs)
  local keep = {}
  for _, h in ipairs(hs) do
    if h.delay > 0 then h.delay = h.delay - 1 keep[#keep + 1] = h
    else h.left = h.left - 1 if h.left > 0 then keep[#keep + 1] = h end end
  end
  return keep
end
local function visible(hs)
  local n = 0
  for _, h in ipairs(hs) do if h.delay <= 0 then n = n + 1 end end
  return n
end

for _, n in ipairs({ 2, 4, 6 }) do
  local hs, seenMax, everAll = pop(n), 0, false
  for _ = 1, 400 do
    hs = tick(hs)
    local v = visible(hs)
    if v > seenMax then seenMax = v end
    if v == n then everAll = true end
  end
  check(everAll, ("%d hearts: all %d are on screen together at some point")
    :format(n, n))
  check(#hs == 0, ("%d hearts: every one expires"):format(n))
end

-- the failure mode itself: no tick means one heart, forever
do
  local hs = pop(4)
  check(visible(hs) == 1, "untickled: only the first heart is visible")
  check(#hs == 4, "untickled: nothing ever expires (the shipped bug)")
end

if fails > 0 then print(("%d FAILED"):format(fails)) os.exit(1) end
print("APPEAL HEARTS OK: staggered, all shown, all expire")
