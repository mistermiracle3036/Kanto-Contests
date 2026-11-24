-- Save-restore order (REQUESTS 933/1092, exchange/CONTRACTS.md): every
-- contest-party restore runs before the bundled-evolutions protector.
-- From engine: luajit <this> <review-root> <Crystal generated-data>
package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit')
require('src.core.Version').engine='0.4.0'
require('src.core.GameVersion').current='crystal'
local root,cache=assert(arg[1]),assert(arg[2])
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
  o.modOptions.kanto_contests={expanded_species=false}  -- bundled OFF: protector hides KC_*
  return o
end
local r=T.sdk.loadMods({'Kanto-Contests'},{generation=2,root=root,data=data})
SaveData.loadOptions=original
T.eq(#r.errors,0,'no loader errors')
T.eq(r.data.pokemon.KC_HONCHKROW,nil,'bundled species absent when OFF')

-- 1. By contract: on each shared save event, every Contests listener that is
-- not the protector sits at >= 0 and the protector at exactly -90.
local events=r.loader.events.listeners
for _,name in ipairs({'save.loading','checkpoint.restored','game.ready'}) do
  local mine={}
  for _,e in ipairs(events[name] or {}) do
    if e.owner=='kanto_contests' then mine[#mine+1]=e.priority end
  end
  T.eq(#mine>=1,true,name..' has Contests listeners')
  T.eq(mine[#mine],-90,name..' protector is last, at -90')
  for i=1,#mine-1 do T.eq(mine[i]>=0,true,name..' listener '..i..' runs at >= 0') end
end

-- 2. By behaviour: a save written mid-contest, whose stashed party holds a
-- bundled Honchkrow, loads with that Honchkrow hidden ONCE and the rest of
-- the party back -- never two hidden copies, never a lost entrant.
local function midContestSave()
  local honch={species='KC_HONCHKROW',nickname='KEEP',contestWins={COOL=3}}
  local pika={species='PIKACHU',nickname='SPARK'}
  return {party={pika},kcPartyStash={honch,pika},kcPartySlot=2,
    boxes={},inventory={},player={badges={}},flags={}}, honch, pika
end
local Runtime=require('src.mods.Runtime')
local function check(label, emit)
  local save,honch,pika=midContestSave()
  local game={data=r.data,save=save,options={}}
  r.loader.game=game
  emit(save,game)
  T.eq(save.kcPartyStash,nil,label..': stash restored')
  T.eq(save.kcContestInterrupted,true,label..': interruption remembered')
  T.eq(#save.party,1,label..': party is the entrant only')
  T.eq(save.party[1],pika,label..': entrant back in the party')
  local hidden=0
  local g=save.modData and save.modData.kanto_contests and save.modData.kanto_contests.saveGuardian
  local function walk(t,seen)
    if type(t)~='table' or seen[t] then return end
    seen[t]=true
    if t.species=='KC_HONCHKROW' and t.nickname=='KEEP' then hidden=hidden+1 end
    for _,v in pairs(t) do walk(v,seen) end
  end
  walk(g,{})
  T.eq(hidden,1,label..': Honchkrow kept safe exactly once')
  T.eq(honch.contestWins.COOL,3,label..': contest wins kept')
end
check('save.loading',function(save) Runtime.emit('save.loading',{raw=save}) end)
check('checkpoint.restored',function(_,game) Runtime.emit('checkpoint.restored',{game=game}) end)
T.finish('Restore order')
