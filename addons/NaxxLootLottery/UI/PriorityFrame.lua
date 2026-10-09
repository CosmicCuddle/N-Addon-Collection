-- ============================================================
-- Naxxramas Loot Ledger / Wrath 3.3.5a
-- Phase 8 Priority Setup: separate browse and edit pages.
-- Suggestions are optional and NEVER saved without Save Rule.
-- ============================================================
local NLL = NaxxLootLottery
local UI = NLL.UI
local PAGE_SIZE = 4
local RAID = "MOLTEN_CORE"

local BOSSES = {
    "All", "Lucifron", "Magmadar", "Gehennas", "Garr", "Shazzrah",
    "Baron Geddon", "Golemagg the Incinerator", "Sulfuron Harbinger",
    "Majordomo Executus", "Ragnaros", "Trash", "All bosses"
}

local function Font(parent, template, value, x, y, width)
    local font = parent:CreateFontString(nil, "OVERLAY", template)
    font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    font:SetWidth(width)
    font:SetJustifyH("LEFT")
    font:SetText(value or "")
    return font
end

local function SearchText()
    local t = UI.prioritySearchBox and UI.prioritySearchBox:GetText() or ""
    return string.lower((t or ""):match("^%s*(.-)%s*$") or "")
end

local function SourceContains(item, boss)
    if boss == "All" then return true end
    for _, source in ipairs(item.bosses or {}) do
        if source == boss then return true end
    end
    return false
end

local function GetItemTexture(itemID)
    return (GetItemIcon and GetItemIcon(itemID)) or
        "Interface\\Icons\\INV_Misc_QuestionMark"
end

function UI:GetPriorityFilteredItems()
    local search = SearchText()
    local boss = self.priorityBossFilter or "All"
    local output = {}
    for _, item in ipairs(NLL.Data.MoltenCore:GetItems()) do
        local suggested = NLL.PrioritySuggestions:GetSuggestion(RAID, item.itemID)
        local use = not self.prioritySuggestionsOnly or
            (suggested ~= nil and
             NLL.PriorityEngine:GetRuleSource(RAID, item.itemID) ~= "CUSTOM")
        if use and SourceContains(item, boss) and
            (search == "" or tostring(item.itemID) == search or
             string.find(string.lower(item.name), search, 1, true)) then
            table.insert(output, item)
        end
    end
    return output
end

function UI:SetPriorityBossFilter(boss)
    self.priorityBossFilter = boss or "All"
    UIDropDownMenu_SetText(self.priorityBossDropDown, self.priorityBossFilter)
    self.priorityPage = 1
    self:RefreshPrioritySetup()
end

function UI:SetPriorityRoleSelection(roleID, value)
    self.priorityRoleSelections = self.priorityRoleSelections or {}
    self.priorityRoleSelections[roleID] = value
    local dropdown = self.priorityRoleDropDowns and self.priorityRoleDropDowns[roleID]
    if not dropdown then return end
    local label = "Unset"
    if value == 1 or value == 2 or value == 3 then
        label = "Tier " .. tostring(value)
    elseif value == NLL.PriorityEngine.EXCLUDE then
        label = "Not eligible"
    end
    UIDropDownMenu_SetText(dropdown, label)
end

-- Navigate to the next unapplied suggestion within the current filter.
function UI:GetNextSuggestedItemID(itemID)
    local filtered = self:GetPriorityFilteredItems()
    local found = false
    for _, item in ipairs(filtered) do
        if found and item.itemID ~= itemID and
            NLL.PrioritySuggestions:GetSuggestion(RAID, item.itemID) and
            NLL.PriorityEngine:GetRuleSource(RAID, item.itemID) ~= "CUSTOM" then
            return item.itemID
        end
        if item.itemID == itemID then found = true end
    end
    -- Fallback: next suggested starting from the top of the filter.
    for _, item in ipairs(filtered) do
        if item.itemID ~= itemID and
            NLL.PrioritySuggestions:GetSuggestion(RAID, item.itemID) and
            NLL.PriorityEngine:GetRuleSource(RAID, item.itemID) ~= "CUSTOM" then
            return item.itemID
        end
    end
    return nil
