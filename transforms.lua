-- Derive hall source sheets from the player's imported game at install/load.
-- The ZIP contains this recipe, never the imported tileset pixels.
return function(ctx)
  for _,name in ipairs({"mart","traditional_house","lighthouse","facility","elite_four_room"}) do
    local path="tilesets/"..name..".png"
    if ctx.exists(path) then ctx.writeImage(ctx.readImage(path),path) end
  end
end
