-- Naxxramas Loot Ledger v0.1.0.27: conservative 3.3.5 loot identity.
-- Wrath does not expose a trustworthy loot-source GUID via GetLootSourceInfo.
-- Treat overlapping loot scans as the SAME opportunity until a leader explicitly
-- confirms a new corpse. Never infer a new opportunity from a reopen or /reload.
local NLL = NaxxLootLottery
NLL.LootIdentity = NLL.LootIdentity or {}
local I = NLL.LootIdentity
I.confirmation = nil -- transient: never allow a reload to arm a reset
I.scanNumber = 0
local function Now() return GetTime and GetTime() or 0 end
local function Wall() return time and time() or 0 end
local function Name() return UnitName and UnitName('player') or 'Unknown' end
local function Log(action, message, oldID, newID)
    if not NLL.db then return end
    local history = NLL.db.lootIdentityAudit
    if type(history) ~= 'table' then history={}; NLL.db.lootIdentityAudit=history end
    history[#history+1]={action=action,note=message,oldID=oldID,newID=newID,
        actor=Name(),when=date and date('%Y-%m-%d %H:%M:%S') or 'unknown'}
    while #history>100 do table.remove(history,1) end
end
-- Schema 3 stores the active group plus a bounded archive of previous groups.
-- The client cannot distinguish two identical physical corpses. Ambiguity must
-- never be interpreted as permission to roll again.
local MAX_ARCHIVED=80
function I:Initialize()
    if self.initialized then return end
    local session=NLL.db and NLL.db.raidSession
    if not session then return end
    if type(session.lootIdentity)~='table' then session.lootIdentity={} end
    local book=session.lootIdentity
    if type(book.rows)~='table' then book.rows={} end
    if type(book.serial)~='number' then book.serial=0 end
    if type(book.groups)~='table' then book.groups={} end
    if type(book.oldProcessed)~='table' then book.oldProcessed={} end
    if type(NLL.db.lootIdentityAudit)~='table' then NLL.db.lootIdentityAudit={} end
    if book.schema~=2 and book.schema~=3 then
        -- Pre-0.1.0.26 loot queues have no durable identity guarantee.
        session.currentLoot={}
        book.rows={};book.id=nil;book.serial=0;book.groups={}
    end
    book.schema=3
    -- A restored winner is display-only, never sufficient for a direct award.
    for _,g in ipairs(book.groups) do
        for _,row in ipairs(g.rows or {}) do
            if row.processed then row.awardContextClosed=true end
        end
    end
    for _,row in ipairs(book.rows) do
        if row.processed then row.awardContextClosed=true end
    end
    self.initialized=true
end
function I:GetGroup()
    return NLL.db and NLL.db.raidSession and NLL.db.raidSession.lootIdentity
end
function I:GetRow(uid)
    if not uid then return nil end
    local book=self:GetGroup()
    for _,row in ipairs(book and book.rows or {}) do
        if row.uid==uid then return row end
    end
    for _,g in ipairs(book and book.groups or {}) do
        for _,row in ipairs(g.rows or {}) do
            if row.uid==uid then return row end
        end
    end
    return nil
end
local function ArchiveActive(book)
    if not book.id or #book.rows==0 then return end
    -- These references belong exclusively to the saved history group.
    book.groups[#book.groups+1]={id=book.id,rows=book.rows,serial=book.serial,
        startedAt=book.startedAt,lastSeenAt=book.lastSeenAt,
        explicitConfirmed=book.explicitConfirmed}
    while #book.groups>MAX_ARCHIVED do
        local removed=table.remove(book.groups,1)
        -- Never discard the fact a completed item could already have won,
        -- even when old individual group details are compacted.
        for _,r in ipairs(removed.rows or {}) do
            if r.processed then book.oldProcessed[tostring(r.itemID)]=true end
        end
    end
