-- Naxxramas Loot Ledger v0.1.0.17 - manual, post-drop ticket lottery.
-- Tickets are created ONLY on explicit Prepare Tickets for an observed drop.
-- Real draws use the 3.3.5 RandomRoll/CHAT_MSG_SYSTEM result mechanism.
-- There is deliberately NO GiveMasterLoot call anywhere in this module.
local NLL = NaxxLootLottery
NLL.TicketLottery = NLL.TicketLottery or {}
local L = NLL.TicketLottery
L.active = nil
L.results = {} -- completed rolls by dropUID, session only
L.liveLootObserved = false -- never persisted: reload requires opening loot anew

local function Now() return GetTime and GetTime() or 0 end
local function CharacterKey(s)
    return string.lower((tostring(s or ''):match('^([^%-]+)') or ''))
end
local function CopyTickets(tickets)
    local out={}
    for i,t in ipairs(tickets or {}) do out[i]={number=t.number, character=t.character} end
    return out
end
function L:GetSelectedEntry()
    local loot = NLL.LootDetection:GetCurrentLoot() or {}
    return loot[(NLL.UI and NLL.UI.currentLootSelected) or 1]
end
function L:GetActiveFor(entry)
    if not entry then return nil end
    if entry.identityUncertain then return nil end -- never display a guessed winner
    if self.active and entry.dropUID == self.active.dropUID then
        return self.active
    end
    if self.results[entry.dropUID] then return self.results[entry.dropUID] end
    -- Restore completed real winners after /reload. Ticket results and the
    -- persistent identity lock are separate from transient raid/UI objects.
    if entry.slotIndex ~= 0 and NLL.LootIdentity then
        local restored=NLL.LootIdentity:RestoreOutcome(entry)
        if restored then
            self.results[entry.dropUID]=restored
            return restored
        end
    end
    return nil
end
function L:AuthorityAllowed(testDrop)
    if testDrop then
        return NLL.db and NLL.db.settings and NLL.db.settings.debug == true
    end
    if not GetNumRaidMembers or (GetNumRaidMembers() or 0) == 0 then
        return false
    end
    if IsRaidLeader and IsRaidLeader() then return true end
    if IsRaidOfficer and IsRaidOfficer() then return true end
    return false
end
function L:Invalidate(reason)
    if self.active and self.active.status ~= 'COMPLETE' then
        self:Record('INVALIDATED', nil, reason or 'Pool invalidated')
    end
    self.active = nil
end
function L:Record(state, roll, reason)
    if not self.active or not NLL.db then return end
    NLL.db.lotteryHistory = NLL.db.lotteryHistory or {}
    local a=self.active
    local row={
        status=state, itemID=a.itemID, itemName=a.itemName,
        raidKey=a.raidKey, dropUID=a.dropUID, boss=a.boss,
        tier=a.tier, tickets=CopyTickets(a.tickets),
        winningTicket=roll, winner=a.winner,
        test=a.test, method=a.method, note=reason,
        when=date and date('%Y-%m-%d %H:%M:%S') or 'unknown'
    }
    table.insert(NLL.db.lotteryHistory, row)
    while #NLL.db.lotteryHistory > 100 do table.remove(NLL.db.lotteryHistory,1) end
