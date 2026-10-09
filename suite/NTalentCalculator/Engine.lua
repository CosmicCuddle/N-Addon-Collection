-- N Talent Calculator - offline planner for WoW 3.3.5a / Lua 5.1
-- Uses the same approved custom DBC data and NT1 share codes as the website.
-- This never allocates character talents, casts spells or edits server data.

NTalentCalculator = NTalentCalculator or {}
local M = NTalentCalculator
M.Data = NTalentCalculatorData
M.ERA = {
    vanilla = {title="Vanilla", level=60, maxRow=6},
    tbc = {title="The Burning Crusade", level=70, maxRow=8},
    wotlk = {title="Wrath of the Lich King", level=80, maxRow=10}
}
M.CLASS_ORDER = {
    "warrior", "paladin", "hunter", "rogue", "priest", "deathknight",
    "shaman", "mage", "warlock", "druid"
}
M.OFF_CENTRE = {
    vanilla = {[263]=901, [302]=1022},
    tbc = {[382]=1747}
}
M.era = nil    -- unknown until authoritative IP response or completed quests
M.tier = nil
M.class = nil
M.level = 60
M.points = {}
M.lastError = nil

local function KeyClass(value)
    value = string.lower(value or "")
    value = value:gsub("[^a-z]", "")
    return value
end

function M:PlayerClass()
    if type(UnitClass) ~= "function" then return "warrior" end
    local _, class = UnitClass("player")
    local value = KeyClass(class)
    return self.Data and self.Data.classes[value] and value or "warrior"
end

function M:Initialize()
    if not self.Data or not self.Data.classes then
        self:Print("No approved server talent data available.")
        return false
    end
    self.class = self:PlayerClass()
    self.points = {}
    if type(NTalentCalculatorDB) ~= "table" then
        NTalentCalculatorDB = { builds = {} }
    end
    if type(NTalentCalculatorDB.builds) ~= "table" then
        NTalentCalculatorDB.builds = {}
    end
    return true
end

function M:Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffE6C35CN Talents:|r " .. tostring(message))
    end
end

function M:GetTrees(class)
    return self.Data and self.Data.classes and self.Data.classes[class or self.class] or nil
end

function M:FindTalent(id, class)
    for _, tree in ipairs(self:GetTrees(class) or {}) do
        for _, talent in ipairs(tree[4]) do
            if talent[1] == id then return talent, tree end
        end
    end
end

function M:Available(talent, tree, era)
    era = era or self.era
    if not talent or not tree or not self.ERA[era] then return false end
    local maxRow = self.ERA[era].maxRow
    if talent[2] < maxRow then return true end
    if talent[2] > maxRow then return false end
    if era == "wotlk" then return true end
    local capstone = self.OFF_CENTRE[era][tree[1]]
    if capstone then return talent[1] == capstone end
    return talent[3] == 1
end

function M:LevelCap(era)
    return self.ERA[era or self.era] and self.ERA[era or self.era].level or nil
end

function M:Spent(points)
    local total = 0
    for _, count in pairs(points or self.points) do total = total + count end
    return total
end

function M:TreeSpent(tree, points, maxExclusiveRow)
    local count = 0
    for _, talent in ipairs(tree[4]) do
        if maxExclusiveRow == nil or talent[2] < maxExclusiveRow then
            count = count + ((points or self.points)[talent[1]] or 0)
        end
    end
    return count
end

function M:Validate(points, era, class, level)
    era = era or self.era
    class = class or self.class
    level = level or self.level
    local rules = self.ERA[era]
    if not rules then return false, "Individual Progression tier is not known yet." end
    if type(level) ~= "number" or level < 10 or level > rules.level then
        return false, "Invalid level for this progression era."
    end
    if class == "deathknight" and era ~= "wotlk" then
        return false, "Death Knights are only available in Wrath."
    end
    local trees = self:GetTrees(class)
    if not trees then return false, "Unknown class." end
    local lookup = {}
    local belonged = {}
    for _, tree in ipairs(trees) do
        for _, talent in ipairs(tree[4]) do
            lookup[talent[1]] = talent
            belonged[talent[1]] = tree
        end
    end
    local total = 0
    for id, rank in pairs(points) do
        local talent = lookup[id]
        if not talent or type(rank) ~= "number" or rank < 1
            or rank ~= math.floor(rank) or rank > #talent[4] then
            return false, "Unknown talent ID or invalid rank: " .. tostring(id)
        end
        total = total + rank
    end
    if total > level - 9 then
        return false, "This build needs " .. (total + 9) .. " character levels."
    end
    for id, rank in pairs(points) do
        if rank > 0 then
            local talent, tree = lookup[id], belonged[id]
            if not self:Available(talent, tree, era) then
                return false, talent[5] .. " is unavailable during " .. rules.title .. "."
            end
            if self:TreeSpent(tree, points, talent[2]) < talent[2] * 5 then
                return false, talent[5] .. " requires " ..
                    (talent[2] * 5) .. " points in earlier rows of " .. tree[2] .. "."
            end
            local requires = talent[7]
            if requires and requires ~= 0 then
                local prerequisite = lookup[requires]
                if not prerequisite then
                    return false, "Unresolved DBC prerequisite ID " .. requires ..
                        " for " .. talent[5] .. "."
                end
                local requiredRank = (talent[8] or 0) + 1
                if (points[requires] or 0) < requiredRank then
                    return false, talent[5] .. " requires " ..
                        prerequisite[5] .. " rank " .. requiredRank .. "."
                end
            end
        end
    end
    return true
