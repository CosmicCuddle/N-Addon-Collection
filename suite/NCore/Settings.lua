-- N Addon Suite module control panel, WoW 3.3.5a / Lua 5.1.
-- Addons cannot be safely unloaded once running; use Reload UI.
-- This layout is intentionally compact to fit WoW's larger UI fonts.

local Suite = NCore
local panel
local rows = {}

local function MakeLabel(parent, font, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    label:SetJustifyH("LEFT")
    return label
end

local function MakeButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetText(label)
    return button
end

local function Separator(parent, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(0.70, 0.54, 0.25, 0.40)
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", 28, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -28, y)
    line:SetHeight(1)
end

local function Refresh()
    if not panel then return end

    for _, entry in ipairs(rows) do
        local enabled, installed = Suite:IsEnabled(entry.module.folder)
        entry.row.check:SetChecked(installed and enabled)

        if installed then
            entry.row.check:Enable()
            if enabled then
                entry.row.status:SetText("|cff65d86aEnabled|r")
            else
                entry.row.status:SetText("|cffedb96bDisabled|r")
            end
        else
            entry.row.check:Disable()
            entry.row.status:SetText("|cffff7878Not installed|r")
        end
    end

    if Suite.needsReload then
        panel.notice:SetText("|cffffcc66Changes saved. Reload to apply.|r")
        panel.reload:Enable()
    else
        panel.notice:SetText("Choose modules. Reload after changes.")
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

    -- A nearly opaque solid backing keeps nameplates, players and bright
    -- scenery from competing with the settings text.
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 32,
        insets = { left = 10, right = 10, top = 10, bottom = 10 }
    })
    panel:SetBackdropColor(0.025, 0.02, 0.025, 0.96)
    panel:SetBackdropBorderColor(0.68, 0.55, 0.28, 1)
    panel:Hide()

    local title = MakeLabel(panel, "GameFontNormalLarge", "N Addon Suite", 28, -23)
    title:SetTextColor(1, 0.85, 0.35)
    MakeLabel(panel, "GameFontHighlightSmall", "Core v" .. Suite.version .. "  |  WoW 3.3.5a", 28, -49)

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)
    Separator(panel, -72)

    MakeLabel(panel, "GameFontNormal", "Required feature", 28, -86)
    local required = MakeLabel(panel, "GameFontHighlight", "N Classic Battlegrounds", 43, -113)
    required:SetTextColor(0.95, 0.95, 1)

    local requiredStatus = MakeLabel(panel, "GameFontNormalSmall", "ALWAYS ON", 0, 0)
    requiredStatus:ClearAllPoints()
    requiredStatus:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -34, -114)
    requiredStatus:SetJustifyH("RIGHT")
    requiredStatus:SetTextColor(0.40, 0.95, 0.48)

    local requiredHint = MakeLabel(panel, "GameFontDisableSmall", "PvP era controls are part of the core; no separate toggle.", 43, -138)
    requiredHint:SetWidth(530)

    Separator(panel, -162)
    MakeLabel(panel, "GameFontNormal", "Optional modules", 28, -177)

    -- Descriptions span the full row below the title. Status appears on the
    -- title line, so long descriptions cannot collide with status labels.
    for index, module in ipairs(Suite.modules) do
        local moduleInfo = module  -- dedicated upvalue for the click handler
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 28, -200 - (index - 1) * 51)
        row:SetWidth(564)
        row:SetHeight(47)

        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
        check:SetWidth(25)
        check:SetHeight(25)

        local name = MakeLabel(row, "GameFontHighlight", module.title, 34, -3)
        name:SetWidth(365)
        name:SetTextColor(0.95, 0.95, 0.95)

        local desc = MakeLabel(row, "GameFontDisableSmall", module.description, 34, -26)
        desc:SetWidth(515)
        desc:SetHeight(16)

        local status = MakeLabel(row, "GameFontNormalSmall", "", 0, 0)
        status:ClearAllPoints()
        status:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -5)
        status:SetWidth(126)
        status:SetJustifyH("RIGHT")

        check:SetScript("OnClick", function(self)
            local desired = self:GetChecked() and true or false
            local ok, problem = Suite:SetEnabled(moduleInfo.folder, desired)
            if not ok then
                Suite:Print(problem)
            end
            Refresh()
        end)

        row.check = check
        row.status = status
        rows[index] = { row = row, module = moduleInfo }
    end

    Separator(panel, -419)
    panel.notice = MakeLabel(panel, "GameFontHighlightSmall", "", 28, -441)
    panel.notice:SetWidth(430)
    panel.notice:SetHeight(18)

    panel.reload = MakeButton(panel, "Reload UI", 100, 25)
    panel.reload:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 23)
    panel.reload:SetScript("OnClick", function() Suite:RequestReload() end)

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
