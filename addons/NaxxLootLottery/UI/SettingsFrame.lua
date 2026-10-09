-- ============================================================
-- Naxxramas Loot Ledger
-- UI/SettingsFrame.lua
-- ============================================================

local NLL = NaxxLootLottery
local UI = NLL.UI

function UI:CreateSettingsPanel(parent)
    local panel =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    panel:SetAllPoints(parent)

    local heading =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalLarge"
        )

    heading:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        12,
        -10
    )

    heading:SetText("Settings")

    local appearanceButton =
        self:CreateTextButton(
            panel,
            "Appearance",
            100
        )

    appearanceButton:SetPoint(
        "TOPLEFT",
        heading,
        "BOTTOMLEFT",
        0,
        -10
    )

    local priorityButton =
        self:CreateTextButton(
            panel,
            "Priority Setup",
            112
        )

    priorityButton:SetPoint(
        "LEFT",
        appearanceButton,
        "RIGHT",
        8,
        0
    )

    local debugButton = self:CreateTextButton(panel, "Debug Lab", 95)
    debugButton:SetPoint("LEFT", priorityButton, "RIGHT", 8, 0)

    local awardButton = self:CreateTextButton(panel, "Loot Awards", 110)
    awardButton:SetPoint("LEFT", debugButton, "RIGHT", 8, 0)

    local awardPage = CreateFrame("Frame", nil, panel)
    awardPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -72)
    awardPage:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)

    local historyButton = self:CreateTextButton(panel, "Award History", 110)
    historyButton:SetPoint("LEFT", awardButton, "RIGHT", 8, 0)

    local historyPage = CreateFrame("Frame", nil, panel)
    historyPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -72)
    historyPage:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)

    local debugPage = CreateFrame("Frame", nil, panel)
    debugPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -72)
    debugPage:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)

    local appearancePage =
        CreateFrame(
            "Frame",
            nil,
            panel
        )

    appearancePage:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        10,
        -72
    )

    appearancePage:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        -10,
        10
    )

    local priorityPage =
        CreateFrame(
            "Frame",
            nil,
            panel
        )

    priorityPage:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        10,
        -72
    )

    priorityPage:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        -10,
        10
    )

    local appearance =
        appearancePage:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormal"
        )

    appearance:SetPoint(
        "TOPLEFT",
        appearancePage,
        "TOPLEFT",
        8,
        -4
    )

    appearance:SetText("Appearance")

    local help =
        appearancePage:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    help:SetPoint(
        "TOPLEFT",
        appearance,
        "BOTTOMLEFT",
        0,
        -10
    )

    help:SetWidth(690)
    help:SetJustifyH("LEFT")

    help:SetText(
        "Choose how Naxxramas Loot Ledger looks on this client. " ..
        "The skin changes appearance only; all loot data and functions remain identical."
    )

    local dark =
        self:CreateTextButton(
            appearancePage,
            "NLL Dark",
            150
        )

    dark:SetPoint(
        "TOPLEFT",
        help,
        "BOTTOMLEFT",
        0,
        -26
    )

    local vanilla =
        self:CreateTextButton(
            appearancePage,
            "Vanilla WoW",
            150
        )

    vanilla:SetPoint(
        "LEFT",
        dark,
        "RIGHT",
        12,
        0
    )

    dark:SetScript(
        "OnClick",
        function()
            UI:SetSkin("DARK")
        end
    )

    vanilla:SetScript(
        "OnClick",
        function()
            UI:SetSkin("VANILLA")
        end
    )

    local description =
        appearancePage:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlight"
        )

    description:SetPoint(
        "TOPLEFT",
        dark,
        "BOTTOMLEFT",
        0,
        -28
    )

    description:SetWidth(690)
    description:SetJustifyH("LEFT")

    local details =
        appearancePage:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    details:SetPoint(
        "TOPLEFT",
        description,
        "BOTTOMLEFT",
        0,
        -16
    )

    details:SetWidth(690)
    details:SetJustifyH("LEFT")

    local note =
        appearancePage:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontDisableSmall"
        )

    note:SetPoint(
        "TOPLEFT",
        details,
        "BOTTOMLEFT",
        0,
        -22
    )

    note:SetWidth(690)
    note:SetJustifyH("LEFT")

    note:SetText(
        "Skin changes apply immediately and are saved. No /reload is required."
    )

    self:CreateAwardSettingsContent(awardPage)
    self:CreateAwardHistoryContent(historyPage)

    self:CreateDebugLabContent(debugPage)

    self:CreatePrioritySettingsContent(
        priorityPage
    )

    appearanceButton:SetScript(
        "OnClick",
        function()
            UI.settingsMode =
                "appearance"

            UI:RefreshSettingsPanel()
        end
    )

    priorityButton:SetScript(
        "OnClick",
        function()
            UI.settingsMode =
                "priority"

            UI:RefreshSettingsPanel()
        end
    )

    debugButton:SetScript("OnClick", function()
        UI.settingsMode = "debug"
        UI:RefreshSettingsPanel()
    end)

    awardButton:SetScript("OnClick", function()
        UI.settingsMode = "awards"
        UI:RefreshSettingsPanel()
    end)

    historyButton:SetScript("OnClick", function()
        UI.settingsMode = "history"
        UI:RefreshSettingsPanel()
    end)
    self.settingsHistoryButton = historyButton
    self.settingsHistoryPage = historyPage
    self.settingsAwardButton = awardButton
    self.settingsAwardPage = awardPage
    self.settingsDebugButton = debugButton
    self.settingsDebugPage = debugPage
    self.settingsAppearanceButton =
        appearanceButton

    self.settingsPriorityButton =
        priorityButton

    self.settingsAppearancePage =
        appearancePage

    self.settingsPriorityPage =
        priorityPage

    self.settingsDarkButton = dark
    self.settingsVanillaButton = vanilla
    self.settingsSkinDescription = description
    self.settingsSkinDetails = details

    self.settingsMode =
        self.settingsMode
        or "appearance"

    self.settingsPanel = panel

    panel:Hide()
