-- Naxxramas Loot Ledger 0.1.0.18 - drop-scoped candidate review.
-- No override modifies Gear Plans or permanent Priority Rules.
local NLL=NaxxLootLottery
NLL.CandidateReview=NLL.CandidateReview or {}
local R=NLL.CandidateReview
R.states={}
local function Key(value)
    return string.lower((tostring(value or ''):match('^([^%-]+)') or ''))
end
local function Now() return GetTime and GetTime() or 0 end
function R:Initialize() self.states={} end
function R:OnLootChanged()
    self.states={}
    if NLL.UI and NLL.UI.candidateReviewPanel then
        NLL.UI.candidateReviewPanel:Hide()
    end
end
function R:GetState(entry)
    if not entry or not entry.dropUID then return nil end
    -- Each drop in the same loot window has its own independent edits.
    -- The map is discarded when the underlying loot window changes.
    self.states=self.states or {}
    if not self.states[entry.dropUID] then
        self.states[entry.dropUID]={dropUID=entry.dropUID,excluded={},manual={}}
    end
    return self.states[entry.dropUID]
end
function R:IsAuthorized(entry)
    return entry and entry.state=='DETECTED' and
        NLL.TicketLottery and NLL.TicketLottery.liveLootObserved and
        NLL.TicketLottery:AuthorityAllowed(entry.slotIndex==0)
end
function R:CanChange(entry)
    if entry and entry.identityUncertain then
        return false,'Duplicate-copy identity is uncertain; candidate changes are blocked.'
    end
    if not self:IsAuthorized(entry) then
        return false,'Only a raid leader/officer with an observed drop may edit candidates.'
    end
    local active=NLL.TicketLottery:GetActiveFor(entry)
    if active and (active.status=='WAITING_FOR_ROLL' or
       active.status=='ROLL_UNCONFIRMED' or active.status=='COMPLETE') then
        return false,'Roll pending or complete; candidate changes are locked.'
    end
    return true
end
function R:Record(entry,action,character,reason)
    if not NLL.db then return end
    NLL.db.candidateAudit=NLL.db.candidateAudit or {}
    table.insert(NLL.db.candidateAudit, {
        dropUID=entry.dropUID,itemID=entry.itemID,boss=entry.boss,
        action=action,character=character,reason=reason,
        actor=UnitName and UnitName('player') or 'Unknown',
        test=entry.slotIndex==0,
        when=date and date('%Y-%m-%d %H:%M:%S') or tostring(Now())
    })
    while #NLL.db.candidateAudit>200 do
        table.remove(NLL.db.candidateAudit,1)
    end
end
function R:AfterChange(entry,action,character,reason)
    local active=NLL.TicketLottery:GetActiveFor(entry)
    if active and active.status=='PREPARED' then
        NLL.TicketLottery:Invalidate('Leader changed candidate pool')
    end
    self:Record(entry,action,character,reason)
    if NLL.UI then
        if NLL.UI.RefreshCurrentLootPanel then NLL.UI:RefreshCurrentLootPanel() end
        if NLL.UI.RefreshCandidateReview then NLL.UI:RefreshCandidateReview() end
    end
end
-- Additions from raid roster only, not an arbitrary name or offline plan.
function R:FindRosterMember(name)
    local wanted=Key(name)
    if wanted=='' then return nil end
    for _,m in ipairs(NLL.Roster:GetMembers() or {}) do
        if Key(m.name)==wanted then return m end
    end
    return nil
