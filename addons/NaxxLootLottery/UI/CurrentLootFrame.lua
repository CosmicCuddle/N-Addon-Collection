-- ============================================================
-- Naxxramas Loot Ledger
-- UI/CurrentLootFrame.lua
--
-- Phase 6/7 display:
-- detected supported loot + matching NEEDED characters.
-- ============================================================

local NLL = NaxxLootLottery
local UI = NLL.UI

local DROP_ROWS = 5
local MATCH_ROWS = 6

local function GetItemTexture(itemID)
    if GetItemIcon then
        local texture =
            GetItemIcon(itemID)

        if texture then
            return texture
        end
    end

    if GetItemInfo then
        local _, _, _, _, _, _, _, _, _, texture =
            GetItemInfo(itemID)

        if texture then
            return texture
        end
    end

    return
        "Interface\\Icons\\INV_Misc_QuestionMark"
end

function UI:CreateCurrentLootPanel(parent)
    local panel =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    panel:SetAllPoints(parent)

    local heading =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormal"
        )

    heading:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        10,
        -8
    )

    heading:SetText("Current Loot")

    local status =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    status:SetPoint(
        "LEFT",
        heading,
        "RIGHT",
        16,
        0
    )

    status:SetWidth(445)
    status:SetJustifyH("LEFT")

    local clear =
        self:CreateTextButton(
            panel,
            "Clear",
            70
        )

    clear:SetPoint(
        "TOPRIGHT",
        panel,
        "TOPRIGHT",
        -8,
        -4
    )

    clear:SetScript(
        "OnClick",
        function()
            if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
                NLL.DebugSimulator:Cancel()
            else
                NLL.LootDetection:ClearCurrentLoot()
            end
            UI.currentLootSelected = 1
            UI:RefreshCurrentLootPanel()
        end
    )

    local previewButton = self:CreateTextButton(panel, "Preview Pool", 116)
    previewButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -92, -4)
    previewButton:SetScript("OnClick", function()
        local preview = NLL.TicketPlanner:PreviewSelectedLoot()
        UI.currentLootPreviewStatus:SetText(preview.message)
        NLL:Print(preview.message)
        if preview.ready then
            for i = 1, #preview.current do
                NLL:Print("Pool " .. i .. ": " .. preview.current[i].character)
            end
        end
    end)
    self.currentLootPreviewButton = previewButton

    -- Manual ticket controls below the detected-item rows. No award button.
    local prepare = self:CreateTextButton(panel, 'Prepare Tickets', 143)
    prepare:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', 8, 36)
    prepare:SetScript('OnClick',function()
        local entry=NLL.TicketLottery:GetSelectedEntry()
        local ok,notice
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            ok,notice=NLL.DebugSimulator:Prepare()
        else
            ok,notice=NLL.TicketLottery:Prepare(entry)
        end
        NLL:Print(notice)
        UI:RefreshCurrentLootPanel()
    end)
    local draw=self:CreateTextButton(panel,'Start Roll',130)
    draw:SetPoint('LEFT',prepare,'RIGHT',8,0)
    draw:SetScript('OnClick',function()
        local ok,notice
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            ok,notice=NLL.DebugSimulator:Roll()
            NLL:Print(notice)
        else
            ok,notice=NLL.TicketLottery:StartRoll()
        end
        if not ok then NLL:Print(notice) end
        UI:RefreshCurrentLootPanel()
    end)
    local cancel=self:CreateTextButton(panel,'Cancel Tickets',132)
    cancel:SetPoint('BOTTOMLEFT',panel,'BOTTOMLEFT',8,8)
    cancel:SetScript('OnClick',function()
        local ok,notice
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            ok,notice=NLL.DebugSimulator:Cancel()
        else
            ok,notice=NLL.TicketLottery:Cancel('User cancelled')
        end
        NLL:Print(notice)
        UI:RefreshCurrentLootPanel()
    end)
    local reviewButton=self:CreateTextButton(panel,'Review Pool',128)
    reviewButton:SetPoint('LEFT',cancel,'RIGHT',8,0)
    reviewButton:SetScript('OnClick',function()
        local entry=NLL.LootDetection:GetCurrentLoot()[UI.currentLootSelected or 1]
        if entry and NLL.AwardWorkflow:GetOutcome(entry) then
            UI:OpenAwardReview()
        elseif NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            UI.settingsMode='debug';UI:ShowPanel('settings')
        else
            UI:OpenCandidateReview()
        end
    end)
    self.currentLootReviewButton=reviewButton
    local lotteryNote=panel:CreateFontString(nil,'OVERLAY','GameFontNormal')
    lotteryNote:SetPoint('BOTTOMLEFT',panel,'BOTTOMLEFT',8,64)
    lotteryNote:SetWidth(310)
    lotteryNote:SetJustifyH('LEFT')
    lotteryNote:SetText('No tickets prepared.')
    self.currentLootPrepareButton=prepare
    self.currentLootRollButton=draw
    self.currentLootCancelButton=cancel
    self.currentLootLotteryNote=lotteryNote

    local dropsHeader =
        CreateFrame(
            "Frame",
            nil,
            panel
        )

    dropsHeader:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        8,
        -40
    )

    dropsHeader:SetWidth(326)
    dropsHeader:SetHeight(22)

    self:RegisterSkinnedFrame(
        dropsHeader,
        "header"
    )

    local dropsHeaderText =
        dropsHeader:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )

    dropsHeaderText:SetPoint(
        "LEFT",
        dropsHeader,
        "LEFT",
        8,
        0
    )

    dropsHeaderText:SetText("Detected Loot")

    local matchHeader =
        CreateFrame(
            "Frame",
            nil,
            panel
        )

    matchHeader:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        342,
        -40
    )

    matchHeader:SetPoint(
        "TOPRIGHT",
        panel,
        "TOPRIGHT",
        -8,
        -40
    )

    matchHeader:SetHeight(22)

    self:RegisterSkinnedFrame(
        matchHeader,
        "header"
    )

    local function MatchHeader(
        text,
        x,
        width
    )
        local f =
            matchHeader:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontNormalSmall"
            )

        f:SetPoint(
            "LEFT",
            matchHeader,
            "LEFT",
            x,
            0
        )

        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    MatchHeader("Character", 8, 105)
    MatchHeader("Role", 116, 88)
    MatchHeader("Type", 207, 70)
    MatchHeader("Presence", 280, 86)
    MatchHeader("Priority", 370, 92)

    self.currentLootDropRows = {}

    for rowIndex = 1, DROP_ROWS do
        local row =
            CreateFrame(
                "Frame",
                nil,
                panel
            )

        row:SetPoint(
            "TOPLEFT",
            dropsHeader,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 56)
        )

        row:SetWidth(326)
        row:SetHeight(54)
        row:EnableMouse(true)

        self:RegisterSkinnedFrame(
            row,
            (rowIndex % 2) == 0
                and "rowAlt"
                or "row"
        )

        local icon =
            row:CreateTexture(
                nil,
                "ARTWORK"
            )

        icon:SetWidth(36)
        icon:SetHeight(36)

        icon:SetPoint(
            "LEFT",
            row,
            "LEFT",
            6,
            0
        )

        local iconHit =
            CreateFrame(
                "Button",
                nil,
                row
            )

        iconHit:SetAllPoints(icon)

        iconHit:SetScript(
            "OnEnter",
            function(self)
                if not self.itemID then
                    return
                end

                GameTooltip:SetOwner(
                    self,
                    "ANCHOR_RIGHT"
                )

                GameTooltip:SetHyperlink(
                    "item:" ..
                    tostring(self.itemID) ..
                    ":0:0:0:0:0:0:0"
                )

                GameTooltip:Show()
            end
        )

        iconHit:SetScript(
            "OnLeave",
            function()
                GameTooltip:Hide()
            end
        )

        local name =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlight"
            )

        name:SetPoint(
            "TOPLEFT",
            row,
            "TOPLEFT",
            48,
            -7
        )

        name:SetWidth(268)
        name:SetJustifyH("LEFT")

        local source =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontDisableSmall"
            )

        source:SetPoint(
            "TOPLEFT",
            name,
            "BOTTOMLEFT",
            0,
            -4
        )

        source:SetWidth(268)
        source:SetJustifyH("LEFT")

        row:SetScript(
            "OnMouseDown",
            function(self)
                if self.lootIndex then
                    UI.currentLootSelected = self.lootIndex
                    UI.currentLootMatchPage = 1
                    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
                        NLL.DebugSimulator:SelectDrop(self.lootIndex)
                    else
                        UI:RefreshCurrentLootPanel()
                    end
                end
            end
        )

        iconHit:SetScript('OnClick',function()
            local click=row:GetScript('OnMouseDown')
            if click then click(row) end
        end)
        row.icon = icon
        row.iconHit = iconHit
        row.nameText = name
        row.sourceText = source

        self.currentLootDropRows[rowIndex] =
            row
    end

    -- Independent loot paging. Also works with more than five real drops.
    local prevLoot=self:CreateTextButton(panel,"Prev Loot",91)
    prevLoot:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",8,98)
    prevLoot:SetScript("OnClick",function()
        local page=math.max(1,(UI.currentLootDropPage or 1)-1)
        UI.currentLootDropPage=page
        local index=(page-1)*DROP_ROWS+1
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            NLL.DebugSimulator:SelectDrop(index)
        else
            UI.currentLootSelected=index
            UI.currentLootMatchPage=1
            UI:RefreshCurrentLootPanel()
        end
    end)
    local nextLoot=self:CreateTextButton(panel,"Next Loot",91)
    nextLoot:SetPoint("LEFT",prevLoot,"RIGHT",6,0)
    nextLoot:SetScript("OnClick",function()
        local page=(UI.currentLootDropPage or 1)+1
        UI.currentLootDropPage=page
        local index=(page-1)*DROP_ROWS+1
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            NLL.DebugSimulator:SelectDrop(index)
        else
            UI.currentLootSelected=index
            UI.currentLootMatchPage=1
            UI:RefreshCurrentLootPanel()
        end
    end)
    local lootPageText=panel:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    lootPageText:SetPoint("LEFT",nextLoot,"RIGHT",6,0)
    lootPageText:SetWidth(110)
    lootPageText:SetJustifyH("LEFT")
    self.currentLootDropPrev=prevLoot
    self.currentLootDropNext=nextLoot
    self.currentLootDropPageText=lootPageText
    self.currentLootDropPage=1

    local matchStatus =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    matchStatus:SetPoint(
        "TOPLEFT",
        matchHeader,
        "BOTTOMLEFT",
        4,
        -8
    )

    matchStatus:SetWidth(445)
    matchStatus:SetJustifyH("LEFT")

    self.currentLootMatchStatus =
        matchStatus

    self.currentLootMatchRows = {}

    for rowIndex = 1, MATCH_ROWS do
        local row =
            CreateFrame(
                "Frame",
                nil,
                panel
            )

        row:SetPoint(
            "TOPLEFT",
            matchHeader,
            "BOTTOMLEFT",
            0,
            -32 - ((rowIndex - 1) * 38)
        )

        row:SetPoint(
            "TOPRIGHT",
            matchHeader,
            "BOTTOMRIGHT",
            0,
            -32 - ((rowIndex - 1) * 38)
        )

        row:SetHeight(36)

        self:RegisterSkinnedFrame(
            row,
            (rowIndex % 2) == 0
                and "rowAlt"
                or "row"
        )

        local name =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlight"
            )

        name:SetPoint(
            "LEFT",
            row,
            "LEFT",
            8,
            0
        )

        name:SetWidth(105)
        name:SetJustifyH("LEFT")

        local role =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )

        role:SetPoint(
            "LEFT",
            row,
            "LEFT",
            116,
            0
        )

        role:SetWidth(88)
        role:SetJustifyH("LEFT")

        local charType =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )

        charType:SetPoint(
            "LEFT",
            row,
            "LEFT",
            207,
            0
        )

        charType:SetWidth(70)
        charType:SetJustifyH("LEFT")

        local presence =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )

        presence:SetPoint(
            "LEFT",
            row,
            "LEFT",
            280,
            0
        )

        presence:SetWidth(86)
        presence:SetJustifyH("LEFT")

        local priority =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )

        priority:SetPoint(
            "LEFT",
            row,
            "LEFT",
            370,
            0
        )

        priority:SetWidth(92)
        priority:SetJustifyH("LEFT")

        row.nameText = name
        row.roleText = role
        row.typeText = charType
        row.presenceText = presence
        row.priorityText = priority

        self.currentLootMatchRows[rowIndex] =
            row
    end

    local footer =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontDisableSmall"
        )

    footer:SetPoint(
        "BOTTOMLEFT",
        panel,
        "BOTTOMLEFT",
        342,
        10
    )

    footer:SetWidth(440)
    footer:SetJustifyH("LEFT")

    footer:SetText(
        "Post-drop ticket-pool preview only. No tickets, rolls or awards."
    )
    self.currentLootPreviewStatus = footer

    -- A 40-player raid can have more than six NEEDED entries.
    -- Paging keeps every match accessible without expanding the panel.
    local back = self:CreateTextButton(panel, "Prev Matches", 107)
    back:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 342, 37)
    back:SetScript("OnClick", function()
        UI.currentLootMatchPage = math.max(1, (UI.currentLootMatchPage or 1)-1)
        UI:RefreshCurrentLootPanel()
    end)
    local forward = self:CreateTextButton(panel, "Next Matches", 107)
    forward:SetPoint("LEFT", back, "RIGHT", 6, 0)
    forward:SetScript("OnClick", function()
        UI.currentLootMatchPage = (UI.currentLootMatchPage or 1)+1
        UI:RefreshCurrentLootPanel()
    end)
    self.currentLootMatchPrev=back
    self.currentLootMatchNext=forward
    self.currentLootMatchPageText=panel:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    self.currentLootMatchPageText:SetPoint("LEFT",forward,"RIGHT",8,0)
    self.currentLootMatchPageText:SetWidth(140)
    self.currentLootMatchPageText:SetJustifyH("LEFT")
    self.currentLootMatchPage=1

    self.currentLootStatus = status
    self.currentLootSelected = 1
    self.currentLootPanel = panel

    panel:Hide()
