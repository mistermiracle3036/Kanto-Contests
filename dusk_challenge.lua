-- Fantina's first MASTER victory, independent of the Grand Hall quest.
return function(mod)
  local ID = "KC_DUSK_STONE"
  local speciesIds = { KC_HONCHKROW=true, KC_MISMAGIUS=true }
  local function module(name)
    return assert(load(assert(mod:read(name)), "@kanto_contests/"..name))()
  end
  local support = module("species_support.lua")(mod, speciesIds)
  local bundled = mod.options:get("expanded_species") ~= false
  local api = { item=ID, sprite="SPRITE_KC_FANTINA", support=support }
  -- Blaklyte's commissioned walker, identical to Indigo Conference 1.1.55:
  -- source purple and the updated Crystal skin tone, with transparent background.
  mod.content.sprites:register(api.sprite,{id=api.sprite,
    image=mod.assets:path("assets/fantina.png"),frames=6,walker=true,
    spriteType="WALKING_SPRITE",palette="PAL_OW_PINK",paletteId=4,trueColor=true})
  if bundled then
    for _,row in ipairs(module("dusk_species.lua")) do
      local slug,base=row.slug,row.cryBase
      row.slug,row.cryBase=nil,nil
      mod.content.cries:register(row.id,{base=base})
      row.cry,row.picSize=row.id,7
      row.spriteFront=mod.assets:path("assets/"..slug.."_front.png")
      row.spriteBack=mod.assets:path("assets/"..slug.."_back.png")
      row.icon={image=mod.assets:path("assets/"..slug.."_icon.png"),width=16,height=32,frames=2}
      support.register(row)
    end
  end
  function api.target(data, base)
    local name=({MURKROW="HONCHKROW",MISDREAVUS="MISMAGIUS"})[base]
    if not name then return nil end
    local pokemon=data and data.pokemon or {}
    if bundled and pokemon["KC_"..name] then return "KC_"..name end
    -- With our species switched off, a compatible pack can supply the target.
    -- Never overwrite its records or guess between multiple matching species.
    local match
    for id,row in pairs(pokemon) do
      if not speciesIds[id] and type(row)=="table" and tostring(row.name):upper()==name then
        if match then return nil end
        match=id
      end
    end
    return match
  end
  mod.content.items:register(ID,{id=ID,name="DUSK STONE",price=0,
    description="Evolves certain<NEXT>kinds of POKéMON.",
    tossable=true,needsTarget=true})
  mod.content.item_effects:register(ID,{field=true,needsTarget=true,action="stone",
    use=function(ctx)
      local target=api.target(ctx.data,ctx.mon and ctx.mon.species)
      if not target or ctx.mon.item=="EVERSTONE" then
        return {used=false,text="It won't have any\neffect."}
      end
      return {used=true,evolution={method="EVOLVE_ITEM",item=ID,into=target}}
    end})
  if bundled then
    for base,target in pairs({MURKROW="KC_HONCHKROW",MISDREAVUS="KC_MISMAGIUS"}) do
      mod.content.pokemon:patch(base,{evolutions={__append={{method="EVOLVE_ITEM",item=ID,into=target}}}})
    end
  end
  local function state(save)
    if not save then return {} end
    save.kcFantinaChallenge=save.kcFantinaChallenge or {}
    return save.kcFantinaChallenge
  end
  function api.needed(rank,plan)
    return rank=="MASTER" and not state(mod.game and mod.game.save).won
      and not (plan and plan.record==false)
  end
  function api.entry()
    return {sprite=api.sprite,name="FANTINA",species="MISDREAVUS",level=55}
  end
  function api.recordWin(save,rank,won,recorded,participated)
    local s=state(save)
    if rank=="MASTER" and won and recorded and participated and not s.won then
      s.won=true
      s.pending=mod.options:get("dusk_stone_reward")~=false
      s.given=false
    end
  end
  function api.pending(save)
    local s=state(save)
    return s.won and s.pending and not s.given and mod.options:get("dusk_stone_reward")~=false
  end
  function api.give(save,data)
    if not api.pending(save) then return false,"not_pending" end
    if not require("src.inventory.Bag").add(save,ID,1,data) then return false,"bag_full" end
    local s=state(save)
    s.given,s.pending=true,false
    return true
  end
  api.owns={pokemon=bundled and {"KC_HONCHKROW","KC_MISMAGIUS"} or {},items={ID},
    saveFields={"kcFantinaChallenge"}}
  return api
end
