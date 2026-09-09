-- Run from engine: luajit /path/to/mod/tests/gen_gate_test.lua /path/to/mod
package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit')
local GV=require('src.core.GameVersion')
require('src.core.Version').engine='0.2.24'
local path=assert(arg[1]):gsub('\\','/')
local root,folder=path:match('^(.*)/([^/]+)$')
for _,version in ipairs({'red','yellow'}) do
  GV.current=version
  local r=T.sdk.loadMod(folder,{root=root,generation=1})
  T.eq(r.mod and r.mod.state,'loaded',version..' loads')
  local errors=0
  for _,e in ipairs(r.errors) do
    local s=tostring(type(e)=='table' and (e.message or e.code) or e)
    if not s:find('unresolved reference to trainers "OPP_GENTLEMAN"',1,true)
      and not s:find('unresolved reference to pokemon "CHANSEY"',1,true) then
      errors=errors+1; print(s)
    end
  end
  T.eq(errors,0,version..' has no unexpected errors')
  local ex=r.loader.exports.kanto_contests
  T.check(ex~=nil,version..' registered its exports')
  T.check(not (ex and ex.duskChallenge),version..' keeps Gen 2 extension gated')
  r.release()
end
T.finish('Gen 1 loading; Gen 2 checked with release_behavior_test')
