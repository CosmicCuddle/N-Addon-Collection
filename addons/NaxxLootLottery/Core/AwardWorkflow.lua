-- Naxxramas Loot Ledger 0.1.0.25
-- Explicit, opt-in Master Loot requests with two-stage UI consent.
-- A successful API call is NOT proof of item delivery to the winner.
local NLL = NaxxLootLottery
NLL.AwardWorkflow = NLL.AwardWorkflow or {}
local A = NLL.AwardWorkflow
A.verification = nil
A.liveRequests = A.liveRequests or {} -- session-only references; history is saved separately
local ARM_SECONDS = 15

local function Key(s)
    return string.lower((tostring(s or ''):match('^([^%-]+)') or ''))
end
local function ItemID(link)
    return type(link) == 'string' and tonumber(link:match('item:(%d+)')) or nil
end
local function Now() return GetTime and GetTime() or 0 end
local function Selected()
    local loot = NLL.LootDetection:GetCurrentLoot() or {}
    return loot[(NLL.UI and NLL.UI.currentLootSelected) or 1]
end
local function Audit(row)
    if not NLL.db then return nil end
    NLL.db.lootAwardHistory = NLL.db.lootAwardHistory or {}
    table.insert(NLL.db.lootAwardHistory, row)
    while #NLL.db.lootAwardHistory > 100 do
        table.remove(NLL.db.lootAwardHistory, 1)
    end
    return row
end
local function HistoryRow(entry, result, status, note, verified)
    return {
        itemID = entry.itemID, itemName = entry.itemName,
        boss = entry.boss, raidKey = entry.raidKey,
        dropUID = entry.dropUID, slotIndex = verified and verified.slot,
        candidateIndex = verified and verified.candidateIndex,
        winner = result.winner, winningTicket = result.winningTicket,
        status = status, note = note,
        when = date and date('%Y-%m-%d %H:%M:%S') or 'unknown'
    }
end
local function RefreshUI()
    if NLL.UI and NLL.UI.RefreshCurrentLootPanel then
        NLL.UI:RefreshCurrentLootPanel()
    end
    if NLL.UI and NLL.UI.RefreshOverview then
        NLL.UI:RefreshOverview()
    end
end

function A:GetReviewedDrop()
    local entry = Selected()
    return entry
end

function A:GetOutcome(entry)
    if not entry then return nil end
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return NLL.DebugSimulator:GetResultFor(entry)
    end
    local a = NLL.TicketLottery:GetActiveFor(entry)
    if a and a.status == 'COMPLETE' and not a.test then return a end
    return nil
end

-- The dropdown list and its candidate indices belong to the currently
-- selected Blizzard loot slot. Never trust a previously cached index.
function A:ValidateLiveContext(entry, winner)
    if not entry or entry.simulationOnly or entry.identityUncertain or not winner then
        return false, 'A real drop and completed real winner are required.'
    end
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false, 'Simulation active: real awards are blocked.'
    end
    local identity=NLL.LootIdentity and NLL.LootIdentity:GetRow(entry.dropUID)
    if identity and identity.awardContextClosed then
        return false, 'Winner restored from closed loot window: use WoW manual award. Direct award is not safe after reopen/reload.'
    end
    if not NLL.TicketLottery.liveLootObserved or
       type(entry.slotIndex) ~= 'number' or entry.slotIndex < 1 then
        return false, 'Reopen the real loot window; an old or debug drop is not valid.'
    end
    local inQueue = false
    for _, row in ipairs(NLL.LootDetection:GetCurrentLoot() or {}) do
        if row.dropUID == entry.dropUID and row.itemID == entry.itemID and
           row.slotIndex == entry.slotIndex then
            inQueue = true
            break
        end
    end
    if not inQueue then return false, 'The selected drop changed. Review it again.' end
    if not NLL.TicketLottery:AuthorityAllowed(false) then
        return false, 'Raid leader/officer authority required.'
    end
    if type(GetLootMethod) ~= 'function' or type(GetRaidRosterInfo) ~= 'function' then
        return false, 'WoW Master Loot authority APIs are unavailable.'
    end
    local method, _, masterRaidIndex = GetLootMethod()
    if method ~= 'master' then return false, 'Enable Master Loot in WoW first.' end
    -- Officer/leader alone is insufficient: the acting player MUST be the
    -- designated Master Looter, confirmed against the live raid roster.
    if type(masterRaidIndex) ~= 'number' or masterRaidIndex < 1 then
        return false, 'Cannot verify your Master Looter identity from the raid.'
    end
    local masterName = GetRaidRosterInfo(masterRaidIndex)
    if not masterName or Key(masterName) ~= Key(UnitName and UnitName('player')) then
        return false, 'You are not WoW\'s designated Master Looter.'
    end
    if type(GetNumLootItems) ~= 'function' or
       type(GetLootSlotLink) ~= 'function' or
       type(GetMasterLootCandidate) ~= 'function' then
        return false, 'WoW loot candidate APIs are unavailable.'
    end
    local slot = entry.slotIndex
    if not LootFrame or (LootFrame.IsShown and not LootFrame:IsShown()) or
       LootFrame.selectedSlot ~= slot then
        return false, 'Open the WoW Master Loot dropdown for THIS loot slot.'
    end
    if slot > (GetNumLootItems() or 0) or
       ItemID(GetLootSlotLink(slot)) ~= entry.itemID then
        return false, 'The selected WoW loot slot no longer matches this item.'
    end
    if type(GetLootSlotInfo) == 'function' then
        local _, _, quantity, _, locked = GetLootSlotInfo(slot)
        if locked or (quantity and quantity < 1) then
            return false, 'The loot slot is locked or empty.'
        end
    end
    local candidateIndex
    for i = 1, 40 do
        local candidate = GetMasterLootCandidate(i)
        if candidate and Key(candidate) == Key(winner) then
            candidateIndex = i
            break
        end
    end
    if not candidateIndex then
        return false, 'Winner is absent from this item\'s Master Loot candidate list.'
    end
    return true, {dropUID = entry.dropUID, itemID = entry.itemID,
        itemName = entry.itemName, winner = winner, slot = slot,
        candidateIndex = candidateIndex, verifiedAt = Now(), simulated = false}
