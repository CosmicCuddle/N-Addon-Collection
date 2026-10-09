-- Lua 5.1 mock: live Individual Progression protocol and hidden quest fallbacks.
local frame={}
function frame:RegisterEvent(event) self[event] = true end
function frame:SetScript(event,fn) self[event] = fn end
function CreateFrame() return frame end
local sent = {}
function SendChatMessage(message, channel)
    sent[#sent + 1] = {message, channel}
end
local quests = {}
function GetQuestsCompleted() return quests end
NTalentCalculatorDB = nil
NTalentCalculator = {
    tier = nil,
    era = nil,
    Initialize = function(self)
        self.initialized = true
        return true
    end,
    SetProgression = function(self, era, tier)
        self.era, self.tier = era, tier
    end
}
dofile("suite/NTalentCalculator/Progression.lua")
local M=NTalentCalculator
assert(frame.PLAYER_LOGIN and frame.QUEST_QUERY_COMPLETE,
    "Talent calculator must register progression refresh events")

frame.OnEvent(frame, "ADDON_LOADED", "NTalentCalculator")
assert(type(NTalentCalculatorDB) == "table" and
    type(NTalentCalculatorDB.builds) == "table",
    "Saved build table not initialized")
frame.OnEvent(frame, "PLAYER_LOGIN")
assert(M.initialized and #sent == 1)
assert(sent[1][1] == ".ipsvc data" and sent[1][2] == "SAY",
    "Talent addon did not request the existing IP read-only service")

local tests = {
    {0, "vanilla"}, {7, "vanilla"}, {8, "tbc"}, {12, "tbc"},
    {13, "wotlk"}, {18, "wotlk"}
}
for _, case in ipairs(tests) do
    frame.OnEvent(frame, "CHAT_MSG_SYSTEM", "##IPSVC##PD~" .. case[1])
    assert(M.tier == case[1] and M.era == case[2],
        "Incorrect progression era for tier " .. case[1])
end
frame.OnEvent(frame, "CHAT_MSG_SYSTEM", "##IPSVC##PD~unknown")
assert(M.tier == 18, "Invalid server messages must be ignored")

M.tier = nil
quests = {[66008] = true}
frame.OnEvent(frame, "QUEST_QUERY_COMPLETE")
assert(M.era == "tbc" and M.tier == nil, "TBC quest fallback invented a tier")
M.tier = nil
quests = {[66013] = true, [66008] = true}
frame.OnEvent(frame, "QUEST_QUERY_COMPLETE")
assert(M.era == "wotlk" and M.tier == nil, "Wrath quest flag should take priority")
M.tier = nil
quests = {}
frame.OnEvent(frame, "QUEST_QUERY_COMPLETE")
assert(M.era == "vanilla" and M.tier == nil, "Empty completed-quest map identifies Vanilla")
frame.OnEvent(frame, "CHAT_MSG_SYSTEM", "##IPSVC##PD~9")
assert(M.era == "tbc" and M.tier == 9,
    "Authoritative server tier must override the quest-only fallback")
print("N Talent Calculator progression server contract and quest fallback tests passed")