end
function I:NewGroup(book,reason)
    local old=book.id
    ArchiveActive(book)
    local session=NLL.db.raidSession
    session.lootGeneration=(tonumber(session.lootGeneration) or 0)+1
    book.id='L'..tostring(session.lootGeneration)
    book.explicitConfirmed=(reason=='Leader explicitly confirmed different corpse')
    book.rows={};book.serial=0;book.startedAt=Wall();book.schema=3
    Log('NEW_OPPORTUNITY',reason or 'Non-overlapping loot',old,book.id)
end
function I:ActivateArchived(book,index)
    local old=book.id
    local g=table.remove(book.groups,index)
    ArchiveActive(book)
    book.id=g.id;book.rows=g.rows;book.serial=g.serial
    book.startedAt=g.startedAt;book.lastSeenAt=g.lastSeenAt
    book.explicitConfirmed=g.explicitConfirmed
    -- Reactivating previously viewed loot does not reopen the real award
    -- context; its receipt and corpse identity are still unverified.
    for _,row in ipairs(book.rows) do
        if row.processed then row.awardContextClosed=true end
    end
    Log('REVISIT_POSSIBLE', 'Signature matches earlier group; physical corpse unverified',old,book.id)
end
local function Count(rows)
    local counts={}
    for _,r in ipairs(rows or {}) do
        counts[r.itemID]=(counts[r.itemID] or 0)+1
    end
    return counts
