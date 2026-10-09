-- ============================================================
-- Naxxramas Loot Ledger
-- UI/SearchFrame.lua
-- Phase 3 Molten Core search and local reserve controls.
-- ============================================================

local NLL = NaxxLootLottery
local UI = NLL.UI

local RESULTS_PER_PAGE = 6

local function SearchRowBackdrop(row, alternate)
    UI:RegisterSkinnedFrame(
        row,
        alternate
            and "rowAlt"
            or "row"
    )
end

local function GetItemTexture(itemID)
    -- GetItemIcon exists in the Wrath-era client and, unlike
    -- GetItemInfo(), does not require the item to already be
    -- present in the local item cache.
    if GetItemIcon then
        local texture = GetItemIcon(itemID)

        if texture then
            return texture
        end
    end

    -- Secondary fallback if a custom client behaves differently.
    if GetItemInfo then
        local _, _, _, _, _, _, _, _, _, texture =
            GetItemInfo(itemID)

        if texture then
            return texture
        end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function UI:CreateSearchPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    local heading = panel:CreateFontString(
        nil, "OVERLAY", "GameFontNormal"
    )
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
    heading:SetText("Raid Loot Search")

    local sub = panel:CreateFontString(
        nil, "OVERLAY", "GameFontDisableSmall"
    )
    sub:SetPoint("LEFT", heading, "RIGHT", 12, 0)
    sub:SetText("Select a raid, then search its loot")

    local raidLabel = panel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    raidLabel:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        12,
        -38
    )
    raidLabel:SetText("Raid:")

    local moltenCoreButton =
        self:CreateTextButton(
            panel,
            "Molten Core",
            105
        )
    moltenCoreButton:SetPoint(
        "LEFT",
        raidLabel,
        "RIGHT",
        10,
        0
    )

    moltenCoreButton:SetScript(
        "OnClick",
        function()
            UI:SelectSearchRaid(
                "MOLTEN_CORE"
            )
        end
    )

    self.moltenCoreSearchButton =
        moltenCoreButton

    local searchBox = CreateFrame(
        "EditBox",
        "NaxxLootLotterySearchBox",
        panel,
        "InputBoxTemplate"
    )
    searchBox:SetWidth(330)
    searchBox:SetHeight(24)
    searchBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -70)
    searchBox:SetAutoFocus(false)

    local searchButton = self:CreateTextButton(panel, "Search", 70)
    searchButton:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)

    local clearButton = self:CreateTextButton(panel, "Clear", 62)
    clearButton:SetPoint("LEFT", searchButton, "RIGHT", 4, 0)

    local reservedText = panel:CreateFontString(
        nil, "OVERLAY", "GameFontHighlightSmall"
    )
    reservedText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -75)
    reservedText:SetWidth(230)
    reservedText:SetJustifyH("RIGHT")

    self.searchBox = searchBox
    self.searchReservedText = reservedText

    local function RunSearch()
        if not NLL.ItemSearch:GetSelectedRaid() then
            NLL:Print(
                "Select a raid before searching its loot."
            )
            return
        end

        NLL.ItemSearch:Search(searchBox:GetText() or "")
        UI.searchPage = 1
        UI:RefreshSearchPanel()
    end

    searchButton:SetScript("OnClick", RunSearch)

    clearButton:SetScript("OnClick", function()
        searchBox:SetText("")
        RunSearch()
    end)

    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        RunSearch()
    end)

    -- Header
    local header = CreateFrame("Frame", nil, panel)
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -106)
    header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -106)
    header:SetHeight(22)
    UI:RegisterSkinnedFrame(
        header,
        "header"
    )

    local function HeaderText(text, x, width)
        local f = header:CreateFontString(
            nil, "OVERLAY", "GameFontNormalSmall"
        )
        f:SetPoint("LEFT", header, "LEFT", x, 0)
        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    HeaderText("Item", 42, 300)
    HeaderText("Boss / Source", 350, 250)
    HeaderText("Priority", 605, 95)

    self.searchRows = {}

    for rowIndex = 1, RESULTS_PER_PAGE do
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint(
            "TOPLEFT", header, "BOTTOMLEFT",
            0, -((rowIndex - 1) * 46)
        )
        row:SetPoint(
            "TOPRIGHT", header, "BOTTOMRIGHT",
            0, -((rowIndex - 1) * 46)
        )
        row:SetHeight(44)
        SearchRowBackdrop(row, (rowIndex % 2) == 0)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(34)
        icon:SetHeight(34)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)

        local iconHit = CreateFrame("Button", nil, row)
        iconHit:SetWidth(34)
        iconHit:SetHeight(34)
        iconHit:SetPoint("CENTER", icon, "CENTER", 0, 0)

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

        local nameText = row:CreateFontString(
            nil, "OVERLAY", "GameFontHighlight"
        )
        nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 44, -5)
        nameText:SetWidth(290)
        nameText:SetJustifyH("LEFT")

        local idText = row:CreateFontString(
            nil, "OVERLAY", "GameFontDisableSmall"
        )
        idText:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 44, 5)
        idText:SetWidth(290)
        idText:SetJustifyH("LEFT")

        local bossText = row:CreateFontString(
            nil, "OVERLAY", "GameFontHighlightSmall"
        )
        bossText:SetPoint("LEFT", row, "LEFT", 350, 0)
        bossText:SetWidth(245)
        bossText:SetJustifyH("LEFT")

        local priorityText = row:CreateFontString(
            nil, "OVERLAY", "GameFontDisableSmall"
        )
        priorityText:SetPoint("LEFT", row, "LEFT", 605, 0)
        priorityText:SetWidth(92)
        priorityText:SetJustifyH("LEFT")

        local reserveButton =
            self:CreateTextButton(row, "Reserve", 78)
        reserveButton:SetPoint("RIGHT", row, "RIGHT", -5, 0)

        reserveButton:SetScript("OnClick", function(self)
            if self.itemID then
                NLL.ItemSearch:ToggleReservation(self.itemID)
            end
        end)

        row.icon = icon
        row.iconHit = iconHit
        row.nameText = nameText
        row.idText = idText
        row.bossText = bossText
        row.priorityText = priorityText
        row.reserveButton = reserveButton

        self.searchRows[rowIndex] = row
    end

    local resultStatus = panel:CreateFontString(
        nil, "OVERLAY", "GameFontDisableSmall"
    )
    resultStatus:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 8, 14)
    resultStatus:SetWidth(280)
    resultStatus:SetJustifyH("LEFT")

    local previous = self:CreateTextButton(panel, "Previous", 76)
    previous:SetPoint("BOTTOM", panel, "BOTTOM", -48, 10)
    previous:SetScript("OnClick", function()
        if UI.searchPage > 1 then
            UI.searchPage = UI.searchPage - 1
            UI:RefreshSearchPanel()
        end
    end)

    local nextButton = self:CreateTextButton(panel, "Next", 64)
    nextButton:SetPoint("LEFT", previous, "RIGHT", 4, 0)
    nextButton:SetScript("OnClick", function()
        if UI.searchPage < UI.searchTotalPages then
            UI.searchPage = UI.searchPage + 1
            UI:RefreshSearchPanel()
        end
    end)

    local pageText = panel:CreateFontString(
        nil, "OVERLAY", "GameFontHighlightSmall"
    )
    pageText:SetPoint("LEFT", nextButton, "RIGHT", 10, 0)

    self.searchResultStatus = resultStatus
    self.previousSearchButton = previous
    self.nextSearchButton = nextButton
    self.searchPageText = pageText
    self.searchPage = 1
    self.searchTotalPages = 1
    self.searchPanel = panel

    panel:Hide()

    NLL.ItemSearch.results = {}
