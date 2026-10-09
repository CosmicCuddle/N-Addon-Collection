-- ============================================================
-- Naxxramas Loot Ledger
-- Core/NeedMatcher.lua
--
-- Phase 7: match a detected drop against authoritative NEEDED
-- Gear Needs. This does NOT apply priority or run a lottery.
-- ============================================================

local NLL = NaxxLootLottery
NLL.NeedMatcher = NLL.NeedMatcher or {}
local Matcher = NLL.NeedMatcher

local function NormalizeName(name)
    name = tostring(name or "")
    name = string.match(name, "^([^%-]+)") or name
    return string.lower(name)
end

function Matcher:Initialize()
    self.initialized = true
end

function Matcher:FindRaidMember(characterName)
    local wanted = NormalizeName(characterName)
    local members = NLL.Roster:GetMembers() or {}

    for i = 1, #members do
        local member = members[i]

        if NormalizeName(member.name) == wanted then
            return member
        end
    end

    return nil
end

function Matcher:GetMatchesForItem(itemID)
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        if tonumber(itemID) == NLL.DebugSimulator.active.itemID then
            return NLL.DebugSimulator:FakeMatches()
        end
        return {}
    end
    local needs =
        NLL.GearNeeds:GetNeedsForItem(
            tonumber(itemID),
            "NEEDED"
        )

    local merged = {}

    for i = 1, #needs do
        local need = needs[i]

        if need.raidKey == "MOLTEN_CORE" then
            local key = NormalizeName(need.character)

            if key ~= "" then
                local match = merged[key]

                if not match then
                    match = {
                        character = need.character,
                        role = need.role,
                        characterType =
                            need.characterType
                            or "UNKNOWN",
                        sources = {},
                        sourceSeen = {}
                    }

                    merged[key] = match
                end

                if not match.role and need.role then
                    match.role = need.role
                end

                if match.characterType == "UNKNOWN"
                    and need.characterType then

                    match.characterType =
                        need.characterType
                end

                if need.source
                    and not match.sourceSeen[need.source] then

                    match.sourceSeen[need.source] = true
                    table.insert(
                        match.sources,
                        need.source
                    )
                end
            end
        end
    end

    local output = {}

    for key, match in pairs(merged) do
        local member =
            self:FindRaidMember(
                match.character
            )

        match.inRaid = member ~= nil
        match.online =
            member ~= nil
            and member.online ~= false

        match.dead =
            member ~= nil
            and member.isDead == true

        match.eligiblePresence =
            match.inRaid
            and match.online

        match.role =
            match.role
            or NLL.Database:GetRoleAssignment(
                match.character
            )

        match.roleLabel =
            NLL:GetRoleLabel(
                match.role
            )

        -- Some custom Playerbot roster rows can omit the class file.
        -- Prefer live roster data, falling back to a saved known class.
        local savedClass, savedClassName =
            NLL.Database:GetCharacterClass(match.character)
        match.classFile = (member and member.classFile) or savedClass
        match.className = (member and member.className) or savedClassName

        match.classLabel =
            NLL:GetClassLabel(
                match.classFile
            )

        table.insert(output, match)
    end

    table.sort(
        output,
        function(a, b)
            if a.eligiblePresence
                ~= b.eligiblePresence then

                return a.eligiblePresence
            end

            return
                string.lower(a.character or "")
                < string.lower(b.character or "")
        end
    )

    return output
end

function Matcher:GetEligibleMatchesForItem(itemID)
    local all = self:GetMatchesForItem(itemID)
    local eligible = {}

    for i = 1, #all do
        if all[i].eligiblePresence then
            table.insert(eligible, all[i])
        end
    end

    return eligible
end
