-- Naxxramas Loot Ledger v0.1.0.27
-- Read-only diagnostics for real AzerothCore Playerbot rosters and gear plans.
-- The WoW client does not expose a universal IsPlayerbot API. A BOT_GEAR_PLAN
-- means the raid leader marked a character as a bot; it is NOT proof of bot AI.
local NLL=NaxxLootLottery
NLL.PlayerbotCompatibility=NLL.PlayerbotCompatibility or {}
local P=NLL.PlayerbotCompatibility
local function Key(name)
    return string.lower((tostring(name or ''):match('^([^%-]+)') or ''))
end
local function Live()
    return not (NLL.DebugSimulator and NLL.DebugSimulator:IsActive())
end
local function MemberFor(key)
    for _,member in ipairs(NLL.Roster:GetMembers() or {}) do
        if Key(member.name)==key then return member end
    end
end
local function ConfiguredRole(name,member)
    return (member and member.assignedRole) or
        (NLL.Database and NLL.Database:GetRoleAssignment(name))
end
local function ClassFor(name,member)
    local saved=NLL.Database and NLL.Database:GetCharacterClass(name)
    return (member and member.classFile) or saved
end
function P:ReadPlans()
    local plans={}
    local needs=NLL.db and NLL.db.gearNeeds or {}
    for _,need in pairs(needs) do
        if type(need)=='table' and (need.characterType=='PLAYERBOT' or
            need.source=='BOT_GEAR_PLAN') and Key(need.character)~='' then
            local k=Key(need.character)
            if not plans[k] then
                plans[k]={name=need.character,needed=0,obtained=0,disabled=0}
            end
            local p=plans[k]
            if need.status=='NEEDED' then p.needed=p.needed+1
            elseif need.status=='OBTAINED' then p.obtained=p.obtained+1
            elseif need.status=='DISABLED' then p.disabled=p.disabled+1 end
        end
    end
    return plans
end
function P:LiveCandidates()
    -- The Wrath client only supplies candidates for the active selected
    -- Master Loot slot; nothing here should open, change or award a slot.
    if not Live() or type(GetLootMethod)~='function' or
        type(GetMasterLootCandidate)~='function' or
        not LootFrame or type(LootFrame.IsShown)~='function' or
        not LootFrame:IsShown() or type(LootFrame.selectedSlot)~='number' then
        return nil,'WoW Master Loot list not open for an item'
    end
    local method=GetLootMethod()
    if method~='master' then return nil,'Raid is not using Master Loot' end
    local selected=LootFrame.selectedSlot
    if type(GetLootSlotLink)~='function' or not GetLootSlotLink(selected) then
        return nil,'No selected item link in the real loot window'
    end
    local candidates={}
    for i=1,40 do
        local name=GetMasterLootCandidate(i)
        if name then candidates[Key(name)]=i end
    end
    if not next(candidates) then
        return nil,'No candidates exposed for selected item; cannot verify'
    end
    return candidates,'Master Loot candidates read for selected item only'
end
function P:Inspect(name, knownCandidates, knownNote)
    if not Live() then return nil,'Stop the fake raid before running real bot diagnostics.' end
    local k=Key(name)
    local plan=self:ReadPlans()[k]
    if not plan then return nil,'No saved Playerbot gear plan for '..tostring(name) end
    local member=MemberFor(k)
    local status,issue
    if not member then
        status='NOT IN RAID'; issue='Server/client roster does not expose this character'
    elseif member.online==false then
        status='OFFLINE';issue='Bot appears in roster but is offline'
    elseif not member.classFile or not NLL:IsValidClass(member.classFile) then
        status='CLASS UNVERIFIED';issue='Live raid roster did not expose a valid class; a saved class is not proof'
    elseif not ConfiguredRole(plan.name,member) or
        not NLL:IsValidRole(ConfiguredRole(plan.name,member)) then
        status='ROLE UNKNOWN';issue='Assign a role before a lottery'
    else
        status='ROSTER READY';issue='Roster/plan present; actual bot identity and delivery remain unverified'
    end
    local candidates,detail
    if knownCandidates~=nil then
        candidates=knownCandidates~=false and knownCandidates or nil
        detail=knownNote
    else
        candidates,detail=self:LiveCandidates()
    end
    local candidate='NOT CHECKED'
    if candidates then candidate=candidates[k] and
        ('LISTED INDEX '..candidates[k]) or 'NOT LISTED FOR SELECTED ITEM' end
    return {name=plan.name,member=member,status=status,issue=issue,
        classFile=ClassFor(plan.name,member),role=ConfiguredRole(plan.name,member),
        needed=plan.needed,obtained=plan.obtained,disabled=plan.disabled,
        candidate=candidate,candidateNote=detail}
end
function P:Report(name)
    if not Live() then return false,'Stop the fake raid first: /nll sim stop' end
    if NLL.Roster and NLL.Roster.Refresh then NLL.Roster:Refresh() end
    local plans=self:ReadPlans()
    local keys={}
    for key in pairs(plans) do keys[#keys+1]=key end
    table.sort(keys)
    if #keys==0 then
        NLL:Print('No saved Playerbot gear plans. Add a BOT_GEAR_PLAN from Wishlists first.')
        return true
    end
    local one=Key(name)
    if one~='' and not plans[one] then
        return false,'No saved Playerbot plan for '..tostring(name)
    end
    local summary={ready=0,other=0}
    local cachedCandidates,detail=self:LiveCandidates()
    local shown=0
    for _,key in ipairs(keys) do
        local p=self:Inspect(plans[key].name,cachedCandidates or false,detail)
        if p.status=='ROSTER READY' then summary.ready=summary.ready+1
        else summary.other=summary.other+1 end
        if one==key or (one=='' and shown<15) then
            shown=shown+1
            NLL:Print(p.name..': '..p.status..' | '..tostring(p.classFile or '?')..
                ' / '..tostring(p.role or '?')..' | NEEDED '..p.needed..
                ' | Master Loot: '..p.candidate)
            if one==key then
                NLL:Print(p.issue)
                NLL:Print(p.candidateNote)
            end
        end
    end
    NLL:Print('Bot plan preflight: '..#keys..' planned, '..summary.ready..
        ' roster-ready, '..summary.other..' unresolved. This does NOT verify bot AI or receipt.')
    if #keys>15 and one=='' then
        NLL:Print('Showing first 15. Use /nll botcheck <name> for a specific bot.')
    end
    return true
end
