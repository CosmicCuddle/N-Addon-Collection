-- Naxxramas Loot Ledger v0.1.0.25 - readable, audited real award events.
-- Simulation never writes this table.
local NLL = NaxxLootLottery
local UI = NLL.UI
local PAGE_ROWS = 6
local function Label(row)
    local s = row.status or 'UNKNOWN'
    if s == 'LOOT_SLOT_CLEARED' then return 'Slot cleared' end
    if s == 'LEADER_REPORTED' then return 'Leader reported' end
    if s == 'AWARD_REQUESTED' then return 'Request sent' end
    if s == 'AWARD_OUTCOME_UNKNOWN' then return 'Outcome unknown' end
    return s
end
function UI:CreateAwardHistoryContent(parent)
    local panel=CreateFrame('Frame',nil,parent)
    panel:SetAllPoints(parent)
    local heading=panel:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    heading:SetPoint('TOPLEFT',panel,'TOPLEFT',8,-9)
    heading:SetText('Real Loot Award History')
    local caution=panel:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    caution:SetPoint('TOPLEFT',heading,'BOTTOMLEFT',0,-12)
    caution:SetWidth(680)
    caution:SetJustifyH('LEFT')
    caution:SetText('A cleared loot slot is NOT proof the winning character received the item. Simulated awards never appear here.')
    local header=CreateFrame('Frame',nil,panel)
    header:SetPoint('TOPLEFT',panel,'TOPLEFT',4,-68)
    header:SetPoint('TOPRIGHT',panel,'TOPRIGHT',-4,-68)
    header:SetHeight(24)
    self:RegisterSkinnedFrame(header,'header')
    local function Caption(text,offset,width)
        local f=header:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
        f:SetPoint('LEFT',header,'LEFT',offset,0)
        f:SetWidth(width)
        f:SetJustifyH('LEFT')
        f:SetText(text)
    end
    Caption('Item / ID',12,206)
    Caption('Winner',220,116)
    Caption('State',345,156)
    Caption('Time',508,170)
    self.awardHistoryRows={}
    for i=1,PAGE_ROWS do
        local line=CreateFrame('Frame',nil,panel)
        line:SetPoint('TOPLEFT',header,'BOTTOMLEFT',0,-(i-1)*34)
        line:SetPoint('TOPRIGHT',header,'BOTTOMRIGHT',0,-(i-1)*34)
        line:SetHeight(32)
        self:RegisterSkinnedFrame(line,i%2==0 and 'rowAlt' or 'row')
        local function Field(x,width)
            local f=line:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
            f:SetPoint('LEFT',line,'LEFT',x,0)
            f:SetWidth(width)
            f:SetJustifyH('LEFT')
            return f
        end
        local item=Field(12,200)
        local winner=Field(220,116)
        local state=Field(345,156)
        local when=Field(508,150)
        local details=self:CreateTextButton(line,'Info',53)
        details:SetPoint('RIGHT',line,'RIGHT',-5,0)
        details:SetScript('OnClick',function()
            if line.record then
                UI.awardHistoryDetail:SetText(
                    tostring(line.record.itemName)..' -> '..tostring(line.record.winner)..
                    ' | '..Label(line.record)..' | '..tostring(line.record.note or 'No note'))
            end
        end)
        self.awardHistoryRows[i]={panel=line,item=item,winner=winner,state=state,
            when=when,details=details}
    end
    local prev=self:CreateTextButton(panel,'Previous',90)
    prev:SetPoint('TOPLEFT',header,'BOTTOMLEFT',5,-218)
    prev:SetScript('OnClick',function()
        UI.awardHistoryPage=math.max(1,(UI.awardHistoryPage or 1)-1)
        UI:RefreshAwardHistory()
    end)
    local nextButton=self:CreateTextButton(panel,'Next',70)
    nextButton:SetPoint('LEFT',prev,'RIGHT',8,0)
    nextButton:SetScript('OnClick',function()
        UI.awardHistoryPage=(UI.awardHistoryPage or 1)+1
        UI:RefreshAwardHistory()
    end)
    local pages=panel:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    pages:SetPoint('LEFT',nextButton,'RIGHT',15,0)
    self.awardHistoryPrevious=prev
    self.awardHistoryNext=nextButton
    self.awardHistoryPageLabel=pages
    local detail=panel:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    detail:SetPoint('TOPLEFT',prev,'BOTTOMLEFT',0,-18)
    detail:SetWidth(680)
    detail:SetJustifyH('LEFT')
    detail:SetText('Select Info for details. No award receipt is independently verified.')
    self.awardHistoryDetail=detail
    self.awardHistoryPage=1
    self.awardHistoryContent=panel
    self:RefreshAwardHistory()
end
function UI:RefreshAwardHistory()
    if not self.awardHistoryContent then return end
    local rows=(NLL.db and NLL.db.lootAwardHistory) or {}
    local totalPages=math.max(1,math.ceil(#rows/PAGE_ROWS))
    local page=math.min(math.max(1,self.awardHistoryPage or 1),totalPages)
    self.awardHistoryPage=page
    for i=1,PAGE_ROWS do
        local row=self.awardHistoryRows[i]
        local index=#rows-((page-1)*PAGE_ROWS+i-1)
        local data=rows[index]
        if data then
            row.panel.record=data
            row.item:SetText(tostring(data.itemName)..' ('..tostring(data.itemID)..')')
            row.winner:SetText(tostring(data.winner or 'Unknown'))
            row.state:SetText(Label(data))
            row.when:SetText(tostring(data.when or 'Unknown'))
            row.panel:Show()
        else
            row.panel.record=nil
            row.panel:Hide()
        end
    end
    self.awardHistoryPageLabel:SetText('Page '..page..' / '..totalPages..'  ('..#rows..' records)')
    if page<=1 then self.awardHistoryPrevious:Disable() else self.awardHistoryPrevious:Enable() end
    if page>=totalPages then self.awardHistoryNext:Disable() else self.awardHistoryNext:Enable() end
end
