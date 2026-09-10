package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit')
require('src.core.Version').engine='0.2.24'
require('src.core.GameVersion').current=arg[3] or 'crystal'
local modDir=assert(arg[1]):gsub('\\','/')
local root,folder=modDir:match('^(.*)/([^/]+)$')
assert(root and folder,'pass absolute mod directory')
local cache=assert(arg[2])
local data=T.fixtures.fresh()
data.pokemon=assert(loadfile(cache..'/pokemon.lua'))()
data.moves=assert(loadfile(cache..'/moves.lua'))()
data.gen2Trainers=assert(loadfile(cache..'/trainers.lua'))()
data.gen2Tilesets=assert(loadfile(cache..'/tilesets.lua'))()
data.gen2Maps=assert(loadfile(cache..'/maps.lua'))()
data.gen2Scripts=assert(loadfile(cache..'/scripts.lua'))()
data.audio=assert(loadfile(cache..'/audio.lua'))()
data.type_chart=assert(loadfile(cache..'/type_chart.lua'))()
data.gen2Pokedex=assert(loadfile(cache..'/pokedex.lua'))()
data.gen2Icons=assert(loadfile(cache..'/icons.lua'))()
data.gen2Palettes=assert(loadfile(cache..'/palettes.lua'))()
local SaveData=require('src.core.SaveData')
local originalOptions=SaveData.loadOptions
if arg[4]=='off' then
  SaveData.loadOptions=function(...)
    local o=originalOptions(...)
    o.modOptions=o.modOptions or {};o.modOptions.kanto_contests={expanded_species=false}
    return o
  end