end

function UI:SavePriorityEditor()
    local ok, rule = NLL.PriorityEngine:SaveRule(
        RAID, self.prioritySelectedItemID,
        self.priorityRoleSelections, self.priorityClassSelections)
    if not ok then NLL:Print(rule); return false end
    self.prioritySuggestionUnsaved = false
    local state = NLL.PriorityEngine:GetState(RAID, self.prioritySelectedItemID)
    if state == NLL.PriorityEngine.STATUS.CONFIGURED then
        NLL:Print("Priority rule saved. No lottery has been started.")
    else
        NLL:Print("Draft saved; complete every role/class selection.")
    end
    self:RefreshPriorityEditor()
    return true
end

function UI:OpenPriorityBrowse()
    self.priorityEditorVisible = false
    if self.priorityEditPage then self.priorityEditPage:Hide() end
    if self.priorityBrowsePage then self.priorityBrowsePage:Show() end
    self:RefreshPrioritySetup()
end

function UI:OpenPriorityEditor(itemID)
    local item = NLL.Data.MoltenCore:GetItem(itemID)
    if not item then return end
    self.prioritySelectedItemID = item.itemID
    self.priorityRoleSelections = {}
    self.priorityClassSelections = {}
    self.prioritySuggestionUnsaved = false
    local rule = NLL.PriorityEngine:GetRule(RAID, item.itemID)
    local classes = NLL.PriorityEngine:GetEffectiveClassEligibility(RAID, item.itemID, rule)
    for _, classInfo in ipairs(NLL.classes) do
        self.priorityClassSelections[classInfo.id] = classes[classInfo.id] == true
    end
    for _, role in ipairs(NLL.roles) do
        self:SetPriorityRoleSelection(role.id, rule and
            rule.rolePriority and rule.rolePriority[role.id] or nil)
    end
    self.priorityEditorVisible = true
    self.priorityBrowsePage:Hide()
    self.priorityEditPage:Show()
    self:RefreshPriorityEditor()
end

-- Older calls from earlier builds can still use this method.
function UI:LoadPriorityEditor(itemID)
    self:OpenPriorityEditor(itemID)
end