end

function A:Review(entry)
    entry = entry or Selected()
    self.verification = nil
    if not entry then return false, 'Select a loot item first.' end
    local result = self:GetOutcome(entry)
    if not result or not result.winner then
        return false, 'A completed lottery winner is required for award review.'
    end
    if result.awardStatus then
        return false, 'An award is already reported/requested for this drop.'
    end
    if entry.simulationOnly then
        if not (NLL.DebugSimulator and NLL.DebugSimulator:IsActive()) then
            return false, 'No active simulated raid.'
        end
        self.verification = {dropUID=entry.dropUID, winner=result.winner,
            itemID=entry.itemID, simulated=true}
        return true, 'SIMULATION: fake award changes only the fake Gear Plan.'
    end
    local ok, data = self:ValidateLiveContext(entry, result.winner)
    if not ok then return false, data end
    self.verification = data
    return true, 'Winner confirmed in the LIVE WoW Master Loot list. ' ..
        'Report a manual award, or use opt-in Direct Award after two confirmations.'
end

-- Existing leader-reported manual-award path remains available.
function A:Confirm(entry)
    entry = entry or Selected()
    local verified = self.verification
    if not entry or not verified or entry.dropUID ~= verified.dropUID then
        return false, 'Review this exact drop first.'
    end
    local result = self:GetOutcome(entry)
    if not result or result.winner ~= verified.winner or result.awardStatus then
        return false, 'Winner changed or an award is already recorded.'
    end
    if verified.simulated then
        if not entry.simulationOnly then return false, 'Simulation mismatch.' end
        local ok, msg = NLL.DebugSimulator:ConfirmAward()
        if ok then self.verification = nil end
        return ok, msg
    end
    if entry.simulationOnly or not NLL.TicketLottery:AuthorityAllowed(false) or
       NLL.TicketLottery:GetActiveFor(entry) ~= result then
        return false, 'Current real lottery/raid authority required.'
    end
    result.awardStatus = 'LEADER_REPORTED'
    if NLL.LootIdentity then NLL.LootIdentity:MarkAward(entry.dropUID,result.awardStatus) end
    Audit(HistoryRow(entry, result, 'LEADER_REPORTED',
        'Leader reports separate manual Blizzard UI award; delivery not verified', verified))
    self.verification = nil
    RefreshUI()
    return true, 'Leader-reported manual award recorded. Receipt is not verified.'
end

function A:IsDirectEnabled()
    return NLL.db and NLL.db.settings and
        NLL.db.settings.directMasterLootEnabled == true
end
function A:SetDirectEnabled(value)
    if not NLL.db or not NLL.db.settings then return false end
    -- Never permit changing a real-award safety setting in fake mode.
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then return false end
    NLL.db.settings.directMasterLootEnabled = value == true
    self:Cancel()
    return true
end

function A:ArmDirectAward(entry)
    entry = entry or Selected()
    if not self:IsDirectEnabled() then
        return false, 'Direct Master Loot is OFF. Enable it in Settings > Loot Awards.'
    end
    for _, pending in pairs(self.liveRequests) do
        if pending and pending.history and pending.history.status == 'AWARD_REQUESTED' then
            return false, 'Another real Master Loot request is awaiting a result. Investigate first.'
        end
    end
    local verified = self.verification
    if not entry or not verified or verified.simulated or
       entry.dropUID ~= verified.dropUID then
        return false, 'Review this live winner before arming Direct Award.'
    end
    local result = self:GetOutcome(entry)
    if not result or result.awardStatus or result.winner ~= verified.winner then
        return false, 'The winning result changed or has already been awarded.'
    end
    local ok, fresh = self:ValidateLiveContext(entry, result.winner)
    if not ok then self:Cancel(); return false, fresh end
    if fresh.slot ~= verified.slot or fresh.candidateIndex ~= verified.candidateIndex then
        self:Cancel()
        return false, 'Master Loot selection changed. Start award review again.'
    end
    verified.armedAt = Now()
    return true, 'ARMED: ' .. result.winner .. ' / ' .. entry.itemName ..
        '. Re-check both names, then press CONFIRM GIVE ITEM within 15 seconds.'