end
function R:MergeMatches(entry,matches)
    local result={}
    local seen={}
    for _,m in ipairs(matches or {}) do
        local key=Key(m.character)
        if key~='' and not seen[key] then
            seen[key]=true
            result[#result+1]=m
        end
    end
    local state=self:GetState(entry)
    if state then
        for key,m in pairs(state.manual) do
            if not seen[key] then
                -- Never trust a cached manual addition as proof the
                -- character is still in the live raid roster.
                local member=self:FindRosterMember(m.character)
                local updated={}
                for field,value in pairs(m) do updated[field]=value end
                updated.inRaid=member~=nil
                updated.online=member~=nil and member.online==true
                updated.eligiblePresence=updated.inRaid and updated.online
                if member then
                    updated.classFile=member.classFile
                    updated.classLabel=NLL:GetClassLabel(member.classFile)
                    updated.role=member.assignedRole or
                        NLL.Database:GetRoleAssignment(member.name)
                    updated.roleLabel=NLL:GetRoleLabel(updated.role)
                end
                seen[key]=true
                result[#result+1]=updated
            end
        end
    end
    table.sort(result,function(a,b) return Key(a.character)<Key(b.character) end)
    return result
end
function R:AddCandidate(entry,name)
    local ok,why=self:CanChange(entry)
    if not ok then return false,why end
    local member=self:FindRosterMember(name)
    if not member or not member.online then
        return false,'Character must be online in the current raid roster.'
    end
    local state=self:GetState(entry)
    local key=Key(member.name)
    for _,m in ipairs(NLL.NeedMatcher:GetMatchesForItem(entry.itemID)) do
        if Key(m.character)==key then
            return false,'Already has a NEEDED entry; use Restore if excluded.'
        end
    end
    if state.manual[key] then return false,'Already manually added.' end
    local classFile=member.classFile
    local role=member.assignedRole or NLL.Database:GetRoleAssignment(member.name)
    if not classFile or not role or not NLL.roleLabels[role] then
        return false,'Assign this character a known class and NLL role first.'
    end
    local proposed={character=member.name,role=role,
        roleLabel=NLL:GetRoleLabel(role),classFile=classFile,
        classLabel=NLL:GetClassLabel(classFile),
        characterType=NLL.Database:GetCharacterType(member.name) or 'UNKNOWN',
        inRaid=true,online=true,eligiblePresence=true,
        source='MANUAL_CANDIDATE',manualAddition=true}
    local tier,label=NLL.PriorityEngine:GetCandidatePriority(
        entry.raidKey or 'MOLTEN_CORE',entry.itemID,proposed)
    if tier~=1 and tier~=2 and tier~=3 then
        return false,'Not eligible under the current class/role priority rule: '..tostring(label)
    end
    state.manual[key]=proposed
    state.excluded[key]=nil
    self:AfterChange(entry,'ADDED',member.name,'Explicit raid leader candidate addition')
    return true,'Added '..member.name..' as an explicit manual candidate. Logged.'
end
function R:Exclude(entry,name,reason)
    local ok,why=self:CanChange(entry)
    if not ok then return false,why end
    reason=tostring(reason or ''):match('^%s*(.-)%s*$') or ''
    if #reason<4 then return false,'Enter a reason (at least 4 characters).' end
    local state=self:GetState(entry)
    local key=Key(name)
    local found=false
    for _,m in ipairs(self:MergeMatches(entry,NLL.NeedMatcher:GetMatchesForItem(entry.itemID))) do
        if Key(m.character)==key then found=true break end
    end
    if not found then return false,'Character not in this drop candidate list.' end
    if state.excluded[key] then return false,'Already excluded.' end
    state.excluded[key]=reason
    self:AfterChange(entry,'EXCLUDED',name,reason)
    return true,'Excluded '..name..': '..reason
end
function R:Restore(entry,name)
    local ok,why=self:CanChange(entry)
    if not ok then return false,why end
    local state=self:GetState(entry)
    local key=Key(name)
    if not state.excluded[key] then return false,'Candidate is not excluded.' end
    state.excluded[key]=nil
    self:AfterChange(entry,'RESTORED',name,'Leader restored candidate')
    return true,'Restored '..name..'.'
end
function R:RemoveManual(entry,name)
    local ok,why=self:CanChange(entry)
    if not ok then return false,why end
    local state=self:GetState(entry)
    local key=Key(name)
    if not state.manual[key] then return false,'Not a manually added candidate.' end
    state.manual[key]=nil
    state.excluded[key]=nil
    self:AfterChange(entry,'REMOVED_MANUAL',name,'Leader removed manual addition')
    return true,'Removed manual addition '..name..'.'
end
function R:IsExcluded(entry,name)
    local state=self:GetState(entry)
    return state and state.excluded[Key(name)] or nil
end
function R:IsManual(entry,name)
    local state=self:GetState(entry)
    return state and state.manual[Key(name)]~=nil or false
end
