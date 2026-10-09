-- ============================================================
-- Naxxramas Loot Ledger
-- Core/Core.lua
-- WoW 3.3.5a / Interface 30300 / Lua 5.1
-- ============================================================

NaxxLootLottery = NaxxLootLottery or {}
local NLL = NaxxLootLottery

NLL.name = "Naxxramas Loot Ledger"
NLL.shortName = "NLL"
NLL.version = "0.1.0.27"
NLL.databaseVersion = 1
NLL.initialized = false
NLL.initializeAttempted = false
NLL.initializationError = nil
NLL.slashRegistered = false

NLL.roles = {
    { id = "MAIN_TANK",           label = "Main Tank" },
    { id = "TANK",                label = "Tank" },
    { id = "HEALER",              label = "Healer" },
    { id = "MELEE_DPS",           label = "Melee DPS" },
    { id = "RANGED_PHYSICAL_DPS", label = "Ranged Physical DPS" },
    { id = "CASTER_DPS",          label = "Caster DPS" }
}

NLL.roleLabels = {}
for i = 1, #NLL.roles do
    local role = NLL.roles[i]
    NLL.roleLabels[role.id] = role.label
end

NLL.classes = {
    { id = "WARRIOR",     label = "Warrior" },
    { id = "PALADIN",     label = "Paladin" },
    { id = "HUNTER",      label = "Hunter" },
    { id = "ROGUE",       label = "Rogue" },
    { id = "PRIEST",      label = "Priest" },
    { id = "DEATHKNIGHT", label = "Death Knight" },
    { id = "SHAMAN",      label = "Shaman" },
    { id = "MAGE",        label = "Mage" },
    { id = "WARLOCK",     label = "Warlock" },
    { id = "DRUID",       label = "Druid" }
}

NLL.classLabels = {}
for i = 1, #NLL.classes do
    local classInfo = NLL.classes[i]
    NLL.classLabels[classInfo.id] = classInfo.label
end

function NLL:IsValidClass(classFile)
    if classFile == nil then
        return true
    end

    return self.classLabels[
        classFile
    ] ~= nil
end

function NLL:GetClassLabel(classFile)
    if classFile == nil then
        return "Unknown"
    end

    return self.classLabels[
        classFile
    ] or tostring(classFile)
end

function NLL:IsValidRole(roleID)
    if roleID == nil then
        return true
    end
    return self.roleLabels[roleID] ~= nil
end

function NLL:GetRoleLabel(roleID)
    if roleID == nil then
        return "Unassigned"
    end
    return self.roleLabels[roleID] or "Unknown"
end

function NLL:Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffd6b45d[NLL]|r " .. tostring(message)
        )
    end
end

function NLL:Debug(message)
    if not NaxxLootLotteryDB
        or not NaxxLootLotteryDB.settings
        or not NaxxLootLotteryDB.settings.debug
        or not DEFAULT_CHAT_FRAME then
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage(
        "|cffd6b45d[NLL DEBUG]|r " .. tostring(message)
    )
end

function NLL:RegisterSlashCommands()
    if self.slashRegistered then
        return
    end

    SLASH_NAXXLOOTLOTTERY1 = "/nll"
    SLASH_NAXXLOOTLOTTERY2 = "/naxxlootlottery"

    SlashCmdList["NAXXLOOTLOTTERY"] = function(message)
        NLL:HandleSlashCommand(message)
    end

    self.slashRegistered = true
end