end
function L:Prepare(entry, matches)
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,"Simulation active: use the fake ticket controls."
    end
    entry=entry or self:GetSelectedEntry()
    if not entry or not entry.dropUID or entry.state~='DETECTED' then
        return false, 'Open a supported loot window before preparing tickets.'
    end
    if not self.liveLootObserved then
        return false, 'Reopen the loot window; an old SavedVariables drop is not valid.'
    end
    local isTest = entry.slotIndex == 0
    if not self:AuthorityAllowed(isTest) then
        return false, 'Only raid leaders/officers may run a lottery; debug test needs /nll debug.'
    end
    if self.active and (self.active.status == 'WAITING_FOR_ROLL' or
        self.active.status == 'ROLL_UNCONFIRMED') then
        return false, 'The previous roll is pending/unconfirmed. Cancel Tickets first (audited). '
    end
    if (entry.identityUncertain and not isTest) then
        return false,'Duplicate item identity is ambiguous after looting. Do not guess; inspect the corpse and previous roll history.'
    end
    if (not isTest and NLL.LootIdentity and
        NLL.LootIdentity:IsProcessed(entry.dropUID)) or
        self:GetActiveFor(entry) and self:GetActiveFor(entry).status=='COMPLETE' or
        (self.active and self.active.status == 'COMPLETE' and
        self.active.dropUID == entry.dropUID) then
        return false, 'This drop already has a winner. No duplicate roll.'
    end
    if self.active and self.active.status == 'PREPARED' and
        self.active.dropUID ~= entry.dropUID then
        self:Invalidate('Switched to a different drop before rolling')
    end
    -- No tickets exist merely from a wishlist or the preview.
    if NLL.Roster then NLL.Roster:Refresh() end
    local preview=NLL.TicketPlanner:BuildPreview(entry,matches)
    if not preview.ready then return false, preview.message end
    if #preview.current < 1 then return false,'No eligible candidates.' end
    local snapshot={}
    local tickets={}
    for i,m in ipairs(preview.current) do
        snapshot[i]=CharacterKey(m.character)
        tickets[i]={number=i,character=m.character}
    end
    self.active={
        dropUID=entry.dropUID, itemID=entry.itemID, itemName=entry.itemName,
        raidKey=entry.raidKey, boss=entry.boss, tier=preview.chosenTier,
        tickets=tickets, candidateKeys=snapshot,
        status='PREPARED', test=isTest, createdAt=Now(), method=nil
    }
    NLL:Print((isTest and '[TEST] ' or '') .. 'Prepared ' .. #tickets ..
        ' tickets for ' .. entry.itemName .. ' (priority tier ' .. preview.chosenTier .. ').')
    for _,t in ipairs(tickets) do
        NLL:Print('Ticket ' .. t.number .. ' - ' .. t.character)
    end
    return true, 'Tickets prepared; check the roster, then click Start Roll.'
end
function L:PoolStillMatches(entry)
    local a=self:GetActiveFor(entry)
    if not a then return false,'Drop changed. Prepare tickets again.' end
    local preview=NLL.TicketPlanner:BuildPreview(entry)
    if not preview.ready or preview.chosenTier~=a.tier or
        #preview.current~=#a.tickets then
        return false,'Roster/priority changed. Cancel and prepare new tickets.'
    end
    for i,m in ipairs(preview.current) do
        if CharacterKey(m.character)~=a.candidateKeys[i] then
            return false,'Candidate list changed. Cancel and prepare again.'
        end
    end
    return true
end
function L:Finish(roll,method)
    local a=self.active
    if not a or a.status~='WAITING_FOR_ROLL' then return false end
    roll=tonumber(roll)
    if not roll or roll%1~=0 or roll<1 or roll>#a.tickets then return false end
    local entry=nil
    for _,v in ipairs(NLL.LootDetection:GetCurrentLoot() or {}) do
        if v.dropUID==a.dropUID then entry=v break end
    end
    local poolOkay,poolReason=self:PoolStillMatches(entry)
    if not entry or not poolOkay or not self:AuthorityAllowed(a.test) then
        a.status='ROLL_UNCONFIRMED'
        self:Record('UNVERIFIED',nil,'Pool/authority changed during server roll: '..
            tostring(poolReason or 'permission lost'))
        NLL:Print('Roll result NOT accepted: candidate pool or authority changed. '..
            'No winner recorded; cancel and investigate.')
        return false
    end
    a.winner=a.tickets[roll].character
    a.winningTicket=roll
    a.status='COMPLETE'
    a.method=method
    a.awardStatus=nil -- not an award until a separate confirmation
    self.results[a.dropUID]=a
    if not a.test and NLL.LootIdentity then
        NLL.LootIdentity:MarkCompleted(a.dropUID,a.winner,roll,method)
    end
    self:Record('COMPLETE',roll,'Result only. Loot award remains manual.')
    NLL:Print((a.test and '[TEST - no loot awarded] ' or '') ..
        a.itemName .. ': winning ticket ' .. roll .. ' = ' .. a.winner ..
        '. Award remains MANUAL.')
    if NLL.UI and NLL.UI.RefreshCurrentLootPanel then
        NLL.UI:RefreshCurrentLootPanel()
    end
    if NLL.UI and NLL.UI.ShowWinnerAnnouncement then
        NLL.UI:ShowWinnerAnnouncement(a.itemName, a.winner, roll, a.test == true)
    end
    return true
