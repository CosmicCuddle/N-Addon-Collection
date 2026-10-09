-- ============================================================
-- Naxxramas Loot Ledger
-- Core/PriorityEngine.lua
--
-- Phase 8 configurable priority engine.
--
-- IMPORTANT:
-- This file contains the machinery for user-defined priority rules.
-- It deliberately contains NO predefined Molten Core priorities.
-- ============================================================

local NLL = NaxxLootLottery

NLL.PriorityEngine =
    NLL.PriorityEngine or {}

local Priority =
    NLL.PriorityEngine

Priority.STATUS = {
    MANUAL_ONLY = "MANUAL_ONLY",
    NOT_CONFIGURED = "NOT_CONFIGURED",
    DRAFT = "DRAFT",
    CONFIGURED = "CONFIGURED"
}

Priority.EXCLUDE = "EXCLUDE"

function Priority:Initialize()
    self.initialized = true
end

function Priority:GetRaidRules(raidKey)
    if not NLL.db
        or not NLL.db.priorityRules then

        return nil
    end

    local rules =
        NLL.db.priorityRules[
            raidKey
        ]

    if type(rules) ~= "table" then
        return nil
    end

    return rules
end

-- A guild's saved rule is always the highest-precedence editable policy.
function Priority:GetCustomRule(raidKey, itemID)
    local rules = self:GetRaidRules(raidKey)
    if not rules then return nil end
    return rules[tonumber(itemID)]
end

function Priority:PresetsEnabled()
    return NLL.db and NLL.db.settings and
        NLL.db.settings.priorityPresetsEnabled == true
end

function Priority:SetPresetsEnabled(enabled)
    if not NLL.db or not NLL.db.settings then return false end
    NLL.db.settings.priorityPresetsEnabled = enabled == true
    -- No priorityRules entries are inserted, deleted, or overwritten.
    return true
end

-- Virtual rule: built from curated in-addon recommendations, with no saved
-- per-item copies. Upgrading the addon can improve presets while any custom
-- policy remains untouched. Manual/guild items never receive presets.
function Priority:GetPresetRule(raidKey, itemID)
    if not self:PresetsEnabled() or raidKey ~= "MOLTEN_CORE" then
        return nil
    end
    local item = NLL.Data.MoltenCore:GetItem(tonumber(itemID))
    if not item or item.manualOnly or not NLL.PrioritySuggestions then
        return nil
    end
    local suggested = NLL.PrioritySuggestions:GetSuggestion(raidKey, itemID)
    if not suggested or type(suggested.rolePriority) ~= "table" then
        return nil
    end
    return {
        raidKey = raidKey, itemID = tonumber(itemID),
        rolePriority = suggested.rolePriority,
        classEligibility = suggested.classEligibility,
        preset = true, presetKind = suggested.kind,
        presetNote = suggested.note
    }
end

function Priority:GetRule(raidKey, itemID)
    return self:GetCustomRule(raidKey, itemID) or
        self:GetPresetRule(raidKey, itemID)
end

function Priority:GetRuleSource(raidKey, itemID)
    if self:GetCustomRule(raidKey, itemID) then return "CUSTOM" end
    if self:GetPresetRule(raidKey, itemID) then return "PRESET" end
    return "NONE"
end

function Priority:GetPresetSummary(raidKey)
    local info = {items=0, manual=0, available=0, preset=0,
        custom=0, unconfigured=0, drafts=0}
    if raidKey ~= "MOLTEN_CORE" then return info end
    for _,item in ipairs(NLL.Data.MoltenCore:GetItems()) do
        info.items = info.items + 1
        if item.manualOnly then
            info.manual = info.manual + 1
        else
            if NLL.PrioritySuggestions:GetSuggestion(raidKey, item.itemID) then
                info.available = info.available + 1
            end
            local source = self:GetRuleSource(raidKey, item.itemID)
            if source == "CUSTOM" then
                if self:GetState(raidKey, item.itemID) == self.STATUS.DRAFT then
                    info.drafts = info.drafts + 1
                else
                    info.custom = info.custom + 1
                end
            elseif source == "PRESET" then info.preset = info.preset + 1
            else info.unconfigured = info.unconfigured + 1 end
        end
    end
    return info
end

