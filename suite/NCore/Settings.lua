-- N Addon Suite module control panel, WoW 3.3.5a / Lua 5.1.
-- Addons cannot be safely unloaded after they have loaded. Apply with /reload.

local Suite = NCore
local panel
local rows = {}

local function MakeLabel(parent, font, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function MakeButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetText(label)
    return button
end

local function Refresh()
    if not panel then return end

    for _, entry in ipairs(rows) do
        local row = entry.row
        local enabled, installed = Suite:IsEnabled(entry.module.folder)
        row.check:SetChecked(installed and enabled)
        if installed then
            row.check:Enable()
            if enabled then
                row.status:SetText("|cff65d86aEnabled|r")
            else
                row.status:SetText("|cffedb96bDisabled|r")
            end
        else
            row.check:Disable()
            row.status:SetText("|cffff7878Not installed|r")
        end
    end

    if Suite.needsReload then
        panel.notice:SetText("|cffffcc66Changes saved. Reload UI to apply.|r")
        panel.reload:Enable()
    else
        panel.notice:SetText("Choose which optional addons load when the UI starts.")
        panel.reload:Disable()
    end
end

local function CreatePanel()
    if panel then return panel end

    panel = CreateFrame("Frame", "NSuiteSettingsFrame", UIParent)
    panel:SetWidth(620)
    panel:SetHeight(485)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
    panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    panel:SetClampedToScreen(true)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 10, right = 10, top = 10, bottom = 10 }
    })
    panel:Hide()

    local title = MakeLabel(panel, "GameFontNormalLarge", "N Addon Suite", 27, -23)
    title:SetTextColor(1, 0.85, 0.35)
    MakeLabel(panel, "GameFontHighlightSmall", "Core v" .. Suite.version .. "   |   WoW 3.3.5a", 28, -49)

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)

    MakeLabel(panel, "GameFontNormal", "Required feature", 28, -82)
    local locked = MakeLabel(panel, "GameFontHighlight", "N Classic Battlegrounds", 43, -111)
    locked:SetTextColor(0.9, 0.95, 1)
    local padlock = MakeLabel(panel, "GameFontNormalSmall", "ALWAYS ON", 494, -111)
    padlock:SetTextColor(0.4, 0.95, 0.48)
    MakeLabel(panel, "GameFontDisableSmall", "Expansion-aware PvP interface. Cannot be switched off individually.", 43, -131)

    MakeLabel(panel, "GameFontNormal", "Optional modules", 28, -161)

    for index, module in ipairs(Suite.modules) do
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 28, -181 - (index - 1) * 55)
        row:SetWidth(565)
        row:SetHeight(51)

        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
        check:SetWidth(25)
        check:SetHeight(25)

        local text = MakeLabel(row, "GameFontHighlight", module.title, 34, -3)
        text:SetTextColor(0.95, 0.95, 0.95)
        local desc = MakeLabel(row, "GameFontDisableSmall", module.description, 34, -25)
        desc:SetWidth(385)
        desc:SetJustifyH("LEFT")

        local status = MakeLabel(row, "GameFontNormalSmall", "", 461, -7)
        status:SetWidth(94)
        status:SetJustifyH("RIGHT")

        check:SetScript("OnClick", function(self)
            local desired = self:GetChecked() and true or false
            local ok, problem = Suite:SetEnabled(module.folder, desired)
            if not ok then
                Suite:Print(problem)
            end
            Refresh()
        end)

        row.check = check
        row.status = status
        rows[index] = { row = row, module = module }
    end

    panel.notice = MakeLabel(panel, "GameFontHighlightSmall", "", 28, -416)
    panel.notice:SetWidth(400)
    panel.notice:SetJustifyH("LEFT")

    panel.reload = MakeButton(panel, "Reload UI", 100, 24)
    panel.reload:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -27, 24)
    panel.reload:SetScript("OnClick", function() Suite:RequestReload() end)

    local hint = MakeLabel(panel, "GameFontDisableSmall", "Classic Battlegrounds remains active whenever NCore loads.", 28, -448)
    hint:SetWidth(440)

    panel:SetScript("OnShow", Refresh)
    return panel
end

function Suite:ToggleSettings()
    local frame = CreatePanel()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        Refresh()
    end
end
