-- Naxxramas Loot Ledger v0.1.0.18 - separate candidate review page.
-- Editing only after observed loot; no automatic award, no roll here.
local NLL=NaxxLootLottery
local UI=NLL.UI
local REVIEW_ROWS=6
local function Font(parent,template,text,x,y,width)
    local f=parent:CreateFontString(nil,'OVERLAY',template)
    f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
    f:SetWidth(width)
    f:SetJustifyH('LEFT')
    f:SetText(text or '')
    return f
end
local function CurrentEntry()
    local uid=UI.candidateReviewDropUID
    for _,entry in ipairs(NLL.LootDetection:GetCurrentLoot() or {}) do
        if entry.dropUID==uid then return entry end
    end
    return nil
end
function UI:OpenCandidateReview()
    local entry=NLL.TicketLottery:GetSelectedEntry()
    if not entry or not entry.dropUID or entry.state~='DETECTED' then
        NLL:Print('Review requires a detected loot item.')
        return
    end
    self.candidateReviewDropUID=entry.dropUID
    self.candidateReviewPage=1
    self.candidateReviewPanel:Show()
    self:RefreshCandidateReview()
end
function UI:RefreshCandidateReview()
    if not self.candidateReviewPanel or not self.candidateReviewPanel:IsShown() then return end
    local entry=CurrentEntry()
    if not entry then self.candidateReviewPanel:Hide() return end
    local review=NLL.CandidateReview
    self.candidateReviewTitle:SetText('Review Candidates - '..tostring(entry.itemName))
    local raw=NLL.NeedMatcher:GetMatchesForItem(entry.itemID)
    local merged=review:MergeMatches(entry,raw)
    self.candidateReviewMatches=merged
    local canEdit,why=review:CanChange(entry)
    self.candidateReviewInfo:SetText(
        'Drop-scoped changes only. Character must be in the raid; class and role rules still apply.\n' ..
        (canEdit and 'Leader controls enabled. Changes are recorded.' or tostring(why)))
    if canEdit then self.candidateReviewAddButton:Enable()
    else self.candidateReviewAddButton:Disable() end
    local pages=math.max(1,math.ceil(#merged/REVIEW_ROWS))
    self.candidateReviewPage=math.min(pages,math.max(1,self.candidateReviewPage or 1))
    for index=1,REVIEW_ROWS do
        local row=self.candidateReviewRows[index]
        local m=merged[(self.candidateReviewPage-1)*REVIEW_ROWS+index]
        if m then
            row.character=m.character
            local excluded=review:IsExcluded(entry,m.character)
            local manual=review:IsManual(entry,m.character)
            row.name:SetText(m.character or 'Unknown')
            row.details:SetText(
                (function()
                    local text=tostring(m.classLabel or NLL:GetClassLabel(m.classFile)) ..
                        ' / '..tostring(m.roleLabel or NLL:GetRoleLabel(m.role))
                    if #text>29 then return string.sub(text,1,26)..'...' end
                    return text
                end)())
            row.state:SetText(excluded and ('Excluded: '..excluded) or
                (manual and 'Manually added' or (m.inRaid and m.online and 'In raid' or 'Not present')))
            row.action.label:SetText(excluded and 'Restore' or 'Exclude')
            row.remove:Hide()
            if manual then row.remove:Show() end
            if canEdit then row.action:Enable();row.remove:Enable()
            else row.action:Disable();row.remove:Disable() end
            -- Regenerate Vanilla width from changed label.
            UI:ApplySkinToFrame(row.action)
            row:Show()
        else row.character=nil;row:Hide() end
    end
    self.candidateReviewPageText:SetText(
        'Page '..tostring(self.candidateReviewPage)..'/'..tostring(pages)..
        ' ('..tostring(#merged)..' characters)')
    if self.candidateReviewPage==1 then self.candidateReviewPrev:Disable()
    else self.candidateReviewPrev:Enable() end
    if self.candidateReviewPage==pages then self.candidateReviewNext:Disable()
    else self.candidateReviewNext:Enable() end
end
function UI:CreateCandidateReviewPanel(parent)
    local panel=CreateFrame('Frame',nil,parent)
    panel:SetPoint('TOPLEFT',parent,'TOPLEFT',4,-30)
    panel:SetPoint('BOTTOMRIGHT',parent,'BOTTOMRIGHT',-4,4)
    panel:SetFrameLevel((parent:GetFrameLevel() or 1)+10)
    panel:EnableMouse(true)
    self:RegisterSkinnedFrame(panel,'main')
    self.candidateReviewPanel=panel
    self.candidateReviewTitle=Font(panel,'GameFontNormalLarge','Review Candidates',15,-12,550)
    local close=self:CreateTextButton(panel,'Back to Loot',118)
    close:SetPoint('TOPRIGHT',panel,'TOPRIGHT',-12,-10)
    close:SetScript('OnClick',function()panel:Hide() end)
    self.candidateReviewInfo=Font(panel,'GameFontHighlightSmall','',16,-43,730)
    local nameBox=CreateFrame('EditBox','NaxxLootLotteryManualCandidateName',panel,'InputBoxTemplate')
    nameBox:SetAutoFocus(false);nameBox:SetWidth(175);nameBox:SetHeight(22)
    nameBox:SetPoint('TOPLEFT',panel,'TOPLEFT',22,-88)
    self.candidateReviewNameBox=nameBox
    Font(panel,'GameFontNormalSmall','Add online raid character:',215,-91,175)
    local add=self:CreateTextButton(panel,'Add Candidate',128)
    add:SetPoint('TOPLEFT',panel,'TOPLEFT',405,-88)
    add:SetScript('OnClick',function()
        local entry=CurrentEntry()
        local ok,msg=NLL.CandidateReview:AddCandidate(entry,nameBox:GetText())
        NLL:Print(msg)
        if ok then nameBox:SetText('');nameBox:ClearFocus() end
        UI:RefreshCandidateReview()
    end)
    self.candidateReviewAddButton=add
    Font(panel,'GameFontNormalSmall','Exclusion reason:',20,-122,120)
    local reasonBox=CreateFrame('EditBox','NaxxLootLotteryCandidateReason',panel,'InputBoxTemplate')
    reasonBox:SetAutoFocus(false);reasonBox:SetWidth(270);reasonBox:SetHeight(22)
    reasonBox:SetPoint('TOPLEFT',panel,'TOPLEFT',145,-119)
    reasonBox:SetText('Player passed on this item')
    self.candidateReviewReasonBox=reasonBox
    Font(panel,'GameFontDisableSmall','Reason is saved in the candidate audit log.',430,-122,310)
    local header=CreateFrame('Frame',nil,panel)
    header:SetPoint('TOPLEFT',panel,'TOPLEFT',15,-151)
    header:SetPoint('TOPRIGHT',panel,'TOPRIGHT',-15,-151)
    header:SetHeight(22)
    self:RegisterSkinnedFrame(header,'header')
    Font(header,'GameFontNormalSmall','Character',10,-4,132)
    Font(header,'GameFontNormalSmall','Class / Role',148,-4,230)
    Font(header,'GameFontNormalSmall','Status',392,-4,184)
    self.candidateReviewRows={}
    for i=1,REVIEW_ROWS do
        local row=CreateFrame('Frame',nil,panel)
        row:SetPoint('TOPLEFT',header,'BOTTOMLEFT',0,-((i-1)*33))
        row:SetPoint('TOPRIGHT',header,'BOTTOMRIGHT',0,-((i-1)*33))
        row:SetHeight(31)
        self:RegisterSkinnedFrame(row,(i%2==0) and 'rowAlt' or 'row')
        row.name=Font(row,'GameFontHighlightSmall','',9,-8,135)
        row.details=Font(row,'GameFontHighlightSmall','',148,-8,236)
        row.state=Font(row,'GameFontHighlightSmall','',392,-8,181)
        local action=self:CreateTextButton(row,'Exclude',76)
        action:SetPoint('RIGHT',row,'RIGHT',-80,0)
        action:SetScript('OnClick',function()
            local entry=CurrentEntry()
            if not entry or not row.character then return end
            local review=NLL.CandidateReview
            local ok,msg
            if review:IsExcluded(entry,row.character) then
                ok,msg=review:Restore(entry,row.character)
            else
                ok,msg=review:Exclude(entry,row.character,reasonBox:GetText())
            end
            NLL:Print(msg)
            if ok then UI:RefreshCandidateReview() end
        end)
        row.action=action
        local remove=self:CreateTextButton(row,'Remove',68)
        remove:SetPoint('RIGHT',row,'RIGHT',-5,0)
        remove:SetScript('OnClick',function()
            local entry=CurrentEntry()
            if not entry or not row.character then return end
            local ok,msg=NLL.CandidateReview:RemoveManual(entry,row.character)
            NLL:Print(msg)
            if ok then UI:RefreshCandidateReview() end
        end)
        row.remove=remove
        self.candidateReviewRows[i]=row
    end
    local prev=self:CreateTextButton(panel,'Previous',95)
    prev:SetPoint('BOTTOMLEFT',panel,'BOTTOMLEFT',16,12)
    prev:SetScript('OnClick',function()
        UI.candidateReviewPage=math.max(1,UI.candidateReviewPage-1)
        UI:RefreshCandidateReview()
    end)
    local nextButton=self:CreateTextButton(panel,'Next',85)
    nextButton:SetPoint('LEFT',prev,'RIGHT',8,0)
    nextButton:SetScript('OnClick',function()
        UI.candidateReviewPage=(UI.candidateReviewPage or 1)+1
        UI:RefreshCandidateReview()
    end)
    self.candidateReviewPrev=prev;self.candidateReviewNext=nextButton
    self.candidateReviewPageText=panel:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    self.candidateReviewPageText:SetPoint('LEFT',nextButton,'RIGHT',12,0)
    self.candidateReviewPageText:SetWidth(260)
    panel:Hide()
end
