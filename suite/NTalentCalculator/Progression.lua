-- Authoritative Individual Progression tier, plus hidden-quest fallback.
-- Companion contract: .ipsvc data => ##IPSVC##PD~<highest completed tier>
-- Era breakpoints match the server Companion: Vanilla 0-7, TBC 8-12,
-- WotLK 13+. Do not guess a tier from character level.

local M = NTalentCalculator
local queried = false
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("ADDON_LOADED")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:RegisterEvent("CHAT_MSG_SYSTEM")
loginFrame:RegisterEvent("QUEST_QUERY_COMPLETE")

function M:ReceiveTier(value)
    local tier = tonumber(value)
    if not tier or tier ~= math.floor(tier) or tier < 0 or tier > 100 then
        return false
    end
    if tier >= 13 then
        self:SetProgression("wotlk", tier)
    elseif tier >= 8 then
        self:SetProgression("tbc", tier)
    else
        self:SetProgression("vanilla", tier)
    end
    return true
end

function M:ReadQuestMilestones()
    if self.tier then return end
    if type(GetQuestsCompleted) ~= "function" then return end
    local quests = GetQuestsCompleted()
    if type(quests) ~= "table" then return end
    -- Completed hidden quest flags identify the era, not the specific tier.
    -- Only use this fallback when no server ##IPSVC## response exists yet.
    for id=66013,66018 do
        if quests[id] then
            self:SetProgression("wotlk", nil)
            return
        end
    end
    for id=66008,66012 do
        if quests[id] then
            self:SetProgression("tbc", nil)
            return
        end
    end
    self:SetProgression("vanilla", nil)
end

function M:RequestProgression()
    -- No server-side edits: this is the same read-only request made by the
    -- Individual Progression Companion. Prevent repeated automatic requests.
    if type(SendChatMessage) ~= "function" then return false end
    SendChatMessage(".ipsvc data", "SAY")
    return true
end

loginFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "NTalentCalculator" then
        NTalentCalculatorDB = type(NTalentCalculatorDB) == "table" and
            NTalentCalculatorDB or {builds={}}
        if type(NTalentCalculatorDB.builds) ~= "table" then
            NTalentCalculatorDB.builds = {}
        end
    elseif event == "PLAYER_LOGIN" then
        M:Initialize()
        M:RequestProgression()
        -- NCore's mandatory Classic Battlegrounds also queries completed
        -- milestones. Wait for its QUEST_QUERY_COMPLETE instead of racing
        -- its throttled QueryQuestsCompleted request.
    elseif event == "CHAT_MSG_SYSTEM" and type(arg1) == "string" then
        local value = arg1:match("^##IPSVC##PD~([0-9]+)$")
        if value then M:ReceiveTier(value) end
    elseif event == "QUEST_QUERY_COMPLETE" then
        M:ReadQuestMilestones()
    end
end)