function UI:RefreshPrioritySetup()
    if not self.priorityBrowsePage then return end
    local filtered = self:GetPriorityFilteredItems()
    local maxPage = math.max(1, math.ceil(#filtered / PAGE_SIZE))
    self.priorityPage = math.min(maxPage, math.max(1, self.priorityPage or 1))
    local first = (self.priorityPage-1)*PAGE_SIZE + 1
    for i = 1, PAGE_SIZE do
        local row = self.priorityRows[i]
        local item = filtered[first+i-1]
        row.itemID = item and item.itemID or nil
        if item then
            row.icon:SetTexture(GetItemTexture(item.itemID))
            row.iconHit.itemID = item.itemID
            row.nameText:SetText(item.name)
            row.idText:SetText("Item ID: " .. item.itemID)
            row.sourceText:SetText(NLL.Data.MoltenCore:GetBossText(item))
            row.stateText:SetText(NLL.PriorityEngine:GetDisplayLabel(RAID, item.itemID))
            row:Show()
        else
            row.iconHit.itemID = nil
            row:Hide()
        end
    end
    self.priorityPageText:SetText("Page " .. self.priorityPage .. " / " ..
        maxPage .. "   (" .. #filtered .. " items)")
    if self.priorityBrowseSummary then
        local info = NLL.PriorityEngine:GetPresetSummary(RAID)
        self.priorityBrowseSummary:SetText(
            "Custom " .. info.custom .. "   Presets " .. info.preset ..
            "   Drafts " .. info.drafts .. "   Manual " .. info.manual ..
            "   Not set " .. info.unconfigured .. "   Available " .. info.available)
    end
    if self.prioritySuggestionFilterButton then
        UI:SetButtonState(self.prioritySuggestionFilterButton,
            self.prioritySuggestionsOnly and "active" or "normal")
    end
    if self.priorityPresetToggleButton then
        local enabled = NLL.PriorityEngine:PresetsEnabled()
        self.priorityPresetToggleButton.label:SetText(
            enabled and "Disable Presets" or "Enable Presets")
        UI:SetButtonState(self.priorityPresetToggleButton,
            enabled and "active" or "normal")
        if self.priorityPresetExplanation then
            local info = NLL.PriorityEngine:GetPresetSummary(RAID)
            self.priorityPresetExplanation:SetText(
                (enabled and "ACTIVE" or "OFF") .. "  -  " ..
                info.available .. " presets. Custom rules win; " ..
                "unresearched items remain unconfigured.")
        end
    end
    if self.priorityUndoButton then
        if NLL.PriorityEngine:CanUndo() then self.priorityUndoButton:Enable()
        else self.priorityUndoButton:Disable() end
    end
    if self.priorityPage <= 1 then self.priorityPreviousButton:Disable()
    else self.priorityPreviousButton:Enable() end
    if self.priorityPage >= maxPage then self.priorityNextButton:Disable()
    else self.priorityNextButton:Enable() end
    if self.priorityEditorVisible then self:RefreshPriorityEditor() end
end

function UI:RefreshPriorityEditor()
    if not self.priorityEditPage then return end
    local item = NLL.Data.MoltenCore:GetItem(self.prioritySelectedItemID)
    if not item then return end
    local rule = NLL.PriorityEngine:GetRule(RAID, item.itemID)
    self.prioritySelectedName:SetText(item.name .. "   (" .. item.itemID .. ")")
    self.prioritySelectedSource:SetText("Source: " .. NLL.Data.MoltenCore:GetBossText(item))
    local state = NLL.PriorityEngine:GetDisplayLabel(RAID, item.itemID)
    if self.prioritySuggestionUnsaved then state = state .. "  |cffffd055(Suggestion loaded - not saved)|r" end
    self.priorityEditorStatus:SetText("Rule: " .. state)
    local itemClasses = NLL.PriorityEngine:GetDefaultClassEligibility(RAID, item.itemID)
    local locked = type(item.allowedClasses) == "table"
    if locked then
        self.priorityClassNote:SetText(NLL.Data.MoltenCore:GetAllowedClassText(item) ..
            " (item restriction; locked)")
    else
        local count = 0
        for _, c in ipairs(NLL.classes) do
            if self.priorityClassSelections[c.id] then count=count+1 end
        end
        self.priorityClassNote:SetText(count .. " class(es) selected - editable")
    end
    for _, c in ipairs(NLL.classes) do
        local check = self.priorityClassCheckButtons[c.id]
        check:SetChecked(locked and itemClasses[c.id] or
            self.priorityClassSelections[c.id] == true)
        if item.manualOnly or locked then check:Disable() else check:Enable() end
    end
    for _, role in ipairs(NLL.roles) do
        local dropdown = self.priorityRoleDropDowns[role.id]
        if item.manualOnly then UIDropDownMenu_DisableDropDown(dropdown)
        else UIDropDownMenu_EnableDropDown(dropdown) end
    end
    local editable = not item.manualOnly
    if editable then
        self.prioritySaveButton:Enable(); self.priorityEqualButton:Enable()
        self.priorityResetButton:Enable()
        self.prioritySaveNextButton:Enable()
    else
        self.prioritySaveButton:Disable(); self.priorityEqualButton:Disable()
        self.priorityResetButton:Disable()
        self.prioritySaveNextButton:Disable()
    end
    -- Delete removes only a saved custom override, never the preset library.
    if NLL.PriorityEngine:GetCustomRule(RAID, item.itemID) then
        self.priorityDeleteButton:Enable()
    else self.priorityDeleteButton:Disable() end
    local suggestion = NLL.PrioritySuggestions:GetSuggestion(RAID, item.itemID)
    self.prioritySuggestion = suggestion
    if suggestion and editable then self.prioritySuggestButton:Show()
    else self.prioritySuggestButton:Hide() end
    if item.manualOnly then
        self.priorityHint:SetText("Guild/manual item. No normal lottery or priority rule.")
    elseif NLL.PriorityEngine:GetRuleSource(RAID,item.itemID) == "PRESET" then
        self.priorityHint:SetText(
            "Using a built-in preset. Save Rule only to make a custom override.")
    elseif suggestion then
        self.priorityHint:SetText(
            "Optional suggestion only. Inspect the role tiers, then Save Rule if approved.")
    else
        self.priorityHint:SetText("Set role priorities and Save Rule; Unset keeps a draft.")
    end
end

function UI:CreatePrioritySettingsContent(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    -- BROWSE VIEW. The edit controls are in a different frame and cannot overlap.
    local browse = CreateFrame("Frame", nil, panel)
    browse:SetAllPoints(panel)
    self.priorityBrowsePage = browse
    Font(browse, "GameFontNormal", "Molten Core - Item Priorities", 8, -8, 405)
    Font(browse, "GameFontDisableSmall", "Select an item to review its rules.", 430, -9, 300)
    Font(browse, "GameFontHighlightSmall", "Boss:", 8, -44, 55)
    local bossDrop = CreateFrame("Frame", "NaxxLootLotteryPriorityBossDropDown", browse, "UIDropDownMenuTemplate")
    bossDrop:SetPoint("TOPLEFT", browse, "TOPLEFT", 66, -24)
    UIDropDownMenu_SetWidth(bossDrop, 170)
    self.priorityBossDropDown = bossDrop
    self.priorityBossFilter = self.priorityBossFilter or "All"
    UIDropDownMenu_Initialize(bossDrop, function()
        for _, boss in ipairs(BOSSES) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = boss
            info.checked = UI.priorityBossFilter == boss
            info.func = function() UI:SetPriorityBossFilter(boss) end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(bossDrop, self.priorityBossFilter)
    local search = CreateFrame("EditBox", "NaxxLootLotteryPrioritySearchBox", browse, "InputBoxTemplate")
    search:SetAutoFocus(false); search:SetWidth(192); search:SetHeight(20)
    search:SetPoint("TOPLEFT", browse, "TOPLEFT", 298, -36)
    self.prioritySearchBox = search
    local searchButton = self:CreateTextButton(browse,"Search",72)
    searchButton:SetPoint("LEFT",search,"RIGHT",9,0)
    local clearButton = self:CreateTextButton(browse,"Clear",72)
    clearButton:SetPoint("LEFT",searchButton,"RIGHT",8,0)
    local function DoSearch() UI.priorityPage=1; UI:RefreshPrioritySetup() end
    searchButton:SetScript("OnClick",DoSearch)
    search:SetScript("OnEnterPressed",function(self) self:ClearFocus(); DoSearch() end)
    clearButton:SetScript("OnClick",function() search:SetText(""); DoSearch() end)

    local header = CreateFrame("Frame",nil,browse)
    header:SetPoint("TOPLEFT",browse,"TOPLEFT",4,-76)
    header:SetPoint("TOPRIGHT",browse,"TOPRIGHT",-4,-76)
    header:SetHeight(22)
    self:RegisterSkinnedFrame(header,"header")
    Font(header,"GameFontNormalSmall","ITEM",45,-4,265)
    Font(header,"GameFontNormalSmall","BOSS / SOURCE",315,-4,235)
    Font(header,"GameFontNormalSmall","PRIORITY",558,-4,116)
    self.priorityRows = {}
    for i=1,PAGE_SIZE do
        local row = CreateFrame("Frame",nil,browse)
        row:SetPoint("TOPLEFT",header,"BOTTOMLEFT",0,-((i-1)*54))
        row:SetPoint("TOPRIGHT",header,"BOTTOMRIGHT",0,-((i-1)*54))
        row:SetHeight(52)
        self:RegisterSkinnedFrame(row,(i%2)==0 and "rowAlt" or "row")
        local icon = row:CreateTexture(nil,"ARTWORK")
        icon:SetWidth(34); icon:SetHeight(34)
        icon:SetPoint("LEFT",row,"LEFT",5,0)
        local hit = CreateFrame("Button",nil,row)
        hit:SetAllPoints(icon)
        hit:SetScript("OnEnter",function(self)
            if not self.itemID then return end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:"..self.itemID..":0:0:0:0:0:0:0")
            GameTooltip:Show()
        end)
        hit:SetScript("OnLeave",function() GameTooltip:Hide() end)
        local itemText = Font(row,"GameFontHighlightSmall","",44,-7,264)
        local idText = Font(row,"GameFontDisableSmall","",44,-28,264)
        local source = Font(row,"GameFontHighlightSmall","",315,-9,225)
        source:SetHeight(40)
        local state = Font(row,"GameFontDisableSmall","",558,-12,113)
        local selectBtn=self:CreateTextButton(row,"Edit",66)
        selectBtn:SetPoint("RIGHT",row,"RIGHT",-8,0)
        selectBtn:SetScript("OnClick",function()
            if row.itemID then UI:OpenPriorityEditor(row.itemID) end
        end)
        row.icon=icon; row.iconHit=hit; row.nameText=itemText; row.idText=idText
        row.sourceText=source; row.stateText=state
        self.priorityRows[i]=row
    end
    local previous=self:CreateTextButton(browse,"Previous",86)
    previous:SetPoint("TOPLEFT",browse,"TOPLEFT",8,-320)
    previous:SetScript("OnClick",function()
        UI.priorityPage=math.max(1,(UI.priorityPage or 1)-1); UI:RefreshPrioritySetup()
    end)
    local nextBtn=self:CreateTextButton(browse,"Next",68)
    nextBtn:SetPoint("LEFT",previous,"RIGHT",8,0)
    nextBtn:SetScript("OnClick",function()
        UI.priorityPage=(UI.priorityPage or 1)+1; UI:RefreshPrioritySetup()
    end)
    self.priorityPreviousButton=previous; self.priorityNextButton=nextBtn
    self.priorityPageText=Font(browse,"GameFontHighlightSmall","",185,-323,245)
    local suggestionFilter=self:CreateTextButton(browse,"Suggestions Only",130)
    suggestionFilter:SetPoint("TOPLEFT",browse,"TOPLEFT",438,-316)
    suggestionFilter:SetScript("OnClick",function()
        UI.prioritySuggestionsOnly=not UI.prioritySuggestionsOnly
        UI.priorityPage=1
        UI:RefreshPrioritySetup()
    end)
    self.prioritySuggestionFilterButton=suggestionFilter
    local undo=self:CreateTextButton(browse,"Undo Last Change",145)
    undo:SetPoint("LEFT",suggestionFilter,"RIGHT",7,0)
    undo:SetScript("OnClick",function()
        local ok,message=NLL.PriorityEngine:UndoLastChange()
        NLL:Print(message)
        if ok then UI:RefreshPrioritySetup() end
    end)
    self.priorityUndoButton=undo
    self.priorityBrowseSummary=Font(browse,"GameFontDisableSmall","",8,-361,745)

    -- This is a reversible on/off switch, not a bulk write to SavedVariables.
    local presetToggle=self:CreateTextButton(browse,"Enable Presets",145)
    presetToggle:SetPoint("TOPLEFT",browse,"TOPLEFT",8,-389)
    presetToggle:SetScript("OnClick",function()
        local engine=NLL.PriorityEngine
        local enabled=not engine:PresetsEnabled()
        engine:SetPresetsEnabled(enabled)
        NLL:Print(enabled and "Curated Molten Core presets enabled. Custom rules preserved."
            or "Curated Molten Core presets disabled. Custom rules preserved.")
        UI.priorityPage=1
        UI:RefreshPrioritySetup()
        if UI.RefreshCurrentLootPanel then UI:RefreshCurrentLootPanel() end
    end)
    self.priorityPresetToggleButton=presetToggle
    self.priorityPresetExplanation=Font(browse,"GameFontDisableSmall","",165,-394,580)

    -- EDIT VIEW: no item browser controls exist in this visible frame.
    local editor=CreateFrame("Frame",nil,panel)
    editor:SetAllPoints(panel)
    self.priorityEditPage=editor
    local back=self:CreateTextButton(editor,"Back to Items",120)
    back:SetPoint("TOPLEFT",editor,"TOPLEFT",8,-6)
    back:SetScript("OnClick",function() UI:OpenPriorityBrowse() end)
    Font(editor,"GameFontNormal","Edit Molten Core Priority",150,-9,390)
    self.prioritySuggestButton=self:CreateTextButton(editor,"Load Suggestion",170)
    self.prioritySuggestButton:SetPoint("TOPRIGHT",editor,"TOPRIGHT",-10,-6)
    self.prioritySuggestButton:SetScript("OnClick",function()
        local suggestion=UI.prioritySuggestion
        if not suggestion then return end
        for _,role in ipairs(NLL.roles) do
            UI:SetPriorityRoleSelection(role.id,suggestion.rolePriority[role.id])
        end
        if type(suggestion.classEligibility)=='table' then
            for _,classInfo in ipairs(NLL.classes) do
                UI.priorityClassSelections[classInfo.id]=
                    suggestion.classEligibility[classInfo.id] == true
            end
        end
        UI.prioritySuggestionUnsaved=true
        UI:RefreshPriorityEditor()
        NLL:Print("Suggestion loaded for review only. Press Save Rule to keep it.")
    end)
    self.prioritySelectedName=Font(editor,"GameFontHighlight","",10,-44,745)
    self.prioritySelectedSource=Font(editor,"GameFontDisableSmall","",10,-69,745)
    self.priorityEditorStatus=Font(editor,"GameFontHighlightSmall","",10,-93,745)
    Font(editor,"GameFontNormal","Class Eligibility",10,-125,178)
    self.priorityClassNote=Font(editor,"GameFontDisableSmall","",190,-127,570)
    self.priorityClassCheckButtons={}
    for i, c in ipairs(NLL.classes) do
        local col=(i-1)%5
        local line=math.floor((i-1)/5)
        local x=10+col*151; local y=-148-line*26
        local check=CreateFrame("CheckButton","NaxxLootLotteryPriorityClass_"..i,editor,"UICheckButtonTemplate")
        check:SetPoint("TOPLEFT",editor,"TOPLEFT",x,y)
        check:SetWidth(22);check:SetHeight(22)
        local label=Font(editor,"GameFontHighlightSmall",c.label,x+25,y-5,121)
        check.classFile=c.id
        check:SetScript("OnClick",function(self)
            UI.priorityClassSelections[self.classFile]=self:GetChecked() and true or false
            UI.prioritySuggestionUnsaved=false
            UI:RefreshPriorityEditor()
        end)
        self.priorityClassCheckButtons[c.id]=check
    end
    Font(editor,"GameFontNormal","Role Priority",10,-207,190)
    Font(editor,"GameFontDisableSmall","Tier 1 first; ties get equal tickets. Unset = Draft.",208,-209,540)
    self.priorityRoleDropDowns={}
    for i, role in ipairs(NLL.roles) do
        local col=(i-1)%2
        local line=math.floor((i-1)/2)
        local x=12+col*386
        local y=-235-line*37
        Font(editor,"GameFontHighlightSmall",role.label,x,y,177)
        local dropdown=CreateFrame("Frame","NaxxLootLotteryPriorityRole_"..i,editor,"UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT",editor,"TOPLEFT",x+165,y+10)
        UIDropDownMenu_SetWidth(dropdown,130)
        dropdown.roleID=role.id
        UIDropDownMenu_Initialize(dropdown,function()
            local id=dropdown.roleID
            local current=UI.priorityRoleSelections and UI.priorityRoleSelections[id]
            local options={{"Unset",nil},{"Tier 1",1},{"Tier 2",2},{"Tier 3",3},
                {"Not eligible",NLL.PriorityEngine.EXCLUDE}}
            for j=1,#options do
                local value=options[j][2]
                local info=UIDropDownMenu_CreateInfo()
                info.text=options[j][1]
                info.checked=current==value
                info.func=function()
                    UI:SetPriorityRoleSelection(id,value)
                    UI.prioritySuggestionUnsaved=false
                    UI:RefreshPriorityEditor()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetText(dropdown,"Unset")
        self.priorityRoleDropDowns[role.id]=dropdown
    end
    local equal=self:CreateTextButton(editor,"All Equal",98)
    equal:SetPoint("TOPLEFT",editor,"TOPLEFT",8,-348)
    equal:SetScript("OnClick",function()
        for _,role in ipairs(NLL.roles) do UI:SetPriorityRoleSelection(role.id,1) end
        UI.prioritySuggestionUnsaved=false; UI:RefreshPriorityEditor()
    end)
    local reset=self:CreateTextButton(editor,"Reset Editor",115)
    reset:SetPoint("LEFT",equal,"RIGHT",10,0)
    reset:SetScript("OnClick",function()
        for _,role in ipairs(NLL.roles) do UI:SetPriorityRoleSelection(role.id,nil) end
        local defaults=NLL.PriorityEngine:GetDefaultClassEligibility(RAID,UI.prioritySelectedItemID)
        for _,c in ipairs(NLL.classes) do
            UI.priorityClassSelections[c.id]=defaults[c.id]==true
        end
        UI.prioritySuggestionUnsaved=false; UI:RefreshPriorityEditor()
    end)
    local nextSuggestion=self:CreateTextButton(editor,"Save & Next",135)
    nextSuggestion:SetPoint("TOPLEFT",editor,"TOPLEFT",260,-348)
    nextSuggestion:SetScript("OnClick",function()
        local itemID=UI.prioritySelectedItemID
        -- Remember next before saving so 'Suggestions Only' filtering
        -- does not remove the current item mid-navigation.
        local nextID=UI:GetNextSuggestedItemID(itemID)
        if not UI:SavePriorityEditor() then return end
        UI:RefreshPrioritySetup()
        if nextID then UI:OpenPriorityEditor(nextID)
        else UI:OpenPriorityBrowse(); NLL:Print("No more suggested rules in this filter.") end
    end)
    self.prioritySaveNextButton=nextSuggestion
    local save=self:CreateTextButton(editor,"Save Rule",105)
    save:SetPoint("TOPRIGHT",editor,"TOPRIGHT",-130,-348)
    save:SetScript("OnClick",function()
        UI:SavePriorityEditor()
    end)
    local delete=self:CreateTextButton(editor,"Delete Rule",114)
    delete:SetPoint("LEFT",save,"RIGHT",9,0)
    delete:SetScript("OnClick",function()
        if NLL.PriorityEngine:DeleteRule(RAID,UI.prioritySelectedItemID) then
            NLL:Print("Custom rule deleted. Built-in preset will apply if enabled.")
            UI:OpenPriorityEditor(UI.prioritySelectedItemID)
        end
    end)
    self.priorityEqualButton=equal; self.priorityResetButton=reset
    self.prioritySaveButton=save; self.priorityDeleteButton=delete
    self.priorityHint=Font(editor,"GameFontDisableSmall","",12,-377,730)

    self.prioritySettingsContent=panel
    self.priorityPage=1
    self.priorityRoleSelections={};self.priorityClassSelections={}
    editor:Hide()
    self.priorityEditorVisible=false
    self:RefreshPrioritySetup()
    return panel
end
