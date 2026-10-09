-- Naxxramas Loot Ledger v0.1.0.25
-- The real transfer button is opt-in and requires review, arm and confirm.
local NLL = NaxxLootLottery
local UI = NLL.UI

function UI:CreateAwardReview()
    if self.awardReviewFrame then return end
    local frame = CreateFrame('Frame',nil,self.mainFrame)
    frame:SetSize(635,278)
    frame:SetPoint('CENTER',self.mainFrame,'CENTER',0,0)
    frame:SetFrameStrata('DIALOG')
    frame:SetFrameLevel((self.mainFrame:GetFrameLevel() or 0)+30)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile='Interface\\Buttons\\WHITE8X8',
        edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
        tile=true,tileSize=16,edgeSize=26,
        insets={left=8,right=8,top=8,bottom=8}
    })
    frame:SetBackdropColor(.055,.065,.085,.99)
    frame:SetBackdropBorderColor(.96,.72,.25,1)

    local title=frame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    title:SetPoint('TOP',frame,'TOP',0,-25)
    title:SetText('AWARD REVIEW')
    local subject=frame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    subject:SetPoint('TOP',title,'BOTTOM',0,-19)
    subject:SetWidth(570)
    subject:SetJustifyH('CENTER')
    local status=frame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    status:SetPoint('TOP',subject,'BOTTOM',0,-18)
    status:SetWidth(555)
    status:SetJustifyH('CENTER')
    local warning=frame:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
    warning:SetPoint('BOTTOM',frame,'BOTTOM',0,84)
    warning:SetWidth(550)
    warning:SetJustifyH('CENTER')

    -- The original manual confirmation remains available.
    local manual=self:CreateTextButton(frame,'I Awarded It in WoW',173)
    manual:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',22,25)
    manual:SetScript('OnClick',function()
        local ok,msg=NLL.AwardWorkflow:Confirm()
        NLL:Print(msg)
        if ok then frame:Hide() end
        if UI.RefreshCurrentLootPanel then UI:RefreshCurrentLootPanel() end
        if UI.RefreshOverview then UI:RefreshOverview() end
    end)

    -- The first click ARMS; the second click immediately re-verifies live
    -- Master Loot state and sends the real request. Never used by simulation.
    local direct=self:CreateTextButton(frame,'Arm Direct Award',192)
    direct:SetPoint('LEFT',manual,'RIGHT',12,0)
    direct:SetScript('OnClick',function()
        local entry=NLL.AwardWorkflow:GetReviewedDrop()
        local verified=NLL.AwardWorkflow.verification
        local ok,msg
        if verified and verified.armedAt then
            ok,msg=NLL.AwardWorkflow:CommitDirectAward(entry)
        else
            ok,msg=NLL.AwardWorkflow:ArmDirectAward(entry)
        end
        NLL:Print(msg)
        if ok and NLL.AwardWorkflow.verification and
           NLL.AwardWorkflow.verification.armedAt then
            direct.label:SetText('CONFIRM GIVE ITEM')
            status:SetText('|cffffaa55'..msg..'|r')
        elseif ok then
            frame:Hide()
        else
            direct.label:SetText('Arm Direct Award')
            status:SetText('|cffff7777'..tostring(msg)..'|r')
        end
        if UI.RefreshCurrentLootPanel then UI:RefreshCurrentLootPanel() end
        if UI.RefreshOverview then UI:RefreshOverview() end
    end)

    local close=self:CreateTextButton(frame,'Back / Cancel',133)
    close:SetPoint('LEFT',direct,'RIGHT',12,0)
    close:SetScript('OnClick',function()
        frame:Hide()
        NLL.AwardWorkflow:Cancel()
    end)

    self.awardReviewFrame=frame
    self.awardReviewSubject=subject
    self.awardReviewStatus=status
    self.awardReviewWarning=warning
    self.awardReviewConfirm=manual
    self.awardReviewDirect=direct
    self.awardReviewCancel=close
    frame:Hide()
end

function UI:OpenAwardReview()
    self:CreateAwardReview()
    local loot=NLL.LootDetection:GetCurrentLoot() or {}
    local entry=loot[self.currentLootSelected or 1]
    local ok,msg=NLL.AwardWorkflow:Review(entry)
    if not ok then NLL:Print(msg); return false end
    local result=NLL.AwardWorkflow:GetOutcome(entry)
    self.awardReviewSubject:SetText(tostring(entry.itemName)..'  ->  '..tostring(result.winner))
    self.awardReviewStatus:SetText(msg)
    self.awardReviewDirect.label:SetText('Arm Direct Award')
    if entry.simulationOnly then
        self.awardReviewConfirm.label:SetText('Confirm Fake Award')
        self.awardReviewWarning:SetText('|cffffbb66SIMULATION ONLY: no server roll or real award.|r')
        self.awardReviewDirect:Hide()
    else
        self.awardReviewConfirm.label:SetText('I Awarded It in WoW')
        self.awardReviewDirect:Show()
        if NLL.AwardWorkflow:IsDirectEnabled() then
            self.awardReviewDirect:Enable()
            self.awardReviewWarning:SetText('|cffff9955Real item transfer possible. Arm and then CONFIRM GIVE ITEM deliberately.|r')
        else
            self.awardReviewDirect:Disable()
            self.awardReviewWarning:SetText('Direct Awards OFF in Settings > Loot Awards. Manual award reports remain available.')
        end
    end
    self.awardReviewFrame:Show()
    return true
end