end

function UI:RefreshCurrentLootPanel()
    if not self.currentLootPanel then
        return
    end

    local loot =
        NLL.LootDetection:GetCurrentLoot()
        or {}

    local simulation=NLL.DebugSimulator and NLL.DebugSimulator:IsActive()
    self.currentLootStatus:SetText(
        (simulation and "|cffffcc33[SIMULATION] |r" or "") ..
        tostring(#loot) ..
        (simulation and " fake boss drop(s)." or
         " supported item(s). Previous winners restored for reopened loot.")
    )

    self.currentLootSelected =
        self.currentLootSelected or 1

    if self.currentLootSelected > #loot then
        self.currentLootSelected =
            #loot > 0 and #loot or 1
    end

    local pages=math.max(1,math.ceil(#loot / DROP_ROWS))
    self.currentLootDropPage=math.min(pages,
        math.max(1,math.ceil(self.currentLootSelected / DROP_ROWS)))
    local page=self.currentLootDropPage
    local first=(page-1)*DROP_ROWS
    self.currentLootDropPageText:SetText("Page "..page.."/"..pages)
    if page<=1 then self.currentLootDropPrev:Disable()
    else self.currentLootDropPrev:Enable() end
    if page>=pages then self.currentLootDropNext:Disable()
    else self.currentLootDropNext:Enable() end

    for rowIndex = 1, DROP_ROWS do
        local row =
            self.currentLootDropRows[
                rowIndex
            ]

        local absoluteIndex=first+rowIndex
        local entry = loot[absoluteIndex]

        if entry then
            row.lootIndex = absoluteIndex
            row.iconHit.itemID =
                entry.itemID

            row.icon:SetTexture(
                GetItemTexture(
                    entry.itemID
                )
            )

            local quantityText = ""

            if (entry.quantity or 1) > 1 then
                quantityText =
                    " x" ..
                    tostring(entry.quantity)
            end

            row.nameText:SetText(
                entry.itemName ..
                quantityText
            )

            local source=tostring(entry.boss or 'Unknown source')
            if NLL.AwardWorkflow then
                local outcome=NLL.AwardWorkflow:GetOutcome(entry)
                if outcome and outcome.winner then
                    source='Winner: '..outcome.winner..
                        (outcome.awardStatus and
                            (' ['..tostring(outcome.awardStatus)..']') or ' [ROLL]')
                end
            end
            row.sourceText:SetText(source)

            if absoluteIndex ==
                self.currentLootSelected then

                self:RegisterSkinnedFrame(
                    row,
                    "header"
                )
            else
                self:RegisterSkinnedFrame(
                    row,
                    (rowIndex % 2) == 0
                        and "rowAlt"
                        or "row"
                )
            end

            row:Show()
        else
            row.lootIndex = nil
            row.iconHit.itemID = nil
            row:Hide()
        end
    end

    local selected =
        loot[self.currentLootSelected]

    if not selected then
        self:RefreshTicketLotteryControls(nil)
        self.currentLootPreviewButton:Disable()
        self.currentLootPreviewStatus:SetText("No detected drop; no ticket pool.")
        self.currentLootMatchPageText:SetText("0 matches")
        self.currentLootMatchPrev:Disable()
        self.currentLootMatchNext:Disable()
        self.currentLootMatchStatus:SetText(
            "Open a supported raid loot window to detect items."
        )

        for i = 1, MATCH_ROWS do
            self.currentLootMatchRows[i]:Hide()
        end

        return
    end

    self:RefreshTicketLotteryControls(selected)
    self.currentLootPreviewButton:Enable()
    self.currentLootPreviewStatus:SetText(
        "Preview Pool: shows highest eligible tier; no rolling or awarding."
    )

    local matches =
        NLL.NeedMatcher:GetMatchesForItem(
            selected.itemID
        )
    if not simulation then
        matches=NLL.CandidateReview:MergeMatches(selected,matches)
    end

    local eligible = 0

    for i = 1, #matches do
        if matches[i].eligiblePresence and
            not (simulation and NLL.DebugSimulator.active.exclusions[
                string.lower(matches[i].character or "")]) and
            (simulation or not NLL.CandidateReview:IsExcluded(
                selected,matches[i].character)) then
            eligible = eligible + 1
        end
    end

    local priorityLabel =
        NLL.PriorityEngine:GetDisplayLabel(
            selected.raidKey
                or "MOLTEN_CORE",
            selected.itemID
        )

    if simulation then
        local _,source=NLL.DebugSimulator:GetRule(selected.itemID)
        priorityLabel="Fake rule: "..tostring(source)
    end
    local statusText =
        tostring(#matches) ..
        " NEEDED character(s); " ..
        tostring(eligible) ..
        " currently eligible by raid presence.  " ..
        "Priority: " ..
        priorityLabel ..
        "."

    if selected.manualOnly then
        statusText =
            statusText ..
            "  |cffff9933Guild/manual item - no normal lottery.|r"
    end

    self.currentLootMatchStatus:SetText(
        statusText
    )

    local matchPages = math.max(1, math.ceil(#matches / MATCH_ROWS))
    self.currentLootMatchPage = math.min(matchPages,
        math.max(1,self.currentLootMatchPage or 1))
    self.currentLootMatchPageText:SetText(
        "Page " .. self.currentLootMatchPage .. "/" .. matchPages ..
        " (" .. #matches .. ")")
    if self.currentLootMatchPage == 1 then self.currentLootMatchPrev:Disable()
    else self.currentLootMatchPrev:Enable() end
    if self.currentLootMatchPage == matchPages then self.currentLootMatchNext:Disable()
    else self.currentLootMatchNext:Enable() end

    for rowIndex = 1, MATCH_ROWS do
        local row =
            self.currentLootMatchRows[
                rowIndex
            ]

        local match =
            matches[(self.currentLootMatchPage-1)*MATCH_ROWS + rowIndex]

        if match then
            row.nameText:SetText(
                match.character
                or "Unknown"
            )

            -- Keep class separate from the narrow role column:
            -- appending it here caused text wrapping and overlap.
            row.roleText:SetText(
                match.roleLabel or "Unassigned"
            )

            if simulation then
                row.typeText:SetText("Fake Bot")
            elseif match.characterType ==
                "PLAYERBOT" then

                row.typeText:SetText(
                    "Playerbot"
                )
            elseif match.characterType ==
                "PLAYER" then

                row.typeText:SetText(
                    "Player"
                )
            else
                row.typeText:SetText(
                    "Unknown"
                )
            end

            if not match.inRaid then
                row.presenceText:SetText(
                    "|cffff7777Not in raid|r"
                )
            elseif not match.online then
                row.presenceText:SetText(
                    "|cffffaa55Offline|r"
                )
            else
                row.presenceText:SetText(
                    "|cff66ff66In raid|r"
                )
            end

            local _, priorityLabel =
                NLL.PriorityEngine:GetCandidatePriority(
                    selected.raidKey
                        or "MOLTEN_CORE",
                    selected.itemID,
                    match
                )

            if simulation then
                local _,simLabel=NLL.DebugSimulator:GetCandidatePriority(match)
                if NLL.DebugSimulator.active.exclusions[
                   string.lower(match.character or "")] then simLabel="Excluded" end
                row.priorityText:SetText(simLabel or "Unconfigured")
            elseif NLL.CandidateReview:IsExcluded(selected,match.character) then
                row.priorityText:SetText('Excluded')
            else
                row.priorityText:SetText(priorityLabel or '')
            end

            row:Show()
        else
            row:Hide()
        end
    end
end


function UI:RefreshTicketLotteryControls(selected)
    if not self.currentLootPrepareButton then return end
    local S=NLL.DebugSimulator
    if S and S:IsActive() then
        local a=S.active
        if a.result then
            self.currentLootLotteryNote:SetText(
              "|cff66ff99SIM WINNER: "..a.result.winner.." (#"..a.result.number..")|r" ..
              (a.result.awardStatus and ' [FAKE AWARDED]' or ' [PENDING AWARD]'))
        elseif a.prepared then
            self.currentLootLotteryNote:SetText(
              "[SIMULATION] "..#a.prepared.tickets.." tickets ready")
        else
            self.currentLootLotteryNote:SetText(
              "[SIMULATION] Prepare tickets to test a fake roll.")
        end
        if selected and not a.result and not a.prepared then
            self.currentLootPrepareButton:Enable()
        else self.currentLootPrepareButton:Disable() end
        if a.prepared and not a.result then self.currentLootRollButton:Enable()
        else self.currentLootRollButton:Disable() end
        self.currentLootCancelButton:Enable()
        self.currentLootReviewButton.label:SetText(a.result and 'Review Award' or 'Review Pool')
        self.currentLootReviewButton:Enable()
        return
    end
    local L=NLL.TicketLottery
    local a=L:GetActiveFor(selected)
    self.currentLootReviewButton.label:SetText(a and a.status=='COMPLETE' and 'Review Award' or 'Review Pool')
    if a and a.status == "COMPLETE" and a.winner then
        local awardTag = '[NOT AWARDED]'
        if a.awardStatus == 'LEADER_REPORTED' then awardTag='[REPORTED]'
        elseif a.awardStatus == 'AWARD_REQUESTED' then awardTag='[REQUEST SENT]'
        elseif a.awardStatus == 'LOOT_SLOT_CLEARED' then awardTag='[SLOT CLEARED]'
        elseif a.awardStatus == 'AWARD_OUTCOME_UNKNOWN' then awardTag='[UNKNOWN]' end
        self.currentLootLotteryNote:SetText(
          (a.test and "|cff66ff99TEST WINNER: " or "|cff66ff99WINNER: ") ..
          a.winner .. " (#" .. tostring(a.winningTicket) .. ")|r " .. awardTag)
    else
        self.currentLootLotteryNote:SetText(L:GetStatus(selected))
    end
    local allowed=selected and selected.dropUID and not selected.identityUncertain and
        L.liveLootObserved and L:AuthorityAllowed(selected.slotIndex==0)
    if allowed and (not a or a.status=='PREPARED') then
        self.currentLootPrepareButton:Enable()
    else self.currentLootPrepareButton:Disable() end
    if allowed and a and a.status=='PREPARED' then
        self.currentLootRollButton:Enable()
    else self.currentLootRollButton:Disable() end
    if a and a.status~='COMPLETE' and L:AuthorityAllowed(a.test) then
        self.currentLootCancelButton:Enable()
    else self.currentLootCancelButton:Disable() end
end