end

function UI:SelectSearchRaid(raidKey)
    if raidKey ~= "MOLTEN_CORE" then
        return
    end

    NLL.ItemSearch:SetRaid(raidKey)

    if self.moltenCoreSearchButton then
        self:SetButtonState(
            self.moltenCoreSearchButton,
            "active"
        )
    end

    self.searchPage = 1
    self:RefreshSearchPanel()
end

function UI:SetSearchText(text)
    if not self.searchBox then
        return
    end

    if not NLL.ItemSearch:GetSelectedRaid() then
        self:SelectSearchRaid("MOLTEN_CORE")
    end

    self.searchBox:SetText(text or "")
    NLL.ItemSearch:Search(text or "")
    self.searchPage = 1
    self:RefreshSearchPanel()
end

function UI:RefreshSearchPanel()
    if not self.searchPanel then
        return
    end

    local selectedRaid =
        NLL.ItemSearch:GetSelectedRaid()

    local results = NLL.ItemSearch:GetResults() or {}
    local count = #results

    local totalPages = math.ceil(count / RESULTS_PER_PAGE)
    if totalPages < 1 then
        totalPages = 1
    end

    self.searchTotalPages = totalPages
    self.searchPage = self.searchPage or 1

    if self.searchPage > totalPages then
        self.searchPage = totalPages
    end

    local reservedCount = NLL.ItemSearch:GetReservationCount()

    if selectedRaid == "MOLTEN_CORE" then
        self.searchReservedText:SetText(
            "My Molten Core selections: |cffffffff" ..
            tostring(reservedCount) ..
            "|r"
        )

        self.searchResultStatus:SetText(
            tostring(count) .. " matching item(s)"
        )
    else
        self.searchReservedText:SetText(
            "Select a raid to view its loot."
        )

        self.searchResultStatus:SetText(
            "No raid selected"
        )
    end

    local firstIndex =
        ((self.searchPage - 1) * RESULTS_PER_PAGE) + 1

    local MC = NLL.Data.MoltenCore

    for rowIndex = 1, RESULTS_PER_PAGE do
        local row = self.searchRows[rowIndex]
        local item = results[firstIndex + rowIndex - 1]

        if item then
            row.icon:SetTexture(GetItemTexture(item.itemID))
            row.iconHit.itemID = item.itemID
            row.nameText:SetText(item.name)
            row.idText:SetText("Item ID: " .. tostring(item.itemID))
            row.bossText:SetText(MC:GetBossText(item))

            local priorityLabel =
                NLL.PriorityEngine:GetDisplayLabel(
                    "MOLTEN_CORE",
                    item.itemID
                )

            if item.manualOnly then
                row.priorityText:SetText(
                    "|cffff9933" ..
                    priorityLabel ..
                    "|r"
                )
            else
                row.priorityText:SetText(
                    priorityLabel
                )
            end

            local reserved =
                NLL.ItemSearch:IsReserved(item.itemID)

            if reserved then
                row.reserveButton.label:SetText("Remove")
                self:SetButtonState(
                    row.reserveButton,
                    "danger"
                )
            else
                row.reserveButton.label:SetText("Reserve")
                self:SetButtonState(
                    row.reserveButton,
                    "normal"
                )
            end

            row.reserveButton.itemID = item.itemID
            row:Show()
        else
            row.iconHit.itemID = nil
            row:Hide()
        end
    end

    self.searchPageText:SetText(
        "Page " .. self.searchPage .. " / " .. totalPages
    )

    if self.searchPage <= 1 then
        self.previousSearchButton:Disable()
    else
        self.previousSearchButton:Enable()
    end

    if self.searchPage >= totalPages then
        self.nextSearchButton:Disable()
    else
        self.nextSearchButton:Enable()
    end

    if self.RefreshOverview then
        self:RefreshOverview()
    end
end
