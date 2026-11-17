-- From engine: luajit <this> <review-root> <Crystal generated-data> [auto|on|off|solo]
package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit')
require('src.core.Version').engine='0.4.0'
require('src.core.GameVersion').current='crystal'
local root,cache,mode=assert(arg[1]),assert(arg[2]),arg[3] or 'auto'
local data=T.fixtures.fresh()
for key,file in pairs({pokemon='pokemon',moves='moves',gen2Trainers='trainers',
  gen2Tilesets='tilesets',gen2Maps='maps',gen2Scripts='scripts',audio='audio',
  type_chart='type_chart',gen2Pokedex='pokedex',gen2Icons='icons',gen2Palettes='palettes',
  items='items',gen2Marts='marts',gen2Encounters='encounters'}) do
  data[key]=assert(loadfile(cache..'/'..file..'.lua'))()
end
local SaveData=require('src.core.SaveData')
local original=SaveData.loadOptions
SaveData.loadOptions=function(...)
  local o=original(...)
  o.modOptions=o.modOptions or {}
  o.modOptions.kanto_contests={}
  if mode=='on' then o.modOptions.kanto_contests.expanded_species=true end
  if mode=='off' then o.modOptions.kanto_contests.expanded_species=false end
  return o
end
local paths={'Kanto-Contests'}
if mode~='solo' then
  paths={'Kanto-Contests','national_dex_gen3','g9-battle-sprites-gen3','gen3-hd-sprites','g1r_modern_spawns'}
end
local r=T.sdk.loadMods(paths,{generation=2,root=root,data=data})
SaveData.loadOptions=original
for _,err in ipairs(r.errors or {}) do print('LOADER',err.message or tostring(err)) end
T.eq(#r.errors,0,'no loader errors')
for _,path in ipairs(paths) do
  local found
  for _,m in pairs(r.mods) do if m.path:match('([^/]+)$')==path then found=m end end
  T.eq(found and found.state,'loaded',path..' loads')
end
assert(r.loader.exports.kanto_contests,'Contests must load')
local dusk=r.loader.exports.kanto_contests.duskChallenge
local game={data=r.data,save={party={},boxes={},inventory={},player={badges={}},flags={}},options={}}
r.loader.game=game
-- The actual shared load event: includes dex reconciliation and spawn-pool generation.
require('src.mods.Runtime').emit('game.ready',{game=game})
local Items=require('src.core.gen2.ItemEffects')
local Evolution=require('src.core.gen2.Evolution')
local expectedBundle=mode=='on' or mode=='solo'
for base,name in pairs({MURKROW='HONCHKROW',MISDREAVUS='MISMAGIUS'}) do
  local target=expectedBundle and 'KC_'..name or name
  T.eq(dusk.target(r.data,base),target,mode..' preferred target '..base)
  T.eq(r.data.pokemon['KC_'..name]~=nil,expectedBundle,'no duplicate bundled species in auto')
  local result=Items.useOnMon(dusk.item,{species=base},r.data)
  T.check(result.used,'reward stone usable')
  T.eq(result.evolution and result.evolution.into,target,'reward stone destination')
  if mode~='solo' then
    local native=Items.useOnMon('DUSK_STONE',{species=base},r.data)
    T.eq(native.evolution and native.evolution.into,name,'Wooble stone keeps its own route')
    T.eq(Evolution.checkMon(r.data,{species=base},{force=true,item='DUSK_STONE'}).into,name,'native eligibility')
  end
end
T.check(not Items.useOnMon(dusk.item,{species='PIKACHU'},r.data).used,'wrong species does not consume')
T.check(not Items.useOnMon(dusk.item,{species='MURKROW',isEgg=true},r.data).used,'egg does not consume')
T.check(not Items.useOnMon(dusk.item,{species='MURKROW',item='EVERSTONE'},r.data).used,'Everstone does not consume')
local save={inventory={[dusk.item]=99}}
dusk.recordWin(save,'MASTER',true,true,true)
T.check(not dusk.give(save,r.data),'full stack keeps pending reward')
save.inventory[dusk.item]=98
T.check(dusk.give(save,r.data),'reward retried successfully')
T.check(not dusk.give(save,r.data),'reward paid once')
-- Provider selection is explicit even with ambiguous same-name third-party records.
if mode~='solo' and not expectedBundle then
  r.data.pokemon.OTHER_MISMAGIUS={name='MISMAGIUS'}
  T.eq(dusk.target(r.data,'MISDREAVUS'),'MISMAGIUS','Wooble beats ambiguous display names')
  r.data.pokemon.OTHER_MISMAGIUS=nil
end
-- Existing bundled mons are never renamed or discarded when AUTO delegates.
if not expectedBundle then
  local old={species='KC_HONCHKROW',nickname='KEEP',contestWins={COOL=3}}
  local legacy={party={old},boxes={},inventory={}}
  local boxMon={species='KC_MISMAGIUS',nickname='BOX40',contestWins={SMART=2}}
  legacy.boxes[40]={boxMon}
  require('src.core.gen2.Boxes').NUM_BOXES=40
  local hidden=dusk.support.protect(legacy,game)
  T.eq(hidden,2,'legacy mons protected in party and expanded box')
  r.data.pokemon.KC_HONCHKROW={id='KC_HONCHKROW',name='HONCHKROW',dex=430}
  r.data.pokemon.KC_MISMAGIUS={id='KC_MISMAGIUS',name='MISMAGIUS',dex=429}
  local _,restored=dusk.support.protect(legacy,game)
  T.eq(restored,2,'legacy mons recoverable when bundled definitions return')
  T.eq(legacy.party[1],old,'same mon and contest fields retained')
  T.eq(legacy.boxes[40][1],boxMon,'expanded box and contest fields retained')
end
T.finish('Wooble compatibility '..mode)