function Priority:IsValidSelection(value)
    return value == 1
        or value == 2
        or value == 3
        or value == self.EXCLUDE
end

function Priority:GetDefaultClassEligibility(
    raidKey,
    itemID
)
    local output = {}

    for i = 1, #NLL.classes do
        output[
            NLL.classes[i].id
        ] = true
    end

    local item = nil

    if raidKey == "MOLTEN_CORE"
        and NLL.Data
        and NLL.Data.MoltenCore then

        item =
            NLL.Data.MoltenCore:GetItem(
                tonumber(itemID)
            )
    end

    if item
        and type(item.allowedClasses)
            == "table" then

        for i = 1, #NLL.classes do
            local classFile =
                NLL.classes[i].id

            output[classFile] =
                item.allowedClasses[
                    classFile
                ] == true
        end
    end

    return output
end

function Priority:GetEffectiveClassEligibility(
    raidKey,
    itemID,
    rule
)
    local item = nil

    if raidKey == "MOLTEN_CORE"
        and NLL.Data
        and NLL.Data.MoltenCore then

        item =
            NLL.Data.MoltenCore:GetItem(
                tonumber(itemID)
            )
    end

    -- Inherent item restrictions always win.
    if item
        and type(item.allowedClasses)
            == "table" then

        return self:GetDefaultClassEligibility(
            raidKey,
            itemID
        )
    end

    if rule
        and type(rule.classEligibility)
            == "table" then

        local output = {}

        for i = 1, #NLL.classes do
            local classFile =
                NLL.classes[i].id

            output[classFile] =
                rule.classEligibility[
                    classFile
                ] == true
        end

        return output
    end

    return self:GetDefaultClassEligibility(
        raidKey,
        itemID
    )
end

function Priority:IsClassEligible(
    raidKey,
    itemID,
    classFile,
    rule
)
    if not classFile then
        return false
    end

    local eligibility =
        self:GetEffectiveClassEligibility(
            raidKey,
            itemID,
            rule
        )

    return eligibility[
        classFile
    ] == true
end

function Priority:GetClassEligibilityText(
    raidKey,
    itemID,
    rule
)
    local eligibility =
        self:GetEffectiveClassEligibility(
            raidKey,
            itemID,
            rule
        )

    local labels = {}

    for i = 1, #NLL.classes do
        local classInfo =
            NLL.classes[i]

        if eligibility[
            classInfo.id
        ] then

            table.insert(
                labels,
                classInfo.label
            )
        end
    end

    if #labels ==
        #NLL.classes then

        return "All classes"
    end

    if #labels == 0 then
        return "No classes"
    end

    if #labels == 1 then
        return labels[1] ..
            " only"
    end

    return table.concat(
        labels,
        ", "
    )
end

function Priority:GetUnsetRoleCount(rule)
    local count = 0

    if type(rule) ~= "table"
        or type(rule.rolePriority) ~= "table" then

        return #NLL.roles
    end

    for i = 1, #NLL.roles do
        local roleID =
            NLL.roles[i].id

        if not self:IsValidSelection(
            rule.rolePriority[roleID]
        ) then

            count = count + 1
        end
    end

    return count
end

function Priority:GetState(
    raidKey,
    itemID
)
    local item = nil

    if raidKey == "MOLTEN_CORE"
        and NLL.Data
        and NLL.Data.MoltenCore then

        item =
            NLL.Data.MoltenCore:GetItem(
                tonumber(itemID)
            )
    end

    if item
        and item.manualOnly then

        return self.STATUS.MANUAL_ONLY
    end

    local rule =
        self:GetRule(
            raidKey,
            itemID
        )

    if not rule then
        return self.STATUS.NOT_CONFIGURED
    end

    if self:GetUnsetRoleCount(rule) > 0 then
        return self.STATUS.DRAFT
    end

    local allowed = self:GetEffectiveClassEligibility(raidKey, itemID, rule)
    local hasClass = false
    for _, yes in pairs(allowed) do if yes then hasClass = true break end end
    if not hasClass then return self.STATUS.DRAFT end
    return self.STATUS.CONFIGURED
end

