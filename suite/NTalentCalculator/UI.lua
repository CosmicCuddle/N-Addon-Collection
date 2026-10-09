-- N Talent Calculator - visual, read-only 3-tree planner (WoW 3.3.5a).
-- Share/import the exact NT1 codes used on Naxxramas Resource Hub.
-- Select text and use Ctrl+C to copy: 3.3.5a has no clipboard-write API.

local M = NTalentCalculator
local window
local trees = {}
local buttons = {}
local shown = {}

local function Label(parent, font, content, x, y, width)
    local value = parent:CreateFontString(nil, "OVERLAY", font)
    value:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then value:SetWidth(width) end
    value:SetJustifyH("LEFT")
    value:SetText(content or "")
    return value
end

local function PushButton(parent, title, width, x, y, func)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(title)
    button:SetScript("OnClick", func)
    return button
end

local function ShowTooltip(button)
    local talent = button.talent
    if not talent or not GameTooltip then return end
    local count = M.points[talent[1]] or 0
    local maxRank = #talent[4]
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(talent[5], 1, 0.84, 0.34)
    GameTooltip:AddLine("Rank " .. count .. "/" .. maxRank, 1, 1, 1)
    local function ShowRank(rank, heading)
        local spell = talent[4][rank]
        local effect = M.Data.tooltips[tostring(spell)]
        local text = effect and effect[1] or
            (talent[10] and talent[10][rank]) or talent[6] or
            "Tooltip not available in the supplied Spell.dbc."
        GameTooltip:AddLine(heading .. " (rank " .. rank .. "):", 0.53, 0.80, 1)
        GameTooltip:AddLine(text, 0.94, 0.94, 0.94, true)
        if effect and effect[2] then
            GameTooltip:AddLine("Some effect values depend on the client.", 1, 0.64, 0.35, true)
        end
    end
    if count > 0 then ShowRank(count, "Current") end
    if count < maxRank then ShowRank(count + 1, "Next") end
    GameTooltip:AddLine("Left-click: add rank. Right-click: remove rank.", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

local function NewTalentButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(35, 35)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    button.icon = icon
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 3)
    border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, -3)
    button.border = border
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local rank = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    rank:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    rank:SetShadowOffset(1, -1)
    button.rank = rank
    button:SetScript("OnClick", function(self, mouseButton)
        local delta = mouseButton == "RightButton" and -1 or 1
        local ok, issue = M:Adjust(self.talent[1], delta)
        if not ok then M:Print(issue) end
        if GameTooltip then
            GameTooltip:Hide()
            ShowTooltip(self)
        end
    end)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:Hide()
    return button
end

local function UpdateLayout()
    local rule = M.ERA[M.era]
    if not window or not rule then return end
    local visibleRows = rule.maxRow + 1
    local height = 288 + visibleRows * 40
    window:SetHeight(height)
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    if screenW > 100 and screenH > 100 then
        window:SetScale(math.max(0.55, math.min(1,
            (screenW - 38) / 1030, (screenH - 38) / height)))
    end
end

