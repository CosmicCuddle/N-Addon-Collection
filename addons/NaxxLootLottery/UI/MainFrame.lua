-- ============================================================
-- Naxxramas Loot Ledger
-- UI/MainFrame.lua
--
-- Compact dark UI inspired by the practical layout style of
-- classic meter/raid addons, while remaining an original UI.
-- ============================================================

local NLL = NaxxLootLottery
NLL.UI = NLL.UI or {}
local UI = NLL.UI

local function SetMainBackdrop(frame)
    UI:RegisterSkinnedFrame(
        frame,
        "main"
    )
end

function UI:CreateTextButton(parent, text, width)
    local button =
        CreateFrame(
            "Button",
            nil,
            parent
        )

    button.nllBaseWidth = width or 90
    button.nllBaseHeight = 22

    button:SetWidth(
        button.nllBaseWidth
    )

    button:SetHeight(
        button.nllBaseHeight
    )

    local label =
        button:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )

    label:SetPoint(
        "CENTER",
        button,
        "CENTER",
        0,
        0
    )

    label:SetText(text)

    button.label = label

    self:AttachButtonSkin(button)

    return button
end

function UI:CreateMainFrame()
    if self.mainFrame then
        return
    end

    local frame = CreateFrame(
        "Frame",
        "NaxxLootLotteryMainFrame",
        UIParent
    )

    frame:SetWidth(820)
    frame:SetHeight(550)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    -- Keep the frame hidden while it is being constructed.
    -- This prevents a partially-built window being left on-screen
    -- if a later child-control creation fails.
    frame:Hide()
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)

    SetMainBackdrop(frame)

    -- Allow Escape to close this named frame using the
    -- classic WoW UISpecialFrames system.
    UISpecialFrames = UISpecialFrames or {}

    local alreadySpecial = false

    for i = 1, #UISpecialFrames do
        if UISpecialFrames[i] == "NaxxLootLotteryMainFrame" then
            alreadySpecial = true
            break
        end
    end

    if not alreadySpecial then
        table.insert(
            UISpecialFrames,
            "NaxxLootLotteryMainFrame"
        )
    end

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    titleBar:SetHeight(30)

    self:RegisterSkinnedFrame(
        titleBar,
        "title"
    )

    local title = titleBar:CreateFontString(
        nil, "OVERLAY", "GameFontNormal"
    )
    title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    title:SetText("Naxxramas Loot Ledger")

    local version = titleBar:CreateFontString(
        nil, "OVERLAY", "GameFontDisableSmall"
    )
    version:SetPoint("RIGHT", titleBar, "RIGHT", -34, 0)
    version:SetText("v" .. NLL.version)
    local simulationBadge=titleBar:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    simulationBadge:SetPoint("CENTER",titleBar,"CENTER",65,0)
    simulationBadge:SetText("|cffffcc33[SIMULATION - FAKE RAID]|r")
    self.simulationBadge=simulationBadge
    simulationBadge:Hide()

    local close = CreateFrame(
        "Button", nil, titleBar, "UIPanelCloseButton"
    )
    close:SetPoint("RIGHT", titleBar, "RIGHT", 2, 0)

    -- UIPanelCloseButton does not reliably hide a custom parent
    -- by itself on this 3.3.5 client, so handle it explicitly.
    close:SetScript(
        "OnClick",
        function()
            UI:HideMainFrame()
        end
    )

    -- Navigation strip
    local nav = CreateFrame("Frame", nil, frame)
    nav:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -3)
    nav:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -3)
    nav:SetHeight(28)

    local overviewButton = self:CreateTextButton(nav, "Overview", 90)
    overviewButton:SetPoint("LEFT", nav, "LEFT", 8, 0)
    overviewButton:SetScript("OnClick", function()
        UI:ShowPanel("overview")
    end)

    local rolesButton = self:CreateTextButton(nav, "Raid Roles", 98)
    rolesButton:SetPoint("LEFT", overviewButton, "RIGHT", 8, 0)
    rolesButton:SetScript("OnClick", function()
        NLL.Roster:Refresh()
        UI:ShowPanel("roles")
    end)

    local searchButton = self:CreateTextButton(nav, "Raid Loot Search", 132)
    searchButton:SetPoint("LEFT", rolesButton, "RIGHT", 8, 0)
    searchButton:SetScript("OnClick", function()
        UI:ShowPanel("search")
    end)

    local wishlistButton = self:CreateTextButton(nav, "Wishlists", 92)
    wishlistButton:SetPoint("LEFT", searchButton, "RIGHT", 8, 0)
    wishlistButton:SetScript("OnClick", function()
        UI:ShowPanel("wishlist")
    end)

    local currentLootButton =
        self:CreateTextButton(
            nav,
            "Current Loot",
            98
        )

    currentLootButton:SetPoint(
        "LEFT",
        wishlistButton,
        "RIGHT",
        8,
        0
    )

    currentLootButton:SetScript(
        "OnClick",
        function()
            UI:ShowPanel("currentloot")
        end
    )

    local settingsButton =
        self:CreateTextButton(
            nav,
            "Settings",
            78
        )

    settingsButton:SetPoint(
        "LEFT",
        currentLootButton,
        "RIGHT",
        8,
        0
    )

    settingsButton:SetScript(
        "OnClick",
        function()
            UI:ShowPanel("settings")
        end
    )

    self.navButtons = {
        overview = overviewButton,
        roles = rolesButton,
        search = searchButton,
        wishlist = wishlistButton,
        currentloot = currentLootButton,
        settings = settingsButton
    }

    -- Content
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", nav, "BOTTOMLEFT", 6, -5)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)

    -- DARK is nearly transparent here.
    -- VANILLA uses the Wrath-era QuestBG parchment texture.
    self:RegisterSkinnedFrame(
        content,
        "content"
    )

    self.content = content

    self:CreateOverviewPanel(content)
    self:CreateRolesPanel(content)
    self:CreateSearchPanel(content)
    self:CreateWishlistPanel(content)
    self:CreateCurrentLootPanel(content)
    self:CreateCandidateReviewPanel(self.currentLootPanel)
    self:CreateSettingsPanel(content)

    self.mainFrame = frame
    self.currentPanel = "overview"

    self:ShowPanel("overview")
    frame:Hide()
