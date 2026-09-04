-- Read a town's painted lobby and stage out of the Content Editor bridge
-- and print its KC_HALLS entry.
--
--   luajit tests/read_hall_rooms.lua CIANWOOD BLACKTHORN > rooms.lua
--
-- A room the developer paints is quarter-block work, so the mod carries its
-- OWN composed tileset: each distinct painted 32x32 block becomes one entry
-- in the room's block list and the map grid indexes that list.
--
-- THE BORDER RULE, which this project has hit on every hand-painted room at
-- least once: block id 0 in a map grid does NOT mean "tileset block 0", it
-- means "draw the map header's border block" (engine BorderFill.blockFor).
-- So index 0 is reserved for a FLAT block -- the sheet's solid black, so a
-- glimpse past the wall is black rather than a fragment of wall tiling away
-- forever -- and real blocks start at 1. The grid is asserted to contain no
-- 0. tests/room_border_check.py guards the same two things after the fact.
--
-- PER ENGINE, because Gold's sheets are 128x48 where Crystal's are 128x128
-- and the block tables differ: a painted cell names a (vanilla block,
-- quadrant) pair, and each engine's variant composes its sixteen tiles from
-- THAT game's own tileset. Baking one game's tile ids into both is what
-- shipped garbage in 0.16.x.
--
-- FORCED COLLISION. The editor's palette has no counter mode, and it lets a
-- painted mat or staircase keep plain-floor collision, so some cells cannot
-- be finished by painting. Each is listed per room with its reason, applied
-- BEFORE blocks are deduplicated (a changed byte is a different block), and
-- printed when it fires. Nothing is forced silently.
local PROJECT = "C:/Users/dwitt/ce-new/mods/kc_layout/editor_project.lua"
local CACHE = "C:/Users/dwitt/AppData/Roaming/pokemon-love2d/%s/data/generated/"

local COUNTER = 0x90   -- CheckCounterTile: doubles an A press over the desk
local SOLID   = 0x07
local WALK    = 0x00
local CARPET  = 0x70   -- COLL_WARP_CARPET_DOWN

-- The desk is six cells wide at y=2 in every lobby, because every lobby was
-- painted over Goldenrod's layout. Goldenrod ships COUNTER there; without it
-- the judge behind the desk cannot be talked to at all.
local function deskCounter()
  local t = {}
  for x = 2, 7 do
    t[#t + 1] = { x, 2, COUNTER,
      "desk: the editor has no counter mode, and a solid desk blocks the judge" }
  end
  return t
end

