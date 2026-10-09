-- NLL Phase 9 preparation: POST-DROP CANDIDATE PREVIEW ONLY.
-- This module never rolls, transmits tickets, chooses a winner or awards loot.
local NLL = NaxxLootLottery
NLL.TicketPlanner = NLL.TicketPlanner or {}
local Planner = NLL.TicketPlanner

local function ByName(a, b)
    return string.lower(a.character or "") < string.lower(b.character or "")
end

function Planner:BuildPreview(entry, matches, options)
    options = options or {}
    -- Simulated entries are accepted ONLY by the explicit sandbox caller.
    -- They cannot pass the real DETECTED-drop checks in TicketLottery.
    local sandbox = options.simulation == true and
        type(entry) == "table" and entry.simulationOnly == true
    local result = {
        ready = false,
        message = "",
        itemID = entry and entry.itemID or nil,
        chosenTier = nil,
        current = {}, waiting = {}, excluded = {}, unresolved = {},
        -- no pre-drop or post-drop lottery ticket objects created
        previewOnly = true,
        debug = entry and entry.slotIndex == 0 or false
    }
    if type(entry) ~= "table" or
        (not sandbox and entry.state ~= "DETECTED") or
        (sandbox and entry.state ~= "SIMULATED_DROP") or
        (entry.simulationOnly and not sandbox) then
        result.message = "No real detected drop. Simulation requires the Debug Lab."
        return result
    end
    local raidKey = entry.raidKey or "MOLTEN_CORE"
    if raidKey ~= "MOLTEN_CORE" or not NLL.Data.MoltenCore:GetItem(entry.itemID) then
        result.message = "Unsupported drop; no ticket preview."
        return result
    end
    local item = NLL.Data.MoltenCore:GetItem(entry.itemID)
    if entry.manualOnly or item.manualOnly or
        (not sandbox and NLL.PriorityEngine:GetState(raidKey, entry.itemID) ==
        NLL.PriorityEngine.STATUS.MANUAL_ONLY) then
        result.message = "Guild/manual item: no normal lottery."
        return result
    end
    if sandbox then
        local rule = options.rule
        if type(rule) ~= "table" or
            NLL.PriorityEngine:GetUnsetRoleCount(rule) > 0 then
            result.message = "Simulation needs a complete priority rule or suggestion."
            return result
        end
    elseif NLL.PriorityEngine:GetState(raidKey, entry.itemID) ~=
        NLL.PriorityEngine.STATUS.CONFIGURED then
        result.message = "Priority rule must be fully configured first."
        return result
    end
    if sandbox and type(matches) ~= "table" then
        result.message = "Simulation requires an explicit fake candidate roster."
        return result
    end
    matches = matches or NLL.NeedMatcher:GetMatchesForItem(entry.itemID)
    if not sandbox and NLL.CandidateReview then
        matches = NLL.CandidateReview:MergeMatches(entry,matches)
    end
    local pools = { {}, {}, {} }
    local seen = {}
    for i = 1, #matches do
        local m = matches[i]
        local key = string.lower((m.character or ""):match("^([^%-]+)") or "")
        if key ~= "" and not seen[key] then
            seen[key] = true
            -- Explicit leader exclusions are auditable and never rewrite plans.
            if sandbox and options.excluded and options.excluded[key] then
                table.insert(result.excluded, {match=m,
                    reason="Simulated leader exclusion"})
            elseif not sandbox and NLL.CandidateReview and
                NLL.CandidateReview:IsExcluded(entry,m.character) then
                table.insert(result.excluded,{match=m,reason='Leader exclusion: '..
                    tostring(NLL.CandidateReview:IsExcluded(entry,m.character))})
            -- Check presence first. Off-raid plans never enter this pool.
            elseif not m.inRaid or not m.online or m.eligiblePresence == false then
                table.insert(result.excluded, {match=m, reason="Not present/online"})
            elseif not m.classFile or not NLL:IsValidClass(m.classFile) then
                table.insert(result.unresolved, {match=m, reason="Class unknown"})
            elseif not m.role or not NLL.roleLabels[m.role] then
                table.insert(result.unresolved, {match=m, reason="Role unassigned"})
            else
                local tier, explanation
                if sandbox then
                    -- Use the REAL class-eligibility evaluator against the
                    -- sandbox's selected rule, never changing saved guild rules.
                    if not NLL.PriorityEngine:IsClassEligible(
                        raidKey, entry.itemID, m.classFile, options.rule) then
                        tier = NLL.PriorityEngine.EXCLUDE
                        explanation = "Wrong class"
                    else
                        tier = options.rule.rolePriority[m.role]
                        explanation = tier == NLL.PriorityEngine.EXCLUDE and
                            "Not eligible" or "Unconfigured role"
                    end
                else
                    tier, explanation = NLL.PriorityEngine:GetCandidatePriority(
                        raidKey, entry.itemID, m)
                end
                if tier == 1 or tier == 2 or tier == 3 then
                    table.insert(pools[tier], m)
                elseif tier == NLL.PriorityEngine.EXCLUDE then
                    table.insert(result.excluded, {match=m, reason=explanation or "Excluded"})
                else
                    table.insert(result.unresolved, {match=m, reason=explanation or "Unresolved"})
                end
            end
        end
    end
    for tier = 1, 3 do table.sort(pools[tier], ByName) end
    for tier = 1, 3 do
        if #pools[tier] > 0 then result.chosenTier=tier break end
    end
    for tier = 1, 3 do
        for _, m in ipairs(pools[tier]) do
            if tier == result.chosenTier then
                table.insert(result.current, m)
            else
                table.insert(result.waiting, {match=m, tier=tier})
            end
        end
    end
    if #result.unresolved > 0 then
        result.message = tostring(#result.unresolved) ..
            " present NEEDED character(s) have missing role/class information. " ..
            "Resolve before using this pool. No roll or award."
        return result
    end
    if not result.chosenTier then
        result.message="No eligible, present NEEDED characters at any configured tier."
        return result
    end
    result.ready = true
    result.message = "Tier " .. result.chosenTier .. " has " ..
        #result.current .. " equal-priority candidate(s); " ..
        #result.waiting .. " waiting; " .. #result.excluded ..
        " excluded. Preview only: no roll or award."
    return result
end

function Planner:PreviewSelectedLoot()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return NLL.DebugSimulator:Preview()
    end
    local UI = NLL.UI
    local loot = NLL.LootDetection:GetCurrentLoot() or {}
    local index = UI.currentLootSelected or 1
    local entry = loot[index]
    local matches = entry and NLL.NeedMatcher:GetMatchesForItem(entry.itemID) or {}
    return self:BuildPreview(entry, matches)
end
