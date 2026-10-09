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

function Suite:IsEnabled(folder)
    local index = self:FindIndex(folder)
    if not index then return false, false end

    if type(GetAddOnEnableState) == "function" then
        -- 3.3.5a: returns 0 when disabled; 1 or 2 when enabled.
        local state = GetAddOnEnableState(UnitName("player"), index)
        if type(state) == "number" then
            return state > 0, true
        end
    end

    local _, _, _, enabled = GetAddOnInfo(index)
    return enabled and true or false, true
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

    -- Blizzard's addon manager handles persistence of the enabled state.
    local success, err = pcall(method, index)
    if not success then
        return false, tostring(err)
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
SlashCmdList["NSUITE"] = function()
    if Suite.ToggleSettings then
        Suite:ToggleSettings()
    else
        Suite:Print("The suite settings UI is unavailable.")
    end
end