local TOWNS = {
  CIANWOOD = {
    rank = "HYPER", city = "CIANWOOD_CITY",
    lobby = {
      id = "KC_CIANWOOD_CONTEST_HALL", label = "CIANWOOD CONTEST HALL",
      tilesId = "KC_CIANWOOD_HALL_TILES", source = "TILESET_LIGHTHOUSE",
      borderTile = 1,          -- the lighthouse sheet's one solid-black tile
      song = "OLIVINE_LIGHTHOUSE_1F",
      width = 5, height = 4, arrival = { x = 4, y = 7 },
      warps = { { 4, 7 }, { 5, 7 } }, warpTo = "CIANWOOD_CITY",
      force = (function()
        local t = deskCounter()
        t[#t + 1] = { 1, 0, SOLID, "the wall machine reads as stairs" }
        return t
      end)(),
    },
    stage = {
      id = "KC_CIANWOOD_CONTEST_STAGE", label = "CIANWOOD STAGE",
      tilesId = "KC_CIANWOOD_STAGE_TILES", source = "TILESET_LIGHTHOUSE",
      borderTile = 1,
      song = "GOLDENROD_GAME_CORNER",
      width = 5, height = 7, arrival = { x = 3, y = 8 },
      warps = { { 4, 13 }, { 5, 13 } }, warpTo = "KC_CIANWOOD_CONTEST_HALL",
      force = {},
    },
  },
  BLACKTHORN = {
    rank = "MASTER", city = "BLACKTHORN_CITY",
    lobby = {
      id = "KC_BLACKTHORN_CONTEST_HALL", label = "BLACKTHORN CONTEST HALL",
      tilesId = "KC_BLACKTHORN_HALL_TILES", source = "TILESET_FACILITY",
      borderTile = 54,
      song = "DRAGONS_DEN_1F",
      width = 5, height = 4, arrival = { x = 4, y = 7 },
      warps = { { 4, 7 }, { 5, 7 } }, warpTo = "BLACKTHORN_CITY",
      force = (function()
        local t = deskCounter()
        t[#t + 1] = { 4, 7, CARPET, "the exit mat is painted but walks like floor" }
        t[#t + 1] = { 5, 7, CARPET, "the exit mat is painted but walks like floor" }
        return t
      end)(),
    },
    stage = {
      id = "KC_BLACKTHORN_CONTEST_STAGE", label = "BLACKTHORN STAGE",
      tilesId = "KC_BLACKTHORN_STAGE_TILES", source = "TILESET_ELITE_FOUR_ROOM",
      borderTile = 0,
      song = "WILLS_ROOM",
      width = 5, height = 7, arrival = { x = 3, y = 8 },
      warps = { { 4, 13 }, { 5, 13 } }, warpTo = "KC_BLACKTHORN_CONTEST_HALL",
      force = {
        { 3, 9, WALK, "the stage steps are drawn but walled off -- sealed the platform" },
        { 6, 9, WALK, "the stage steps are drawn but walled off -- sealed the platform" },
      },
    },
  },
}

-- The staff and the handful of standing spectators. Goldenrod's set, which
-- is the layout every one of these rooms was painted over; every cell is
-- checked against the paint below rather than assumed.
local LOBBY_ACTORS = {
  { name = "KC_HALL_JUDGE", marker = "kcHallJudge",
    sprite = "SPRITE_GENTLEMAN", x = 4, y = 1, movement = 6 },
  { name = "KC_HALL_VENDOR", marker = "kcHallVendor",
    sprite = "SPRITE_TEACHER", x = 1, y = 7, movement = 9 },
  { name = "KC_HALL_APPRAISER", marker = "kcHallAppraiser",
    sprite = "SPRITE_BEAUTY", x = 8, y = 7, movement = 8 },
  { name = "KC_AUD_1", marker = "kcAudience",
    sprite = "SPRITE_POKEFAN_M", x = 1, y = 4, movement = 9 },
  { name = "KC_AUD_2", marker = "kcAudience",
    sprite = "SPRITE_GRANNY", x = 2, y = 4, movement = 9 },
  { name = "KC_AUD_3", marker = "kcAudience",
    sprite = "SPRITE_TWIN", x = 6, y = 6, movement = 7 },
}

local CELL_COLL = {   -- editor LayeredMap.lua CELL_COLL, verbatim
  solid = 0x07, walk = 0x00, grass = 0x18, water = 0x21, shore = 0x23,
  cut = 0x12, door = 0x71, stairs = 0x7a, cave = 0x7b, panel = 0x7c,
  carpet_down = 0x70, carpet_left = 0x76, carpet_up = 0x78, carpet_right = 0x7e,
  carpet = 0x70, ledge_right = 0xa0, ledge_left = 0xa1, ledge_up = 0xa2,
  ledge_down = 0xa3, ledge = 0xa3, face_right = 0xb0, face_left = 0xb1,
  face_up = 0xb2, face_down = 0xb3, face = 0xb2,
}

local P = dofile(PROJECT)
local TS = {}
for _, game in ipairs({ "gs", "crystal" }) do
  TS[game] = dofile(CACHE:format(game == "gs" and "gold" or "crystal") .. "tilesets.lua")
end

local warnings = 0
local function warn(fmt, ...)
  warnings = warnings + 1
  io.stderr:write("WARN  " .. string.format(fmt, ...) .. "\n")
end
local function note(fmt, ...)
  io.stderr:write("      " .. string.format(fmt, ...) .. "\n")
end

-- one painted room -> cells, then blocks, with index 0 held for the border
local function readRoom(def)
  local s = assert(P.layeredMaps[def.id], def.id .. " has no painted layers")
  local cells = s.layers[1].cells
  local CW, CH = s.cellWidth, s.cellHeight
  if CW ~= def.width * 2 or CH ~= def.height * 2 then
    warn("%s is %dx%d cells, expected %dx%d", def.id, CW, CH,
         def.width * 2, def.height * 2)
  end

  local blk, quad, coll = {}, {}, {}
  local sources = {}
  for y = 0, CH - 1 do
    for x = 0, CW - 1 do
      local i = y * CW + x + 1
      local c = cells[i]
      local name = c and tostring(c.source):match("^@runtime:(.+)$")
      if name then sources[name] = true end
      blk[i] = math.floor((c and c.tile or 0) / 4)
      quad[i] = (c and c.tile or 0) % 4
      coll[i] = CELL_COLL[s.collision[i]] or SOLID
    end
  end
  local nsrc, only = 0, nil
  for name in pairs(sources) do nsrc = nsrc + 1; only = name end
  if nsrc ~= 1 then
    warn("%s draws from %d tilesets -- a composed room can ship only one image",
         def.id, nsrc)
  elseif only ~= def.source then
    warn("%s is painted in %s but the entry says %s", def.id, only, def.source)
  end

  -- forced collision, before the dedup that turns cells into blocks
  for _, f in ipairs(def.force or {}) do
    local x, y, want, why = f[1], f[2], f[3], f[4]
    local i = y * CW + x + 1
    if coll[i] ~= want then
      note("%s (%d,%d) 0x%02X -> 0x%02X  %s", def.id, x, y, coll[i], want, why)
      coll[i] = want
    end
  end

  -- dedup into blocks; index 0 stays the border
  local key, blocks, colls, grid = {}, {}, {}, {}
  for by = 0, def.height - 1 do
    for bx = 0, def.width - 1 do
      local q, cb = {}, {}
      for n = 0, 3 do
        local x, y = bx * 2 + (n % 2), by * 2 + math.floor(n / 2)
        local i = y * CW + x + 1
        q[#q + 1] = blk[i]; q[#q + 1] = quad[i]
        cb[#cb + 1] = coll[i]
      end
      local k = table.concat(q, ",") .. "|" .. table.concat(cb, ",")
      if not key[k] then
        blocks[#blocks + 1] = q
        colls[#colls + 1] = cb
        key[k] = #blocks                 -- 1-based, so 0 is never emitted
      end
      grid[#grid + 1] = key[k]
    end
  end
  for _, v in ipairs(grid) do
    assert(v >= 1, def.id .. ": a grid cell is 0, which the engine draws as the border")
  end
  return { def = def, blocks = blocks, coll = colls, grid = grid }
end

-- compose a room's sixteen tiles per block, for one engine
local function tilesFor(room, engine)
  local ts = TS[engine][room.def.source]
  if not (ts and ts.blocks) then
    warn("%s is missing on %s", room.def.source, engine)
    return nil, nil
  end
  local rows = {}
  for _, q in ipairs(room.blocks) do
    local t = {}
    for ty = 0, 3 do
      for tx = 0, 3 do
        local qi = math.floor(ty / 2) * 2 + math.floor(tx / 2)
        local srcBlock, qd = q[qi * 2 + 1], q[qi * 2 + 2]
        local b = ts.blocks[srcBlock + 1]
        local idx = (math.floor(qd / 2) * 2 + (ty % 2)) * 4
          + ((qd % 2) * 2 + (tx % 2)) + 1
        t[#t + 1] = (b and b[idx]) or 0
      end
    end
    rows[#rows + 1] = t
  end
  return rows, ts
end

local function list(t, fmt)
  local o = {}
  for _, v in ipairs(t) do o[#o + 1] = string.format(fmt or "%d", v) end
  return table.concat(o, ", ")
end

local function wrapped(t, per, indent)
  local o, line = {}, {}
  for i, v in ipairs(t) do
    line[#line + 1] = tostring(v)
    if i % per == 0 then
      o[#o + 1] = indent .. table.concat(line, ", ") .. ","
      line = {}
    end
  end
  if #line > 0 then o[#o + 1] = indent .. table.concat(line, ", ") .. "," end
  return table.concat(o, "\n")
end

local function variant(room, engine)
  local tiles, ts = tilesFor(room, engine)
  if not tiles then return "" end
  local flat = {}
  for i = 1, 16 do flat[i] = room.def.borderTile end
  local b = { "              { " .. list(flat) .. " },   -- 0: the border block" }
  local c = { "              { 0x07, 0x07, 0x07, 0x07 }," }
  for n, row in ipairs(tiles) do
    b[#b + 1] = "              { " .. list(row) .. " },"
    c[#c + 1] = "              { " .. list(room.coll[n], "0x%02X") .. " },"
  end
  return table.concat({
    ("          %s = {"):format(engine),
    ('            image = "%s",'):format(ts.image),
    ("            imageWidth = %d, imageHeight = %d, tilesPerRow = %d,")
      :format(ts.imageWidth, ts.imageHeight, ts.tilesPerRow),
    "            border = 0,",
    "            tilePalettes = {",
    wrapped(ts.tilePalettes, 20, "              "),
    "            },",
    "            blocks = {",
    table.concat(b, "\n"),
    "            },",
    "            collision = {",
    table.concat(c, "\n"),
    "            },",
    "          },",
  }, "\n")
end

local function actorsText(room)
  local d = room.def
  if not d.actors then return nil end
  local o = { "      actors = {" }
  for _, a in ipairs(d.actors) do
    local id = room.grid[math.floor(a.y / 2) * d.width + math.floor(a.x / 2) + 1]
    local byte = room.coll[id][(a.y % 2) * 2 + (a.x % 2) + 1]
    if byte == SOLID then
      warn("%s: %s at (%d,%d) stands in a wall", d.id, a.name, a.x, a.y)
    end
    o[#o + 1] = ('        { name = "%s", marker = "%s",'):format(a.name, a.marker)
    o[#o + 1] = ('          sprite = "%s", x = %d, y = %d, movement = %d },')
      :format(a.sprite, a.x, a.y, a.movement)
  end
  o[#o + 1] = "      },"
  return table.concat(o, "\n")
end

local function roomText(room, which)
  local d = room.def
  local w = {}
  for _, p in ipairs(d.warps) do
    w[#w + 1] = ('        { x = %d, y = %d, destMap = "%s", destWarp = 1 },')
      :format(p[1], p[2], d.warpTo)
  end
  local grid = {}
  for y = 0, d.height - 1 do
    local row = {}
    for x = 0, d.width - 1 do row[#row + 1] = room.grid[y * d.width + x + 1] end
    grid[#grid + 1] = "        " .. table.concat(row, ", ") .. ","
  end
  local parts = {
    ("    %s = {"):format(which),
    ('      id = "%s",'):format(d.id),
    "      warps = {", table.concat(w, "\n"), "      },",
    ('      label = "%s",'):format(d.label),
    ('      song = "%s",'):format(d.song),
    '      palette = "PALETTE_DAY",',
    ("      width = %d, height = %d,"):format(d.width, d.height),
    ("      arrival = { x = %d, y = %d },"):format(d.arrival.x, d.arrival.y),
    "      tiles = {",
    ('        id = "%s",'):format(d.tilesId),
    ('        source = "%s",'):format(d.source),
    "        variants = {",
    variant(room, "gs"),
    variant(room, "crystal"),
    "        },",
    "      },",
    "      blocks = {",
    table.concat(grid, "\n"),
    "      },",
  }
  local a = actorsText(room)
  if a then parts[#parts + 1] = a end
  parts[#parts + 1] = "    },"
  return table.concat(parts, "\n")
end

for _, key in ipairs(arg) do
  local town = assert(TOWNS[key], "no such town: " .. tostring(key))
  town.lobby.actors = LOBBY_ACTORS
  local lobby, stage = readRoom(town.lobby), readRoom(town.stage)
  print(("  %s = {"):format(key))
  print(('    rank = "%s",'):format(town.rank))
  print(roomText(lobby, "lobby"))
  print(roomText(stage, "stage"))
  print("  },")
  note("%s: lobby %d block(s), stage %d block(s)", key, #lobby.blocks, #stage.blocks)
end
io.stderr:write(warnings .. " warning(s)\n")
os.exit(warnings == 0 and 0 or 1)