function NLL:HandleSlashCommand(message)
    message = message or ""

    local command, arguments =
        string.match(message, "^%s*(%S*)%s*(.-)%s*$")

    command = string.lower(command or "")
    arguments = arguments or ""

    -- These diagnostics deliberately work even when a later addon
    -- module failed to initialize.
    if command == "version" then
        self:Print(
            self.name ..
            " version " ..
            self.version
        )
        return
    end

    if command == "status" then
        if self.initialized then
            self:Print(
                "Initialization status: READY."
            )
        elseif self.initializationError then
            self:Print(
                "Initialization status: FAILED."
            )
            self:Print(
                "Error: " ..
                tostring(
                    self.initializationError
                )
            )
        elseif self.initializeAttempted then
            self:Print(
                "Initialization status: incomplete."
            )
        else
            self:Print(
                "Initialization status: not attempted yet."
            )
        end
        return
    end

    if not self.initialized then
        self:Print(
            "The addon loaded, but initialization did not complete."
        )

        if self.initializationError then
            self:Print(
                "Use /nll status to see the initialization error."
            )
        else
            self:Print(
                "Try /reload, then use /nll status."
            )
        end

        return
    end

    if command == "" or command == "toggle" then
        self.UI:ToggleMainFrame()
        return
    end

    if command == "show" then
        self.UI:ShowMainFrame()
        return
    end

    if command == "hide" then
        self.UI:HideMainFrame()
        return
    end

    if command == "roles" or command == "roster" then
        if self.Roster then
            self.Roster:Refresh()
        end
        self.UI:ShowMainFrame("roles")
        return
    end

    if command == "search" or command == "loot" then
        self.UI:ShowMainFrame("search")

        -- With only Molten Core implemented, a slash search can
        -- safely select it automatically when text was supplied.
        if arguments ~= "" then
            if self.UI.SelectSearchRaid then
                self.UI:SelectSearchRaid("MOLTEN_CORE")
            end

            if self.UI.SetSearchText then
                self.UI:SetSearchText(arguments)
            end
        end
        return
    end

    if command == "wishlist"
        or command == "wishlists"
        or command == "plans"
        or command == "gear" then

        self.UI:ShowMainFrame("wishlist")
        return
    end

    if command == "inbox" then
        self.UI:ShowMainFrame("wishlist")
        self.UI.wishlistMode = "inbox"
        self.UI:RefreshWishlistPanel()
        return
    end

    if command == "current"
        or command == "currentloot" then

        self.UI:ShowMainFrame(
            "currentloot"
        )
        return
    end

    if command == "settings"
        or command == "options" then

        self.UI:ShowMainFrame(
            "settings"
        )
        return
    end

    if command == "botcheck" then
        local ok, message=self.PlayerbotCompatibility:Report(arguments or '')
        if not ok then self:Print(message) end
        return
    end
    if command == "newloot" then
        local ok, message
        if string.lower(arguments or '') == 'confirm' then
            ok, message = self.LootIdentity:ConfirmReset()
        else
            ok, message = self.LootIdentity:PrepareReset()
        end
        self:Print(message)
        return
    end
    if command == "lootidentity" then
        local group=self.LootIdentity:GetGroup()
        self:Print('Current loot opportunity: '..tostring(group and group.id or 'none'))
        self:Print('Previously assigned items: '..tostring(group and group.rows and #group.rows or 0))
        self:Print('Archived loot groups: '..tostring(group and group.groups and #group.groups or 0))
        return
    end

    if command == "sim" or command == "simulator" then
        if not self.DebugSimulator:IsEnabled() then
            self:Print("Debug Lab disabled. Run /nll debug first.")
            return
        end
        local sub,who = string.match(arguments or "", "^%s*(%S*)%s*(.-)%s*$")
        sub=string.lower(sub or "")
        if sub == "" or sub == "open" then
            self.UI.settingsMode="debug"
            self.UI:ShowMainFrame("settings")
            self.UI:RefreshSettingsPanel()
            return
        end
        local sim=self.DebugSimulator
        local ok,msg
        if sub == "list" or sub == "help" then
            ok=true
            msg="Scenarios: "..table.concat(sim:AvailableScenarios(),", ")
        elseif sub == "all" or sub == "mc40" or sub == "all40" or
            sub == "40" or sub == "healer" or sub == "manual" or
            sub == "missing" or sim:ClassTestInfo(sub) then
            ok,msg=sim:Start(sub)
        elseif sub == "preview" then
            local p
            p,msg=sim:Preview()
            ok=p and p.ready
        elseif sub == "prepare" then ok,msg=sim:Prepare()
        elseif sub == "roll" then ok,msg=sim:Roll()
        elseif sub == "reset" then
            ok,msg=sim:Start(sim.active and sim.active.scenario or "mage")
        elseif sub == "stop" then ok,msg=sim:Stop()
        elseif sub == "next" then ok,msg=sim:NextDrop()
        elseif sub == "select" then ok,msg=sim:SelectDrop(tonumber(who))
        elseif sub == "award" then
            self.UI:ShowMainFrame('currentloot')
            ok=self.UI:OpenAwardReview()
            msg=ok and 'Review the separate fake award confirmation window.' or
                'Finish a fake lottery before reviewing its award.'
        elseif sub == "status" then ok,msg=true,sim:Status()
        elseif sub == "exclude" then ok,msg=sim:SetExcluded(who,true)
        elseif sub == "restore" then ok,msg=sim:SetExcluded(who,false)
        elseif sub == "offline" then ok,msg=sim:SetOnline(who,false)
        elseif sub == "online" then ok,msg=sim:SetOnline(who,true)
        else
            msg="Use /nll sim list for every class. Or preview|prepare|roll|next|reset|stop."
        end
        self:Print(msg or "No simulator response.")
        if self.UI and self.UI.RefreshDebugLab then self.UI:RefreshDebugLab() end
        if ok and (sub=="all" or sub=="mc40" or sub=="all40" or
            sub=="40" or sub=="healer" or sub=="manual" or
            sub=="missing" or sim:ClassTestInfo(sub)) then
            self.UI:ShowMainFrame("roles")
        end
        return
    end

    if command == "awardreview" then
        self.UI:ShowMainFrame('currentloot')
        self.UI:OpenAwardReview()
        return
    end
    if command == "awardhistory" then
        local history=self.db and self.db.lootAwardHistory or {}
        self:Print('Real award events: '..tostring(#history))
        for i=math.max(1,#history-9),#history do
            local row=history[i]
            self:Print('['..tostring(i)..'] '..tostring(row.itemName)..
                ' -> '..tostring(row.winner)..' ['..tostring(row.status)..']')
        end
        return
    end
    if command == "directaward" then
        local action=string.lower(arguments or '')
        if action=='off' then
            self.AwardWorkflow:SetDirectEnabled(false)
            self:Print('Direct Master Loot disabled.')
        else
            self:Print('Direct Master Loot: '..
                (self.AwardWorkflow:IsDirectEnabled() and 'ON' or 'OFF')..
                '. Change it in Settings > Loot Awards, or use /nll directaward off.')
        end
        return
    end
    if command == "candidateaudit" then
        local history=self.db and self.db.candidateAudit or {}
        self:Print('Candidate review events: '..tostring(#history))
        for i=math.max(1,#history-7),#history do
            local e=history[i]
            self:Print('['..tostring(i)..'] '..tostring(e.action)..' '..
                tostring(e.character)..' - '..tostring(e.reason or ''))
        end
        return
    end
    if command == "reviewpool" then
        self.UI:ShowMainFrame('currentloot')
        self.UI:OpenCandidateReview()
        return
    end
    if command == "lotteryhistory" then
        local history = self.db and self.db.lotteryHistory or {}
        self:Print("Recent lottery events: " .. #history)
        for i = math.max(1, #history-4), #history do
            local record=history[i]
            self:Print("[" .. i .. "] " .. tostring(record.itemName) ..
                ": " .. tostring(record.status) ..
                (record.winner and (" - " .. record.winner) or "") ..
                (record.test and " [TEST]" or ""))
        end
        return
    end
    if command == "canceltickets" then
        local ok, msg=self.TicketLottery:Cancel("Slash command cancel")
        self:Print(msg)
        if self.UI and self.UI.RefreshCurrentLootPanel then
            self.UI:RefreshCurrentLootPanel()
        end
        return
    end
    if command == "presets" then
        local arg = string.lower(arguments or "")
        if arg == "on" or arg == "off" then
            self.PriorityEngine:SetPresetsEnabled(arg == "on")
            self:Print("Curated presets " .. (arg == "on" and "enabled" or "disabled") ..
                ". Saved custom rules were not changed.")
            if self.UI and self.UI.RefreshPrioritySetup then
                self.UI:RefreshPrioritySetup()
            end
            if self.UI and self.UI.RefreshCurrentLootPanel then
                self.UI:RefreshCurrentLootPanel()
            end
        else
            self:Print("Presets: " ..
                (self.PriorityEngine:PresetsEnabled() and "ON" or "OFF") ..
                ". Use /nll presets on or /nll presets off.")
        end
        return
    end

    if command == "priorities"
        or command == "prioritysetup" then

        self.UI.settingsMode =
            "priority"

        self.UI:ShowMainFrame(
            "settings"
        )

        self.UI:RefreshSettingsPanel()
        return
    end

    if command == "testdrop" then
        if not NaxxLootLotteryDB.settings.debug then
            self:Print(
                "Enable /nll debug before using testdrop."
            )
            return
        end

        local itemID =
            tonumber(arguments)

        if not itemID then
            self:Print(
                "Usage: /nll testdrop <Molten Core Item ID>"
            )
            return
        end

        local ok, result =
            self.LootDetection:InjectTestDrop(
                itemID
            )

        if not ok then
            self:Print(result)
            return
        end

        self:Print(
            "Injected test drop: " ..
            result.itemName ..
            ". No loot was awarded."
        )

        self.UI:ShowMainFrame(
            "currentloot"
        )
        return
    end

    if command == "preview" then
        local preview = self.TicketPlanner:PreviewSelectedLoot()
        self:Print(preview.message)
        if preview.ready then
            for i = 1, #preview.current do
                self:Print("Preview #" .. i .. ": " .. preview.current[i].character)
            end
        end
        return
    end

    if command == "clearloot" then
        self.LootDetection:ClearCurrentLoot()
        self:Print(
            "Current loot queue cleared."
        )
        return
    end

    if command == "undopriority" then
        local ok, msg = self.PriorityEngine:UndoLastChange()
        self:Print(msg)
        if ok and self.UI.RefreshPrioritySetup then
            self.UI:RefreshPrioritySetup()
        end
        return
    end

    if command == "priority" then
        local itemID =
            tonumber(arguments)

        if not itemID then
            self:Print(
                "Usage: /nll priority <Molten Core Item ID>"
            )
            return
        end

        local item =
            self.Data.MoltenCore:GetItem(
                itemID
            )

        if not item then
            self:Print(
                "That Item ID is not in the Molten Core database."
            )
            return
        end

        self:Print(
            item.name ..
            " priority: " ..
            self.PriorityEngine:GetDisplayLabel(
                "MOLTEN_CORE",
                itemID
            )
        )

        return
    end

    if command == "debug" then
        NaxxLootLotteryDB.settings.debug =
            not NaxxLootLotteryDB.settings.debug

        if NaxxLootLotteryDB.settings.debug then
            self:Print("Debug mode enabled.")
            self:Debug("Debug output is working.")
        else
            -- End any fake session when debug is switched off.
            -- No persistent data or live loot is affected.
            if self.DebugSimulator and self.DebugSimulator.active then
                self.DebugSimulator:Stop()
            end
            self:Print("Debug mode disabled.")
        end
        return
    end

    if command == "help" then
        self:Print("/nll - Open or close the addon.")
        self:Print("/nll roles - Open raid role assignments.")
        self:Print("/nll search [item] - Open Raid Loot Search.")
        self:Print("/nll wishlist - Open wishlists and gear plans.")
        self:Print("/nll inbox - Open submitted wishlist inbox.")
        self:Print("/nll current - Open detected current loot.")
        self:Print("/nll settings - Open addon settings.")
        self:Print("/nll priorities - Open Molten Core priority setup.")
        self:Print("/nll presets on/off - Activate built-in priority presets.")
        self:Print("/nll undopriority - Undo the last saved/deleted rule.")
        self:Print("/nll roster - Refresh the raid roster.")
        self:Print("/nll debug - Toggle debug output.")
        self:Print("/nll sim - Open isolated fake raid Debug Lab.")
        self:Print("/nll sim list - List all class and safety scenarios.")
        self:Print("/nll sim all - 20 fake bots across ten 3.3.5 classes.")
        self:Print("/nll sim mc40 - Molten Core 40-player raid, 8 groups.")
        self:Print("/nll sim <class> - Class-specific fake raid (e.g. rogue, deathknight).")
        self:Print("/nll sim preview|prepare|roll|next|reset|stop - Fake workflow.")
        self:Print("/nll testdrop <id> - Debug-only fake drop.")
        self:Print("/nll clearloot - Clear detected loot (not the roll history).")
        self:Print("/nll lootidentity - Show current and archived loot group counts.")
        self:Print("/nll botcheck [name] - Read-only real Playerbot roster/loot preflight.")
        self:Print("/nll newloot - Confirm a DIFFERENT corpse when loot overlaps.")
        self:Print("/nll newloot confirm - Confirm new corpse within 20 seconds.")
        self:Print("/nll priority <id> - Show priority configuration state.")
        self:Print("/nll preview - Preview current drop priority, no roll.")
        self:Print("/nll reviewpool - Review current drop candidates.")
        self:Print("/nll candidateaudit - Show recent leader candidate changes.")
        self:Print("/nll lotteryhistory - Show last 5 lottery records.")
        self:Print("/nll awardreview - Review the selected winner and manual award.")
        self:Print("/nll awardhistory - Show manual, requested and observed awards.")
        self:Print("/nll directaward off - Immediately disable live direct awarding.")
        self:Print("/nll sim next|select <number>|award - Test multiple drops/award.")
        self:Print("/nll canceltickets - Cancel pending tickets, log cancellation.")
        self:Print("/nll version - Show addon version.")
        self:Print("/nll status - Show addon initialization status.")
        return
    end

    self:Print("Unknown command. Type /nll help.")
end

local function RequireModule(
    name,
    value
)
    if not value then
        error(
            "Required module did not load: " ..
            tostring(name)
        )
    end

    return value
end

function NLL:Initialize()
    if self.initialized then
        return
    end

    RequireModule(
        "Storage/Database.lua",
        self.Database
    )

    RequireModule(
        "Data/MoltenCore.lua",
        self.Data
            and self.Data.MoltenCore
    )

    RequireModule(
        "Core/RaidRoster.lua",
        self.Roster
    )

    RequireModule(
        "Core/ItemSearch.lua",
        self.ItemSearch
    )

    RequireModule(
        "Core/GearNeeds.lua",
        self.GearNeeds
    )

    RequireModule(
        "Core/Communication.lua",
        self.Communication
    )

    RequireModule(
        "Core/NeedMatcher.lua",
        self.NeedMatcher
    )
    RequireModule(
        "Core/CandidateReview.lua",
        self.CandidateReview
    )
    RequireModule(
        "Core/DebugSimulator.lua",
        self.DebugSimulator
    )

    RequireModule(
        "Core/PriorityEngine.lua",
        self.PriorityEngine
    )

    RequireModule(
        "Core/PlayerbotCompatibility.lua",
        self.PlayerbotCompatibility
    )
    RequireModule(
        "Core/LootIdentity.lua",
        self.LootIdentity
    )
    RequireModule(
        "Core/LootDetection.lua",
        self.LootDetection
    )

    RequireModule(
        "Core/TicketPlanner.lua",
        self.TicketPlanner
    )
    RequireModule(
        "Core/TicketLottery.lua",
        self.TicketLottery
    )
    RequireModule(
        "Core/AwardWorkflow.lua",
        self.AwardWorkflow
    )
    RequireModule(
        "UI/AwardReviewFrame.lua",
        self.UI and self.UI.OpenAwardReview
    )
    RequireModule(
        "Core/PrioritySuggestions.lua",
        self.PrioritySuggestions
    )

    RequireModule(
        "UI/MainFrame.lua",
        self.UI
            and self.UI.CreateMainFrame
    )

    self.Database:Initialize()
    self.Data.MoltenCore:Initialize()

    self.Roster:Initialize()
    self.ItemSearch:Initialize()
    self.GearNeeds:Initialize()
    self.Communication:Initialize()
    self.NeedMatcher:Initialize()
    self.CandidateReview:Initialize()
    self.LootIdentity:Initialize()
    self.LootDetection:Initialize()
    self.PriorityEngine:Initialize()

    self.UI:CreateMainFrame()
    self.UI:ApplySkin()

    self.initialized = true
    self.initializationError = nil

    self:Debug(
        self.name ..
        " " ..
        self.version ..
        " initialized."
    )
end

function NLL:SafeInitialize()
    if self.initialized then
        return true
    end

    if self.initializeAttempted
        and self.initializationError then

        return false
    end

    self.initializeAttempted = true

    local ok, err =
        pcall(
            function()
                NLL:Initialize()
            end
        )

    if not ok then
        self.initializationError =
            tostring(err)

        self:Print(
            "Initialization failed. /nll status will show the error."
        )

        return false
    end

    return true
end

local eventFrame = CreateFrame("Frame")
NLL.eventFrame = eventFrame

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if event == "ADDON_LOADED" then
            local loadedAddon = ...

            if loadedAddon ==
                "NaxxLootLottery" then

                NLL:SafeInitialize()
            end

            return
        end

        if event == "PLAYER_LOGIN" then
            -- Fallback: if the addon folder was renamed, the strict
            -- ADDON_LOADED name check above may not match. Initialise
            -- here as well, but never retry a recorded failure.
            if not NLL.initialized
                and not NLL.initializeAttempted then

                NLL:SafeInitialize()
            end

            if NLL.initialized
                and NLL.Roster then

                NLL.Roster:Refresh()
            end

            return
        end
    end
)

-- Register slash commands during Core.lua load rather than waiting
-- for later systems. This guarantees /nll version and /nll status
-- remain available even if another module has a load/init problem.
NLL:RegisterSlashCommands()
