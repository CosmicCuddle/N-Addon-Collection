-- v0.1.0.25 - explicit opt-in for dangerous real Master Loot transfers.
local NLL = NaxxLootLottery
local UI = NLL.UI
function UI:CreateAwardSettingsContent(parent)
    local page = CreateFrame('Frame', nil, parent)
    page:SetAllPoints(parent)
    local heading = page:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    heading:SetPoint('TOPLEFT',page,'TOPLEFT',14,-14)
    heading:SetText('Live Loot Awards')
    local detail = page:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    detail:SetPoint('TOPLEFT',heading,'BOTTOMLEFT',0,-22)
    detail:SetWidth(680)
    detail:SetJustifyH('LEFT')
    detail:SetText('Your lottery can keep reporting awards manually. You may also opt in to sending a real Master Loot request from NLL.')
    local warning = page:CreateFontString(nil,'OVERLAY','GameFontNormal')
    warning:SetPoint('TOPLEFT',detail,'BOTTOMLEFT',0,-32)
    warning:SetWidth(680)
    warning:SetJustifyH('LEFT')
    warning:SetText('|cffff9955IMPORTANT: A Master Loot request can transfer real items and cannot be undone by NLL.|r')
    local procedure = page:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    procedure:SetPoint('TOPLEFT',warning,'BOTTOMLEFT',0,-26)
    procedure:SetWidth(670)
    procedure:SetJustifyH('LEFT')
    procedure:SetText('Direct mode requires a verified winner and open Blizzard loot slot. It also requires two deliberate clicks (Arm and Confirm) and resets OFF every login or /reload.')
    local status = page:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    status:SetPoint('TOPLEFT',procedure,'BOTTOMLEFT',0,-32)
    status:SetWidth(650)
    status:SetJustifyH('LEFT')
    local toggle = UI:CreateTextButton(page,'Enable Direct Awards',210)
    toggle:SetPoint('TOPLEFT',status,'BOTTOMLEFT',0,-18)
    toggle:SetScript('OnClick',function()
        local enable = not NLL.AwardWorkflow:IsDirectEnabled()
        local changed = NLL.AwardWorkflow:SetDirectEnabled(enable)
        if changed then
            NLL:Print(enable and 'Direct Master Loot ENABLED: always confirm recipient and item.' or
                'Direct Master Loot DISABLED. Manual award reporting is available.')
        else
            NLL:Print('Stop the fake raid before changing live-award settings.')
        end
        UI:RefreshAwardSettingsContent()
    end)
    local foot = page:CreateFontString(nil,'OVERLAY','GameFontDisableSmall')
    foot:SetPoint('TOPLEFT',toggle,'BOTTOMLEFT',0,-26)
    foot:SetWidth(670)
    foot:SetJustifyH('LEFT')
    foot:SetText('NLL never auto-awards after a roll. A successful GiveMasterLoot call is only a request, not proof the winner received it. Fake raids never make this call.')
    self.awardSettingsPage = page
    self.awardSettingsStatus = status
    self.awardSettingsToggle = toggle
end
function UI:RefreshAwardSettingsContent()
    if not self.awardSettingsPage then return end
    local enabled = NLL.AwardWorkflow:IsDirectEnabled()
    self.awardSettingsStatus:SetText(enabled and
        '|cffffaa55Direct Master Loot: ENABLED (use carefully)|r' or
        '|cff66ff99Direct Master Loot: OFF (recommended until live testing)|r')
    self.awardSettingsToggle.label:SetText(enabled and
        'Disable Direct Awards' or 'Enable Direct Awards')
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        self.awardSettingsToggle:Disable()
    else
        self.awardSettingsToggle:Enable()
    end
end
