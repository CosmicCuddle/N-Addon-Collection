-- ============================================================
-- Naxxramas Loot Ledger
-- Core/GearNeeds.lua
--
-- Phase 4 persistent Gear Need model.
--
-- A Gear Need records:
--   Character
--   ItemID
--   Raid
--   Role
--   Status
--   Source
--   Character Type
--
-- Source and Character Type are deliberately separate concepts.
-- ============================================================

local NLL = NaxxLootLottery

NLL.GearNeeds = NLL.GearNeeds or {}
local GearNeeds = NLL.GearNeeds

GearNeeds.validStatuses = {
    NEEDED = true,
    OBTAINED = true,
    DISABLED = true
}

GearNeeds.validSources = {
    RAID_LEADER_MANUAL = true,
    BOT_GEAR_PLAN = true,
    PLAYER_SUBMITTED = true
}

GearNeeds.validCharacterTypes = {
    PLAYER = true,
    PLAYERBOT = true,
    UNKNOWN = true
}

function GearNeeds:Initialize()
    self.initialized = true
end

function GearNeeds:Trim(text)
    text = tostring(text or "")
    return string.match(text, "^%s*(.-)%s*$") or ""
end

function GearNeeds:NormalizeCharacterName(name)
    return string.lower(self:Trim(name))
end

function GearNeeds:MakeKey(characterName, raidKey, itemID, source)
    return
        self:NormalizeCharacterName(characterName) ..
        "|" ..
        tostring(raidKey or "") ..
        "|" ..
        tostring(tonumber(itemID) or 0) ..
        "|" ..
        tostring(source or "")
end

function GearNeeds:IsValidStatus(status)
    return self.validStatuses[status] == true
end

function GearNeeds:IsValidSource(source)
    return self.validSources[source] == true
end

function GearNeeds:IsValidCharacterType(characterType)
    return self.validCharacterTypes[characterType] == true
end

function GearNeeds:GetCount()
    local count = 0

    if not NLL.db or type(NLL.db.gearNeeds) ~= "table" then
        return 0
    end

    for key, need in pairs(NLL.db.gearNeeds) do
        if type(need) == "table" then
            count = count + 1
        end
    end

    return count
end

function GearNeeds:GetNeed(key)
    if not NLL.db or not key then
        return nil
    end

    return NLL.db.gearNeeds[key]
end

function GearNeeds:AddNeed(
    characterName,
    itemID,
    raidKey,
    role,
    status,
    source,
    characterType
)
    characterName = self:Trim(characterName)
    itemID = tonumber(itemID)
    raidKey = raidKey or "MOLTEN_CORE"
    status = status or "NEEDED"
    source = source or "RAID_LEADER_MANUAL"
    characterType = characterType or "UNKNOWN"

    if characterName == "" then
        return false, "Character name is required."
    end

    if not itemID then
        return false, "A valid Item ID is required."
    end

    if role ~= nil and not NLL:IsValidRole(role) then
        return false, "Invalid role."
    end

    if not self:IsValidStatus(status) then
        return false, "Invalid Gear Need status."
    end

    if not self:IsValidSource(source) then
        return false, "Invalid Gear Need source."
    end

    if not self:IsValidCharacterType(characterType) then
        return false, "Invalid character type."
    end

    local item =
        NLL.Data
        and NLL.Data.MoltenCore
        and NLL.Data.MoltenCore:GetItem(itemID)

    if raidKey == "MOLTEN_CORE" and not item then
        return false, "That Item ID is not in the Molten Core database."
    end

    local key =
        self:MakeKey(characterName, raidKey, itemID, source)

    local need = NLL.db.gearNeeds[key]

    if type(need) ~= "table" then
        need = {}
        NLL.db.gearNeeds[key] = need
    end

    need.key = key
    need.character = characterName
    need.itemID = itemID
    need.raid = "Molten Core"
    need.raidKey = raidKey
    need.role = role
    need.status = status
    need.source = source
    need.characterType = characterType

    NLL.Database:SetCharacterType(
        characterName,
        characterType
    )

    if role ~= nil then
        NLL.Database:SetRoleAssignment(
            characterName,
            role,
            nil
        )
    end

    NLL:Debug(
        "Gear Need saved: " ..
        characterName ..
        " / " ..
        tostring(itemID) ..
        " / " ..
        source
    )

    return true, need
end

function GearNeeds:RemoveNeed(key)
    if not key or not NLL.db then
        return false
    end

    if NLL.db.gearNeeds[key] then
        NLL.db.gearNeeds[key] = nil
        return true
    end

    return false
end

function GearNeeds:SetStatus(key, status)
    if not self:IsValidStatus(status) then
        return false
    end

    local need = self:GetNeed(key)
    if not need then
        return false
    end

    need.status = status
    return true
end