local function CreateWindow()
    if window then return window end
    window = CreateFrame("Frame", "NTalentCalculatorFrame", UIParent)
    window:SetWidth(1030)
    window:SetHeight(730)
    window:SetPoint("CENTER", UIParent, "CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:SetClampedToScreen(true)
    window:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, edgeSize = 32,
        insets = {left=9, right=9, top=9, bottom=9}
    })
    window:SetBackdropColor(0.025, 0.025, 0.035, 0.98)
    window:SetBackdropBorderColor(0.69, 0.55, 0.29, 1)
    window:Hide()

    local heading = Label(window, "GameFontNormalLarge", "N Talent Calculator", 31, -22)
    heading:SetTextColor(1, 0.84, 0.34)
    Label(window, "GameFontDisableSmall", "Theorycraft only - this does not modify your character's talents", 32, -49, 600)

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -8, -8)

    window.era = Label(window, "GameFontNormal", "Checking Individual Progression...", 31, -79, 650)
    window.tierLabel = Label(window, "GameFontHighlightSmall", "", 31, -103, 450)
    window.budget = Label(window, "GameFontNormal", "", 778, -106, 210)

    window.previous = PushButton(window, "< Class", 91, 572, -76, function()
        M:CycleClass(-1)
    end)
    window.className = Label(window, "GameFontNormal", "", 674, -83, 135)
    window.nextClass = PushButton(window, "Class >", 91, 882, -76, function()
        M:CycleClass(1)
    end)

    for i=1,3 do
        local panel = CreateFrame("Frame", nil, window)
        panel:SetPoint("TOPLEFT", window, "TOPLEFT", 31 + (i-1)*328, -145)
        panel:SetWidth(308)
        panel:SetHeight(490)
        panel:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 14,
            insets = {left=3,right=3,top=3,bottom=3}
        })
        panel:SetBackdropColor(0.085, 0.08, 0.105, 0.90)
        panel:SetBackdropBorderColor(0.43, 0.35, 0.21, 1)
        local name = Label(panel, "GameFontNormal", "", 14, -10, 200)
        local count = Label(panel, "GameFontHighlightSmall", "", 243, -10, 55)
        count:SetJustifyH("RIGHT")
        trees[i] = {panel=panel, title=name, count=count}
    end

    -- All code sharing happens through the input field. Show code places a
    -- validated NT1 string here, and players use Ctrl+C to copy it.
    local codeLabel = Label(window, "GameFontNormalSmall",
        "Website-compatible NT1 build code (Ctrl+C to copy):", 31, -1, 450)
    codeLabel:ClearAllPoints()
    codeLabel:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 31, 80)

    window.code = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    window.code:SetSize(650, 26)
    window.code:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 43, 44)
    window.code:SetAutoFocus(false)
    window.code:SetMaxLetters(2000)
    window.code:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    window.code:SetScript("OnEnterPressed", function(self)
        local ok, reason = M:ImportCode(self:GetText())
        if not ok then M:Print(reason) else M:Print("Build imported.") end
        self:ClearFocus()
    end)

    window.exportButton = PushButton(window, "Show code", 95, 0, 0, function()
        local value = M:ExportCode()
        if not value then M:Print("Still waiting for progression tier.") return end
        window.code:SetText(value)
        window.code:SetFocus()
        window.code:HighlightText()
        M:Print("Code selected. Press Ctrl+C to copy.")
    end)
    window.exportButton:ClearAllPoints()
    window.exportButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -226, 45)

    window.importButton = PushButton(window, "Import", 85, 0, 0, function()
        local ok, reason = M:ImportCode(window.code:GetText())
        if not ok then M:Print(reason) else M:Print("Build imported.") end
    end)
    window.importButton:ClearAllPoints()
    window.importButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -133, 45)

    window.resetButton = PushButton(window, "Reset", 82, 0, 0, function()
        M.points = {}
        M:RefreshUI()
    end)
    window.resetButton:ClearAllPoints()
    window.resetButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -36, 45)

    window.notice = Label(window, "GameFontHighlightSmall",
        "Share builds with the website using NT1 codes. Save with /ntalent save NAME.", 32, -1, 880)
    window.notice:ClearAllPoints()
    window.notice:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 32, 20)
    return window
end

