-- ============================================================
-- Naxxramas Loot Ledger
-- Storage/Database.lua
-- ============================================================

local NLL = NaxxLootLottery
NLL.Database = NLL.Database or {}
local Database = NLL.Database

function Database:Initialize()
    if type(NaxxLootLotteryDB) ~= "table" then
        NaxxLootLotteryDB = {}
    end

    local db = NaxxLootLotteryDB

    if type(db.version) ~= "number" then
        db.version = NLL.databaseVersion
    end

    if type(db.settings) ~= "table" then
        db.settings = {}
    end

    if db.settings.debug == nil then
        db.settings.debug = false
    end

    -- Direct real loot transfer must be opted into EACH LOGIN/reload.
    -- Do not persist a previous enabled flag across client restarts.
    db.settings.directMasterLootEnabled = false

    -- One-click, reversible preset library. Never bulk-overwrites guild rules.
    -- Disabled for all preexisting users until they opt in on Priority Setup.
    if type(db.settings.priorityPresetsEnabled) ~= "boolean" then
        db.settings.priorityPresetsEnabled = false
    end

    -- v0.1.0.5 renames the old CLASSIC placeholder skin to
    -- VANILLA and upgrades it to a parchment-style Blizzard UI.
    if db.settings.skin == "CLASSIC" then
        db.settings.skin = "VANILLA"
    end

    if db.settings.skin ~= "DARK"
        and db.settings.skin ~= "VANILLA" then

        db.settings.skin = "DARK"
    end

    if type(db.characters) ~= "table" then
        db.characters = {}
    end

    if type(db.gearNeeds) ~= "table" then
        db.gearNeeds = {}
    end

    if type(db.gearNeedsSchema) ~= "number" then
        db.gearNeedsSchema = 1
    end

    if type(db.roleAssignments) ~= "table" then
        db.roleAssignments = {}
    end

    if type(db.history) ~= "table" then
        db.history = {}
    end

    if type(db.raidSession) ~= "table" then
        db.raidSession = {}
    end

    if type(db.raidSession.currentLoot) ~= "table" then
        db.raidSession.currentLoot = {}
    end
    if type(db.lotteryHistory) ~= "table" then
        db.lotteryHistory = {}
    end
    if type(db.lootAwardHistory) ~= "table" then
        db.lootAwardHistory = {}
    end
    if type(db.candidateAudit) ~= 'table' then
        db.candidateAudit = {}
    end
    if type(db.raidSession.lootGeneration) ~= "number" then
        db.raidSession.lootGeneration = 0
    end

    -- Phase 3 local pre-submission selections.
    -- Phase 4 will build the fuller wishlist editor around this.
    if type(db.localWishlists) ~= "table" then
        db.localWishlists = {}
    end

    if type(db.submissionInbox) ~= "table" then
        db.submissionInbox = {}
    end

    if type(db.priorityRules) ~= "table" then
        db.priorityRules = {}
    end

    if type(db.priorityRules.MOLTEN_CORE) ~= "table" then
        db.priorityRules.MOLTEN_CORE = {}
    end

    NLL.db = db
end

function Database:UpdateCharacterFromRoster(member)
    if not member or not member.name or not NLL.db then
        return
    end

    local character = NLL.db.characters[member.name]
    if type(character) ~= "table" then
        character = {}
        NLL.db.characters[member.name] = character
    end

    character.name = member.name
    character.class = member.classFile
    character.className = member.className
    character.level = member.level

    if character.characterType == nil then
        character.characterType = "UNKNOWN"
    end
end

function Database:GetRoleAssignment(name)
    if not name or not NLL.db then
        return nil
    end

    local entry = NLL.db.roleAssignments[name]

    if type(entry) == "string" then
        if NLL:IsValidRole(entry) then
            return entry
        end
        return nil
    end

    if type(entry) == "table" and NLL:IsValidRole(entry.role) then
        return entry.role
    end

    return nil
end

function Database:SetRoleAssignment(name, roleID, member)
    if not name or name == "" or not NLL.db then
        return false
    end

    if roleID == nil then
        NLL.db.roleAssignments[name] = nil
        return true
    end

    if not NLL:IsValidRole(roleID) then
        return false
    end

    local entry = NLL.db.roleAssignments[name]
    if type(entry) ~= "table" then
        entry = {}
        NLL.db.roleAssignments[name] = entry
    end

    entry.role = roleID

    if member then
        entry.class = member.classFile
        entry.className = member.className
    end

    return true
end


function Database:GetCharacterClass(name)
    if not name
        or name == ""
        or not NLL.db then

        return nil, nil
    end

    local function Normalize(value)
        value = tostring(value or "")
        value =
            string.match(
                value,
                "^([^%-]+)"
            )
            or value

        return string.lower(value)
    end

    local wanted =
        Normalize(name)

    local direct =
        NLL.db.characters[name]

    if type(direct) == "table" then
        return direct.class,
            direct.className
    end

    for characterName, character
        in pairs(
            NLL.db.characters
        ) do

        if type(character) == "table"
            and Normalize(characterName)
                == wanted then

            return character.class,
                character.className
        end
    end

    local roleEntry =
        NLL.db.roleAssignments[name]

    if type(roleEntry) == "table" then
        return roleEntry.class,
            roleEntry.className
    end

    return nil, nil
end

function Database:GetLocalWishlist(characterName, raidKey)
    if not characterName or not raidKey or not NLL.db then
        return nil
    end

    if type(NLL.db.localWishlists[characterName]) ~= "table" then
        NLL.db.localWishlists[characterName] = {}
    end

    if type(NLL.db.localWishlists[characterName][raidKey]) ~= "table" then
        NLL.db.localWishlists[characterName][raidKey] = {}
    end

    return NLL.db.localWishlists[characterName][raidKey]
end

function Database:IsLocallyReserved(characterName, raidKey, itemID)
    local wishlist = self:GetLocalWishlist(characterName, raidKey)
    return wishlist and wishlist[itemID] == true
end

function Database:SetLocalReservation(characterName, raidKey, itemID, wanted)
    local wishlist = self:GetLocalWishlist(characterName, raidKey)
    if not wishlist then
        return false
    end

    if wanted then
        wishlist[itemID] = true
    else
        wishlist[itemID] = nil
    end

    return true
end

function Database:GetLocalReservationCount(characterName, raidKey)
    local wishlist = self:GetLocalWishlist(characterName, raidKey)
    local count = 0

    if wishlist then
        for itemID, wanted in pairs(wishlist) do
            if wanted then
                count = count + 1
            end
        end
    end

    return count
end


-- ============================================================
-- PHASE 4 CHARACTER / GEAR PLAN HELPERS
-- ============================================================

function Database:SetCharacterType(name, characterType)
    if not name or name == "" or not NLL.db then
        return false
    end

    local character = NLL.db.characters[name]
    if type(character) ~= "table" then
        character = {
            name = name
        }
        NLL.db.characters[name] = character
    end

    character.characterType = characterType
    return true
end

function Database:GetCharacterType(name)
    if not name or not NLL.db then
        return "UNKNOWN"
    end

    local character = NLL.db.characters[name]
    if type(character) == "table" and character.characterType then
        return character.characterType
    end

    return "UNKNOWN"
end
