-- Embeddable credits screen. Copy this file unchanged into each mod.
-- Increment on every library change, including drawing/layout changes.
local LIB_VERSION = 2
local ROW_ID = "credits:book"
local Credits = {}

function Credits.attach(mod, initialEntries)
  local Font = mod.ui.Font
  local registered, registrationOrder = {}, {}
  local contributions = setmetatable({}, { __mode = "k" })
  local syncRow
  local VISIBLE, TOP, STEP = 10, 24, 10

  local function optionalString(value)
    return type(value) == "string" and value ~= "" and value or nil
  end
  local function union(target, values)
    local seen = {}
    for _, value in ipairs(target) do seen[value] = true end
    if type(values) == "table" then
      for _, value in ipairs(values) do
        if optionalString(value) and not seen[value] then
          target[#target + 1], seen[value] = value, true
        end
      end
    end
  end
  local function copyEntry(entry)
    if type(entry) ~= "table" or not optionalString(entry.artist)
      or not entry.artist:find("%S") then return nil end
    local result = { artist = entry.artist, works = {}, mods = {},
      source = optionalString(entry.source), note = optionalString(entry.note) }
    union(result.works, entry.works)
    union(result.mods, entry.mods)
    return result
  end

  local function copyEntries(entries)
    local copies = {}
    if type(entries) == "table" then
      for _, entry in ipairs(entries) do
        local copy = copyEntry(entry)
        if copy then copies[#copies + 1] = copy end
      end
    end
    return copies
  end
  local baked = copyEntries(initialEntries)

  -- Owns this API and transient registrations, no save fields. Copy callers'
  -- tables so later mutation cannot change the next book unexpectedly.
  local function registerCredits(modId, entries)
    if not optionalString(modId) or type(entries) ~= "table" then return false end
    local copies = {}
    for _, entry in ipairs(entries) do
      local copy = copyEntry(entry)
      if copy then copies[#copies + 1] = copy end
    end
    if not registered[modId] then registrationOrder[#registrationOrder + 1] = modId end
    registered[modId] = copies
    -- Refresh a menu already assembled but not yet selected. Open screens
    -- retain their own snapshot, matching the runtime API in 0.1.0.
    for row in pairs(contributions) do syncRow(row) end
    return true
  end
  local function mergedEntries(rawEntries)
    local entries, byArtist = {}, {}
    local function add(list)
      for _, entry in ipairs(list) do
        local existing = byArtist[entry.artist]
        if existing then
          union(existing.works, entry.works)
          union(existing.mods, entry.mods)
          existing.source = existing.source or entry.source
          existing.note = existing.note or entry.note
        else
          local copy = copyEntry(entry)
          entries[#entries + 1], byArtist[copy.artist] = copy, copy
        end
      end
    end
    add(copyEntries(rawEntries))
    table.sort(entries, function(a, b)
      local al, bl = a.artist:lower(), b.artist:lower()
      if al == bl then return a.artist < b.artist end
      return al < bl
    end)
    return entries
  end
  local function display(text)
    text = text:gsub("%%", " percent "):gsub("%+", " plus "):gsub("%s+", " ")
    local out = {}
    for _, span in ipairs(Font.split(text)) do
      out[#out + 1] = span.code and text:sub(span.from, span.to) or "?"
    end
    return table.concat(out)
  end
  local function prefix(text)
    local spans = Font.split(text)
    local count = math.min(18, Font.spansFitting(spans, 144))
    return count > 0 and spans[count].to or 0
  end
  local function wrap(rows, text, artistIndex)
    text = display(text):match("^%s*(.-)%s*$")
    while #text > 0 do
      local cut = prefix(text)
      -- A custom glyph wider than the whole panel cannot supply a line.
      if cut == 0 then break end
      if cut < #text then
        local space = text:sub(1, cut + 1):match("^.*() ")
        if space and space > 1 then cut = space - 1 end
      end
      rows[#rows + 1] = { text = text:sub(1, cut), artist = artistIndex }
      text = text:sub(cut + 1):gsub("^%s+", "")
    end
  end
  local function buildRows(entries)
    local rows = {}
    for i, entry in ipairs(entries) do
      if i > 1 then rows[#rows + 1] = { rule = true, artist = i } end
      wrap(rows, entry.artist, i)
      if #entry.works > 0 then wrap(rows, table.concat(entry.works, ", "), i) end
      if #entry.mods > 0 then wrap(rows, "IN: " .. table.concat(entry.mods, ", "), i) end
      if entry.note then wrap(rows, entry.note, i) end
    end
    return rows
  end
  local function open(game, rawEntries)
    local entries = mergedEntries(rawEntries)
    local rows = buildRows(entries)
    local pages = math.max(1, math.ceil(#rows / VISIBLE))
    local state = { isOpaque = true, offset = 0 }
    function state:update(_dt)
      local input = game.input
      if input:wasPressed("b") then game.stack:pop()
      elseif input:wasPressed("up") then self.offset = math.max(0, self.offset - 1)
      elseif input:wasPressed("down") then
        self.offset = math.min((pages - 1) * VISIBLE, self.offset + 1)
      end
    end
    -- Trainer Journey's rule/rightText/header idiom, using public surfaces:
    -- ModUI exposes Font and Theme, but does not expose Gen 2 Chrome.
    local function rule(y)
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.rectangle("fill", 4, y, 152, 1)
    end
    local function rightText(text, y)
      Font.draw(text, 156 - Font.width(text), y)
    end
    function state:draw()
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 0, 0, 160, 144)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw("CREDITS", 4, 4)
      rightText(tostring(math.floor(self.offset / VISIBLE) + 1) .. "/" .. pages, 4)
      rule(17)
      for i = 1, VISIBLE do
        local row = rows[self.offset + i]
        if row then
          local y = TOP + (i - 1) * STEP
          if row.rule then rule(y + 4) else Font.draw(row.text, 12, y) end
        end
      end
      Font.drawCode(mod.ui.Theme.cursor, 4, TOP)
      rule(127)
      Font.draw("B:CLOSE", 4, 136)
      local current = rows[self.offset + 1]
      rightText(tostring(current and current.artist or 0) .. "/" .. #entries, 136)
      love.graphics.setColor(1, 1, 1, 1)
    end
    game.stack:push(state)
  end
  -- Each row owns one flat shared list. Remember only our contribution's
  -- object identities, so re-running a hook or runtime registration replaces
  -- our entries without removing another embedded copy's entries.
  syncRow = function(row)
    local shared = row.creditsEntries
    local previous = contributions[row] or {}
    for i = #shared, 1, -1 do
      if previous[shared[i]] then table.remove(shared, i) end
    end
    local owned = {}
    local function append(entries)
      for _, entry in ipairs(copyEntries(entries)) do
        shared[#shared + 1], owned[entry] = entry, true
      end
    end
    append(baked)
    for _, id in ipairs(registrationOrder) do append(registered[id]) end
    contributions[row] = owned
  end

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local rows = next(game, items)
    if type(rows) ~= "table" then return rows end
    local row
    for _, candidate in ipairs(rows) do
      if candidate.id == ROW_ID then row = candidate; break end
    end
    if not row then
      row = { id = ROW_ID, label = "CREDITS",
        desc = { "Artists and", "their work" }, creditsEntries = {} }
      rows[#rows + 1] = row
    end
    if not row.creditsLib or row.creditsLib < LIB_VERSION then
      row.creditsLib = LIB_VERSION
      row.onSelect = function()
        local top = game.stack:top()
        if top and top.items and top.onClose then top:close() end
        -- Read the shared list at selection, after every hook has appended.
        if not game.stack:top() then open(game, row.creditsEntries) end
      end
    end
    syncRow(row)
    return rows
  end)
  -- Optional return used by Credits Book to preserve its runtime API.
  -- Ordinary embedding callers only need attach(mod, theirEntries).
  return registerCredits
end

return Credits
