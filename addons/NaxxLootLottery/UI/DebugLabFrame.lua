-- Naxxramas Loot Ledger Debug Lab. All data is simulated in memory.
local NLL=NaxxLootLottery
local UI=NLL.UI
local function Text(parent, style, x, y, width, value)
    local f=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    f:SetWidth(width)
    f:SetJustifyH("LEFT")
    f:SetText(value or "")
    return f
end
function UI:CreateDebugLabContent(parent)
    local label=Text(parent,"GameFontNormal",8,-5,700,
        "Debug Raid Simulator - FAKE data only")
    local warning=Text(parent,"GameFontHighlightSmall",8,-28,700,
        "No real players, saved Gear Plans, server rolls, guild rules or loot awards are changed.")
    Text(parent,"GameFontNormalSmall",8,-55,650,"Scenario (starts a fresh fake raid):")
    local scenarios={
        {"Mage Contest","mage"},{"Healer Loot","healer"},
        {"Guild Item","manual"},{"Missing Role","missing"}
    }
    for i,c in ipairs(scenarios) do
        local b=self:CreateTextButton(parent,c[1],118)
        b:SetPoint("TOPLEFT",parent,"TOPLEFT",8+(i-1)*132,-78)
        b:SetScript("OnClick",function()
            local ok,message=NLL.DebugSimulator:Start(c[2])
            NLL:Print(message)
            UI:RefreshDebugLab()
            if ok then UI:ShowMainFrame("roles") end
        end)
    end
    local fullMC=self:CreateTextButton(parent,"40-Player MC",153)
    fullMC:SetPoint("TOPLEFT",parent,"TOPLEFT",545,-78)
    fullMC:SetScript("OnClick",function()
        local ok,msg=NLL.DebugSimulator:Start("mc40")
        NLL:Print(msg)
        UI:RefreshDebugLab()
        if ok then UI:ShowMainFrame("roles") end
    end)
    Text(parent,"GameFontNormalSmall",8,-112,155,"Class-specific raid:")
    local picker=CreateFrame("Frame","NaxxLootLotteryDebugClassPicker",parent,
        "UIDropDownMenuTemplate")
    picker:SetPoint("TOPLEFT",parent,"TOPLEFT",130,-103)
    UIDropDownMenu_SetWidth(picker,185)
    self.debugLabSelectedClass="warrior"
    UIDropDownMenu_SetText(picker,"Warrior")
    local scenarioLabels={warrior="Warrior",paladin="Paladin",hunter="Hunter",
        rogue="Rogue",priest="Priest",deathknight="Death Knight",
        shaman="Shaman",mage="Mage",warlock="Warlock",druid="Druid"}
    UIDropDownMenu_Initialize(picker,function()
        for _,key in ipairs(NLL.DebugSimulator:AvailableScenarios()) do
            if scenarioLabels[key] then
                local scenario=key
                local info=UIDropDownMenu_CreateInfo()
                info.text=scenarioLabels[key]
                info.checked=UI.debugLabSelectedClass==scenario
                info.func=function()
                    UI.debugLabSelectedClass=scenario
                    UIDropDownMenu_SetText(picker,scenarioLabels[scenario])
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    local startClass=self:CreateTextButton(parent,"Start Class Raid",146)
    startClass:SetPoint("TOPLEFT",parent,"TOPLEFT",350,-112)
    startClass:SetScript("OnClick",function()
        local ok,msg=NLL.DebugSimulator:Start(UI.debugLabSelectedClass)
        NLL:Print(msg)
        if ok then UI:ShowMainFrame("roles") end
    end)
    local startAll=self:CreateTextButton(parent,"All Classes (20)",160)
    startAll:SetPoint("TOPLEFT",parent,"TOPLEFT",506,-112)
    startAll:SetScript("OnClick",function()
        local ok,msg=NLL.DebugSimulator:Start("all")
        NLL:Print(msg)
        if ok then UI:ShowMainFrame("roles") end
    end)
    self.debugLabClassButtons={startClass,startAll,fullMC}
    self.debugLabClassPicker=picker
    Text(parent,"GameFontNormalSmall",8,-148,700,
        "Use normal Raid Roles, Wishlists and Current Loot; each class has fake Gear Plans.")
    local actions={
        {"Preview Pool",function() local p,msg=NLL.DebugSimulator:Preview();return p~=nil and p.ready,msg end},
        {"Prepare Tickets",function() return NLL.DebugSimulator:Prepare() end},
        {"Fake Roll",function() return NLL.DebugSimulator:Roll() end},
        {"Reset Scenario",function()
            local a=NLL.DebugSimulator.active
            return NLL.DebugSimulator:Start(a and a.scenario or "mage")
        end}
    }
    self.debugLabButtons={}
    for i,c in ipairs(actions) do
        local b=self:CreateTextButton(parent,c[1],118)
        b:SetPoint("TOPLEFT",parent,"TOPLEFT",8+(i-1)*132,-170)
        b:SetScript("OnClick",function()
            local ok,msg=c[2]()
            NLL:Print(msg or "Simulation updated.")
            UI:RefreshDebugLab()
        end)
        self.debugLabButtons[#self.debugLabButtons+1]=b
    end
    local changes={
        {"Exclude SimBryn",function() return NLL.DebugSimulator:SetExcluded("SimBryn",true) end},
        {"Restore SimBryn",function() return NLL.DebugSimulator:SetExcluded("SimBryn",false) end},
        {"SimBryn Offline",function() return NLL.DebugSimulator:SetOnline("SimBryn",false) end},
        {"Stop Simulator",function() return NLL.DebugSimulator:Stop() end}
    }
    for i,c in ipairs(changes) do
        local b=self:CreateTextButton(parent,c[1],118)
        b:SetPoint("TOPLEFT",parent,"TOPLEFT",8+(i-1)*132,-204)
        b:SetScript("OnClick",function()
            local ok,msg=c[2]()
            NLL:Print(msg)
            UI:RefreshDebugLab()
        end)
        self.debugLabButtons[#self.debugLabButtons+1]=b
    end
    local openTabs={
        {"View Raid Roles","roles"},{"View Gear Plans","wishlist"},
        {"View Boss Loot","currentloot"},{"Next Boss Drop",nil}
    }
    for i,c in ipairs(openTabs) do
        local b=self:CreateTextButton(parent,c[1],125)
        b:SetPoint("TOPLEFT",parent,"TOPLEFT",8+(i-1)*137,-238)
        b:SetScript("OnClick",function()
            if c[2] then UI:ShowMainFrame(c[2])
            else local ok,msg=NLL.DebugSimulator:NextDrop();NLL:Print(msg) end
        end)
        self.debugLabButtons[#self.debugLabButtons+1]=b
    end
    self.debugLabStatus=Text(parent,"GameFontHighlight",8,-276,720,"")
    self.debugLabDetail=Text(parent,"GameFontHighlightSmall",8,-306,710,"")
    self.debugLabDetail:SetHeight(80)
    self.debugLabDetail:SetJustifyV("TOP")
    self.debugLabPanel=parent
    parent:Hide()
end
function UI:RefreshDebugLab()
    if not self.debugLabPanel then return end
    local S=NLL.DebugSimulator
    if not S:IsEnabled() then
        self.debugLabStatus:SetText("Debug disabled. Run /nll debug first.")
        self.debugLabDetail:SetText("Nothing is simulated while Debug is disabled. "..
            "Start a scenario and use Raid Roles, Wishlists and Current Loot to play through it.")
        for _,b in ipairs(self.debugLabButtons) do b:Disable() end
        for _,b in ipairs(self.debugLabClassButtons or {}) do b:Disable() end
        UIDropDownMenu_DisableDropDown(self.debugLabClassPicker)
        return
    end
    for _,b in ipairs(self.debugLabButtons) do b:Enable() end
    for _,b in ipairs(self.debugLabClassButtons or {}) do b:Enable() end
    UIDropDownMenu_EnableDropDown(self.debugLabClassPicker)
    self.debugLabStatus:SetText(S:Status())
    local a=S.active
    if not a then
        self.debugLabDetail:SetText("Choose a scenario above (10 to 40 imaginary characters). "..
            "Switch to the normal tabs to watch the fake raid. Everything stays in memory.")
        return
    end
    local rows={"Fake raid: "..#a.players.." Playerbots in "..
        math.ceil(#a.players/5).." groups. All fake; no server bots spawned."}
    local needed={}
    for _,p in ipairs(a.players) do
        if p.need or (p.wantedItems and p.wantedItems[a.itemID]) then
            local mark=(p.online and "online" or "offline")
            if a.exclusions[string.lower(p.character)] then mark=mark..", excluded" end
            table.insert(needed,p.character.." ["..(p.classFile or "?")..", "..
                (p.role or "UNASSIGNED")..", "..mark.."]")
        end
    end
    -- Debug Lab is a small status pane. The normal Wishlists and Raid
    -- Roles windows page through all 40 players and their gear needs.
    local shown={}
    for i=1,math.min(#needed,5) do shown[#shown+1]=needed[i] end
    table.insert(rows,"Selected drop needs ("..#needed.."): "..
        table.concat(shown,"   |   ")..
        (#needed>5 and "  ... see Wishlists" or ""))
    local preview=a.lastPreview
    if preview then
        table.insert(rows,"Preview: "..preview.message)
        table.insert(rows,"Rule source: "..tostring(preview.ruleSource))
        local names={}
        for _,m in ipairs(preview.current) do names[#names+1]=m.character end
        local firstNames={}
        for i=1,math.min(#names,8) do firstNames[#firstNames+1]=names[i] end
        table.insert(rows,"Highest eligible tier ("..#names.." players): "..
            (#names>0 and table.concat(firstNames,", ") or "none")..
            (#names>8 and ", ..." or ""))
    end
    if a.prepared then
        local t={}
        for _,ticket in ipairs(a.prepared.tickets) do
            t[#t+1]="#"..ticket.number.." "..ticket.character
        end
        local ticketPreview={}
        for i=1,math.min(#t,8) do ticketPreview[#ticketPreview+1]=t[i] end
        table.insert(rows,"Fake tickets ("..#t.."): "..table.concat(ticketPreview,", ")..
            (#t>8 and ", ..." or ""))
    end
    if a.result then
        table.insert(rows,"FAKE WINNER: "..a.result.winner.." (#"..a.result.number..") - NEVER awarded")
    end
    self.debugLabDetail:SetText(table.concat(rows,"\n"))
end