end

function M:SetProgression(era, tier)
    if not self.ERA[era] then return false end
    local previousEra = self.era
    self.era = era
    self.tier = tier
    if previousEra ~= era then
        self.level = self.ERA[era].level
        if self.class == "deathknight" and era ~= "wotlk" then
            self.class = self:PlayerClass()
            if self.class == "deathknight" then self.class = "warrior" end
        end
        local valid = self:Validate(self.points)
        if not valid then self.points = {} end
    end
    if self.RefreshUI then self:RefreshUI() end
    return true
end

function M:SetClass(class)
    class = KeyClass(class)
    if not self:GetTrees(class) then return false, "Unknown class." end
    if class == "deathknight" and self.era ~= "wotlk" then
        return false, "Death Knights are only available in Wrath."
    end
    self.class = class
    self.points = {}
    if self.RefreshUI then self:RefreshUI() end
    return true
end

function M:Adjust(id, delta)
    if not self.era then return false, "Waiting for Individual Progression." end
    if delta ~= 1 and delta ~= -1 then return false, "Invalid rank change." end
    local talent = self:FindTalent(id)
    if not talent then return false, "Unknown talent." end
    local current = self.points[id] or 0
    local nextRank = current + delta
    if nextRank < 0 or nextRank > #talent[4] then
        return false, "This talent cannot gain or lose another rank."
    end
    local trial = {}
    for talentId, points in pairs(self.points) do trial[talentId] = points end
    if nextRank == 0 then trial[id] = nil else trial[id] = nextRank end
    local valid, reason = self:Validate(trial)
    if not valid then return false, reason end
    self.points = trial
    if self.RefreshUI then self:RefreshUI() end
    return true
end

local ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz"
local function Base36(value)
    if value == 0 then return "0" end
    local digits = ""
    while value > 0 do
        local remaining = value % 36
        digits = ALPHABET:sub(remaining+1, remaining+1) .. digits
        value = math.floor(value / 36)
    end
    return digits
end

function M:ExportCode()
    if not self.era or not self.class then return nil end
    local ids = {}
    for id, rank in pairs(self.points) do
        if rank > 0 then ids[#ids+1] = id end
    end
    table.sort(ids)
    local chunks = {}
    for _, id in ipairs(ids) do
        chunks[#chunks+1] = Base36(id) .. "-" .. self.points[id]
    end
    return "NT1:" .. self.era .. ":" .. self.class .. ":" ..
        table.concat(chunks, ".")
end

function M:ImportCode(value)
    if type(value) ~= "string" or #value > 2000 then
        return false, "Invalid or excessively long code."
    end
    local era, class, body = value:match("^NT1:([^:]+):([^:]+):(.*)$")
    if not self.ERA[era] or not self:GetTrees(class) or
        (body and body:find(":", 1, true)) then
        return false, "Expected a valid NT1:era:class:talents code."
    end
    if not self.era then return false, "Waiting for Individual Progression." end
    if era ~= self.era then
        return false, "This is a " .. self.ERA[era].title ..
            " build. Your progression currently allows " .. self.ERA[self.era].title .. "."
    end
    local trial = {}
    if body ~= "" then
        local count = 0
        for chunk in string.gmatch(body .. ".", "(.-)%.") do
            count = count + 1
            if count > 120 then return false, "Too many talents in build code." end
            local token, rank = chunk:match("^([0-9a-z]+)%-([1-9])$")
            if not token then return false, "Invalid talent code entry." end
            local id = tonumber(token, 36)
            if not id or id <= 0 or id > 10000000 or trial[id] then
                return false, "Duplicate or invalid talent ID."
            end
            trial[id] = tonumber(rank)
        end
    end
    local valid, reason = self:Validate(trial, era, class, self.ERA[era].level)
    if not valid then return false, reason end
    self.class, self.level, self.points = class, self.ERA[era].level, trial
    if self.RefreshUI then self:RefreshUI() end
    return true
end

function M:SaveBuild(name)
    name = type(name) == "string" and name:match("^%s*(.-)%s*$") or ""
    if name == "" or #name > 50 then return false, "Use a name of 1-50 characters." end
    local code = self:ExportCode()
    if not code then return false, "Wait for Individual Progression." end
    local saves = NTalentCalculatorDB and NTalentCalculatorDB.builds
    if type(saves) ~= "table" then return false, "SavedVariables unavailable." end
    saves[name] = code
    return true
end

function M:LoadBuild(name)
    local saves = NTalentCalculatorDB and NTalentCalculatorDB.builds
    if type(saves) ~= "table" or not saves[name] then
        return false, "No saved build with that name."
    end
    return self:ImportCode(saves[name])
end
