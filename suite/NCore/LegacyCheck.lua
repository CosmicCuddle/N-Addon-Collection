-- N Addon Suite legacy-installation check for WoW 3.3.5a / Lua 5.1.
-- Quietly inspects the client's registered addon list at login. A warning is
-- only shown when a known obsolete folder or older *installed* TOC version is
-- found. No files, saved settings, or addon enable states are modified.

local Suite = NCore
local warningFrame

-- Exact historical addon folder IDs. Never match loosely on "N", "Journal",
-- etc: similarly named unrelated addons must not trigger a false warning.
local LEGACY_FOLDERS = {
    ServerDungeonJournal = "older Dungeon Journal installation",
    NaxxramasClassicBattlegrounds = "older Classic Battlegrounds installation",
    NClassicBattlegrounds = "standalone Classic Battlegrounds (now built into NCore)",
    ["N-ClassicBattlegrounds"] = "older Classic Battlegrounds installation",
}

local function ParseVersion(version)
    if type(version) ~= "string" then return nil end
    local numeric = version:match("^%s*[vV]?(%d[%d%.]*)")
    if not numeric then return nil end
    local parts = {}
    for digits in numeric:gmatch("%d+") do
        parts[#parts + 1] = tonumber(digits)
    end
    if #parts == 0 then return nil end

    -- Two versions with equal numeric parts: a beta/rc is older than a
    -- release. We do not infer order among different prerelease labels.
    local remainder = version:sub((version:find(numeric, 1, true) or 1) + #numeric)
    local prerelease = remainder:match("^%s*[-_]") ~= nil
    return parts, prerelease
end

local function IsOlder(installed, expected)
    local current, currentPre = ParseVersion(installed)
    local target, targetPre = ParseVersion(expected)
    if not current or not target then return false end
    for index = 1, math.max(#current, #target) do
        local x, y = current[index] or 0, target[index] or 0
        if x ~= y then return x < y end
    end
    return currentPre and not targetPre or false
end

local function ReadMetadata(folder, index)
    if type(GetAddOnMetadata) ~= "function" then return nil end
    -- Older client implementations vary on whether they accept addon names
    -- or indexes. Try both without breaking login if one form fails.
    local ok, value = pcall(GetAddOnMetadata, folder, "Version")
    if ok and type(value) == "string" and value ~= "" then return value end
    ok, value = pcall(GetAddOnMetadata, index, "Version")
    if ok and type(value) == "string" and value ~= "" then return value end
    return nil
end

local function GetOptionalVersion(folder)
    local expected = Suite.expectedVersions
    if type(expected) ~= "table" then return nil end
    return expected[folder]
end

function Suite:ScanLegacyInstallations()
    local issues = {}
    if type(GetNumAddOns) ~= "function" or
       type(GetAddOnInfo) ~= "function" then
        return issues
    end

    for index = 1, GetNumAddOns() do
        local folder = GetAddOnInfo(index)
        if type(folder) == "string" then
            local oldReason = LEGACY_FOLDERS[folder]
            if oldReason then
                issues[#issues + 1] = {
                    folder = folder,
                    kind = "legacy",
                    detail = oldReason
                }
            else
                local required = GetOptionalVersion(folder)
                if required then
                    local found = ReadMetadata(folder, index)
                    if found and IsOlder(found, required) then
                        issues[#issues + 1] = {
                            folder = folder,
                            kind = "outdated",
                            detail = "installed v" .. found ..
                                "; bundled v" .. required
                        }
                    end
                end
            end
        end
    end

    table.sort(issues, function(a, b) return a.folder < b.folder end)
    return issues
end

local function AddLabel(parent, font, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function CreateWarningFrame()
    if warningFrame then return warningFrame end
    local frame = CreateFrame("Frame", "NSuiteLegacyWarningFrame", UIParent)
    frame:SetWidth(620)
    frame:SetHeight(355)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)
    if UIParent and UIParent.GetWidth and UIParent.GetHeight then
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        if type(width) == "number" and type(height) == "number"
            and width > 100 and height > 100 then
            frame:SetScale(math.max(0.65, math.min(
                1, (width - 48) / 620, (height - 48) / 355
            )))
        end
    end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 32,
        insets = { left = 10, right = 10, top = 10, bottom = 10 }
    })
    frame:SetBackdropColor(0.035, 0.025, 0.025, 0.98)
    frame:SetBackdropBorderColor(0.85, 0.40, 0.24, 1)

    local title = AddLabel(frame, "GameFontNormalLarge",
        "N Addon Suite - Older addons detected", 29, -27, 510)
    title:SetTextColor(1, 0.76, 0.38)

    AddLabel(frame, "GameFontHighlightSmall",
        "An older or duplicate addon may still load alongside the suite.",
        30, -67, 550)

    frame.lines = {}
    for i = 1, 6 do
        local line = AddLabel(frame, "GameFontHighlightSmall", "",
            32, -100 - (i - 1) * 24, 548)
        line:SetHeight(21)
        frame.lines[i] = line
    end

    frame.more = AddLabel(frame, "GameFontNormalSmall", "",
        32, -250, 548)
    frame.help = AddLabel(frame, "GameFontHighlightSmall",
        "Close WoW, back up the listed folders, and move old copies",
        30, -272, 550)
    AddLabel(frame, "GameFontHighlightSmall",
        "outside Interface/AddOns. Keep your WTF SavedVariables.",
        30, -291, 550)

    frame.dismiss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.dismiss:SetWidth(110)
    frame.dismiss:SetHeight(25)
    frame.dismiss:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 24)
    frame.dismiss:SetText("Dismiss")
    frame.dismiss:SetScript("OnClick", function() frame:Hide() end)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -9, -9)
    frame:Hide()
    warningFrame = frame
    return frame
end

function Suite:ShowLegacyWarning(issues)
    if type(issues) ~= "table" or #issues == 0 then return false end
    local frame = CreateWarningFrame()
    for i = 1, #frame.lines do
        local issue = issues[i]
        local text = issue and (issue.folder .. ": " .. issue.detail) or ""
        frame.lines[i]:SetText(text)
    end
    if #issues > #frame.lines then
        frame.more:SetText("And " .. (#issues - #frame.lines) ..
            " more; use /nsuite check to rescan after cleaning up.")
    else
        frame.more:SetText("")
    end
    frame:Show()
    return true
end

function Suite:CheckLegacyInstallations(quiet)
    local issues = self:ScanLegacyInstallations()
    self.legacyIssues = issues
    if #issues > 0 then
        self:ShowLegacyWarning(issues)
        if not quiet then
            self:Print(#issues .. " older or duplicate addon folder(s) found.")
        end
    elseif not quiet then
        self:Print("No registered older or duplicate addon folders detected.")
    end
    return issues
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        Suite:CheckLegacyInstallations(true)
    end
end)
