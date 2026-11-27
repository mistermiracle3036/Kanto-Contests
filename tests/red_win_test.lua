-- Red: a routine that ends 1st on points is a WIN (developer via the Desk,
-- 2026-11-27, REQUESTS 1218). It must take the emptied-meter path -- hp 0,
-- BattleState:onFaint, which ends the battle as "win", so the vanilla prize
-- and onFinish's contestWins follow -- and anything below 1st must stay the
-- clean "run" loss with no prize.
-- Run from engine: luajit /path/to/mod/tests/red_win_test.lua /path/to/mod
package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit')
require('src.core.GameVersion').current='red'
require('src.core.Version').engine='0.4.0'
local path=assert(arg[1]):gsub('\\','/')
local root,folder=path:match('^(.*)/([^/]+)$')
local r=T.sdk.loadMod(folder,{root=root,generation=1})
T.eq(r.mod and r.mod.state,'loaded','red loads')
local BS=require('src.battle.BattleState')

-- A stand-in battle: only what kcAppeal touches on the last round.
local function battle(playerScore, rivalScores)
  local b={ contest='COOL', queue={}, said={}, fainted=nil,
    kcRound=4, kcPlayerScore=playerScore, kcHearts=0,
    kcRivalScore=rivalScores, kcRivalHearts={0,0,0},
    rng=function(lo,hi) return hi and lo or 1 end }
  function b:moveDef() return { id='TACKLE', name='TACKLE' } end
  function b:romText(_, fmt, ...) return fmt:format(...) end
  function b:sayNextAuto(t) self.said[#self.said+1]=t end
  function b:sayNext(t) self.said[#self.said+1]=t end
  function b:applyDamage(t, d) t.mon.hp=math.max(0,t.mon.hp-d) end
  function b:onFaint(t) self.fainted=t; self.result='win' end
  local user={ isPlayer=true, name='PIKACHU', mon={} }
  local target={ mon={ hp=999, stats={hp=999} } }
  return b, user, target
end
local function said(b, text)
  for _, t in ipairs(b.said) do if t:find(text,1,true) then return true end end
  return false
end

do -- leads every rival on points: a win, by the meter's own path
  local b,user,target=battle(500,{10,10,10})
  BS.performMove(b,user,target,{ id='TACKLE', pp=10 })
  T.eq(b.fainted,target,'1st on points calls onFaint (the win path)')
  T.eq(target.mon.hp,0,'the meter is emptied, as on a filled-meter win')
  T.eq(b.result,'win','the battle ends as a win, so prize and contestWins follow')
  T.check(said(b,'You place 1st'),'"You place 1st of 4!" is still read')
  T.check(not said(b,'shakes'),'no "The judge shakes his head." on a win')
end

do -- behind a rival: unchanged, the clean loss
  local b,user,target=battle(0,{500,0,0})   -- one rival ahead: 2nd
  BS.performMove(b,user,target,{ id='TACKLE', pp=10 })
  T.eq(b.fainted,nil,'2nd does not call onFaint')
  T.eq(b.result,'run','2nd ends as run: no prize')
  T.check(said(b,'shakes'),'the judge still shakes his head on a loss')
  T.check(said(b,'You place 2nd'),'and reads the placing')
end
T.finish('Red 1st on points')