end
local r=T.sdk.loadMods({folder},{generation=2,root=root,data=data})
SaveData.loadOptions=originalOptions
for id,m in pairs(r.mods) do print(id,m.state); T.eq(m.state,'loaded',id..' loads') end
for _,err in ipairs(r.errors or {}) do print('ERROR',type(err)=='table' and (err.message or err.code or tostring(err)) or err) end
T.check(#(r.errors or {})==0,'all dependencies load without errors')
local x=r.loader.exports.kanto_contests
T.eq(x and x.questHooks,2,'updated quest hook version')
T.check(type(x and x.bestRank)=='function','best-rank export')

local game={data=r.data,save={party={},boxes={},inventory={},player={badges={},money=5000},flags={}},
  stack={items={}},options={}}
function game.stack:push(x) self.items[#self.items+1]=x end
function game.stack:pop() return table.remove(self.items) end
function game.stack:top() return self.items[#self.items] end
local w={game=game,npcs={},player={cellX=4,cellY=7},maps=data.gen2Maps,sprites={}}
local dialoguePages=0
function w:busy() return false end
function w:showText(text,done)
  self.lastText=text
  for page in (text..'\f'):gmatch('(.-)\f') do
    dialoguePages=dialoguePages+1
    local n=0
    for line in (page..'\n'):gmatch('(.-)\n') do
      n=n+1; assert(#line<=18,'overlong dialogue: '..line)
    end
    assert(n<=2,'too many dialogue rows')
  end
  if done then self.pendingText=done end
end
function w:npcAt(x,y)
  for _,n in ipairs(self.npcs) do if n.cellX==x and n.cellY==y then return n end end
end
function w:rebuildPeople()
  self.npcs={}
  for _,obj in ipairs(self.map.def.objects or {}) do
    self.npcs[#self.npcs+1]={def=obj,cellX=obj.x,cellY=obj.y}
  end
end
w.addRuntimeObject=require('src.world.gen2.World').addRuntimeObject
w.removeRuntimeObject=require('src.world.gen2.World').removeRuntimeObject
function w:cancelMapNameSign() end
game.world=w
r.loader.game=game
require('src.mods.Runtime').emit('game.ready',{game=game})
local Runtime=require('src.mods.Runtime')
local OW=require('src.world.OverworldController')
local Map=require('src.world.gen2.Map')

local textLog={}
function w:showText(text,done)
  textLog[#textLog+1]=text
  self.pendingText=done
  if text:find('A little gift',1,true) then
    local partner
    for _,npc in ipairs(self.npcs) do if npc.def.kcFantinaReward then partner=npc;break end end
    T.check(partner~=nil,'Fantina present when gift conversation opens')
    if partner then
      local dx,dy=partner.cellX-self.player.cellX,partner.cellY-self.player.cellY
      local expected=dx>0 and 'right' or dx<0 and 'left' or dy>0 and 'down' or 'up'
      T.eq(self.player.facing,expected,'player faces Fantina before gift dialogue')
    end
  end
end
function w:warpToMapId(id,x,y,facing)
  local def=assert(data.gen2Maps[id])
  self.map=Map.new(def,data.gen2Tilesets[def.tileset])
  self.player.cellX,self.player.cellY,self.player.facing=x,y,facing
  self:rebuildPeople()
  Runtime.emit('map.entered',{mapId=id})
  return true
end
local selectedCategory=1
function w:openScriptMenu(header,style,done) self.categoryMenu=header; done(selectedCategory) end
local selectedSlot=1
function w:selectPartyMon(prompt,done) done(selectedSlot,game.save.party[selectedSlot]) end
function w:beginMovement(id,path,done) if done then done() end end
function w:turnObject(id,facing)
  if id==0 then self.player.facing=facing end
end
function w:showPokePic() end
function w:playCry() end
function w:playMapMusic() end
function w:pushBattleTransition(a,b,done) done(); return true end
local function tick()
  if w.pendingText then local done=w.pendingText; w.pendingText=nil; done() end
  Runtime.call('core.update',function() end,game,1/60)
end
local function until_(pred,label)
  for i=1,2500 do if pred() then return true end; tick() end
  T.check(false,label..' timed out'); return false
end
local Mon=require('src.battle.gen2.Mon')
local Evolution=require('src.core.gen2.Evolution')
local Items=require('src.core.gen2.ItemEffects')
local Serializer=require('src.core.SaveSerializer')
local dusk=x.duskChallenge
T.check(dusk~=nil,'standalone Dusk challenge loads')
T.eq(dusk.sprite,'SPRITE_KC_FANTINA','Fantina uses her commissioned sprite')
local fantinaSprite=data.gen2Sprites[dusk.sprite]
T.check(fantinaSprite and fantinaSprite.trueColor,'Fantina retains Indigo source colors')
T.eq(fantinaSprite.paletteId,4,'Fantina uses Indigo fallback palette')
T.check(data.pokemon.KC_HONCHKROW and data.pokemon.KC_MISMAGIUS,'both evolutions registered')
T.check(data.gen2Pokedex.entries.KC_MISMAGIUS~=nil,'custom dex entry installed')
T.check(data.gen2Icons.species.KC_HONCHKROW~=nil,'custom party icon installed')
T.same(data.gen2Palettes.pokemon.KC_MISMAGIUS.normal,{{230,41,140},{66,49,99}},'Polished Crystal palette installed')
for base,target in pairs({MURKROW='KC_HONCHKROW',MISDREAVUS='KC_MISMAGIUS'}) do
  local mon=Mon.new(data,base,30,{moves={'TACKLE'},nickname='PARTNER'})
  mon.contestWins={COOL=3}; mon.contestRanks={COOL={HYPER=true}}
  mon.contest={cool=100};mon.kcSheen=80;mon.item='BERRY'
  local result=Items.useOnMon(dusk.item,mon,data)
  T.check(result.used,'Dusk Stone accepts '..base)
  T.eq(result.evolution.into,target,'correct evolution target for '..base)
  T.eq(Evolution.checkMon(data,mon,{force=true,item=dusk.item}).into,target,'native stone eligibility')
  local evolved=Evolution.apply(data,mon,result.evolution)
  T.eq(evolved.species,target,'native evolution produces '..target)
  T.eq(evolved.nickname,'PARTNER','nickname retained')
  T.eq(evolved.contestWins.COOL,3,'contest wins survive evolution')
  T.eq(evolved.kcSheen,80,'sheen survives evolution')
  T.eq(evolved.item,'BERRY','held item survives stone evolution')
  local saved=Serializer.decode(Serializer.encode({party={evolved}}))
  T.eq(saved.party[1].species,target,'evolution serializes')
  mon.item='EVERSTONE'
  T.check(not Items.useOnMon(dusk.item,mon,data).used,'Everstone prevents consumption')
end
T.check(not Items.useOnMon(dusk.item,{species='PIKACHU'},data).used,'wrong species does not consume stone')
T.check(not Items.useOnMon(dusk.item,{species='MURKROW',isEgg=true},data).used,'egg does not consume stone')

local function freshParty()
  local party={}
  for i=1,6 do party[i]=Mon.new(data,'MARILL',30,{moves={'TACKLE','WATER_GUN'},nickname='MON'..i}) end
  party[3].contest={cool=100};party[3].kcSheen=100
  game.save.party=party;game.save.kcPartyStash=nil;game.save.kcPartySlot=nil
  game.save.mail={party={[3]={message='MY LETTER'}}}
  return party
end
local function enter(hall,category,slot)
  selectedSlot,selectedCategory=slot or 3,category or 1
  game.stack.items={};w.pendingText=nil;textLog={}
  w:warpToMapId(hall,4,7,'up')
  if hall=='KC_BLACKTHORN_CONTEST_HALL' and dusk.needed('MASTER') then
    local found=false
    for _,npc in ipairs(w.npcs) do
      if npc.def.kcFantina then found=npc.def.sprite=='SPRITE_KC_FANTINA' end
    end
    T.check(found,'MASTER lobby shows commissioned Fantina')
  end
  for _,npc in ipairs(w.npcs) do if npc.def.kcHallJudge then OW.talkTo(w,npc);break end end
end
local halls={
  {'KC_JOHTO_CONTEST_HALL','KC_JOHTO_CONTEST_STAGE','NORMAL'},
  {'KC_ECRUTEAK_CONTEST_HALL','KC_ECRUTEAK_CONTEST_STAGE','SUPER'},
  {'KC_CIANWOOD_CONTEST_HALL','KC_CIANWOOD_CONTEST_STAGE','HYPER'},
  {'KC_BLACKTHORN_CONTEST_HALL','KC_BLACKTHORN_CONTEST_STAGE','MASTER'},
}
local party=freshParty()
local castLines=assert(loadfile(modDir..'/cast_lines.lua'))()
local function checkCastContext(context,label)
  local pendingText=w.pendingText
  local checked=0
  for _,npc in ipairs(w.npcs) do
    local def=npc.def
    if def.kcCoordinator and not def.kcFantina then
      local allowed={}
      local base=tostring(def.sprite):match('^SPRITE_(.+)$')
      for _,source in ipairs({castLines.characters[def.sprite] or {},
          castLines.classes[base] or {},castLines.pools}) do
        for _,line in ipairs(source[context] or {}) do allowed[line]=true end
        if context=='won' or context=='lost' then
          -- Cast classes without result-specific writing use their existing fallback.
          for _,line in ipairs(source.stage or {}) do allowed[line]=true end
          for _,line in ipairs(source.queue or {}) do allowed[line]=true end
        end
      end
      OW.talkTo(w,npc)
      T.check(allowed[textLog[#textLog]],label..': '..def.name..' uses '..context..' dialogue')
      checked=checked+1
    end
  end
  T.check(checked>0,label..' checked actual coordinators')
  w.pendingText=pendingText
end
for _,h in ipairs(halls) do
  enter(h[1])
  until_(function() local top=game.stack:top();return top and top.E end,'judging '..h[3])
  local screen=game.stack:top()
  T.eq(screen.rank,h[3],'hall selects '..h[3])
  T.eq(screen.s.c[1].mon.nickname,'MON3','selected third party member performs')
  if h[3]=='MASTER' then
    T.eq(screen.s.c[4].name,'FANTINA','Fantina guaranteed in first MASTER')
    local found=false
    for _,npc in ipairs(w.npcs) do
      if npc.def.name=='KC_COORD_3' then found=npc.def.sprite=='SPRITE_KC_FANTINA' end
    end
    T.check(found,'MASTER stage shows commissioned Fantina')
    -- A loss is followed by a different category's MASTER attempt.
    screen.onDone(4,{{who=1,total=10}})
    checkCastContext('lost','finished MASTER stage')
    until_(function() return w.map.id==h[1] end,'loss returns to lobby')
    checkCastContext('queue','next MASTER queue after loss')
    T.check(not game.save.kcFantinaChallenge.won,'loss keeps Fantina challenge active')
    party[3].contestWins.BEAUTY=3
    enter(h[1],2)
    until_(function() local top=game.stack:top();return top and top.E end,'retry judging')
    screen=game.stack:top()
    T.eq(screen.s.c[4].name,'FANTINA','Fantina returns after loss across categories')
    T.eq(screen.kind,'BEAUTY','retry uses different category')
  end
  screen.onDone(1,{{who=1,total=200},{who=2,total=100},{who=3,total=80},{who=4,total=60}})
  checkCastContext('won','finished '..h[3]..' stage')
  until_(function() return w.map.id==h[1] end,'result returns to lobby')
  checkCastContext('queue','next '..h[3]..' queue after win')
  T.eq(#game.save.party,6,'full party restored after '..h[3])
  T.eq(game.save.party[3].nickname,'MON3','party order restored')
  T.eq(game.save.mail.party[3].message,'MY LETTER','party mail restored')
end
T.check(game.save.kcFantinaChallenge.won,'first MASTER win recorded once across categories')
until_(function() return game.save.kcFantinaChallenge.given end,'Fantina approach and gift')
T.eq(game.save.inventory[dusk.item],1,'approach grants one stone')
for _=1,12 do tick() end
T.check(not dusk.needed('MASTER'),'later MASTER contests do not force Fantina')
T.check(not dusk.give(game.save,data),'reward cannot be claimed twice')
T.eq(game.save.inventory[dusk.item],1,'one-time reward stays one')

-- Full stack uses the same Bag.add refusal as a full item pocket.
local rewardSave={inventory={[dusk.item]=99}}
dusk.recordWin(rewardSave,'MASTER',true,true,true)
T.check(not dusk.give(rewardSave,data),'full bag retains unclaimed reward')
T.check(rewardSave.kcFantinaChallenge.pending,'full bag reward stays pending')
rewardSave.inventory[dusk.item]=98
T.check(dusk.give(rewardSave,data),'reward can be collected after making space')
r.loader.modOptions.kanto_contests={dusk_stone_reward=false}
local offSave={inventory={}}
dusk.recordWin(offSave,'MASTER',true,true,true)
T.check(offSave.kcFantinaChallenge.won and not dusk.pending(offSave),'reward-off still completes challenge without gift')
r.loader.modOptions.kanto_contests={}

for _,bad in ipairs({'egg','fainted','no_moves'}) do
  party=freshParty()
  if bad=='egg' then party[3].isEgg=true elseif bad=='fainted' then party[3].hp=0 else party[3].moves={} end
  enter(halls[1][1])
  for _=1,8 do tick() end
  T.eq(w.map.id,halls[1][1],bad..' rejected before stage')
  T.eq(#game.save.party,6,bad..' leaves party intact')
  T.check(not game.save.kcPartyStash,bad..' does not stash party')
end

-- Load a real serialized in-contest party, then run save.loading recovery.
party=freshParty();enter(halls[1][1])
until_(function()return game.save.kcPartyStash~=nil end,'party is stashed')
local loaded=Serializer.decode(Serializer.encode(game.save))
loaded.party[1].contestWins={COOL=9}
T.check(loaded.party[1]~=loaded.kcPartyStash[3],'serializer duplicates shared tables')
Runtime.emit('save.loading',{raw=loaded})
T.eq(#loaded.party,6,'reload recovers six Pokemon')
T.eq(loaded.party[3].contestWins.COOL,9,'reload retains live entrant updates')
T.eq(loaded.mail.party[3].message,'MY LETTER','reload restores mail to third slot')
T.check(not loaded.kcPartyStash,'reload clears stash')
w.pendingText=nil;game.save=loaded
w:warpToMapId(halls[1][2],3,3,'down')
until_(function()return w.map.id==halls[1][1]end,'interrupted stage returns to lobby')
T.eq(#game.save.party,6,'cancelled contest stays playable with whole team')

-- Switching bundled definitions off must preserve the exact Pokemon and mail.
local a=Mon.new(data,'KC_HONCHKROW',30,{nickname='CROW'})
local b=Mon.new(data,'KC_MISMAGIUS',30,{nickname='WITCH'})
local guardSave={party={a,b},boxes={},mail={party={[2]={message='SAFE'}}}}
local defA,defB=data.pokemon.KC_HONCHKROW,data.pokemon.KC_MISMAGIUS
data.pokemon.KC_HONCHKROW,data.pokemon.KC_MISMAGIUS=nil,nil
local hidden=dusk.support.protect(guardSave,game)
T.eq(hidden,2,'disabled species are safely stored')
T.eq(#guardSave.party,0,'unavailable species leave active party')
local stored=Serializer.decode(Serializer.encode(guardSave))
data.pokemon.KC_HONCHKROW,data.pokemon.KC_MISMAGIUS=defA,defB
local _,restored=dusk.support.protect(stored,game)
T.eq(restored,2,'reenabled species restored from serialized hidden storage')
T.eq(stored.party[1].nickname,'CROW','original order restored')
T.eq(stored.party[2].nickname,'WITCH','second Pokemon preserved')
T.eq(stored.mail.party[2].message,'SAFE','held mail restored with its Pokemon')
local unexpected=0
for _,err in ipairs(r.errors or {}) do
  if not tostring(err):find('Bundled evolutions are disabled',1,true) then
    unexpected=unexpected+1; print('LOAD_ERROR',err)
  end
end
T.eq(unexpected,0,'no unexpected loader/runtime errors')
r.release()
T.finish('release behavior and Dusk challenge')