end

function A:CommitDirectAward(entry)
    entry = entry or Selected()
    local verified = self.verification
    if not self:IsDirectEnabled() or not entry or not verified or
       verified.simulated or verified.dropUID ~= entry.dropUID then
        return false, 'Direct award is not armed for this drop.'
    end
    if not verified.armedAt or (Now() - verified.armedAt) > ARM_SECONDS then
        self:Cancel()
        return false, 'Confirmation expired. Review the Master Loot candidate again.'
    end
    local result = self:GetOutcome(entry)
    if not result or result.awardStatus or result.winner ~= verified.winner or
       NLL.TicketLottery:GetActiveFor(entry) ~= result then
        self:Cancel()
        return false, 'Winner/result changed; direct award stopped.'
    end
    local ok, fresh = self:ValidateLiveContext(entry, result.winner)
    if not ok then self:Cancel(); return false, fresh end
    if fresh.slot ~= verified.slot or fresh.candidateIndex ~= verified.candidateIndex then
        self:Cancel()
        return false, 'Selected slot or recipient changed; direct award stopped.'
    end
    if type(GiveMasterLoot) ~= 'function' then
        self:Cancel()
        return false, 'GiveMasterLoot is unavailable in this client.'
    end
    -- Explicit user click only. This call can move REAL items, and is
    -- deliberately never invoked by timers, OnShow, or fake-raid modes.
    local transferOK, transferError = pcall(GiveMasterLoot, fresh.slot, fresh.candidateIndex)
    self:Cancel()
    if not transferOK then
        return false, 'WoW refused the request: ' .. tostring(transferError)
    end
    -- The API returns no delivery receipt. Do NOT mark Gear Plan OBTAINED.
    result.awardStatus = 'AWARD_REQUESTED'
    if NLL.LootIdentity then NLL.LootIdentity:MarkAward(entry.dropUID,result.awardStatus) end
    local history = Audit(HistoryRow(entry, result, 'AWARD_REQUESTED',
        'GiveMasterLoot invoked after explicit double confirmation; delivery unverified', fresh))
    self.liveRequests[entry.dropUID] = {
        slot = fresh.slot, history = history, result = result
    }
    RefreshUI()
    return true, 'Master Loot request SENT for ' .. result.winner ..
        '. WoW has not yet confirmed receipt. Do not award this item twice.'
end

function A:OnLootSlotCleared(slot)
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then return end
    for uid, request in pairs(self.liveRequests) do
        if request.slot == slot and request.history.status == 'AWARD_REQUESTED' then
            request.history.status = 'LOOT_SLOT_CLEARED'
            request.history.note = 'WoW loot slot cleared after request; recipient receipt not verified'
            request.result.awardStatus = 'LOOT_SLOT_CLEARED'
            if NLL.LootIdentity then NLL.LootIdentity:MarkAward(uid,request.result.awardStatus) end
            self.liveRequests[uid] = nil
            RefreshUI()
            break
        end
    end
end
function A:OnLootClosed()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then return end
    for uid, request in pairs(self.liveRequests) do
        if request.history.status == 'AWARD_REQUESTED' then
            request.history.status = 'AWARD_OUTCOME_UNKNOWN'
            request.history.note = 'Loot window closed without observing slot cleared; investigate manually'
            request.result.awardStatus = 'AWARD_OUTCOME_UNKNOWN'
            if NLL.LootIdentity then NLL.LootIdentity:MarkAward(uid,request.result.awardStatus) end
        end
        self.liveRequests[uid] = nil
    end
    self:Cancel()
    RefreshUI()
end
function A:Cancel() self.verification = nil end
function A:GetStatus(entry)
    local result = self:GetOutcome(entry)
    if not result then return 'No confirmed lottery winner.' end
    local s = result.awardStatus
    if s == 'SIMULATED_AWARDED' then return 'SIMULATED AWARD: fake Gear Plan obtained' end
    if s == 'LEADER_REPORTED' then return 'AWARD REPORTED: receipt not verified' end
    if s == 'AWARD_REQUESTED' then return 'AWARD REQUEST SENT: receipt pending/unverified' end
    if s == 'LOOT_SLOT_CLEARED' then return 'LOOT SLOT CLEARED: recipient not independently verified' end
    if s == 'AWARD_OUTCOME_UNKNOWN' then return 'AWARD OUTCOME UNKNOWN: investigate before retrying' end
    if entry.simulationOnly then return 'SIM WINNER: fake award awaiting confirmation' end
    return 'WINNER ONLY: loot not awarded by NLL'
end