function M:CycleClass(step)
    if not self.era then self:Print("Waiting for your Individual Progression tier.") return end
    local index = 1
    for i, class in ipairs(self.CLASS_ORDER) do
        if class == self.class then index = i break end
    end
    for _=1,#self.CLASS_ORDER do
        index = ((index - 1 + step + #self.CLASS_ORDER) % #self.CLASS_ORDER) + 1
        local class = self.CLASS_ORDER[index]
        if class ~= "deathknight" or self.era == "wotlk" then
            self:SetClass(class)
            return
        end
    end
end

function M:RefreshUI()
    if not window or not window:IsShown() then return end
    if not self.era or not self:GetTrees(self.class) then
        window.era:SetText("Reading your Individual Progression tier...")
        window.tierLabel:SetText("Talent trees remain locked until the era is confirmed.")
        window.budget:SetText("")
        window.className:SetText("")
        for _, button in ipairs(buttons) do button:Hide() end
        for _, tree in ipairs(trees) do tree.panel:Hide() end
        return
    end

    UpdateLayout()
    local rule = self.ERA[self.era]
    window.era:SetText(rule.title .. "   |   Talent rows 1-" .. (rule.maxRow + 1))
    window.tierLabel:SetText(self.tier and ("Individual Progression: Tier " .. self.tier) or
        ("Individual Progression: " .. rule.title .. " (quest milestones)"))
    window.className:SetText(string.upper(self.class))
    window.budget:SetText(self:Spent() .. " / " .. (self.level - 9) .. " points")
    for _, button in ipairs(buttons) do button:Hide() end

    local poolIndex = 0
    for index, tree in ipairs(self:GetTrees()) do
        local view = trees[index]
        view.panel:Show()
        view.panel:SetHeight((rule.maxRow + 1) * 40 + 54)
        view.title:SetText(tree[2])
        view.count:SetText(self:TreeSpent(tree) .. " pts")
        for _, talent in ipairs(tree[4]) do
            if self:Available(talent, tree) then
                poolIndex = poolIndex + 1
                local button = buttons[poolIndex]
                if not button then
                    button = NewTalentButton(window)
                    buttons[poolIndex] = button
                end
                local row, col = talent[2], talent[3]
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", view.panel, "TOPLEFT",
                    25 + col*68, -43 - row*40)
                local iconKey = self.Data.icons[tostring(talent[9])]
                if type(iconKey) == "string" and
                    iconKey:match("^[a-zA-Z0-9_%-]+$") then
                    button.icon:SetTexture("Interface\\Icons\\" .. iconKey)
                else
                    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end
                button.talent = talent
                local rank = self.points[talent[1]] or 0
                button.rank:SetText(rank .. "/" .. #talent[4])
                if rank > 0 then
                    button.border:SetVertexColor(0.2, 0.95, 0.25)
                else
                    local trial = {}
                    for k,v in pairs(self.points) do trial[k] = v end
                    trial[talent[1]] = 1
                    local available = self:Validate(trial)
                    if available then
                        button.border:SetVertexColor(0.9, 0.75, 0.27)
                    else
                        button.border:SetVertexColor(0.45, 0.45, 0.45)
                    end
                end
                button:Show()
            end
        end
    end
    for i=poolIndex+1,#buttons do buttons[i]:Hide() end
end

function M:ToggleWindow()
    local frame = CreateWindow()
    if frame:IsShown() then frame:Hide() else frame:Show() self:RefreshUI() end
end

SLASH_NTALENT1 = "/ntalent"
SLASH_NTALENT2 = "/ntc"
SlashCmdList["NTALENT"] = function(text)
    text = (text or ""):match("^%s*(.-)%s*$")
    if text == "" then M:ToggleWindow()
    elseif text == "refresh" then
        M:RequestProgression()
        M:Print("Requested your Individual Progression tier from the server.")
    elseif text == "code" then
        M:ToggleWindow()
        local value = M:ExportCode()
        if window and value then
            window.code:SetText(value)
            window.code:SetFocus()
            window.code:HighlightText()
        end
    elseif text:sub(1,7) == "import " then
        local ok, reason = M:ImportCode(text:sub(8))
        if not ok then M:Print(reason) else M:Print("Build imported.") end
    elseif text:sub(1,5) == "save " then
        local ok, reason = M:SaveBuild(text:sub(6))
        M:Print(ok and "Build saved." or reason)
    elseif text:sub(1,5) == "load " then
        local ok, reason = M:LoadBuild(text:sub(6))
        M:Print(ok and "Saved build loaded." or reason)
    else
        M:Print("Commands: /ntalent, /ntalent code, /ntalent refresh, " ..
            "/ntalent import NT1:..., /ntalent save NAME, /ntalent load NAME")
    end
end
