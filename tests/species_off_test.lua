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
function w:turnObject() end
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

local dusk=x.duskChallenge
T.check(not data.pokemon.KC_HONCHKROW and not data.pokemon.KC_MISMAGIUS,'off registers no bundled species')
T.check(not data.gen2Pokedex.entries.KC_HONCHKROW,'off adds no dex entries')
for _,row in ipairs(data.pokemon.MURKROW.evolutions or {}) do
  T.check(row.item~=dusk.item,'off adds no evolution patch')
end
local Items=require('src.core.gen2.ItemEffects')
T.check(not Items.useOnMon(dusk.item,{species='MISDREAVUS'},data).used,'off without another provider safely refuses stone')
local other={name='MISMAGIUS',id='OTHER_MISMAGIUS'}
data.pokemon.OTHER_MISMAGIUS=other
local result=Items.useOnMon(dusk.item,{species='MISDREAVUS'},data)
T.check(result.used,'off can use compatible external species')
T.eq(result.evolution.into,'OTHER_MISMAGIUS','external target selected without dependency')
T.check(data.pokemon.OTHER_MISMAGIUS==other,'foreign definition preserved')
data.pokemon.AMBIGUOUS_MISMAGIUS={name='MISMAGIUS'}
T.check(not Items.useOnMon(dusk.item,{species='MISDREAVUS'},data).used,'ambiguous external species fail without consuming stone')
T.check(dusk.needed('MASTER'),'species-off retains Fantina challenge')
T.eq(#r.errors,0,'off loads without errors')
r.release();T.finish('bundled species off')
