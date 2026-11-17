-- A POKeMON's picture in the Gen 2 picture window (World:showPokePic), asking a
-- sprite provider first. 0.37.58, REQUESTS 978: a WoobleDex species carries a
-- placeholder spriteFront (the grey ball with "?") and WoobleSpritePack draws the
-- real art through the open battle.mon_pic hook chain (its main.lua wraps it and
-- answers at natural size). The engine draws world.pokePic at native size in a
-- 7x7-tile box, so provider art is fitted into a 56x56 canvas. With no provider
-- registered, this is exactly World:showPokePic.
return function(world, index, mon)
  world:showPokePic(index)
  local okR, Runtime = pcall(require, "src.mods.Runtime")
  if not (okR and type(Runtime) == "table" and Runtime.wantsHook
      and Runtime.wantsHook("battle.mon_pic")) then return end
  local current = world.pokePic
  local ok, pic = pcall(Runtime.call, "battle.mon_pic", function(img) return img end, current,
    { mon = mon, species = mon and mon.species, side = "front", natural = true,
      shiny = mon and mon.shiny })
  if not (ok and pic and pic ~= current and type(pic.getDimensions) == "function") then return end
  local G = love and love.graphics
  if not (G and G.newCanvas) then return end
  local w, h = pic:getDimensions()
  local box = 56
  local scale = math.min(1, box / math.max(w, h, 1))
  local okC, canvas = pcall(G.newCanvas, box, box)
  if not okC then return end
  pcall(canvas.setFilter, canvas, "nearest", "nearest")
  G.push("all")
  G.setCanvas(canvas)
  G.clear(0, 0, 0, 0)
  G.setColor(1, 1, 1, 1)
  G.draw(pic, math.floor((box - w * scale) / 2), math.floor(box - h * scale), 0, scale, scale)
  G.pop()
  world.pokePic = canvas
  world.pokePicTrueColor = true
end
