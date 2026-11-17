-- Headless rendering-contract test; actual phone pixels remain a device check.
local S=dofile(assert(arg[1])..'/contest_screen.lua')
local fallback={getDimensions=function() return 48,48 end}
local art={getDimensions=function() return 120,80 end}
local draws, palettes, requested={},0,0
love={graphics={setColor=function() end,draw=function(...) draws[#draws+1]={...} end}}
local mon={species='MISMAGIUS',shiny=true}
local s=setmetatable({performer=1,s={c={{mon=mon}}},
  game={data={pokemon={MISMAGIUS={spriteBack='placeholder'}},gen2Palettes={}}}},S)
-- Bind the screen methods on this minimal test fixture.
s.mods=S.mods; s.drawPerformer=S.drawPerformer
s.image=function() return fallback end
s._mods={Palettes={monColors=function() return {} end},
  GbcPalette={available=function() return true end,with=function(_,fn) palettes=palettes+1;fn() end},
  Runtime={wantsHook=function() return true end,call=function(name,vanilla,img,ctx)
    assert(name=='battle.mon_pic' and ctx.natural and ctx.side=='back')
    assert(ctx.mon==mon and ctx.shiny==true)
    requested=requested+1;return art
  end}}
s:drawPerformer()
assert(requested==1 and draws[1][1]==art,'provider image reaches draw')
assert(draws[1][5]==0.4,'natural image fits 48-pixel box')
assert(palettes==0,'provider art retains true colour')
s._mods.Runtime.call=function(_,vanilla,img) return vanilla(img) end
s:drawPerformer()
assert(draws[2][1]==fallback and draws[2][5]==1,'unchanged vanilla fallback')
assert(palettes==1,'vanilla fallback retains palette')
s.anim={bg={hidden={player=true}}}
s:drawPerformer()
assert(#draws==2,'move animation hide state is respected')
print('8/8 picture contract checks passed')
