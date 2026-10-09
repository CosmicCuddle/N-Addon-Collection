-- NLL 0.1.0.21: A visual result popup, not an award window.
-- No code in this file changes SavedVariables or gives loot.
local NLL = NaxxLootLottery
local UI = NLL.UI

function UI:CreateWinnerAnnouncement()
    if self.winnerAnnouncement then return end
    if not self.mainFrame then return end

    local frame = CreateFrame("Frame", nil, self.mainFrame)
    frame:SetWidth(490)
    frame:SetHeight(218)
    frame:SetPoint("CENTER", self.mainFrame, "CENTER", 0, 3)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel((self.mainFrame:GetFrameLevel() or 0) + 25)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 26,
        insets = { left=8, right=8, top=8, bottom=8 }
    })
    frame:SetBackdropColor(0.055, 0.065, 0.085, 0.98)
    frame:SetBackdropBorderColor(0.96, 0.72, 0.25, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -23)
    title:SetWidth(440)
    title:SetJustifyH("CENTER")
    title:SetText("LOTTERY WINNER")

    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("TOP", title, "BOTTOM", 0, -22)
    name:SetWidth(440)
    name:SetJustifyH("CENTER")

    local item = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    item:SetPoint("TOP", name, "BOTTOM", 0, -12)
    item:SetWidth(440)
    item:SetJustifyH("CENTER")

    local ticket = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ticket:SetPoint("TOP", item, "BOTTOM", 0, -9)
    ticket:SetWidth(440)
    ticket:SetJustifyH("CENTER")

    local disclaimer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    disclaimer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 45)
    disclaimer:SetWidth(440)
    disclaimer:SetJustifyH("CENTER")

    local close = self:CreateTextButton(frame, "Close Result", 130)
    close:SetPoint("BOTTOM", frame, "BOTTOM", 85, 15)
    local award = self:CreateTextButton(frame, "Review Award", 132)
    award:SetPoint("BOTTOM",frame,"BOTTOM",-85,15)
    award:SetScript("OnClick",function()
        frame:Hide()
        UI:ShowMainFrame("currentloot")
        UI:OpenAwardReview()
    end)
    close:SetScript("OnClick", function() frame:Hide() end)

    self.winnerReviewAwardButton = award
    self.winnerAnnouncement = frame
    self.winnerAnnouncementTitle = title
    self.winnerAnnouncementName = name
    self.winnerAnnouncementItem = item
    self.winnerAnnouncementTicket = ticket
    self.winnerAnnouncementDisclaimer = disclaimer
    frame:Hide()
end

function UI:HideWinnerAnnouncement()
    if self.winnerAnnouncement then self.winnerAnnouncement:Hide() end
end

function UI:ShowWinnerAnnouncement(itemName, winner, ticketNumber, simulated)
    if not itemName or not winner or not ticketNumber then return false end
    if not self.mainFrame then return false end
    self:CreateWinnerAnnouncement()
    -- Keep the result visible even if the addon was hidden during /roll.
    if not self.mainFrame:IsShown() then
        self:ShowMainFrame("currentloot")
    end
    local label = simulated and "SIMULATION WINNER" or "LOTTERY WINNER"
    self.winnerAnnouncementTitle:SetText("|cffffd568" .. label .. "|r")
    self.winnerAnnouncementName:SetText("|cff66ff99" .. tostring(winner) .. "|r")
    self.winnerAnnouncementItem:SetText(tostring(itemName))
    self.winnerAnnouncementTicket:SetText("Winning ticket #" .. tostring(ticketNumber))
    self.winnerAnnouncementDisclaimer:SetText(simulated and
        "|cffffbb66FAKE RAID - no real equipment awarded|r" or
        "|cffffbb66RESULT ONLY - award the item manually|r")
    self.winnerAnnouncement:Show()
    return true
end