end
function L:StartRoll(entry)
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,"Simulation active: no server roll permitted."
    end
    entry=entry or self:GetSelectedEntry()
    local a=self:GetActiveFor(entry)
    if not a or a.status~='PREPARED' then
        return false,'Prepare tickets for this drop first.'
    end
    if not self:AuthorityAllowed(a.test) or not self.liveLootObserved then
        return false,'A current drop and raid leader/officer permissions are required.'
    end
    if NLL.Roster then NLL.Roster:Refresh() end
    local good,reason=self:PoolStillMatches(entry)
    if not good then return false,reason end
    -- One server-visible ticket roll per drop. No automatic winner before here.
    a.status='WAITING_FOR_ROLL'
    a.rollStarted=Now()
    a.roller=CharacterKey(UnitName and UnitName('player'))
    if a.test then
        local result = math.random(1,#a.tickets)
        self:Finish(result,'LOCAL_TEST_RANDOM')
        return true,'TEST draw completed; no loot awarded.'
    end
    if not RandomRoll then
        a.status='PREPARED'
        return false,'RandomRoll API missing; no draw started.'
    end
    a.method='SERVER_RANDOM_ROLL'
    RandomRoll(1,#a.tickets)
    NLL:Print('Waiting for YOUR server /roll (1-' .. #a.tickets ..
        '). Do not start another roll until resolved.')
    return true,'Waiting for WoW server roll result.'
end
-- Parse the localized WoW 3.3.5 RANDOM_ROLL_RESULT message exactly.
-- Do not interpret unrelated raid members' rolls as NLL's winner.
function L:OnSystemMessage(message)
    local a=self.active
    if not a or a.test or a.status~='WAITING_FOR_ROLL' or
        type(message)~='string' then return end
    if Now()-a.rollStarted>15 then return end
    local localized=RANDOM_ROLL_RESULT
    if type(localized)~='string' then return end
    local pattern='^'..localized:
        gsub('([%(%)%.%+%-%*%?%[%]%^%$])','%%%1'):
        gsub('%%s','(.-)'):
        gsub('%%d','(%%d+)')..'$'
    local roller,value,minimum,maximum=message:match(pattern)
    if not roller or CharacterKey(roller)~=a.roller then return end
    if tonumber(minimum)~=1 or tonumber(maximum)~=#a.tickets then return end
    self:Finish(tonumber(value),'SERVER_RANDOM_ROLL')
end
function L:Cancel(reason)
    if not self.active then return false,'No tickets to cancel.' end
    if self.active.status=='COMPLETE' then
        return false,'A winning ticket is already recorded. Re-rolling this drop is blocked.'
    end
    if not self:AuthorityAllowed(self.active.test) then
        return false,'Raid leader/officer permission required.'
    end
    self:Record('CANCELLED',nil,reason or 'Manually cancelled')
    self.active=nil
    return true,'Ticket session cancelled and recorded. You may prepare again.'
end
function L:GetStatus(entry)
    local a=self:GetActiveFor(entry)
    if not a then
        if entry and entry.identityUncertain then
            return 'AMBIGUOUS: repeated item copies; inspect history first.'
        end
        return 'No tickets prepared.'
    end
    if a.status=='PREPARED' then return #a.tickets .. ' tickets ready; press Start Roll.' end
    if a.status=='WAITING_FOR_ROLL' then return 'Awaiting server roll; no winner yet.' end
    if a.status=='COMPLETE' then
        return (a.test and '[TEST] ' or '')..'Won # ' .. a.winningTicket .. ': '..a.winner ..
            (a.awardStatus=='LEADER_REPORTED' and ' [AWARD REPORTED]' or ' [NOT AWARDED]')
    end
    return a.status
end
function L:OnUpdate(elapsed)
    self.tick=(self.tick or 0)+(elapsed or 0)
    if self.tick < 0.5 then return end
    self.tick=0
    local a=self.active
    if a and a.status=='WAITING_FOR_ROLL' and Now()-a.rollStarted>15 then
        a.status='ROLL_UNCONFIRMED'
        NLL:Print('Could not verify server roll. NO WINNER recorded. '
            ..'Use Cancel Tickets and investigate; never guess a result.')
        if NLL.UI and NLL.UI.RefreshCurrentLootPanel then
            NLL.UI:RefreshCurrentLootPanel()
        end
    end
end
local events=CreateFrame('Frame')
events:RegisterEvent('CHAT_MSG_SYSTEM')
events:SetScript('OnEvent',function(_,event,message)
    if NLL.initialized and event=='CHAT_MSG_SYSTEM' then
        L:OnSystemMessage(message)
    end
end)
events:SetScript('OnUpdate',function(_,dt)
    if NLL.initialized then L:OnUpdate(dt) end
end)
