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
--   pendingContest  a bare `local X` VARIABLE, declared below the function
--                that reads it. This test PASSED anyway: it treated any
--                bare `local X` as a sanctioned forward declaration
--                without checking where it sat. The reads resolved to a
--                nil global, so the MC announced "NORMAL CONTEST CONTEST"
--                instead of the category and the judging step read nil
--                and returned -- no battle. One bug, both symptoms.
--   restoreParty called from map.entered, defined below it, so the
--                pcall around it swallowed a nil call and the player's
--                party was never given back
--
-- None of compile, gen_gate, gold_contest or the dialogue lint can see
-- it. This can: every `local function` in the file must be defined
-- before the first line that calls it.
local path = arg and arg[1] or "../Kanto-Contests/main.lua"
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
-- Same failure one rung down: a bare `local X` is only a forward
-- declaration if it sits ABOVE the code that reads it. Below, every read
-- is a nil global -- and unlike a nil CALL that does not even throw, so
-- there is no pcall message and nothing in the log. It just reads nil.
--
-- Only MODULE-LEVEL declarations are checked (indent exactly two, the
-- top level of this file), and only names declared once. A first pass
-- compared positions file-wide and flagged three names that were all
-- fine: `pool` and `dir` are function PARAMETERS and `dmg` is declared
-- in four separate function bodies. Lua scopes per block; a file-wide
-- position comparison does not, so it has to be narrowed to the one
-- scope where position IS the whole story.
local declAt, seen, vars = {}, {}, {}
for name in code:gmatch("local ([%w_]+)") do seen[name] = (seen[name] or 0) + 1 end
for pos, name in code:gmatch("()\n  local ([%w_]+)%s*\n") do
  if not declAt[name] and not defAt[name] and seen[name] == 1 then
    declAt[name] = pos; vars[#vars + 1] = name
  end
end

for _, name in ipairs(vars) do
  local d = declAt[name]
  for pos in code:gmatch("()[^%w_.:]" .. name .. "[^%w_]") do
    local stmt = code:sub(math.max(1, pos - 6), pos + #name)
    if pos < d and not stmt:match("local%s+" .. name .. "$") then
      bad = bad + 1
      local line = select(2, code:sub(1, pos):gsub("\n", "")) + 1
      print(("  FAIL %s read at line ~%d but declared at ~%d -- reads nil")
        :format(name, line, select(2, code:sub(1, d):gsub("\n", "")) + 1))
      break
    end
  end
end

print(("checked %d local functions and %d module-level declarations")
  :format(#order, #vars))
if bad > 0 then
  print(("%d used before it exists -- each reads nil at run time"):format(bad))
  os.exit(1)
end
print("SCOPE OK: every local function and variable is declared before use")