function GearNeeds:GetAllNeeds(characterFilter)
    local output = {}
    local normalizedFilter = self:NormalizeCharacterName(characterFilter)

    if not NLL.db or type(NLL.db.gearNeeds) ~= "table" then
        return output
    end

    for key, need in pairs(NLL.db.gearNeeds) do
        if type(need) == "table" then
            local include = true

            if normalizedFilter ~= "" then
                local normalizedName =
                    self:NormalizeCharacterName(need.character)

                if not string.find(
                    normalizedName,
                    normalizedFilter,
                    1,
                    true
                ) then
                    include = false
                end
            end

            if include then
                need.key = key
                table.insert(output, need)
            end
        end
    end

    table.sort(output, function(a, b)
        local aName = string.lower(a.character or "")
        local bName = string.lower(b.character or "")

        if aName ~= bName then
            return aName < bName
        end

        local aItem =
            NLL.Data.MoltenCore:GetItem(a.itemID)
        local bItem =
            NLL.Data.MoltenCore:GetItem(b.itemID)

        local aItemName = aItem and aItem.name or tostring(a.itemID)
        local bItemName = bItem and bItem.name or tostring(b.itemID)

        return string.lower(aItemName) < string.lower(bItemName)
    end)

    return output
end

function GearNeeds:GetNeedsForItem(itemID, status)
    local output = {}
    itemID = tonumber(itemID)

    for key, need in pairs(NLL.db.gearNeeds) do
        if type(need) == "table"
            and need.itemID == itemID
            and (status == nil or need.status == status) then

            need.key = key
            table.insert(output, need)
        end
    end

    return output
end

function GearNeeds:ResolveItem(text)
    text = self:Trim(text)

    if text == "" then
        return nil, "Enter an item name, Item ID, or item link."
    end

    local itemID = NLL.ItemSearch:ExtractItemID(text)

    if itemID then
        local item = NLL.Data.MoltenCore:GetItem(itemID)

        if item then
            return item
        end

        return nil, "That Item ID is not in the Molten Core database."
    end

    local lowerText = string.lower(text)
    local exact = nil
    local partialMatches = {}

    local items = NLL.Data.MoltenCore:GetItems()

    for i = 1, #items do
        local item = items[i]
        local lowerName = string.lower(item.name)

        if lowerName == lowerText then
            exact = item
            break
        end

        if string.find(lowerName, lowerText, 1, true) then
            table.insert(partialMatches, item)
        end
    end

    if exact then
        return exact
    end

    if #partialMatches == 1 then
        return partialMatches[1]
    end

    if #partialMatches > 1 then
        return nil,
            "More than one item matches. Use a more complete name or Item ID."
    end

    return nil, "No Molten Core item matched that search."
end


-- ============================================================
-- PHASE 5 PLAYER-SUBMITTED MERGE RULES
-- ============================================================

function GearNeeds:RemovePlayerSubmittedForRaid(
    characterName,
    raidKey
)
    local normalized =
        self:NormalizeCharacterName(characterName)

    local removeKeys = {}

    for key, need in pairs(NLL.db.gearNeeds) do
        if type(need) == "table"
            and self:NormalizeCharacterName(
                need.character
            ) == normalized
            and need.raidKey == raidKey
            and need.source == "PLAYER_SUBMITTED" then

            table.insert(removeKeys, key)
        end
    end

    for i = 1, #removeKeys do
        NLL.db.gearNeeds[removeKeys[i]] = nil
    end
end

function GearNeeds:HasOtherSourceNeed(
    characterName,
    raidKey,
    itemID
)
    local normalized =
        self:NormalizeCharacterName(characterName)

    for key, need in pairs(NLL.db.gearNeeds) do
        if type(need) == "table"
            and self:NormalizeCharacterName(
                need.character
            ) == normalized
            and need.raidKey == raidKey
            and need.itemID == tonumber(itemID)
            and need.source ~= "PLAYER_SUBMITTED" then

            return true, need
        end
    end

    return false, nil
end

function GearNeeds:ReplacePlayerSubmitted(
    characterName,
    raidKey,
    itemIDs
)
    raidKey = raidKey or "MOLTEN_CORE"

    self:RemovePlayerSubmittedForRaid(
        characterName,
        raidKey
    )

    local role =
        NLL.Database:GetRoleAssignment(
            characterName
        )

    local added = 0
    local conflicts = 0

    for i = 1, #itemIDs do
        local itemID = tonumber(itemIDs[i])

        if itemID then
            local conflict =
                self:HasOtherSourceNeed(
                    characterName,
                    raidKey,
                    itemID
                )

            if conflict then
                conflicts = conflicts + 1
            end

            local ok =
                self:AddNeed(
                    characterName,
                    itemID,
                    raidKey,
                    role,
                    "NEEDED",
                    "PLAYER_SUBMITTED",
                    "PLAYER"
                )

            if ok then
                added = added + 1
            end
        end
    end

    return added, conflicts
end