end

function UI:RefreshSettingsPanel()
    if not self.settingsPanel then
        return
    end

    local mode =
        self.settingsMode
        or "appearance"

    self.settingsAppearancePage:Hide()
    self.settingsPriorityPage:Hide()
    self.settingsDebugPage:Hide()
    self.settingsAwardPage:Hide()
    self.settingsHistoryPage:Hide()

    self:SetButtonState(
        self.settingsAppearanceButton,
        mode == "appearance"
            and "active"
            or "normal"
    )

    self:SetButtonState(
        self.settingsPriorityButton,
        mode == "priority"
            and "active"
            or "normal"
    )

    self:SetButtonState(self.settingsDebugButton,
        mode == "debug" and "active" or "normal")

    self:SetButtonState(self.settingsAwardButton,
        mode == "awards" and "active" or "normal")

    self:SetButtonState(self.settingsHistoryButton,
        mode == "history" and "active" or "normal")

    if mode == "history" then
        self.settingsHistoryPage:Show()
        self:RefreshAwardHistory()
        return
    end

    if mode == "awards" then
        self.settingsAwardPage:Show()
        self:RefreshAwardSettingsContent()
        return
    end

    if mode == "debug" then
        self.settingsDebugPage:Show()
        self:RefreshDebugLab()
        return
    end

    if mode == "priority" then
        self.settingsPriorityPage:Show()
        self:RefreshPrioritySetup()
        return
    end

    self.settingsMode =
        "appearance"

    self.settingsAppearancePage:Show()

    local skinID =
        self:GetSkinID()

    self:SetButtonState(
        self.settingsDarkButton,
        skinID == "DARK"
            and "active"
            or "normal"
    )

    self:SetButtonState(
        self.settingsVanillaButton,
        skinID == "VANILLA"
            and "active"
            or "normal"
    )

    if skinID == "VANILLA" then
        self.settingsSkinDescription:SetText(
            "Vanilla WoW: actual Wrath quest-window parchment artwork with old Blizzard framing."
        )

        self.settingsSkinDetails:SetText(
            "Uses the four Wrath-era QuestFramePanelTemplate parchment textures, " ..
            "classic panel-button artwork, warm brown rows, and gold borders."
        )
    else
        self.settingsSkinDescription:SetText(
            "NLL Dark: the compact dark interface used by the addon so far."
        )

        self.settingsSkinDetails:SetText(
            "Keeps the current clean dark presentation and compact raid-addon layout."
        )
    end
end
