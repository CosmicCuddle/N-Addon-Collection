-- WoW 3.3.5a / Lua 5.1 mock for silent legacy installation detection.
local objects = {}
local frameMethods = {}
local function mockFrame()
    return setmetatable({shown = false}, {__index = frameMethods})
end
function frameMethods:SetWidth(value) self.width = value end
function frameMethods:SetHeight(value) self.height = value end
function frameMethods:GetWidth() return self.width end
function frameMethods:GetHeight() return self.height end
function frameMethods:SetPoint(...) self.position = {...} end
function frameMethods:CreateFontString() return mockFrame() end
function frameMethods:SetTexture() end
function frameMethods:SetText(value) self.text = value end
function frameMethods:SetTextColor() end
function frameMethods:SetJustifyH() end
function frameMethods:SetBackdrop() end
function frameMethods:SetBackdropColor(...) self.background = {...} end
function frameMethods:SetBackdropBorderColor() end
function frameMethods:SetFrameStrata() end
function frameMethods:SetToplevel() end
function frameMethods:EnableMouse() end
function frameMethods:SetMovable() end
function frameMethods:RegisterForDrag() end
function frameMethods:SetClampedToScreen() end
function frameMethods:SetScale(value) self.scale = value end
function frameMethods:RegisterEvent(value) self.event = value end
function frameMethods:UnregisterEvent(value) self.event = nil end
function frameMethods:SetScript(event, callback)
    self.scripts = self.scripts or {}
    self.scripts[event] = callback
end
function frameMethods:SetChecked() end
function frameMethods:Show() self.shown = true end
function frameMethods:Hide() self.shown = false end
function frameMethods:IsShown() return self.shown end

UIParent = mockFrame()
UIParent.width, UIParent.height = 720, 550
local registration
function CreateFrame(kind, name)
    local frame = mockFrame()
    if name then _G[name] = frame end
    if kind == "Frame" and not name then registration = frame end
    return frame
end

local addons = {
    {name="NCore", version="2.0.0-alpha.1"},
    {name="DungeonJournal", version="0.6.1"},
    {name="IndividualProgressionAddon", version="5.2.0"},
    {name="MultiBot", version="4.0"},
    {name="NaxxLootLottery", version="0.1.0.27"},
}
function GetNumAddOns() return #addons end
function GetAddOnInfo(index) return addons[index].name end
function GetAddOnMetadata(value, key)
    assert(key == "Version", "Unexpected metadata lookup")
    for i, addon in ipairs(addons) do
        if value == i or value == addon.name then return addon.version end
    end
end

local messages = {}
NCore = {
    expectedVersions = {
        DungeonJournal = "0.6.1",
        IndividualProgressionAddon = "5.2.0",
        MultiBot = "4.0",
        NaxxLootLottery = "0.1.0.27",
    },
    Print = function(_, msg) messages[#messages + 1] = msg end,
}

dofile("suite/NCore/LegacyCheck.lua")
assert(registration and registration.event == "PLAYER_LOGIN",
    "Silent detector should register on login")
assert(#NCore:ScanLegacyInstallations() == 0, "Clean suite should have no warnings")
registration.scripts.OnEvent(registration, "PLAYER_LOGIN")
assert(NSuiteLegacyWarningFrame == nil,
    "Clean installation must not open a warning window")
assert(registration.event == nil, "Detector should unregister after login")

-- The optional preview must be labeled as an example and leave addon data intact.
local countBeforeDemo = #addons
local priorScan = NCore.legacyIssues
NCore:ShowLegacyWarningDemo()
local preview = NSuiteLegacyWarningFrame
assert(preview and preview:IsShown(), "The manual warning demo should appear")
assert(preview.title.text:find("Example warning", 1, true),
    "The simulated dialog must clearly identify itself as an example")
assert(#addons == countBeforeDemo, "A demo must not create additional addons")
assert(NCore.legacyIssues == priorScan, "A demo must not alter real scan results")
preview.dismiss.scripts.OnClick()


-- Older version in the current addon folder.
addons[2].version = "v0.5.9"
local old = NCore:ScanLegacyInstallations()
assert(#old == 1 and old[1].kind == "outdated", "Older version not detected")
assert(old[1].detail:find("0.6.1", 1, true), "Expected version not displayed")
NCore:CheckLegacyInstallations(true)
local dialog = NSuiteLegacyWarningFrame
assert(dialog and dialog:IsShown(), "On-screen warning not shown")
assert(dialog.background and dialog.background[4] >= 0.95,
    "Warning window should be readable")
assert(dialog.lines[1].text:find("DungeonJournal", 1, true),
    "Outdated folder missing from visible warning")
dialog.dismiss.scripts.OnClick()
assert(not dialog:IsShown(), "Dismiss button must close warning")

-- Current addon present but a previously renamed version is also installed.
addons[2].version = "0.6.1"
addons[#addons + 1] = {name="ServerDungeonJournal", version="0.2.0"}
addons[#addons + 1] = {name="NClassicBattlegrounds", version="1.0.0"}
old = NCore:ScanLegacyInstallations()
assert(#old == 2, "Both obsolete addon folders should be identified")
assert(old[1].kind == "legacy" and old[2].kind == "legacy",
    "Standalone BG and old journal should always be considered duplicates")
assert(NCore:ShowLegacyWarning(old) == true, "Legacy alert should open")
assert(dialog:IsShown(), "Legacy alert did not reopen")

-- Newer than the collection is not an older version.
addons = {
    {name="NCore", version="2.0.0-alpha.1"},
    {name="DungeonJournal", version="0.7.0"},
    {name="MultiBot", version="4.0"},
}
assert(#NCore:ScanLegacyInstallations() == 0,
    "Do not flag a newer version as outdated")

-- Unknown or absent metadata should not be inaccurately called 'older'.
addons[2].version = nil
assert(#NCore:ScanLegacyInstallations() == 0,
    "Unverifiable metadata must not cause false obsolete warnings")

-- No metadata API: still safely recognizes distinct old addon folders.
GetAddOnMetadata = nil
addons[#addons + 1] = {name="NaxxramasClassicBattlegrounds"}
assert(#NCore:ScanLegacyInstallations() == 1,
    "Detect known obsolete folder even without version metadata")

-- The checker must not edit files, saved variables or addon enable flags.
print("Lua 5.1 silent addon audit and popup tests passed")
