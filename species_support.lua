-- Minimal Gen 2 adapter derived from Expanded Species 0.7.0 (MIT).
-- Contains only owned-species registration, dex/visual setup and save recovery.
-- No encounter, trainer, trade, form or global sprite wrappers are installed.
local FIRST_CUSTOM_DEX, API_VERSION = 252, 1
local SAVE_GUARDIAN_FORMAT, PARTY_SIZE, MONS_PER_BOX = 1, 6, 20
local function isInteger(v) return type(v)=="number" and v>=1 and v%1==0 end
local function copy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local out = {}
    seen[value] = out
    for key, item in pairs(value) do
        out[copy(key, seen)] = copy(item, seen)
    end
    return out
end

local function arrayContains(items, wanted)
    for _, item in ipairs(items or {}) do
        if item == wanted then
            return true
        end
    end
    return false
end

local function appendUnique(items, value)
    if not arrayContains(items, value) then
        items[#items + 1] = value
    end
end

local function markerFor(definition)
    if type(definition) ~= "table" then
        return nil
    end
    if type(definition.expandedSpecies) == "table" then
        return definition.expandedSpecies
    end
    return nil
end

local function isCustomSpecies(definition)
    if markerFor(definition) then
        return true
    end

    return (isInteger(definition.dex) and definition.dex >= FIRST_CUSTOM_DEX)
        or (isInteger(definition.index) and definition.index >= FIRST_CUSTOM_DEX)
end

local function requestedDex(speciesId, definition)
    local marker = markerFor(definition)
    local requested = marker and marker.requestedDex or definition.dex
    if not isInteger(requested) or requested < FIRST_CUSTOM_DEX then
        requested = nil
    end
    return requested, speciesId
end

local function sortedCustomSpecies(pokemon)
    local result = {}
    for speciesId, definition in pairs(pokemon or {}) do
        if type(speciesId) == "string"
            and type(definition) == "table"
            and isCustomSpecies(definition) then
            result[#result + 1] = speciesId
        end
    end

    table.sort(result, function(left, right)
        local leftDex = requestedDex(left, pokemon[left]) or math.huge
        local rightDex = requestedDex(right, pokemon[right]) or math.huge
        if leftDex ~= rightDex then
            return leftDex < rightDex
        end
        return left < right
    end)
    return result
end

local function customDexEntry(speciesId, definition)
    local marker = markerFor(definition) or {}
    local supplied = marker.dexEntry
    if type(supplied) ~= "table" and type(definition.dexEntry) == "table" then
        supplied = definition.dexEntry
    end
    supplied = supplied or {}

    local height = supplied.height
    if not isInteger(height) then
        local feet = tonumber(supplied.heightFt) or 0
        local inches = tonumber(supplied.heightIn) or 0
        height = math.max(0, math.floor(feet)) * 100 + math.max(0, math.floor(inches))
    end

    local weight = supplied.weight
    if type(weight) ~= "number" then
        local pounds = tonumber(supplied.weightLbs)
        weight = pounds and math.floor(pounds * 10 + 0.5) or 0
    end

    return {
        id = speciesId,
        dex = definition.dex,
        kind = supplied.kind or "CUSTOM",
        height = height,
        weight = weight,
        text = supplied.text or "A custom species.<NEXT>Added by a mod.",
        text2 = supplied.text2 or "Its data uses a<NEXT>virtual species ID.",
    }
end

local function rebuildPokedex(data, pokemon, customIds)
    local dex = data.gen2Pokedex
    if type(dex) ~= "table" then
        return
    end

    dex.entries = dex.entries or {}
    dex.newOrder = dex.newOrder or {}

    local customSet = {}
    for _, speciesId in ipairs(customIds) do
        customSet[speciesId] = true
        dex.entries[speciesId] = customDexEntry(speciesId, pokemon[speciesId])
    end

    local newOrder = {}
    for _, speciesId in ipairs(dex.newOrder) do
        if not customSet[speciesId] and pokemon[speciesId] then
            appendUnique(newOrder, speciesId)
        end
    end
    for _, speciesId in ipairs(customIds) do
        appendUnique(newOrder, speciesId)
    end
    dex.newOrder = newOrder

    local alphabetical = {}
    for speciesId, entry in pairs(dex.entries) do
        if pokemon[speciesId] and type(entry) == "table" then
            alphabetical[#alphabetical + 1] = speciesId
        end
    end
    table.sort(alphabetical, function(left, right)
        local leftName = tostring(pokemon[left].name or left):upper()
        local rightName = tostring(pokemon[right].name or right):upper()
        if leftName ~= rightName then
            return leftName < rightName
        end
        return left < right
    end)
    dex.alphabeticalOrder = alphabetical
end

local function safeIconId(speciesId)
    return "ICON_EXPANDED_SPECIES_" .. speciesId
end

local function installVisuals(data, pokemon, customIds)
    local iconData = data.gen2Icons
    local paletteData = data.gen2Palettes

    for _, speciesId in ipairs(customIds) do
        local definition = pokemon[speciesId]
        local marker = markerFor(definition) or {}

        if type(iconData) == "table" then
            iconData.icons = iconData.icons or {}
            iconData.species = iconData.species or {}

            local suppliedIcon = marker.icon or definition.icon
            if type(suppliedIcon) == "string" then
                suppliedIcon = { image = suppliedIcon }
            end

            if type(suppliedIcon) == "table" and type(suppliedIcon.image) == "string" then
                local iconId = safeIconId(speciesId)
                iconData.icons[iconId] = {
                    id = iconId,
                    image = suppliedIcon.image,
                    width = suppliedIcon.width or 16,
                    height = suppliedIcon.height or 32,
                    frames = suppliedIcon.frames or 2,
                }
                iconData.species[speciesId] = iconId
            else
                local fallback = marker.iconFallback or definition.iconFallback or "DITTO"
                iconData.species[speciesId] = iconData.species[fallback]
                    or iconData.species.DITTO
            end
        end

        if type(paletteData) == "table" then
            paletteData.pokemon = paletteData.pokemon or {}
            local suppliedPalette = marker.palette or definition.palette
            if type(suppliedPalette) == "table" then
                paletteData.pokemon[speciesId] = copy(suppliedPalette)
            else
                local fallback = marker.paletteFallback or definition.paletteFallback or "DITTO"
                local fallbackPalette = paletteData.pokemon[fallback]
                    or paletteData.pokemon.DITTO
                if fallbackPalette then
                    paletteData.pokemon[speciesId] = copy(fallbackPalette)
                end
            end
        end
    end
end


return function(mod, ownedIds)
  local function isGen2() return true end
  local function boxCount() return 14 end
  -- The guard owns only our two namespaced species. Other providers keep
  -- their own recovery policy, even when their content is disabled.
  local function isCustomSpecies(def)
    return def and ownedIds[def.id] == true
  end
    local function saveGuardian(save)
        if type(save) ~= "table" then return nil end
        save.modData = type(save.modData) == "table" and save.modData or {}
        local bucket = save.modData[mod.id]
        if type(bucket) ~= "table" then
            bucket = {}
            save.modData[mod.id] = bucket
        end
        local guardian = bucket.saveGuardian
        if type(guardian) ~= "table" then
            guardian = {}
            bucket.saveGuardian = guardian
        end
        guardian.format = SAVE_GUARDIAN_FORMAT
        guardian.catalog = type(guardian.catalog) == "table" and guardian.catalog or {}
        guardian.missing = type(guardian.missing) == "table" and guardian.missing or {}
        guardian.nextSequence = math.max(1,
            math.floor(tonumber(guardian.nextSequence) or 1))
        return guardian
    end

    local function catalogLiveSpecies(guardian, pokemon)
        if not guardian or type(pokemon) ~= "table" then return end
        for speciesId, definition in pairs(pokemon) do
            if type(speciesId) == "string" and type(definition) == "table"
                and isCustomSpecies(definition) then
                local marker = markerFor(definition) or {}
                guardian.catalog[speciesId] = {
                    species = speciesId,
                    provider = marker.provider,
                    name = definition.name or speciesId,
                    frameworkApi = marker.api or API_VERSION,
                }
            end
        end
    end

    local function stampOwnedMon(mon, pokemon, catalog)
        if type(mon) ~= "table" or type(mon.species) ~= "string" then return end
        local definition = pokemon and pokemon[mon.species]
        if not (definition and isCustomSpecies(definition)) then return end
        local row = catalog and catalog[mon.species] or {}
        local marker = type(mon.expandedSpecies) == "table"
            and mon.expandedSpecies or {}
        marker.api = API_VERSION
        marker.species = mon.species
        marker.provider = row and row.provider
            or (markerFor(definition) or {}).provider
        mon.expandedSpecies = marker
    end

    local function eachActiveSaveMon(save, fn)
        if type(save) ~= "table" or type(fn) ~= "function" then return end
        for index, mon in ipairs(save.party or {}) do
            fn(mon, { kind = "party", index = index })
        end
        for boxIndex = 1, boxCount() do
            local box = save.boxes and save.boxes[boxIndex]
            if type(box) == "table" then
                for index, mon in ipairs(box) do
                    fn(mon, { kind = "box", box = boxIndex, index = index })
                end
            end
        end
        local dayCare = save.dayCare
        if type(dayCare) == "table" then
            if dayCare.man and dayCare.man.mon then
                fn(dayCare.man.mon, { kind = "dayCare", side = "man" })
            end
            if dayCare.lady and dayCare.lady.mon then
                fn(dayCare.lady.mon, { kind = "dayCare", side = "lady" })
            end
            if dayCare.egg then fn(dayCare.egg, { kind = "dayCare", side = "egg" }) end
        end
        if save.daycare and save.daycare.mon then
            fn(save.daycare.mon, { kind = "legacyDayCare" })
        end
        local contest = save.bugContest
        if type(contest) == "table" then
            for index, mon in ipairs(contest.stash or {}) do
                fn(mon, { kind = "bugContestStash", index = index })
            end
            if contest.caught then
                fn(contest.caught, { kind = "bugContestCaught" })
            end
        end
    end

    local function partyMail(save)
        save.mail = type(save.mail) == "table" and save.mail or {}
        save.mail.party = type(save.mail.party) == "table" and save.mail.party or {}
        return save.mail.party
    end

    local function removePartyMail(save, index)
        local rows = partyMail(save)
        local removed = rows[index]
        for slot = index, PARTY_SIZE - 1 do rows[slot] = rows[slot + 1] end
        rows[PARTY_SIZE] = nil
        return removed
    end

    local function insertPartyMail(save, index, entry)
        local rows = partyMail(save)
        for slot = PARTY_SIZE, index + 1, -1 do
            rows[slot] = rows[slot - 1]
        end
        rows[index] = entry
    end

    local function missingDefinition(mon, pokemon)
        return type(mon) == "table" and type(mon.species) == "string"
            and ownedIds[mon.species] and not (pokemon and pokemon[mon.species])
    end

    local function quarantineEntry(guardian, mon, source, mail)
        local catalog = guardian.catalog[mon.species] or {}
        local monMarker = type(mon.expandedSpecies) == "table"
            and mon.expandedSpecies or {}
        local entry = {
            sequence = guardian.nextSequence,
            species = mon.species,
            provider = catalog.provider or monMarker.provider,
            name = mon.nickname or mon.name or catalog.name or mon.species,
            mon = mon,
            source = copy(source),
        }
        if mail ~= nil then entry.mail = mail end
        guardian.nextSequence = guardian.nextSequence + 1
        guardian.missing[#guardian.missing + 1] = entry
        return entry
    end

    local function quarantineMissing(save, pokemon, guardian)
        local moved = 0
        save.party = type(save.party) == "table" and save.party or {}
        for index = #save.party, 1, -1 do
            local mon = save.party[index]
            if missingDefinition(mon, pokemon) then
                local mail = isGen2() and partyMail(save)[index] or nil
                table.remove(save.party, index)
                if isGen2() then removePartyMail(save, index) end
                quarantineEntry(guardian, mon,
                    { kind = "party", index = index }, mail)
                moved = moved + 1
            end
        end

        save.boxes = type(save.boxes) == "table" and save.boxes or {}
        for boxIndex = 1, boxCount() do
            local box = save.boxes[boxIndex]
            if type(box) == "table" then
                for index = #box, 1, -1 do
                    local mon = box[index]
                    if missingDefinition(mon, pokemon) then
                        table.remove(box, index)
                        quarantineEntry(guardian, mon,
                            { kind = "box", box = boxIndex, index = index })
                        moved = moved + 1
                    end
                end
            end
        end

        local dayCare = save.dayCare
        if type(dayCare) == "table" then
            for _, side in ipairs({ "man", "lady" }) do
                local slot = dayCare[side]
                if type(slot) == "table" and missingDefinition(slot.mon, pokemon) then
                    local mon = slot.mon
                    slot.mon = nil
                    quarantineEntry(guardian, mon,
                        { kind = "dayCare", side = side })
                    moved = moved + 1
                end
            end
            if missingDefinition(dayCare.egg, pokemon) then
                local mon = dayCare.egg
                dayCare.egg = nil
                quarantineEntry(guardian, mon,
                    { kind = "dayCare", side = "egg" })
                moved = moved + 1
            end
        end

        if type(save.daycare) == "table"
            and missingDefinition(save.daycare.mon, pokemon) then
            local mon = save.daycare.mon
            save.daycare.mon = nil
            quarantineEntry(guardian, mon, { kind = "legacyDayCare" })
            moved = moved + 1
        end

        local contest = save.bugContest
        if type(contest) == "table" then
            local stash = contest.stash
            if type(stash) == "table" then
                for index = #stash, 1, -1 do
                    local mon = stash[index]
                    if missingDefinition(mon, pokemon) then
                        table.remove(stash, index)
                        quarantineEntry(guardian, mon,
                            { kind = "bugContestStash", index = index })
                        moved = moved + 1
                    end
                end
            end
            if missingDefinition(contest.caught, pokemon) then
                local mon = contest.caught
                contest.caught = nil
                quarantineEntry(guardian, mon, { kind = "bugContestCaught" })
                moved = moved + 1
            end
        end
        return moved
    end

    local function insertAt(items, index, value)
        index = math.max(1, math.min(math.floor(tonumber(index) or (#items + 1)),
            #items + 1))
        table.insert(items, index, value)
        return index
    end

    local function restoreExact(save, entry)
        local source = entry.source or {}
        local mon = entry.mon
        if source.kind == "party" then
            save.party = type(save.party) == "table" and save.party or {}
            if #save.party >= PARTY_SIZE then return false end
            local index = insertAt(save.party, source.index, mon)
            insertPartyMail(save, index, entry.mail)
            return true
        elseif source.kind == "box" then
            save.boxes = type(save.boxes) == "table" and save.boxes or {}
            local boxIndex = math.floor(tonumber(source.box) or 0)
            if boxIndex < 1 or boxIndex > boxCount() then return false end
            local box = save.boxes[boxIndex]
            if type(box) ~= "table" then
                box = {}
                save.boxes[boxIndex] = box
            end
            if #box >= MONS_PER_BOX then return false end
            insertAt(box, source.index, mon)
            return true
        elseif source.kind == "dayCare" then
            save.dayCare = type(save.dayCare) == "table" and save.dayCare or {}
            if source.side == "egg" then
                if save.dayCare.egg ~= nil then return false end
                save.dayCare.egg = mon
                return true
            end
            if source.side ~= "man" and source.side ~= "lady" then return false end
            save.dayCare[source.side] = type(save.dayCare[source.side]) == "table"
                and save.dayCare[source.side] or {}
            if save.dayCare[source.side].mon ~= nil then return false end
            save.dayCare[source.side].mon = mon
            return true
        elseif source.kind == "legacyDayCare" then
            save.daycare = type(save.daycare) == "table" and save.daycare or {}
            if save.daycare.mon ~= nil then return false end
            save.daycare.mon = mon
            return true
        elseif source.kind == "bugContestStash" then
            if type(save.bugContest) ~= "table" or save.bugContest.active ~= true then
                return false
            end
            save.bugContest.stash = type(save.bugContest.stash) == "table"
                and save.bugContest.stash or {}
            insertAt(save.bugContest.stash, source.index, mon)
            return true
        elseif source.kind == "bugContestCaught" then
            if type(save.bugContest) ~= "table" or save.bugContest.active ~= true then
                return false
            end
            if save.bugContest.caught ~= nil then return false end
            save.bugContest.caught = mon
            return true
        end
        return false
    end

    local function restoreFallback(save, entry)
        -- Party MAIL has no legal box representation. Keep such a mon in the
        -- hidden store until a party slot is free rather than detach its letter.
        if entry.mail ~= nil then
            save.party = type(save.party) == "table" and save.party or {}
            if #save.party >= PARTY_SIZE then return false end
            local index = #save.party + 1
            save.party[index] = entry.mon
            insertPartyMail(save, index, entry.mail)
            return true
        end
        save.boxes = type(save.boxes) == "table" and save.boxes or {}
        for boxIndex = 1, boxCount() do
            local box = save.boxes[boxIndex]
            if type(box) ~= "table" then
                box = {}
                save.boxes[boxIndex] = box
            end
            if #box < MONS_PER_BOX then
                box[#box + 1] = entry.mon
                return true
            end
        end
        return false
    end

    local function restoreAvailable(save, pokemon, guardian)
        local restored = 0
        local remaining = {}
        table.sort(guardian.missing, function(left, right)
            local leftSequence = type(left) == "table" and left.sequence or 0
            local rightSequence = type(right) == "table" and right.sequence or 0
            return (tonumber(leftSequence) or 0) > (tonumber(rightSequence) or 0)
        end)
        for _, entry in ipairs(guardian.missing) do
            local mon = type(entry) == "table" and entry.mon
            local speciesId = mon and mon.species
                or (type(entry) == "table" and entry.species)
            if type(mon) == "table" and pokemon and pokemon[speciesId]
                and (restoreExact(save, entry) or restoreFallback(save, entry)) then
                restored = restored + 1
            else
                remaining[#remaining + 1] = entry
            end
        end
        guardian.missing = remaining
        return restored
    end


  local api = {}
  function api.register(row)
    row.expandedSpecies = { api=1, provider=mod.id, requestedDex=row.dex,
      dexEntry=copy(row.dexEntry), icon=copy(row.icon), palette=copy(row.palette),
      sourceName=row.name }
    row.index = nil
    mod.content.pokemon:register(row.id, row)
  end
  function api.reconcile(game)
    if not (game and game.data) then return end
    local data, ids = game.data, {}
    for id in pairs(ownedIds) do if data.pokemon[id] then ids[#ids+1]=id end end
    if #ids==0 then return end
    table.sort(ids)
    local used = {}
    for id,row in pairs(data.pokemon) do
      if not ownedIds[id] then used[row.dex or 0]=true; used[row.index or 0]=true end
    end
    local index=FIRST_CUSTOM_DEX
    for _,id in ipairs(ids) do
      while used[index] do index=index+1 end
      data.pokemon[id].dex, data.pokemon[id].index=index,index
      data.pokemon[id].expandedSpecies.virtualIndex=index
      used[index]=true; index=index+1
    end
    rebuildPokedex(data,data.pokemon,ids)
    installVisuals(data,data.pokemon,ids)
  end
  function api.protect(save, game)
    if not (save and game and game.data and game.data.pokemon) then return 0,0 end
    if mod.exports.restoreContestParty then mod.exports.restoreContestParty(save) end
    local pokemon=game.data.pokemon
    local guardian=saveGuardian(save)
    catalogLiveSpecies(guardian,pokemon)
    local restored=restoreAvailable(save,pokemon,guardian)
    local hidden=quarantineMissing(save,pokemon,guardian)
    eachActiveSaveMon(save,function(mon) stampOwnedMon(mon,pokemon,guardian.catalog) end)
    if hidden>0 then
      require("src.mods.Runtime").reportError(mod.id,
        "Bundled evolutions are disabled. Your affected Pokemon are kept safely; enable Bundled evolutions and relaunch to restore them.")
    end
    return hidden,restored
  end
  mod.events:on("save.loading",function(ctx)
    local save=ctx and ctx.raw
    if save and save.kcPartyStash then
      save.kcContestInterrupted=true
      if mod.exports.restoreContestParty then mod.exports.restoreContestParty(save) end
    end
    api.protect(save,mod.game)
  end)
  mod.events:on("game.ready",function(ctx)
    local game=ctx and ctx.game or mod.game
    api.reconcile(game)
    api.protect(game and game.save,game)
  end)
  mod.events:on("checkpoint.restored",function(ctx)
    local game=ctx and ctx.game or mod.game
    if game and game.save and game.save.kcPartyStash then game.save.kcContestInterrupted=true end
    api.protect(game and game.save,game)
  end)
  return api
end