end

function UI:SetActiveNav(panelName)
    if not self.navButtons then
        return
    end

    for key, button in pairs(
        self.navButtons
    ) do
        self:SetButtonState(
            button,
            key == panelName
                and "active"
                or "normal"
        )
    end
end

function UI:CreateOverviewPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    local heading = panel:CreateFontString(
        nil, "OVERLAY", "GameFontNormalLarge"
    )
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
    heading:SetText("Overview")

    local status = panel:CreateFontString(
        nil, "OVERLAY", "GameFontHighlight"
    )
    status:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -14)
    status:SetWidth(740)
    status:SetJustifyH("LEFT")
    self.overviewStatus = status

    local reservedHeading = panel:CreateFontString(
        nil, "OVERLAY", "GameFontNormal"
    )
    reservedHeading:SetPoint(
        "TOPLEFT",
        status,
        "BOTTOMLEFT",
        0,
        -22
    )
    reservedHeading:SetText("My Molten Core Wishlist")

    local reservedHint = panel:CreateFontString(
        nil, "OVERLAY", "GameFontDisableSmall"
    )
    reservedHint:SetPoint(
        "LEFT",
        reservedHeading,
        "RIGHT",
        12,
        0
    )
    reservedHint:SetText(
        "Reserved items and their raid outcome"
    )

    local header = CreateFrame("Frame", nil, panel)
    header:SetPoint(
        "TOPLEFT",
        reservedHeading,
        "BOTTOMLEFT",
        0,
        -10
    )
    header:SetWidth(745)
    header:SetHeight(22)
    self:RegisterSkinnedFrame(
        header,
        "header"
    )

    local function HeaderText(text, x, width)
        local f = header:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
        f:SetPoint("LEFT", header, "LEFT", x, 0)
        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    HeaderText("Item", 45, 315)
    HeaderText("Boss / Source", 365, 245)
    HeaderText("Winner", 615, 120)

    self.overviewReservedRows = {}

    for rowIndex = 1, 6 do
        local row = CreateFrame("Frame", nil, panel)

        row:SetPoint(
            "TOPLEFT",
            header,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 52)
        )

        row:SetWidth(745)
        row:SetHeight(50)

        self:RegisterSkinnedFrame(
            row,
            (rowIndex % 2) == 0
                and "rowAlt"
                or "row"
        )

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(34)
        icon:SetHeight(34)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)

        local iconHit = CreateFrame("Button", nil, row)
        iconHit:SetWidth(34)
        iconHit:SetHeight(34)
        iconHit:SetPoint("CENTER", icon, "CENTER", 0, 0)

        iconHit:SetScript(
            "OnEnter",
            function(self)
                if not self.itemID then
                    return
                end

                GameTooltip:SetOwner(
                    self,
                    "ANCHOR_RIGHT"
                )

                GameTooltip:SetHyperlink(
                    "item:" ..
                    tostring(self.itemID) ..
                    ":0:0:0:0:0:0:0"
                )

                GameTooltip:Show()
            end
        )

        iconHit:SetScript(
            "OnLeave",
            function()
                GameTooltip:Hide()
            end
        )

        local itemText = row:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlight"
        )
        itemText:SetPoint(
            "TOPLEFT",
            row,
            "TOPLEFT",
            45,
            -6
        )
        itemText:SetWidth(310)
        itemText:SetJustifyH("LEFT")

        local idText = row:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontDisableSmall"
        )
        idText:SetPoint(
            "TOPLEFT",
            itemText,
            "BOTTOMLEFT",
            0,
            -3
        )
        idText:SetWidth(310)
        idText:SetJustifyH("LEFT")

        local sourceText = row:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )
        sourceText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            365,
            0
        )
        sourceText:SetWidth(240)
        sourceText:SetJustifyH("LEFT")

        local winnerText = row:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )
        winnerText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            615,
            0
        )
        winnerText:SetWidth(120)
        winnerText:SetJustifyH("LEFT")

        row.icon = icon
        row.iconHit = iconHit
        row.itemText = itemText
        row.idText = idText
        row.sourceText = sourceText
        row.winnerText = winnerText
        row.itemID = nil

        self.overviewReservedRows[rowIndex] = row
    end

    local footer = panel:CreateFontString(
        nil, "OVERLAY", "GameFontDisableSmall"
    )

    footer:SetPoint(
        "BOTTOMLEFT",
        panel,
        "BOTTOMLEFT",
        12,
        12
    )

    footer:SetWidth(740)
    footer:SetJustifyH("LEFT")

    footer:SetText(
        "Winner is intentionally blank until an item is actually awarded."
    )

    self.overviewFooter = footer
    self.overviewPanel = panel
