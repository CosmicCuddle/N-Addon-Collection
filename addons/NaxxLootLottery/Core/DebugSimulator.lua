-- NLL v0.1.0.19: session-only Debug Raid Simulator (WoW 3.3.5 / Lua 5.1).
-- No SavedVariables writes, live roster mutations, loot scanning, network
-- messages, RandomRoll(), GiveMasterLoot(), or real TicketLottery actions.
local NLL = NaxxLootLottery
NLL.DebugSimulator = NLL.DebugSimulator or {}
local S = NLL.DebugSimulator
S.active = nil
S.history = {}
local function Key(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
end
local function Copy(src)
    local t = {}
    for k,v in pairs(src or {}) do t[k] = v end
    return t
end
local function Enabled()
    return NLL.db and NLL.db.settings and NLL.db.settings.debug == true
end
function S:IsEnabled() return Enabled() end
function S:IsActive() return Enabled() and self.active ~= nil end

-- All playable classes in the 3.3.5 client. Death Knights have no
-- Molten Core class set; their test uses the unrestricted Quick Strike Ring.
local CLASS_TESTS = {
    warrior={itemID=16863,role="MAIN_TANK",tag="War"},
    paladin={itemID=16859,role="HEALER",tag="Pal"},
    hunter={itemID=16849,role="RANGED_PHYSICAL_DPS",tag="Hun"},
    rogue={itemID=16824,role="MELEE_DPS",tag="Rog"},
    priest={itemID=16812,role="HEALER",tag="Pri"},
    deathknight={itemID=18821,role="MELEE_DPS",tag="Dk"},
    shaman={itemID=16837,role="HEALER",tag="Sha"},
    mage={itemID=16800,role="CASTER_DPS",tag="Mag"},
    warlock={itemID=16805,role="CASTER_DPS",tag="Lock"},
    druid={itemID=16829,role="HEALER",tag="Dru"}
}
local CLASS_ORDER={"warrior","paladin","hunter","rogue","priest",
    "deathknight","shaman","mage","warlock","druid"}
function S:AvailableScenarios()
    return {"all", "mc40", "warrior", "paladin", "hunter", "rogue", "priest",
        "deathknight", "shaman", "mage", "warlock", "druid",
        "healer", "manual", "missing"}
end
function S:ClassTestInfo(scenario)
    return CLASS_TESTS[string.lower(tostring(scenario or ""))]
end
function S:BuildClassScenario(scenario)
    local players, wishlists, drops = {}, {}, {}
    local function Add(name,classKey,online,wanted)
        local spec=CLASS_TESTS[classKey]
        local classFile=string.upper(classKey)
        local p={character=name,classFile=classFile,role=spec.role,
            online=online~=false,need=false}
        players[#players+1]=p
        wishlists[name]=wanted or {spec.itemID}
        return p
    end
    if scenario == "mc40" then
        -- Full-size MC stress test: 40 imaginary Playerbots, eight groups of
        -- five, four of each playable 3.3.5 class. Roles reflect a mixed raid.
        -- They are all in the virtual raid; no actual Playerbot is spawned.
        local roles = {
            warrior={"MAIN_TANK", "TANK", "TANK", "MELEE_DPS"},
            paladin={"HEALER", "HEALER", "MELEE_DPS", "MELEE_DPS"},
            hunter={"RANGED_PHYSICAL_DPS", "RANGED_PHYSICAL_DPS",
                "RANGED_PHYSICAL_DPS", "RANGED_PHYSICAL_DPS"},
            rogue={"MELEE_DPS", "MELEE_DPS", "MELEE_DPS", "MELEE_DPS"},
            priest={"HEALER", "HEALER", "HEALER", "CASTER_DPS"},
            deathknight={"MELEE_DPS", "MELEE_DPS", "MELEE_DPS", "MELEE_DPS"},
            shaman={"HEALER", "HEALER", "MELEE_DPS", "CASTER_DPS"},
            mage={"CASTER_DPS", "CASTER_DPS", "CASTER_DPS", "CASTER_DPS"},
            warlock={"CASTER_DPS", "CASTER_DPS", "CASTER_DPS", "CASTER_DPS"},
            druid={"HEALER", "HEALER", "TANK", "CASTER_DPS"}
        }
        -- Each wave has one representative of all ten classes, so the
        -- eight five-character groups are mixed instead of class-stacked.
        for wave=1,4 do
            for _,key in ipairs(CLASS_ORDER) do
                local spec=CLASS_TESTS[key]
                local role=roles[key][wave]
                local name="Sim"..spec.tag..wave
                local wanted={}
                local classSetRole=role==spec.role or
                    (key=="warrior" and role=="TANK")
                if classSetRole then wanted[#wanted+1]=spec.itemID end
                if role=="HEALER" then wanted[#wanted+1]=19140 end
                if role=="CASTER_DPS" then wanted[#wanted+1]=19147 end
                if role=="MELEE_DPS" or role=="RANGED_PHYSICAL_DPS" then
                    wanted[#wanted+1]=18821
                end
                local p=Add(name,key,true,wanted)
                p.role=role
            end
        end
        -- A cross-class need exercises the item restriction without
        -- interfering with otherwise valid Tier 1 candidates.
        wishlists["SimLock1"][#wishlists["SimLock1"]+1]=16800
        for _,key in ipairs(CLASS_ORDER) do
            drops[#drops+1]=CLASS_TESTS[key].itemID
        end
        drops[#drops+1]=19140 -- healer competition
        drops[#drops+1]=19147 -- caster competition
        drops[#drops+1]=18821 -- physical-DPS competition
        return players,wishlists,drops
    end
    if scenario=="all" then
        -- Twenty imaginary bots: two competitors for each of ten classes.
        -- For set drops also add one wrong-class gear need to verify exclusion.
        for _,key in ipairs(CLASS_ORDER) do
            local spec=CLASS_TESTS[key]
            drops[#drops+1]=spec.itemID
            Add("Sim"..spec.tag.."A",key,true,{spec.itemID})
            Add("Sim"..spec.tag.."B",key,true,{spec.itemID})
        end
        -- Cross-class wishlists: visible but excluded by class-set rules.
        -- Death Knight's ring deliberately stays unrestricted.
        local outsider=players[1]
        wishlists[outsider.character][#wishlists[outsider.character]+1]=16800
        return players,wishlists,drops
    end
    local spec=CLASS_TESTS[scenario]
    Add("Sim"..spec.tag.."A",scenario,true,{spec.itemID})
    Add("Sim"..spec.tag.."B",scenario,true,{spec.itemID})
    Add("Sim"..spec.tag.."Off",scenario,false,{spec.itemID})
    local other=scenario=="mage" and "warlock" or "mage"
    Add("SimRival",other,true,{spec.itemID})
    -- Other class roles populate the normal Raid Roles and Gear Plans tabs.
    for _,key in ipairs(CLASS_ORDER) do
        if key~=scenario and key~=other and #players<12 then
            local extra=CLASS_TESTS[key]
            local fillerID=extra.itemID
            if fillerID==spec.itemID then fillerID=19147 end
            Add("Sim"..extra.tag.."Support",key,true,{fillerID})
        end
    end
    -- Include two other independently rollable drops, not just the class item.
    drops={spec.itemID}
    if spec.itemID~=19147 then drops[#drops+1]=19147 end
    if spec.itemID~=18821 then drops[#drops+1]=18821 end
    return players,wishlists,drops
end
function S:ScenarioPlayers()
    -- These are imaginary members with imaginary Gear Needs. They do not
    -- appear in the real raid roster or anywhere in SavedVariables.
    return {
      {character="SimAria", classFile="MAGE", role="CASTER_DPS", need=true, online=true},
      {character="SimBryn", classFile="MAGE", role="CASTER_DPS", need=true, online=true},
      {character="SimCora", classFile="WARLOCK", role="CASTER_DPS", need=true, online=true},
      {character="SimDena", classFile="MAGE", role="CASTER_DPS", need=true, online=false},
      {character="SimEli", classFile="PRIEST", role="HEALER", need=false, online=true},
      {character="SimFaye", classFile="PALADIN", role="HEALER", need=false, online=true},
      {character="SimGale", classFile="DRUID", role="HEALER", need=false, online=true},
      {character="SimHera", classFile="WARRIOR", role="MAIN_TANK", need=false, online=true},
      {character="SimIvan", classFile="ROGUE", role="MELEE_DPS", need=false, online=true},
      {character="SimJuno", classFile="HUNTER", role="RANGED_PHYSICAL_DPS", need=false, online=true}
    }
end
function S:GetRule(itemID)
    local P = NLL.PriorityEngine
    local custom = P:GetCustomRule("MOLTEN_CORE",itemID)
    if custom then return custom,"CUSTOM" end
    local suggestion = NLL.PrioritySuggestions:GetSuggestion("MOLTEN_CORE",itemID)
    if suggestion then return suggestion,"BUILT-IN SUGGESTION (not saved)" end
    return nil,"NONE"
end
function S:Start(scenario)
    if NLL.UI and NLL.UI.HideWinnerAnnouncement then NLL.UI:HideWinnerAnnouncement() end
    if not Enabled() then return false,"Run /nll debug to enable the Debug Lab first." end
    scenario = string.lower(tostring(scenario or "mage"))
    if scenario == "" then scenario="mage" end
    if scenario == "40" or scenario == "all40" then scenario="mc40" end
    local classScenario=(scenario=="all" or scenario=="mc40" or
        (CLASS_TESTS[scenario] and scenario~="mage"))
    local customPlayers,customWishlists,customDrops
    if classScenario then
        customPlayers,customWishlists,customDrops=self:BuildClassScenario(scenario)
    end
    local ids = {mage=16800, healer=19140, manual=18564, missing=16800}
    local itemID = classScenario and customDrops[1] or ids[scenario]
    if not itemID then return false,
        "Unknown scenario. Try /nll sim list for all class and safety tests." end
    local item = NLL.Data.MoltenCore:GetItem(itemID)
    if not item then return false,"Scenario item missing from Molten Core database." end
    local players = customPlayers or self:ScenarioPlayers()
    if scenario == "healer" then
        for _,p in ipairs(players) do
            p.need = p.role == "HEALER" or p.character == "SimAria"
        end
    elseif scenario == "missing" then
        for _,p in ipairs(players) do
            if p.character == "SimBryn" then p.role=nil end
        end
    end
    -- Give each fake Playerbot a small unsaved Gear Plan. This simulates
    -- bots requesting multiple drops across a raid evening.
    local wishlists = {
      SimAria={16800,19147,18821}, SimBryn={16800,19147},
      SimCora={19147,18821}, SimDena={16800,18821},
      SimEli={19140,18875}, SimFaye={19140,18875},
      SimGale={19140,18875}, SimHera={18879,18821},
      SimIvan={18821,18823}, SimJuno={18821,18823}
    }
    if customWishlists then wishlists=customWishlists end
    for _,p in ipairs(players) do
        p.wantedItems={}
        p.obtainedItems={}
        for _,id in ipairs(wishlists[p.character] or {}) do
            p.wantedItems[id]=true
        end
        p.characterType="PLAYERBOT"
        p.name=p.character
        p.assignedRole=p.role
        p.className=NLL:GetClassLabel(p.classFile)
        p.raidIndex=_
        p.subgroup=math.floor((_ - 1)/5)+1
        p.level=60
        p.inRaid=true
    end
    -- The test scenarios use one active boss drop at a time. Other items
    -- are stored as wishlist needs for the Next Drop action.
    self.history = {}
    local drops=customDrops or (scenario=="healer" and {19140,18875} or
        scenario=="manual" and {18564} or
        {16800,19147,18821})
    local entries={}
    for i,id in ipairs(drops) do
        local dropItem=NLL.Data.MoltenCore:GetItem(id)
        entries[i]={itemID=id,itemName=dropItem.name,raidKey="MOLTEN_CORE",
            state="SIMULATED_DROP",simulationOnly=true,
            dropUID="SIMULATED-"..scenario.."-"..i,
            manualOnly=dropItem.manualOnly==true,slotIndex=-99,
            boss="SIMULATION BOSS",quantity=1}
    end
    self.active = {
        scenario=scenario, players=players, itemID=itemID, entry=entries[1],
        entries=entries,drops=drops,dropPosition=1,dropStates={},
        exclusions={},prepared=nil,result=nil,lastPreview=nil
    }
    if NLL.UI then
        NLL.UI.currentLootSelected=1
        NLL.UI.currentLootDropPage=1
        NLL.UI.currentLootMatchPage=1
    end
    self:RefreshUI()
    return true,"[SIMULATION] Fake raid started: "..scenario.." ("..
        tostring(#players).." fake Playerbots / "..
        tostring(math.ceil(#players/5)).." groups, "..#entries.." drops)."
end
function S:Stop()
    if NLL.UI and NLL.UI.HideWinnerAnnouncement then NLL.UI:HideWinnerAnnouncement() end
    if NLL.UI and NLL.UI.awardReviewFrame then NLL.UI.awardReviewFrame:Hide() end
    if NLL.AwardWorkflow then NLL.AwardWorkflow:Cancel() end
    self.active=nil
    self.history={}
    self:RefreshUI()
    return true,"[SIMULATION] Stopped. No live raid data or history changed."
end
-- Every mock drop keeps its own tickets, winner and award status.
-- No values here ever enter SavedVariables.
local function SaveDropState(a)
    if not a then return end
    a.dropStates[a.dropPosition]={prepared=a.prepared,result=a.result,
        exclusions=a.exclusions,lastPreview=a.lastPreview}
end

function S:SelectDrop(index)
    if not self:IsActive() then return false,"No simulated raid active." end
    if NLL.UI and NLL.UI.awardReviewFrame then NLL.UI.awardReviewFrame:Hide() end
    if NLL.AwardWorkflow then NLL.AwardWorkflow:Cancel() end
    local a=self.active
    index=tonumber(index)
    if not index or index<1 or index>#a.entries then
        return false,"Unknown simulated drop." end
    SaveDropState(a)
    local state=a.dropStates[index] or {}
    a.dropPosition=index
    a.entry=a.entries[index]
    a.itemID=a.entry.itemID
    a.prepared=state.prepared
    a.result=state.result
    a.exclusions=state.exclusions or {}
    a.lastPreview=state.lastPreview
    if NLL.UI then
        NLL.UI.currentLootSelected=index
        NLL.UI.currentLootDropPage=math.ceil(index / 5)
        NLL.UI.currentLootMatchPage=1
    end
    self:RefreshUI()
    return true,"[SIMULATION] Selected drop "..index.."/"..#a.entries..": "..a.entry.itemName
end

function S:GetResultFor(entry)
    local a=self.active
    if not self:IsActive() or not entry then return nil end
    for i,e in ipairs(a.entries) do
        if e.dropUID==entry.dropUID then
            if i==a.dropPosition then return a.result end
            return a.dropStates[i] and a.dropStates[i].result or nil
        end
    end
end

function S:ConfirmAward()
    local a=self.active
    if not self:IsActive() or not a.result then
        return false,"No simulated winner to award." end
    if a.result.awardStatus then
        return false,"This fake drop has already been marked awarded." end
    a.result.awardStatus="SIMULATED_AWARDED"
    for _,p in ipairs(a.players) do
        if p.character==a.result.winner and p.obtainedItems then
            p.obtainedItems[a.itemID]=true
        end
    end
    self:RefreshUI()
    return true,"[SIMULATION] Fake award recorded for "..a.result.winner..". No real item moved."
end

function S:GetPlayers()
    return self.active and self.active.players or {}
end
function S:FakeMatches()
    local output={}
    for _,p in ipairs(self:GetPlayers()) do
        if (p.need and not (p.obtainedItems and p.obtainedItems[self.active.itemID])
            and self.active.itemID ==
            (self.active.scenario == "healer" and 19140 or
             self.active.scenario == "manual" and 18564 or 16800)) or
            (p.wantedItems and p.wantedItems[self.active.itemID] and
                not (p.obtainedItems and p.obtainedItems[self.active.itemID])) then
            local m=Copy(p)
            m.inRaid=p.inRaid ~= false
            m.online=p.online == true
            m.eligiblePresence=m.inRaid and m.online
            m.roleLabel=NLL:GetRoleLabel(m.role)
            m.classLabel=NLL:GetClassLabel(m.classFile)
            m.characterType="SIMULATED"
            table.insert(output,m)
        end
    end
    return output
end
function S:Preview()
    if not Enabled() then return nil,"Debug Lab disabled; run /nll debug." end
    local a=self.active
    if not a then return nil,"Start a fake raid scenario first." end
    local rule,source=self:GetRule(a.itemID)
    local preview=NLL.TicketPlanner:BuildPreview(a.entry,
        self:FakeMatches(),{simulation=true,rule=rule,excluded=a.exclusions})
    preview.ruleSource=source
    a.lastPreview=preview
    self:RefreshUI()
    return preview,preview.message
end
local function Snapshot(a,preview)
    -- The signature includes the rule AND all fake players. Changing any
    -- role, eligibility setting, presence, or need invalidates old tickets.
    local rule = NLL.DebugSimulator:GetRule(a.itemID)
    local parts={tostring(a.itemID),tostring(preview.chosenTier)}
    for _,r in ipairs(NLL.roles) do
        parts[#parts+1] = r.id .. "=" .. tostring(rule and
            rule.rolePriority and rule.rolePriority[r.id] or "UNSET")
    end
    local classes = NLL.PriorityEngine:GetEffectiveClassEligibility(
        "MOLTEN_CORE",a.itemID,rule)
    for _,c in ipairs(NLL.classes) do
        parts[#parts+1] = c.id .. "=" .. tostring(classes[c.id] == true)
    end
    for _,p in ipairs(a.players) do
        table.insert(parts,table.concat({p.character,p.classFile or "?",
            p.role or "?",tostring(p.need),tostring(p.online),
            tostring(p.inRaid~=false),tostring(a.exclusions[Key(p.character)] == true)},":"))
    end
    for _,m in ipairs(preview.current) do
        table.insert(parts,"TICKET:"..Key(m.character))
    end
    return table.concat(parts,"|")
end
function S:Prepare()
    local a=self.active
    if not a then return false,"Start a simulated raid first." end
    if a.result then return false,"Simulation already has a result. Reset scenario for another run." end
    local preview,message=self:Preview()
    if not preview or not preview.ready then return false,message end
    local tickets={}
    for i,m in ipairs(preview.current) do
        tickets[i]={number=i,character=m.character}
    end
    a.prepared={tickets=tickets,signature=Snapshot(a,preview),tier=preview.chosenTier}
    self:RefreshUI()
    return true,"[SIMULATION] Prepared "..#tickets.." fake tickets (Tier "..preview.chosenTier..")."
end
function S:Roll()
    if not Enabled() then return false,"Debug Lab disabled." end
    local a=self.active
    if not a or not a.prepared then return false,"Prepare simulated tickets first." end
    if a.result then return false,"Fake winner already recorded; reset scenario first." end
    local preview,message=self:Preview()
    if not preview or not preview.ready or
        Snapshot(a,preview) ~= a.prepared.signature then
        a.prepared=nil
        self:RefreshUI()
        return false,"[SIMULATION] Fake pool changed; tickets cancelled. Prepare again."
    end
    local winningTicket=math.random(1,#a.prepared.tickets)
    local winner=a.prepared.tickets[winningTicket].character
    a.result={winner=winner,number=winningTicket,method="LOCAL_SIMULATION_ONLY"}
    -- Gear remains NEEDED until the separate award confirmation.
    self.history[#self.history+1]=a.result
    self:RefreshUI()
    if NLL.UI and NLL.UI.ShowWinnerAnnouncement then
        NLL.UI:ShowWinnerAnnouncement(a.entry.itemName, winner, winningTicket, true)
    end
    return true,"[SIMULATION] Fake ticket #"..winningTicket.." = "..winner..". No server roll or loot award."
end
function S:SetExcluded(name,excluded)
    local a=self.active
    if not Enabled() or not a then return false,"Start a simulated raid first." end
    if a.result then return false,"Fake draw complete. Reset scenario to change candidates." end
    local found=false
    for _,p in ipairs(a.players) do
        if Key(p.character)==Key(name) then found=true break end
    end
    if not found then return false,"Fake player not found." end
    a.exclusions[Key(name)]=excluded and true or nil
    a.prepared=nil
    a.lastPreview=nil
    self:RefreshUI()
    return true,"[SIMULATION] "..name..(excluded and " excluded." or " restored.")
end
function S:SetOnline(name,online)
    local a=self.active
    if not Enabled() or not a then return false,"Start a simulated raid first." end
    if a.result then return false,"Fake draw complete. Reset scenario first." end
    for _,p in ipairs(a.players) do
        if Key(p.character)==Key(name) then
            p.online=online == true
            -- Keep prepared tickets until Roll to exercise pool-change guard.
            a.lastPreview=nil
            self:RefreshUI()
            return true,"[SIMULATION] "..p.character..(online and " online." or " offline.")
        end
    end
    return false,"Fake player not found."
end
function S:Status()
    local a=self.active
    if not a then return "Inactive. Enable /nll debug, then start a scenario." end
    local item=NLL.Data.MoltenCore:GetItem(a.itemID)
    local line="[SIMULATION] "..a.scenario.." ("..#a.players..
        " fake bots, "..math.ceil(#a.players/5).." groups) / "..
        (item and item.name or tostring(a.itemID))
    if a.result then
        return line.." / fake winner: "..a.result.winner.." (#"..a.result.number..")"
    end
    if a.prepared then return line.." / "..#a.prepared.tickets.." tickets prepared" end
    return line.." / awaiting preview"
end
function S:RefreshUI()
    local UI=NLL.UI
    if not UI then return end
    if UI.RefreshDebugLab then UI:RefreshDebugLab() end
    if UI.RefreshSimulationIndicator then UI:RefreshSimulationIndicator() end
    if UI.RefreshRolesPanel then UI:RefreshRolesPanel() end
    if UI.RefreshCurrentLootPanel then UI:RefreshCurrentLootPanel() end
    if UI.RefreshWishlistPanel then UI:RefreshWishlistPanel() end
    if UI.RefreshOverview then UI:RefreshOverview() end
end

-- Integrated fake-raid facade. These APIs are session-only; live DB tables
-- and the real roster/loot queue are not modified.
function S:GetRoster()
    if not self:IsActive() then return nil end
    local output={}
    for i,p in ipairs(self.active.players) do
        output[i]={name=p.character,raidIndex=i,rank=i==1 and 2 or 0,
          subgroup=p.subgroup or 1,level=60,className=p.className,
          classFile=p.classFile,online=p.online,isDead=false,
          assignedRole=p.role,simulationOnly=true,
          isMasterLooter=i==1}
    end
    return output
end
function S:AssignRole(name,roleID)
    if not self:IsActive() then return false end
    if roleID and not NLL.roleLabels[roleID] then return false end
    for _,p in ipairs(self.active.players) do
        if Key(p.character)==Key(name) then
            p.role=roleID; p.assignedRole=roleID
            self.active.prepared=nil; self.active.lastPreview=nil
            self:RefreshUI(); return true
        end
    end
    return false
end
function S:GetLoot()
    if not self:IsActive() then return nil end
    return self.active.entries
end
function S:GetNeeds()
    if not self:IsActive() then return {} end
    local rows={}
    for _,p in ipairs(self.active.players) do
        for id,wanted in pairs(p.wantedItems or {}) do
            if wanted then
                rows[#rows+1]={character=p.character,classFile=p.classFile,
                  role=p.role,online=p.online,itemID=id,
                  itemName=(NLL.Data.MoltenCore:GetItem(id) or {}).name or tostring(id),
                  state=p.obtainedItems and p.obtainedItems[id] and "OBTAINED" or "NEEDED"}
            end
        end
    end
    table.sort(rows,function(a,b)
        if a.character==b.character then return a.itemID<b.itemID end
        return a.character<b.character
    end)
    return rows
end
function S:GetCandidatePriority(match)
    if not self:IsActive() then return nil,"Inactive" end
    local rule=self:GetRule(self.active.itemID)
    if not rule then return nil,"No suggestion" end
    if not match.classFile then return nil,"Class unknown" end
    if not NLL.PriorityEngine:IsClassEligible("MOLTEN_CORE",self.active.itemID,
          match.classFile,rule) then return "EXCLUDE","Wrong class" end
    if not match.role then return nil,"Role unknown" end
    local n=rule.rolePriority and rule.rolePriority[match.role]
    if n==1 or n==2 or n==3 then return n,"Tier "..n end
    return n,"Not eligible"
end
function S:NextDrop()
    if not self:IsActive() then return false,"Start simulation first." end
    local a=self.active
    if #a.entries<2 then return false,"Only one fake item in this scenario." end
    if NLL.UI and NLL.UI.HideWinnerAnnouncement then
        NLL.UI:HideWinnerAnnouncement() end
    local index=(a.dropPosition % #a.entries)+1
    return self:SelectDrop(index)
end

function S:Cancel()
    if NLL.UI and NLL.UI.HideWinnerAnnouncement then
        NLL.UI:HideWinnerAnnouncement() end
    if not self:IsActive() then return false,"No fake raid." end
    local a=self.active
    if a.result then
        return false,"Winner already recorded. Select another drop or reset raid."
    end
    a.prepared=nil
    a.lastPreview=nil
    self:RefreshUI()
    return true,"[SIMULATION] Selected drop tickets reset; other drops unchanged."
end

-- This module never registers game events and has no SavedVariables.
