-- Run from the engine checkout:
--   luajit ../Kanto-Contests/tests/scope_test.lua
--
-- Lua resolves a name that has no local in scope as a GLOBAL, so calling
-- a `local function` before its definition is not a syntax error and not
-- a load error -- it is a nil call at run time, inside whatever pcall
-- happens to be wrapping it.
--
-- This has now bitten this mod three times:
--   lookerCall   inserted above the LINES it referenced
--   monLabel     used by the stage intro, defined 400 lines below it --
--                the step threw, runSteps caught it and ABORTED the rest
--                of the sequence, so the player's presentation and the
--                contest start silently never happened
--   restoreParty called from map.entered, defined below it, so the
--                pcall around it swallowed a nil call and the player's
--                party was never given back
--
-- None of compile, gen_gate, gold_contest or the dialogue lint can see
-- it. This can: every `local function` in the file must be defined
-- before the first line that calls it.
local path = "../Kanto-Contests/main.lua"
local src = assert(io.open(path)):read("*a")

-- strip comments and strings so a name inside either does not count as a call
local code = src:gsub("%-%-%[%[.-%]%]", " "):gsub("%-%-[^\n]*", "")
                :gsub('"[^"\n]*"', '""'):gsub("'[^'\n]*'", "''")

local defAt, order = {}, {}
for pos, name in code:gmatch("()local function ([%w_]+)") do
  if not defAt[name] then defAt[name] = pos order[#order + 1] = name end
end
-- forward declarations are the sanctioned fix; a name declared with a bare
-- `local X` before use is fine however far below the assignment sits
local fwd = {}
for name in code:gmatch("local ([%w_]+)%s*\n") do fwd[name] = true end
for name in code:gmatch("local ([%w_]+)%s*=%s*nil") do fwd[name] = true end

local bad = 0
for _, name in ipairs(order) do
  if not fwd[name] then
    local d = defAt[name]
    for pos in code:gmatch("()" .. name .. "%s*%(") do
      if pos < d then
        bad = bad + 1
        local line = select(2, code:sub(1, pos):gsub("\n", "")) + 1
        print(("  FAIL %s() called at line ~%d but defined at ~%d")
          :format(name, line, select(2, code:sub(1, d):gsub("\n", "")) + 1))
        break
      end
    end
  end
end
print(("checked %d local functions"):format(#order))
if bad > 0 then
  print(("%d used before definition -- each is a nil call at run time"):format(bad))
  os.exit(1)
end
print("SCOPE OK: every local function is defined before it is called")