end

function UI:RefreshOverview()
    if not self.overviewStatus then
        return
    end

    local raidCount = 0
    if NLL.Roster then
        raidCount = NLL.Roster:GetCount()
    end

    local reservedCount = 0
    if NLL.ItemSearch then
        reservedCount = NLL.ItemSearch:GetReservationCount()
    end

    local sim=NLL.DebugSimulator and NLL.DebugSimulator:IsActive()
    if sim then
        reservedCount=#NLL.DebugSimulator:GetNeeds()
    end
    self.overviewStatus:SetText(
        (sim and "|cffffcc33[SIMULATION] |r" or "") ..
        "Raid members detected: |cffffffff" ..
        tostring(raidCount) ..
        (sim and "|r     Fake gear needs: |cffffffff" or
         "|r     Molten Core items reserved locally: |cffffffff") ..
        tostring(reservedCount) ..
        "|r"
    )

    if not self.overviewReservedRows then
        return
    end

    local playerName = UnitName("player")
    local wishlist = {}

    if playerName and NLL.Database then
        wishlist =
            NLL.Database:GetLocalWishlist(
                playerName,
                "MOLTEN_CORE"
            ) or {}
    end
    if sim then
        wishlist={}
        for _,need in ipairs(NLL.DebugSimulator:GetNeeds()) do
            if need.state=="NEEDED" then wishlist[need.itemID]=true end
        end
        -- Keep the drop visible even after the simulated winner's need
        -- changes to OBTAINED; this is a result, not an award.
        local active = NLL.DebugSimulator.active
        if active then
            for _,entry in ipairs(active.entries or {}) do
                if NLL.DebugSimulator:GetResultFor(entry) then
                    wishlist[entry.itemID]=true
                end
            end
        end
    end
    if self.overviewFooter then
        self.overviewFooter:SetText(sim and
            "|cffffbb66SIMULATION: Winners below are fake results; no real gear awarded.|r" or
            "Real winner only appears after leader reports manual award (not receipt-verified).")
    end

    local items = {}

    for itemID, wanted in pairs(wishlist) do
        if wanted then
            local item =
                NLL.Data.MoltenCore:GetItem(
                    tonumber(itemID)
                )

            if item then
                table.insert(items, item)
            end
        end
    end

    table.sort(
        items,
        function(a, b)
            if sim and NLL.DebugSimulator.active and NLL.DebugSimulator.active.result then
                local winnerItemID=NLL.DebugSimulator.active.itemID
                if a.itemID==winnerItemID and b.itemID~=winnerItemID then return true end
                if b.itemID==winnerItemID and a.itemID~=winnerItemID then return false end
            end
            return string.lower(a.name) < string.lower(b.name)
        end
    )

    for rowIndex = 1, #self.overviewReservedRows do
        local row =
            self.overviewReservedRows[rowIndex]

        local item = items[rowIndex]

        if item then
            row.itemID = item.itemID
            row.iconHit.itemID = item.itemID

            local texture = nil

            if GetItemIcon then
                texture =
                    GetItemIcon(item.itemID)
            end

            if not texture and GetItemInfo then
                local _, _, _, _, _, _, _, _, _, cachedTexture =
                    GetItemInfo(item.itemID)

                texture = cachedTexture
            end

            row.icon:SetTexture(
                texture
                or "Interface\\Icons\\INV_Misc_QuestionMark"
            )

            row.itemText:SetText(item.name)

            row.idText:SetText(
                "Item ID: " ..
                tostring(item.itemID)
            )

            row.sourceText:SetText(
                NLL.Data.MoltenCore:GetBossText(
                    item
                )
            )

            -- Fake winners are visible only during their fake session.
            -- This never represents a real loot award.
            local simResult=nil
            if sim and NLL.DebugSimulator.active then
                for _,entry in ipairs(NLL.DebugSimulator.active.entries or {}) do
                    if entry.itemID==item.itemID then
                        simResult=NLL.DebugSimulator:GetResultFor(entry)
                        if simResult then break end
                    end
                end
            end
            if simResult then
                row.winnerText:SetText('|cff66ff99'..simResult.winner..
                    (simResult.awardStatus and ' [SIM AWARD]' or ' [SIM ROLL]')..'|r')
            else
                local report=nil
                if not sim then
                    for _,entry in ipairs(NLL.LootDetection:GetCurrentLoot() or {}) do
                        if entry.itemID==item.itemID then
                            local result=NLL.AwardWorkflow and
                                NLL.AwardWorkflow:GetOutcome(entry)
                            if result and result.awardStatus then
                                report=result
                                break
                            end
                        end
                    end
                end
                local tag = ''
                if report then
                    if report.awardStatus=='LEADER_REPORTED' then tag=' [REPORTED]'
                    elseif report.awardStatus=='AWARD_REQUESTED' then tag=' [SENT]'
                    elseif report.awardStatus=='LOOT_SLOT_CLEARED' then tag=' [SLOT CLEARED]'
                    else tag=' [UNVERIFIED]' end
                end
                row.winnerText:SetText(report and
                    ('|cff66ff99'..report.winner..tag..'|r') or '')
            end

            row:Show()
        else
            row.itemID = nil
            row.iconHit.itemID = nil
            row:Hide()
        end
    end

    if #items > #self.overviewReservedRows then
        local lastRow =
            self.overviewReservedRows[
                #self.overviewReservedRows
            ]

        lastRow.itemID = nil
        lastRow.iconHit.itemID = nil
        lastRow.icon:SetTexture(nil)

        lastRow.itemText:SetText(
            "+ " ..
            tostring(
                #items
                - #self.overviewReservedRows
                + 1
            ) ..
            " more reserved item(s)"
        )

        lastRow.idText:SetText("")
        lastRow.sourceText:SetText(
            "Full wishlist view coming in Phase 4."
        )
        lastRow.winnerText:SetText("")
        lastRow:Show()
    end
