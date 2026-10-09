-- ============================================================
-- Naxxramas Loot Ledger
-- Core/ItemSearch.lua
-- ============================================================

local NLL = NaxxLootLottery
NLL.ItemSearch = NLL.ItemSearch or {}
local Search = NLL.ItemSearch

Search.results = {}
Search.initialized = false
Search.selectedRaidKey = nil

function Search:Initialize()
    self.initialized = true
    self.results = {}
    self.selectedRaidKey = nil
end

function Search:SetRaid(raidKey)
    if raidKey == "MOLTEN_CORE" then
        self.selectedRaidKey = raidKey
        self:Search("")
        return true
    end

    self.selectedRaidKey = nil
    self.results = {}
    return false
end

function Search:GetSelectedRaid()
    return self.selectedRaidKey
end

function Search:ExtractItemID(text)
    if not text then
        return nil
    end

    local linkedID = string.match(text, "item:(%d+)")
    if linkedID then
        return tonumber(linkedID)
    end

    local trimmed = string.match(text, "^%s*(.-)%s*$") or ""
    if string.match(trimmed, "^%d+$") then
        return tonumber(trimmed)
    end

    return nil
end

function Search:Search(query)
    self.results = {}

    if self.selectedRaidKey ~= "MOLTEN_CORE" then
        return self.results
    end

    local MC = NLL.Data and NLL.Data.MoltenCore
    if not MC then
        return self.results
    end

    query = query or ""
    query = string.match(query, "^%s*(.-)%s*$") or ""

    local itemID = self:ExtractItemID(query)
    local lowerQuery = string.lower(query)

    local items = MC:GetItems()

    for i = 1, #items do
        local item = items[i]
        local matched = false

        if query == "" then
            matched = true
        elseif itemID then
            matched = item.itemID == itemID
        else
            local lowerName = string.lower(item.name)
            if string.find(lowerName, lowerQuery, 1, true) then
                matched = true
            end
        end

        if matched then
            table.insert(self.results, item)
        end
    end

    return self.results
end

function Search:GetResults()
    return self.results
end

function Search:GetPlayerName()
    local name = UnitName("player")
    return name or "Unknown"
end

function Search:IsReserved(itemID)
    return NLL.Database:IsLocallyReserved(
        self:GetPlayerName(),
        "MOLTEN_CORE",
        itemID
    )
end

function Search:ToggleReservation(itemID)
    local playerName = self:GetPlayerName()
    local current = NLL.Database:IsLocallyReserved(
        playerName,
        "MOLTEN_CORE",
        itemID
    )

    NLL.Database:SetLocalReservation(
        playerName,
        "MOLTEN_CORE",
        itemID,
        not current
    )

    if NLL.UI and NLL.UI.RefreshSearchPanel then
        NLL.UI:RefreshSearchPanel()
    end
end

function Search:GetReservationCount()
    return NLL.Database:GetLocalReservationCount(
        self:GetPlayerName(),
        "MOLTEN_CORE"
    )
end