function Priority:GetDisplayLabel(
    raidKey,
    itemID
)
    local state =
        self:GetState(
            raidKey,
            itemID
        )

    if state ==
        self.STATUS.MANUAL_ONLY then

        local item = raidKey == "MOLTEN_CORE" and
            NLL.Data.MoltenCore:GetItem(itemID) or nil
        if item and item.manualReason then
            return "Manual: " .. item.manualReason
        end
        return "Guild item"
    end

    if state ==
        self.STATUS.NOT_CONFIGURED then

        return "Not configured"
    end

    if state ==
        self.STATUS.DRAFT then

        local rule =
            self:GetRule(
                raidKey,
                itemID
            )

        if rule and self:GetUnsetRoleCount(rule) == 0 then
            return "Draft (class eligibility)"
        end

        return
            "Draft (" ..
            tostring(
                self:GetUnsetRoleCount(
                    rule
                )
            ) ..
            " unset)"
    end

    if self:GetRuleSource(raidKey, itemID) == "PRESET" then
        return "Preset"
    end
    return "Configured"
end

-- SavedVariables single-step rollback for priority edits/deletions.
-- This is separate from whole-addon ZIP backups.
local function CopyRule(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = CopyRule(v) end
    return result
end

function Priority:RememberPriorRule(raidKey, itemID)
    if not NLL.db then return end
    local existing = self:GetCustomRule(raidKey, itemID)
    NLL.db.priorityRuleUndo = {
        raidKey = raidKey, itemID = tonumber(itemID),
        existed = existing ~= nil, previous = CopyRule(existing)
    }
end

function Priority:CanUndo()
    return NLL.db and type(NLL.db.priorityRuleUndo) == "table"
end

function Priority:UndoLastChange()
    if not self:CanUndo() then
        return false, "No recent priority change to undo."
    end
    local undo = NLL.db.priorityRuleUndo
    if not undo.raidKey or not tonumber(undo.itemID) then
        NLL.db.priorityRuleUndo = nil
        return false, "Invalid undo record."
    end
    NLL.db.priorityRules[undo.raidKey] =
        NLL.db.priorityRules[undo.raidKey] or {}
    local rules = NLL.db.priorityRules[undo.raidKey]
    if undo.existed then
        rules[tonumber(undo.itemID)] = CopyRule(undo.previous)
    else
        rules[tonumber(undo.itemID)] = nil
    end
    NLL.db.priorityRuleUndo = nil
    return true, "Restored previous priority rule for item " ..
        tostring(undo.itemID) .. "."
end

function Priority:SaveRule(
    raidKey,
    itemID,
    rolePriority,
    classEligibility
)
    -- Simulation never writes saved guild rules.
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,"Stop the fake raid before editing saved priorities."
    end
    raidKey =
        raidKey or "MOLTEN_CORE"

    itemID =
        tonumber(itemID)

    if not itemID then
        return false,
            "A valid Item ID is required."
    end

    local item = nil

    if raidKey == "MOLTEN_CORE" then
        item =
            NLL.Data.MoltenCore:GetItem(
                itemID
            )

        if not item then
            return false,
                "That item is not in the Molten Core database."
        end

        if item.manualOnly then
            return false,
                "Guild/manual items do not use a normal priority rule."
        end
    end

    if type(rolePriority) ~= "table" then
        rolePriority = {}
    end

    local clean = {}

    for i = 1, #NLL.roles do
        local roleID =
            NLL.roles[i].id

        local value =
            rolePriority[roleID]

        if self:IsValidSelection(
            value
        ) then

            clean[roleID] =
                value
        end
    end

    if not NLL.db.priorityRules[
        raidKey
    ] then

        NLL.db.priorityRules[
            raidKey
        ] = {}
    end

    local cleanClasses = {}

    local defaultClasses =
        self:GetDefaultClassEligibility(
            raidKey,
            itemID
        )

    local hasInherentRestriction =
        item
        and type(item.allowedClasses)
            == "table"

    for i = 1, #NLL.classes do
        local classFile =
            NLL.classes[i].id

        if hasInherentRestriction then
            cleanClasses[classFile] =
                defaultClasses[
                    classFile
                ] == true
        elseif type(classEligibility)
            == "table" then

            cleanClasses[classFile] =
                classEligibility[
                    classFile
                ] == true
        else
            cleanClasses[classFile] =
                defaultClasses[
                    classFile
                ] == true
        end
    end

    local rule = {
        raidKey = raidKey,
        itemID = itemID,
        rolePriority = clean,
        classEligibility =
            cleanClasses,
        updatedAt =
            GetTime and GetTime() or 0
    }

    self:RememberPriorRule(raidKey, itemID)
    NLL.db.priorityRules[
        raidKey
    ][itemID] = rule

    local unset =
        self:GetUnsetRoleCount(
            rule
        )

    NLL:Debug(
        "Priority rule saved for " ..
        tostring(itemID) ..
        " with " ..
        tostring(unset) ..
        " unset role(s)."
    )

    return true,
        rule,
        unset
end

function Priority:DeleteRule(
    raidKey,
    itemID
)
    -- Simulation never writes saved guild rules.
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,"Stop the fake raid before editing saved priorities."
    end
    local rules =
        self:GetRaidRules(
            raidKey
        )

    itemID =
        tonumber(itemID)

    if not rules
        or not itemID
        or not rules[itemID] then

        return false
    end

    self:RememberPriorRule(raidKey, itemID)
    rules[itemID] = nil
    return true
end

function Priority:GetRoleSelection(
    raidKey,
    itemID,
    roleID
)
    local rule =
        self:GetRule(
            raidKey,
            itemID
        )

    if not rule
        or type(rule.rolePriority) ~= "table" then

        return nil
    end

    return rule.rolePriority[
        roleID
    ]
end

function Priority:GetCandidatePriority(
    raidKey,
    itemID,
    match
)
    local state =
        self:GetState(
            raidKey,
            itemID
        )

    if state ==
        self.STATUS.MANUAL_ONLY then

        return nil,
            "Manual"
    end

    if state == self.STATUS.NOT_CONFIGURED then
        return nil, "Not configured"
    end
    if state == self.STATUS.DRAFT then
        return nil, "Rule incomplete"
    end

    local rule =
        self:GetRule(
            raidKey,
            itemID
        )

    if not match
        or not match.classFile then

        return nil,
            "Class unknown"
    end

    if not self:IsClassEligible(
        raidKey,
        itemID,
        match.classFile,
        rule
    ) then

        return self.EXCLUDE,
            "Wrong class"
    end

    if not match.role then
        return nil,
            "Role unset"
    end

    local value =
        self:GetRoleSelection(
            raidKey,
            itemID,
            match.role
        )

    if value == self.EXCLUDE then
        return value,
            "Not eligible"
    end

    if value == 1
        or value == 2
        or value == 3 then

        return value,
            "Tier " ..
            tostring(value)
    end

    return nil,
        "Unset"
end

function Priority:Evaluate(
    raidKey,
    itemID,
    matches
)
    matches =
        matches or {}

    local state =
        self:GetState(
            raidKey,
            itemID
        )

    local result = {
        state = state,
        canLottery = false,
        priorityReady = false,
        candidates = matches,
        tiers = {
            {},
            {},
            {}
        },
        excluded = {},
        unresolved = {}
    }

    if state ==
        self.STATUS.MANUAL_ONLY
        or state ==
        self.STATUS.NOT_CONFIGURED then

        return result
    end

    local rule =
        self:GetRule(
            raidKey,
            itemID
        )

    for i = 1, #matches do
        local match =
            matches[i]

        if not match.classFile then
            table.insert(result.unresolved, match)
        elseif not self:IsClassEligible(
                raidKey,
                itemID,
                match.classFile,
                rule
            ) then

            table.insert(
                result.excluded,
                match
            )
        else
            local value =
                self:GetRoleSelection(
                    raidKey,
                    itemID,
                    match.role
                )

            if value == 1
            or value == 2
            or value == 3 then

            table.insert(
                result.tiers[value],
                match
            )
        elseif value ==
            self.EXCLUDE then

            table.insert(
                result.excluded,
                match
            )
            else
                table.insert(
                    result.unresolved,
                    match
                )
            end
        end
    end

    result.priorityReady =
        state ==
            self.STATUS.CONFIGURED
        and #result.unresolved == 0

    -- Phase 9 owns ticket creation and lottery execution.
    -- Phase 8 never starts a lottery.
    result.canLottery = false

    return result
end