end
function I:Assign(entries,forceNew)
    self:Initialize()
    local book=self:GetGroup()
    if not book then return entries end
    entries=entries or {}
    if #entries==0 then return entries end
    local known=Count(book.rows)
    local overlap=false
    for _,entry in ipairs(entries) do
        if known[entry.itemID] then overlap=true break end
    end
    local uncertainItems={}
    if forceNew then
        self:NewGroup(book,'Leader explicitly confirmed different corpse')
    elseif not book.id or #book.rows==0 then
        self:NewGroup(book,'First loot opportunity')
    elseif not overlap then
        -- Find a historical opportunity matching these loot items before
        -- deciding a disjoint scan is a new corpse.
        local choices={}
        for index,g in ipairs(book.groups) do
            local ids=Count(g.rows)
            for _,e in ipairs(entries) do
                if ids[e.itemID] then choices[#choices+1]=index;break end
            end
        end
        if #choices==1 then
            self:ActivateArchived(book,choices[1])
        elseif #choices>1 then
            self:NewGroup(book,'Multiple old signatures match; locked until reviewed')
            for _,e in ipairs(entries) do
                uncertainItems[e.itemID]=true
            end
            Log('AMBIGUOUS_HISTORY','Several earlier corpses share these item IDs; no automatic new tickets')
        else
            self:NewGroup(book,'New non-overlapping signature')
        end
    end
    self.scanNumber=self.scanNumber+1
    local used={}
    local currentCounts=Count(entries)
    for _,entry in ipairs(entries) do
        local matches={}
        for _,row in ipairs(book.rows) do
            if row.itemID==entry.itemID and not used[row.uid] then
                matches[#matches+1]=row
            end
        end
        local match=nil
        for _,row in ipairs(matches) do
            if row.lastSlot==entry.slotIndex then match=row break end
        end
        if not match then match=matches[1] end
        if not match then
            book.serial=book.serial+1
            match={uid=book.id..':'..tostring(book.serial)..':'..tostring(entry.itemID),
                itemID=entry.itemID,firstSlot=entry.slotIndex}
            book.rows[#book.rows+1]=match
        end
        used[match.uid]=true
        match.lastSlot=entry.slotIndex
        match.lastSeen=Wall()
        entry.dropUID=match.uid
        local total=0
        for _,row in ipairs(book.rows) do
            if row.itemID==entry.itemID then total=total+1 end
        end
        local uncertainty=(total>1 and currentCounts[entry.itemID]<total)
            or uncertainItems[entry.itemID]
            or (book.oldProcessed[tostring(entry.itemID)]==true and
                not forceNew and not book.explicitConfirmed)
        -- When a *new* row appears in a group, but an older archived group
        -- processed the same item, we cannot prove it's a distinct item.
        if not forceNew and not book.explicitConfirmed and not match.processed then
            for _,g in ipairs(book.groups) do
                for _,r in ipairs(g.rows or {}) do
                    if r.itemID==entry.itemID and r.processed then
                        uncertainty=true;break
                    end
                end
                if uncertainty then break end
            end
        end
        entry.identityUncertain=uncertainty and true or false
    end
    book.lastSeenAt=Wall()
    return entries
end
function I:MarkCompleted(uid,winner,ticket,method)
    local row=self:GetRow(uid)
    if not row then return end -- standalone debug testdrop is separate
    row.processed=true
    row.winner=winner
    row.winningTicket=ticket
    row.method=method
    row.processedAt=Wall()
    row.awardContextClosed=false
end
function I:OnLootClosed()
    local group=self:GetGroup()
    for _,row in ipairs(group and group.rows or {}) do
        if row.processed then row.awardContextClosed=true end
    end
end
function I:MarkAward(uid,status)
    local row=self:GetRow(uid)
    if row then row.awardStatus=status end
end
function I:IsProcessed(uid)
    local row=self:GetRow(uid)
    return row and row.processed==true or false
end
function I:RestoreOutcome(entry)
    local row=entry and self:GetRow(entry.dropUID)
    if not row or not row.processed then return nil end
    if not row.winner then
        return {dropUID=entry.dropUID,status='COMPLETE',winner=nil,restored=true}
    end
    return {dropUID=entry.dropUID,itemID=entry.itemID,itemName=entry.itemName,
        raidKey=entry.raidKey,boss=entry.boss,status='COMPLETE',
        winner=row.winner,winningTicket=row.winningTicket,
        method=row.method or 'RECOVERED',awardStatus=row.awardStatus,
        test=false,restored=true}
end
function I:PrepareReset()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,'Stop the fake raid before starting a real loot opportunity.'
    end
    if not NLL.LootDetection or not NLL.LootDetection.lootOpen or
        not NLL.TicketLottery.liveLootObserved or
        not NLL.TicketLottery:AuthorityAllowed(false) then
        return false,'Open REAL raid loot as leader/officer before using /nll newloot.'
    end
    local a=NLL.TicketLottery.active
    if a and (a.status=='WAITING_FOR_ROLL' or a.status=='ROLL_UNCONFIRMED') then
        return false,'Resolve or cancel the pending server roll first.'
    end
    local aw=NLL.AwardWorkflow
    for _,r in pairs(aw and aw.liveRequests or {}) do
        if r and r.history and r.history.status=='AWARD_REQUESTED' then
            return false,'An award request is unresolved; investigate before resetting loot identity.'
        end
    end
    local previous=self:GetGroup()
    self.confirmation={at=Now(),previous=previous and previous.id}
    return true,'Only use for a DIFFERENT corpse. To start a new opportunity type /nll newloot confirm within 20 seconds. Do not use this to re-roll the same drop.'
end
function I:ConfirmReset()
    local c=self.confirmation
    self.confirmation=nil
    if not c or Now()-c.at>20 then
        return false,'Confirmation expired. Start with /nll newloot again.'
    end
    if not NLL.LootDetection.lootOpen or
        not NLL.TicketLottery.liveLootObserved or
        not NLL.TicketLottery:AuthorityAllowed(false) or
        (NLL.DebugSimulator and NLL.DebugSimulator:IsActive()) then
        return false,'Real loot window/authority is no longer valid.'
    end
    if (self:GetGroup() or {}).id~=c.previous then
        return false,'Loot opportunity changed; begin a new confirmation.'
    end
    local a=NLL.TicketLottery.active
    if a and (a.status=='WAITING_FOR_ROLL' or a.status=='ROLL_UNCONFIRMED') then
        return false,'Cannot reset while a server roll is unresolved.'
    end
    local success=NLL.LootDetection:ScanLootWindow(true)
    if not success then return false,'No supported real loot found; opportunity unchanged.' end
    return true,'New loot opportunity started. Previous winners remain in history; confirm the corpse really was different.'
end