end

function UI:ShowPanel(panelName)
    -- Close the drop-scoped review overlay when changing tabs.
    if self.candidateReviewPanel then self.candidateReviewPanel:Hide() end
    if self.awardReviewFrame then self.awardReviewFrame:Hide() end
    if NLL.AwardWorkflow then NLL.AwardWorkflow:Cancel() end
    if self.overviewPanel then self.overviewPanel:Hide() end
    if self.rolesPanel then self.rolesPanel:Hide() end
    if self.searchPanel then self.searchPanel:Hide() end
    if self.wishlistPanel then self.wishlistPanel:Hide() end
    if self.currentLootPanel then self.currentLootPanel:Hide() end
    if self.settingsPanel then self.settingsPanel:Hide() end

    if panelName == "roles" then
        self.rolesPanel:Show()
        self:RefreshRolesPanel()
    elseif panelName == "search" then
        self.searchPanel:Show()
        self:RefreshSearchPanel()
    elseif panelName == "wishlist" then
        self.wishlistPanel:Show()
        self:RefreshWishlistPanel()
    elseif panelName == "currentloot" then
        self.currentLootPanel:Show()
        self:RefreshCurrentLootPanel()
    elseif panelName == "settings" then
        self.settingsPanel:Show()
        self:RefreshSettingsPanel()
    else
        panelName = "overview"
        self.overviewPanel:Show()
        self:RefreshOverview()
    end

    self.currentPanel = panelName
    self:SetActiveNav(panelName)
end

function UI:ShowMainFrame(panelName)
    if not self.mainFrame then
        self:CreateMainFrame()
    end

    self:ShowPanel(panelName or self.currentPanel or "overview")
    self.mainFrame:Show()
    self:RefreshSimulationIndicator()
end

function UI:HideMainFrame()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

function UI:ToggleMainFrame()
    if not self.mainFrame then
        self:CreateMainFrame()
    end

    if self.mainFrame:IsShown() then
        self:HideMainFrame()
    else
        self:ShowMainFrame()
    end
end

function UI:RefreshSimulationIndicator()
    if not self.simulationBadge then return end
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        self.simulationBadge:Show()
    else self.simulationBadge:Hide() end
end
