-- N Addon Suite, WoW 3.3.5a (Lua 5.1).
-- Classic Battlegrounds is bundled into this core and has no suite toggle.
-- Optional addons remain independent and are enabled/disabled using Blizzard's API.

NCore = NCore or {}
local Suite = NCore

Suite.version = "2.0.0-alpha.1"
Suite.modules = {
    {
        folder = "IndividualProgressionAddon",
        title = "Individual Progression",
        description = "Era progression, unlocks, attunements and guidance."
    },
    {
        folder = "DungeonJournal",
        title = "Dungeon Journal",
        description = "Instance, raid, boss and loot reference."
    },
    {
        folder = "MultiBot",
        title = "MultiBot Chatless",
        description = "Playerbot commands and management."
    },
    {
        folder = "NaxxLootLottery",
        title = "N Loot Ledger",
        description = "Raid loot planning and lotteries (WIP)."
    }
}

function Suite:Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffE6C35CN Suite:|r " .. tostring(message))
    end
end

function Suite:FindIndex(folder)
    if type(GetNumAddOns) ~= "function" or type(GetAddOnInfo) ~= "function" then
        return nil
    end
    for index = 1, GetNumAddOns() do
        local name = GetAddOnInfo(index)
        if name == folder then
            return index
        end
    end
    return nil
end

-- Return the WoW client's *configured* enable state. This is different
-- from IsAddOnLoaded: an addon already in memory stays loaded until /reload.
local function AsEnabled(value)
    return value ~= nil and value ~= false and value ~= 0
end

function Suite:IsEnabled(folder)
    local index = self:FindIndex(folder)
    if not index then return false, false end

    -- 3.3.5a GetAddOnInfo returns the enabled flag in position 4.
    -- Some clients also provide GetAddOnEnableState; do not rely on it alone.
    local _, _, _, legacyState = GetAddOnInfo(index)
    local legacyEnabled = AsEnabled(legacyState)
    if type(GetAddOnEnableState) == "function" then
        local ok, state = pcall(GetAddOnEnableState, UnitName("player"), index)
        if ok and type(state) == "number" then
            return state > 0, true
        end
    end
    return legacyEnabled, true
end

function Suite:IsLoaded(folder)
    if type(IsAddOnLoaded) ~= "function" then return nil end
    local ok, loaded = pcall(IsAddOnLoaded, folder)
    if not ok then return nil end
    return loaded and true or false
end

local function NameOrNumber(value)
    if value == nil then return "unavailable" end
    return tostring(value)
end

function Suite:PrintStatus()
    self:Print("Optional module diagnostics (configured / loaded now):")
    for _, module in ipairs(self.modules) do
        local index = self:FindIndex(module.folder)
        local enabled, installed = self:IsEnabled(module.folder)
        local loaded = self:IsLoaded(module.folder)
        local label = installed and (enabled and "enabled" or "disabled") or "missing"
        self:Print(module.title .. ": " .. label ..
            " / loaded=" .. NameOrNumber(loaded) ..
            " / index=" .. NameOrNumber(index))
    end

    local count = 0
    if type(GetNumAddOns) == "function" then
        for index = 1, GetNumAddOns() do
            local name = GetAddOnInfo(index)
            if type(name) == "string" then
                local lower = string.lower(name)
                if string.find(lower, "dungeonjournal", 1, true) then
                    count = count + 1
                    self:Print("Journal folder: " .. name ..
                        " / loaded=" .. NameOrNumber(self:IsLoaded(name)))
                end
            end
        end
    end
    if count == 0 then
        self:Print("No Dungeon Journal folder found in the addon list.")
    end
    local registered = type(SlashCmdList) == "table" and
        type(SlashCmdList.DUNGEONJOURNAL) == "function"
    self:Print("/dj command registered: " .. tostring(registered) ..
        ". Disabled addons already loaded remain active until Reload UI.")
end

function Suite:SetEnabled(folder, enable)
    if folder == "NCore" or folder == "NClassicBattlegrounds" then
        return false, "Classic Battlegrounds is mandatory while N Suite is installed."
    end

    local allowed = false
    for _, module in ipairs(self.modules) do
        if module.folder == folder then
            allowed = true
            break
        end
    end
    if not allowed then return false, "Unknown or protected module." end

    local index = self:FindIndex(folder)
    if not index then return false, "Addon files are missing." end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return false, "Leave combat before changing addons."
    end

    local method = enable and EnableAddOn or DisableAddOn
    if type(method) ~= "function" then
        return false, "This client cannot change addon enable states."
    end

    -- Use the exact addon folder. Older 3.3.5 clients accept both folder
    -- names and indices, so try the index only if a name call has no effect.
    local success, err = pcall(method, folder)
    local actual, present = self:IsEnabled(folder)
    if not success or not present or actual ~= enable then
        local retryOK, retryErr = pcall(method, index)
        actual, present = self:IsEnabled(folder)
        if not retryOK or not present or actual ~= enable then
            return false, "WoW did not " ..
                (enable and "enable " or "disable ") .. folder ..
                ". Please check the AddOns list at character selection." ..
                (not retryOK and (" (" .. tostring(retryErr) .. ")") or
                (not success and (" (" .. tostring(err) .. ")") or ""))
        end
    end

    -- Persist addon flags before reload when the legacy API is available.
    -- Never report success if the client explicitly fails to save them.
    if type(SaveAddOns) == "function" then
        local saved, problem = pcall(SaveAddOns)
        if not saved then
            self.needsReload = true
            return false, "Enable state changed but SaveAddOns failed: " .. tostring(problem)
        end
    end

    self.needsReload = true
    return true
end

function Suite:RequestReload()
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        self:Print("Reload the UI after leaving combat.")
        return
    end
    if type(ReloadUI) == "function" then
        ReloadUI()
    else
        self:Print("Use /reload to apply your selected addons.")
    end
end

SLASH_NSUITE1 = "/nsuite"
SLASH_NSUITE2 = "/nsettings"
SlashCmdList["NSUITE"] = function(message)
    message = string.lower((message or ""):match("^%s*(.-)%s*$"))
    if message == "status" or message == "debug" then
        Suite:PrintStatus()
    elseif message == "check" then
        if Suite.CheckLegacyInstallations then
            Suite:CheckLegacyInstallations(false)
        else
            Suite:Print("The installation check is not available.")
        end
    elseif message == "" then
        if Suite.ToggleSettings then
            Suite:ToggleSettings()
        else
            Suite:Print("The suite settings UI is unavailable.")
        end
    else
        Suite:Print("Commands: /nsuite, /nsuite status, /nsuite check")
    end
end
