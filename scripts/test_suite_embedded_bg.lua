-- N Addon Suite v2: test the *actual built ZIP members* for NCore and
-- embedded Classic Battlegrounds under Lua 5.1 / WoW API mocks.
-- Invoked: lua5.1 scripts/test_suite_embedded_bg.lua CORE_FILE BG_FILE
-- Offline regression only; this is NOT real WoW client verification.

local coreFile, bgFile = arg[1], arg[2]
assert(coreFile and bgFile, "Pass extracted NCore and embedded BG Lua paths")
local checks = 0
local function eq(actual, expected, label)
    assert(actual == expected,
        label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end

local now, queries = 1000, 0
local questTable = {}
local npcMode = false
local secureHooks = {}
local tabClicks = 0
local chat = {}

local function Frame(shown)
    local frame = { shown = shown ~= false, scripts = {}, hooks = {} }
    function frame:Show()
        self.shown = true
        if self.hooks.OnShow then self.hooks.OnShow(self) end
    end
    function frame:Hide() self.shown = false end
    function frame:IsShown() return self.shown end
    function frame:Click() tabClicks = tabClicks + 1 end
    function frame:SetScript(event, fn) self.scripts[event] = fn end
    function frame:HookScript(event, fn) self.hooks[event] = fn end
    function frame:RegisterEvent(event)
        self.events = self.events or {}
        self.events[event] = true
    end
    return frame
end

PVPParentFrame = Frame()
PVPParentFrameTab1 = Frame()
PVPParentFrameTab2 = Frame()
PVPBattlegroundFrame = Frame()
PVPFrame = Frame()
PVPFrameArena = Frame()
PVPTeamDetails = Frame()
PVPFrameBlackFilter = Frame()
PVPFrameToggleButton = Frame()
PVPFrameOffSeason = Frame()
WintergraspTimer = Frame()
for i = 1, 3 do
    _G["PVPTeam" .. i] = Frame()
    _G["PVPTeam" .. i .. "Standard"] = Frame()
end

local eventFrame
function CreateFrame(frameType)
    eq(frameType, "Frame", "CreateFrame type")
    eventFrame = Frame()
    return eventFrame
end
function hooksecurefunc(name, fn)
    eq(type(fn), "function", "hook function")
    secureHooks[name] = (secureHooks[name] or 0) + 1
end
function PVPFrame_SetJustBG() end
function PVPBattleground_UpdateBattlegrounds() end
function PVPTeam_Update() end
function PVPFrame_IsJustBG() return npcMode end
function GetNumBattlegroundTypes() return 1 end
function GetBattlegroundInfo(i)
    eq(i, 1, "BG index")
    return "Warsong Gulch", true
end
function IsInInstance() return false end
function GetTime() return now end
function QueryQuestsCompleted() queries = queries + 1 end
function GetQuestsCompleted() return questTable end

DEFAULT_CHAT_FRAME = {AddMessage = function(_, msg) chat[#chat + 1] = msg end}
SlashCmdList = {}
-- A stale standalone SavedVariables flag must not turn off the mandatory suite BG.
NClassicBGQueueSettings = {enabled = false}

-- Test the real packaged core, not a hand-duplicated fake NCore API.
dofile(coreFile)
eq(NCore.version, "2.0.0", "suite framework version")
eq(#NCore.modules, 4, "four optional modules")
eq(SLASH_NSUITE1, "/nsuite", "suite slash command")
eq(SLASH_NSUITE2, "/nsettings", "settings alias")
local allowed, reason = NCore:SetEnabled("NClassicBattlegrounds", false)
eq(allowed, false, "embedded BG cannot be disabled via suite")
eq(type(reason), "string", "suite prevents disable with reason")
allowed = NCore:SetEnabled("NCore", false)
eq(allowed, false, "required suite core cannot be disabled via suite")
dofile(bgFile)
eq(SLASH_NCLASSICBG1, "/ncbg", "legacy BG slash name remains")
eq(type(SlashCmdList.NCLASSICBG), "function", "BG command installed")

local function event(name, value)
    assert(type(eventFrame.scripts.OnEvent) == "function", "missing OnEvent")
    eventFrame.scripts.OnEvent(eventFrame, name, value)
end

eq(eventFrame.events.ADDON_LOADED, true, "ADDON_LOADED registered")
eq(eventFrame.events.QUEST_QUERY_COMPLETE, true, "quest callback registered")
-- In a suite the addon name is NCore, not the old standalone folder.
event("ADDON_LOADED", "NCore")
eq(NClassicBGQueueSettings.enabled, false, "stale setting retained but ignored")
event("PLAYER_LOGIN")
eq(queries, 1, "startup query")
eq(secureHooks.PVPFrame_SetJustBG, 1, "single secure mode hook")
eq(secureHooks.PVPBattleground_UpdateBattlegrounds, 1, "single BG update hook")

questTable = {}
event("QUEST_QUERY_COMPLETE")
eq(PVPParentFrameTab1:IsShown(), true, "Vanilla PvP honor tab retained")
eq(PVPParentFrameTab2:IsShown(), false, "Vanilla remote BG tab hidden")
eq(PVPFrameArena:IsShown(), false, "Vanilla Arena hidden")
eq(WintergraspTimer:IsShown(), false, "Vanilla Wintergrasp hidden")
eq(PVPTeamDetails:IsShown(), false, "Vanilla team info hidden")

-- The packaged suite removes the original /ncbg on and off behaviour.
SlashCmdList.NCLASSICBG("off")
eq(NClassicBGQueueSettings.enabled, false, "BG off command cannot mutate flag")
eq(PVPParentFrameTab2:IsShown(), false, "BG off command cannot expose remote tab")
eq(PVPFrameArena:IsShown(), false, "BG off command cannot expose Arena")
eq(string.find(chat[#chat], "mandatory", 1, true) ~= nil,
    true, "BG off warns mandatory")
SlashCmdList.NCLASSICBG("on")
eq(PVPParentFrameTab2:IsShown(), false, "BG on command retains Vanilla rule")
SlashCmdList.NCLASSICBG("status")
eq(string.find(chat[#chat], "Display: enabled", 1, true) ~= nil,
    true, "suite reports mandatory BG as enabled")

questTable = {[66008] = true}
event("QUEST_QUERY_COMPLETE")
eq(PVPFrameArena:IsShown(), true, "TBC Arena restored")
eq(PVPParentFrameTab2:IsShown(), false, "TBC remote BG still hidden")
eq(WintergraspTimer:IsShown(), false, "TBC Wintergrasp still hidden")

questTable = {[66013] = true}
event("QUEST_QUERY_COMPLETE")
eq(PVPFrameArena:IsShown(), true, "Wrath Arena visible")
eq(PVPParentFrameTab2:IsShown(), true, "Wrath remote BG available")
eq(WintergraspTimer:IsShown(), true, "Wrath Wintergrasp available")

questTable = {}
event("QUEST_QUERY_COMPLETE")
eq(PVPParentFrameTab2:IsShown(), false, "Vanilla remote BG rehidden")
npcMode = true
local originalClicks = tabClicks
event("PLAYER_ENTERING_WORLD")
eq(tabClicks, originalClicks, "NPC BG mode never redirects PvP tab")
eq(PVPBattlegroundFrame:IsShown(), true, "NPC BG panel remains usable")
event("PLAYER_ENTERING_WORLD")
eq(secureHooks.PVPFrame_SetJustBG, 1, "world load does not repeat mode hook")
eq(secureHooks.PVPBattleground_UpdateBattlegrounds, 1, "world load does not repeat BG hook")

local before = queries
now = now + 76
eventFrame.scripts.OnUpdate(eventFrame, 2.1)
eq(queries, before + 1, "quest query refresh respects delay")

print("PASS: " .. checks .. " embedded NCore + Classic BG Lua 5.1 mock assertions")
