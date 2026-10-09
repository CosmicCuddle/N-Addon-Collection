-- ============================================================
-- Naxxramas Loot Ledger
-- UI/WishlistFrame.lua
--
-- Phase 4:
--   * My local wishlist review
--   * Raid-leader manual Gear Needs
--   * Persistent Playerbot gear plans
--   * NEEDED / OBTAINED / DISABLED state changes
-- ============================================================

local NLL = NaxxLootLottery
local UI = NLL.UI

local LOCAL_ROWS = 8
local PLAN_ROWS = 7

local function SetRowBackdrop(row, alternate)
    UI:RegisterSkinnedFrame(
        row,
        alternate
            and "rowAlt"
            or "row"
    )
end

local function GetLocalWishlistItems()
    local output = {}
    local playerName = UnitName("player")

    if not playerName then
        return output
    end

    local wishlist =
        NLL.Database:GetLocalWishlist(
            playerName,
            "MOLTEN_CORE"
        )

    for itemID, wanted in pairs(wishlist or {}) do
        if wanted then
            local item =
                NLL.Data.MoltenCore:GetItem(itemID)

            if item then
                table.insert(output, item)
            end
        end
    end

    table.sort(output, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    return output
end

function UI:CreateWishlistPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    local heading = panel:CreateFontString(
        nil, "OVERLAY", "GameFontNormal"
    )
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
    heading:SetText("Wishlists & Gear Plans")

    local myButton = self:CreateTextButton(
        panel,
        "My Wishlist",
        92
    )
    myButton:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        10,
        -34
    )

    local plansButton = self:CreateTextButton(
        panel,
        "Gear Plans",
        90
    )
    plansButton:SetPoint("LEFT", myButton, "RIGHT", 4, 0)

    local inboxButton = self:CreateTextButton(
        panel,
        "Inbox",
        72
    )
    inboxButton:SetPoint("LEFT", plansButton, "RIGHT", 4, 0)

    myButton:SetScript("OnClick", function()
        UI.wishlistMode = "local"
        UI:RefreshWishlistPanel()
    end)

    plansButton:SetScript("OnClick", function()
        UI.wishlistMode = "plans"
        UI:RefreshWishlistPanel()
    end)

    inboxButton:SetScript("OnClick", function()
        UI.wishlistMode = "inbox"
        UI:RefreshWishlistPanel()
    end)

    self.wishlistMyButton = myButton
    self.wishlistPlansButton = plansButton
    self.wishlistInboxButton = inboxButton

    self:CreateLocalWishlistContent(panel)
    self:CreateGearPlansContent(panel)
    self:CreateInboxContent(panel)
    self:CreateSimulationWishlistContent(panel)

    self.wishlistMode = "local"
    self.wishlistPanel = panel

    panel:Hide()
end

-- ============================================================
-- MY LOCAL WISHLIST
-- ============================================================

function UI:CreateLocalWishlistContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -66)
    content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)

    local status = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    status:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -2)
    status:SetWidth(720)
    status:SetJustifyH("LEFT")

    self.localWishlistStatus = status

    local header = CreateFrame("Frame", nil, content)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -28)
    header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -28)
    header:SetHeight(22)
    UI:RegisterSkinnedFrame(
        header,
        "header"
    )

    local function HeaderText(text, x, width)
        local f = header:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
        f:SetPoint("LEFT", header, "LEFT", x, 0)
        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    HeaderText("Item", 10, 360)
    HeaderText("Boss / Source", 375, 290)

    self.localWishlistRows = {}

    for rowIndex = 1, LOCAL_ROWS do
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint(
            "TOPLEFT",
            header,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 42)
        )
        row:SetPoint(
            "TOPRIGHT",
            header,
            "BOTTOMRIGHT",
            0,
            -((rowIndex - 1) * 42)
        )
        row:SetHeight(40)

        SetRowBackdrop(row, (rowIndex % 2) == 0)

        local itemText = row:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlight"
        )
        itemText:SetPoint("LEFT", row, "LEFT", 10, 0)
        itemText:SetWidth(355)
        itemText:SetJustifyH("LEFT")

        local bossText = row:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )
        bossText:SetPoint("LEFT", row, "LEFT", 375, 0)
        bossText:SetWidth(280)
        bossText:SetJustifyH("LEFT")

        local remove =
            self:CreateTextButton(row, "Remove", 72)
        remove:SetPoint("RIGHT", row, "RIGHT", -5, 0)

        remove:SetScript("OnClick", function(self)
            if self.itemID then
                NLL.ItemSearch:ToggleReservation(
                    self.itemID
                )
                UI:RefreshWishlistPanel()
            end
        end)

        row.itemText = itemText
        row.bossText = bossText
        row.remove = remove

        self.localWishlistRows[rowIndex] = row
    end

    local previous =
        self:CreateTextButton(content, "Previous", 76)
    previous:SetPoint(
        "BOTTOMLEFT",
        content,
        "BOTTOMLEFT",
        0,
        0
    )

    local nextButton =
        self:CreateTextButton(content, "Next", 64)
    nextButton:SetPoint("LEFT", previous, "RIGHT", 4, 0)

    local pageText = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    pageText:SetPoint("LEFT", nextButton, "RIGHT", 10, 0)

    previous:SetScript("OnClick", function()
        if UI.localWishlistPage > 1 then
            UI.localWishlistPage =
                UI.localWishlistPage - 1

            UI:RefreshLocalWishlist()
        end
    end)

    nextButton:SetScript("OnClick", function()
        if UI.localWishlistPage
            < UI.localWishlistTotalPages then

            UI.localWishlistPage =
                UI.localWishlistPage + 1

            UI:RefreshLocalWishlist()
        end
    end)


    local submitButton =
        self:CreateTextButton(
            content,
            "Submit to Leader",
            122
        )

    submitButton:SetPoint(
        "BOTTOMRIGHT",
        content,
        "BOTTOMRIGHT",
        0,
        0
    )

    submitButton:SetScript(
        "OnClick",
        function()
            NLL.Communication:
                SubmitLocalWishlist()
        end
    )

    local submitStatus =
        content:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontDisableSmall"
        )

    submitStatus:SetPoint(
        "RIGHT",
        submitButton,
        "LEFT",
        -10,
        0
    )

    submitStatus:SetWidth(300)
    submitStatus:SetJustifyH("RIGHT")

    self.localSubmitStatus = submitStatus
    self.localSubmitButton = submitButton

    self.localWishlistPrevious = previous
    self.localWishlistNext = nextButton
    self.localWishlistPageText = pageText
    self.localWishlistPage = 1
    self.localWishlistTotalPages = 1
    self.localWishlistContent = content
end

function UI:RefreshLocalWishlist()
    local items = GetLocalWishlistItems()
    local count = #items

    local totalPages =
        math.ceil(count / LOCAL_ROWS)

    if totalPages < 1 then
        totalPages = 1
    end

    self.localWishlistTotalPages = totalPages
    self.localWishlistPage =
        self.localWishlistPage or 1

    if self.localWishlistPage > totalPages then
        self.localWishlistPage = totalPages
    end

    self.localWishlistStatus:SetText(
        "My Molten Core wishlist: |cffffffff" ..
        tostring(count) ..
        "|r item(s). Use Raid Loot Search to add more."
    )

    if self.localSubmitStatus then
        self.localSubmitStatus:SetText(
            NLL.Communication:
                GetOutgoingStatusText()
        )
    end

    local firstIndex =
        ((self.localWishlistPage - 1) * LOCAL_ROWS) + 1

    for rowIndex = 1, LOCAL_ROWS do
        local row = self.localWishlistRows[rowIndex]
        local item = items[firstIndex + rowIndex - 1]

        if item then
            row.itemText:SetText(item.name)
            row.bossText:SetText(
                NLL.Data.MoltenCore:GetBossText(item)
            )
            row.remove.itemID = item.itemID
            row:Show()
        else
            row:Hide()
        end
    end

    self.localWishlistPageText:SetText(
        "Page " ..
        self.localWishlistPage ..
        " / " ..
        totalPages
    )

    if self.localWishlistPage <= 1 then
        self.localWishlistPrevious:Disable()
    else
        self.localWishlistPrevious:Enable()
    end

    if self.localWishlistPage >= totalPages then
        self.localWishlistNext:Disable()
    else
        self.localWishlistNext:Enable()
    end
end

-- ============================================================
-- RAID LEADER / PLAYERBOT GEAR PLANS
-- ============================================================

function UI:CreateGearPlansContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -66)
    content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)

    -- Character name
    local characterLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    characterLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        4,
        -3
    )
    characterLabel:SetText("Character")

    local characterBox = CreateFrame(
        "EditBox",
        "NaxxLootLotteryGearCharacterBox",
        content,
        "InputBoxTemplate"
    )
    characterBox:SetWidth(135)
    characterBox:SetHeight(22)
    characterBox:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        4,
        -20
    )
    characterBox:SetAutoFocus(false)

    -- Character type
    local typeLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    typeLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        150,
        -3
    )
    typeLabel:SetText("Type")

    local typeDrop = CreateFrame(
        "Frame",
        "NaxxLootLotteryGearTypeDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    typeDrop:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        132,
        -14
    )
    UIDropDownMenu_SetWidth(typeDrop, 105)

    typeDrop.value = "PLAYERBOT"

    UIDropDownMenu_Initialize(typeDrop, function()
        local types = {
            { id = "PLAYER", label = "Player" },
            { id = "PLAYERBOT", label = "Playerbot" },
            { id = "UNKNOWN", label = "Unknown" }
        }

        for i = 1, #types do
            local entry = types[i]
            local id = entry.id
            local label = entry.label

            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.checked = typeDrop.value == id

            info.func = function()
                typeDrop.value = id
                UIDropDownMenu_SetText(typeDrop, label)

                if id == "PLAYERBOT" then
                    UI.gearSourceDrop.value =
                        "BOT_GEAR_PLAN"

                    UIDropDownMenu_SetText(
                        UI.gearSourceDrop,
                        "Bot Gear Plan"
                    )
                end
            end

            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(typeDrop, "Playerbot")

    -- Role
    local roleLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    roleLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        270,
        -3
    )
    roleLabel:SetText("Role")

    local roleDrop = CreateFrame(
        "Frame",
        "NaxxLootLotteryGearRoleDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    roleDrop:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        250,
        -14
    )
    UIDropDownMenu_SetWidth(roleDrop, 145)
    roleDrop.value = "MAIN_TANK"

    UIDropDownMenu_Initialize(roleDrop, function()
        for i = 1, #NLL.roles do
            local role = NLL.roles[i]
            local roleID = role.id
            local roleText = role.label

            local info = UIDropDownMenu_CreateInfo()
            info.text = roleText
            info.checked = roleDrop.value == roleID

            info.func = function()
                roleDrop.value = roleID
                UIDropDownMenu_SetText(
                    roleDrop,
                    roleText
                )
            end

            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(roleDrop, "Main Tank")

    -- Source
    local sourceLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    sourceLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        430,
        -3
    )
    sourceLabel:SetText("Source")

    local sourceDrop = CreateFrame(
        "Frame",
        "NaxxLootLotteryGearSourceDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    sourceDrop:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        410,
        -14
    )
    UIDropDownMenu_SetWidth(sourceDrop, 145)
    sourceDrop.value = "BOT_GEAR_PLAN"

    UIDropDownMenu_Initialize(sourceDrop, function()
        local sources = {
            {
                id = "BOT_GEAR_PLAN",
                label = "Bot Gear Plan"
            },
            {
                id = "RAID_LEADER_MANUAL",
                label = "Leader Manual"
            }
        }

        for i = 1, #sources do
            local entry = sources[i]
            local id = entry.id
            local label = entry.label

            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.checked = sourceDrop.value == id

            info.func = function()
                sourceDrop.value = id
                UIDropDownMenu_SetText(
                    sourceDrop,
                    label
                )
            end

            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(sourceDrop, "Bot Gear Plan")

    -- Item input
    local itemLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    itemLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        585,
        -3
    )
    itemLabel:SetText("Molten Core item")

    local itemBox = CreateFrame(
        "EditBox",
        "NaxxLootLotteryGearItemBox",
        content,
        "InputBoxTemplate"
    )
    itemBox:SetWidth(135)
    itemBox:SetHeight(22)
    itemBox:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        580,
        -20
    )
    itemBox:SetAutoFocus(false)

    local addButton =
        self:CreateTextButton(content, "Add Need", 78)
    addButton:SetPoint(
        "TOPRIGHT",
        content,
        "TOPRIGHT",
        -2,
        -19
    )

    self.gearCharacterBox = characterBox
    self.gearTypeDrop = typeDrop
    self.gearRoleDrop = roleDrop
    self.gearSourceDrop = sourceDrop
    self.gearItemBox = itemBox

    addButton:SetScript("OnClick", function()
        local characterName =
            UI.gearCharacterBox:GetText() or ""

        local item, errorMessage =
            NLL.GearNeeds:ResolveItem(
                UI.gearItemBox:GetText() or ""
            )

        if not item then
            NLL:Print(errorMessage)
            return
        end

        local ok, result =
            NLL.GearNeeds:AddNeed(
                characterName,
                item.itemID,
                "MOLTEN_CORE",
                UI.gearRoleDrop.value,
                "NEEDED",
                UI.gearSourceDrop.value,
                UI.gearTypeDrop.value
            )

        if not ok then
            NLL:Print(result)
            return
        end

        NLL:Print(
            item.name ..
            " added for " ..
            result.character ..
            "."
        )

        UI.gearItemBox:SetText("")
        UI:RefreshGearPlans()
    end)

    -- Filter
    local filterLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    filterLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        4,
        -58
    )
    filterLabel:SetText("Filter character")

    local filterBox = CreateFrame(
        "EditBox",
        "NaxxLootLotteryGearFilterBox",
        content,
        "InputBoxTemplate"
    )
    filterBox:SetWidth(145)
    filterBox:SetHeight(22)
    filterBox:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        4,
        -74
    )
    filterBox:SetAutoFocus(false)

    local filterButton =
        self:CreateTextButton(content, "Apply", 58)
    filterButton:SetPoint(
        "LEFT",
        filterBox,
        "RIGHT",
        5,
        0
    )

    local clearFilter =
        self:CreateTextButton(content, "All", 48)
    clearFilter:SetPoint(
        "LEFT",
        filterButton,
        "RIGHT",
        4,
        0
    )

    filterButton:SetScript("OnClick", function()
        UI.gearPlanFilter =
            filterBox:GetText() or ""

        UI.gearPlansPage = 1
        UI:RefreshGearPlans()
    end)

    clearFilter:SetScript("OnClick", function()
        filterBox:SetText("")
        UI.gearPlanFilter = ""
        UI.gearPlansPage = 1
        UI:RefreshGearPlans()
    end)

    self.gearFilterBox = filterBox
    self.gearPlanFilter = ""

    -- List header
    local header = CreateFrame("Frame", nil, content)
    header:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        0,
        -108
    )
    header:SetPoint(
        "TOPRIGHT",
        content,
        "TOPRIGHT",
        0,
        -108
    )
    header:SetHeight(22)
    UI:RegisterSkinnedFrame(
        header,
        "header"
    )

    local function HeaderText(text, x, width)
        local f = header:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
        f:SetPoint("LEFT", header, "LEFT", x, 0)
        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    HeaderText("Character", 8, 120)
    HeaderText("Item", 132, 220)
    HeaderText("Role", 356, 105)
    HeaderText("Source", 465, 110)
    HeaderText("Status", 580, 120)

    self.gearPlanRows = {}

    for rowIndex = 1, PLAN_ROWS do
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint(
            "TOPLEFT",
            header,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 42)
        )
        row:SetPoint(
            "TOPRIGHT",
            header,
            "BOTTOMRIGHT",
            0,
            -((rowIndex - 1) * 42)
        )
        row:SetHeight(40)

        SetRowBackdrop(
            row,
            (rowIndex % 2) == 0
        )

        local characterText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        characterText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            8,
            0
        )
        characterText:SetWidth(120)
        characterText:SetJustifyH("LEFT")

        local itemText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        itemText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            132,
            0
        )
        itemText:SetWidth(220)
        itemText:SetJustifyH("LEFT")

        local roleText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        roleText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            356,
            0
        )
        roleText:SetWidth(105)
        roleText:SetJustifyH("LEFT")

        local sourceText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontDisableSmall"
            )
        sourceText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            465,
            0
        )
        sourceText:SetWidth(110)
        sourceText:SetJustifyH("LEFT")

        local statusName =
            "NaxxLootLotteryNeedStatus" ..
            tostring(rowIndex)

        local statusDrop = CreateFrame(
            "Frame",
            statusName,
            row,
            "UIDropDownMenuTemplate"
        )
        statusDrop:SetPoint(
            "LEFT",
            row,
            "LEFT",
            555,
            -2
        )
        UIDropDownMenu_SetWidth(statusDrop, 100)

        UIDropDownMenu_Initialize(
            statusDrop,
            function()
                local statuses = {
                    "NEEDED",
                    "OBTAINED",
                    "DISABLED"
                }

                for i = 1, #statuses do
                    local status = statuses[i]

                    local info =
                        UIDropDownMenu_CreateInfo()

                    info.text = status
                    info.checked =
                        statusDrop.currentStatus
                        == status

                    info.func = function()
                        if statusDrop.needKey then
                            NLL.GearNeeds:SetStatus(
                                statusDrop.needKey,
                                status
                            )

                            UI:RefreshGearPlans()
                        end
                    end

                    UIDropDownMenu_AddButton(info)
                end
            end
        )

        local remove =
            self:CreateTextButton(row, "X", 28)
        remove:SetPoint(
            "RIGHT",
            row,
            "RIGHT",
            -4,
            0
        )

        remove:SetScript("OnClick", function(self)
            if self.needKey then
                NLL.GearNeeds:RemoveNeed(
                    self.needKey
                )
                UI:RefreshGearPlans()
            end
        end)

        row.characterText = characterText
        row.itemText = itemText
        row.roleText = roleText
        row.sourceText = sourceText
        row.statusDrop = statusDrop
        row.remove = remove

        self.gearPlanRows[rowIndex] = row
    end

    local statusText = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontDisableSmall"
    )
    statusText:SetPoint(
        "BOTTOMLEFT",
        content,
        "BOTTOMLEFT",
        0,
        2
    )
    statusText:SetWidth(270)
    statusText:SetJustifyH("LEFT")

    local previous =
        self:CreateTextButton(content, "Previous", 76)
    previous:SetPoint(
        "BOTTOM",
        content,
        "BOTTOM",
        -48,
        0
    )

    local nextButton =
        self:CreateTextButton(content, "Next", 64)
    nextButton:SetPoint(
        "LEFT",
        previous,
        "RIGHT",
        4,
        0
    )

    local pageText = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    pageText:SetPoint(
        "LEFT",
        nextButton,
        "RIGHT",
        10,
        0
    )

    previous:SetScript("OnClick", function()
        if UI.gearPlansPage > 1 then
            UI.gearPlansPage =
                UI.gearPlansPage - 1

            UI:RefreshGearPlans()
        end
    end)

    nextButton:SetScript("OnClick", function()
        if UI.gearPlansPage
            < UI.gearPlansTotalPages then

            UI.gearPlansPage =
                UI.gearPlansPage + 1

            UI:RefreshGearPlans()
        end
    end)

    self.gearPlansStatus = statusText
    self.gearPlansPrevious = previous
    self.gearPlansNext = nextButton
    self.gearPlansPageText = pageText
    self.gearPlansPage = 1
    self.gearPlansTotalPages = 1
    self.gearPlansContent = content

    content:Hide()
end

function UI:RefreshGearPlans()
    local needs =
        NLL.GearNeeds:GetAllNeeds(
            self.gearPlanFilter
        )

    local count = #needs
    local totalPages =
        math.ceil(count / PLAN_ROWS)

    if totalPages < 1 then
        totalPages = 1
    end

    self.gearPlansTotalPages = totalPages
    self.gearPlansPage =
        self.gearPlansPage or 1

    if self.gearPlansPage > totalPages then
        self.gearPlansPage = totalPages
    end

    self.gearPlansStatus:SetText(
        tostring(count) ..
        " saved Gear Need(s)"
    )

    local firstIndex =
        ((self.gearPlansPage - 1) * PLAN_ROWS) + 1

    for rowIndex = 1, PLAN_ROWS do
        local row = self.gearPlanRows[rowIndex]
        local need =
            needs[firstIndex + rowIndex - 1]

        if need then
            local item =
                NLL.Data.MoltenCore:GetItem(
                    need.itemID
                )

            row.characterText:SetText(
                need.character or "Unknown"
            )

            row.itemText:SetText(
                item
                and item.name
                or tostring(need.itemID)
            )

            row.roleText:SetText(
                NLL:GetRoleLabel(need.role)
            )

            if need.source == "BOT_GEAR_PLAN" then
                row.sourceText:SetText("Bot Plan")
            elseif need.source
                == "RAID_LEADER_MANUAL" then

                row.sourceText:SetText("Manual")
            else
                row.sourceText:SetText(
                    need.source or "Unknown"
                )
            end

            row.statusDrop.needKey = need.key
            row.statusDrop.currentStatus =
                need.status

            UIDropDownMenu_SetText(
                row.statusDrop,
                need.status or "NEEDED"
            )

            row.remove.needKey = need.key
            row:Show()
        else
            row:Hide()
        end
    end

    self.gearPlansPageText:SetText(
        "Page " ..
        self.gearPlansPage ..
        " / " ..
        totalPages
    )

    if self.gearPlansPage <= 1 then
        self.gearPlansPrevious:Disable()
    else
        self.gearPlansPrevious:Enable()
    end

    if self.gearPlansPage >= totalPages then
        self.gearPlansNext:Disable()
    else
        self.gearPlansNext:Enable()
    end

    if self.RefreshOverview then
        self:RefreshOverview()
    end
end


-- ============================================================
-- RAID LEADER SUBMISSION INBOX
-- ============================================================

function UI:CreateInboxContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -66)
    content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)

    local status = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    status:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -2)
    status:SetWidth(720)
    status:SetJustifyH("LEFT")

    self.inboxStatus = status

    local header = CreateFrame("Frame", nil, content)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -28)
    header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -28)
    header:SetHeight(22)
    UI:RegisterSkinnedFrame(
        header,
        "header"
    )

    local function HeaderText(text, x, width)
        local f = header:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
        f:SetPoint("LEFT", header, "LEFT", x, 0)
        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    HeaderText("Player", 8, 155)
    HeaderText("Items", 168, 60)
    HeaderText("Role", 232, 135)
    HeaderText("Received", 372, 170)
    HeaderText("Status", 548, 100)

    self.inboxRows = {}

    for rowIndex = 1, 4 do
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint(
            "TOPLEFT",
            header,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 36)
        )
        row:SetPoint(
            "TOPRIGHT",
            header,
            "BOTTOMRIGHT",
            0,
            -((rowIndex - 1) * 36)
        )
        row:SetHeight(34)

        SetRowBackdrop(
            row,
            (rowIndex % 2) == 0
        )

        local playerText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        playerText:SetPoint("LEFT", row, "LEFT", 8, 0)
        playerText:SetWidth(155)
        playerText:SetJustifyH("LEFT")

        local countText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        countText:SetPoint("LEFT", row, "LEFT", 168, 0)
        countText:SetWidth(60)
        countText:SetJustifyH("LEFT")

        local roleText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        roleText:SetPoint("LEFT", row, "LEFT", 232, 0)
        roleText:SetWidth(135)
        roleText:SetJustifyH("LEFT")

        local receivedText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontDisableSmall"
            )
        receivedText:SetPoint("LEFT", row, "LEFT", 372, 0)
        receivedText:SetWidth(170)
        receivedText:SetJustifyH("LEFT")

        local statusText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        statusText:SetPoint("LEFT", row, "LEFT", 548, 0)
        statusText:SetWidth(100)
        statusText:SetJustifyH("LEFT")

        local review =
            self:CreateTextButton(
                row,
                "Review",
                66
            )
        review:SetPoint(
            "RIGHT",
            row,
            "RIGHT",
            -4,
            0
        )

        review:SetScript("OnClick", function(self)
            if self.submissionKey then
                UI.selectedSubmissionKey =
                    self.submissionKey
                UI.inboxItemPage = 1
                UI:RefreshInbox()
            end
        end)

        row.playerText = playerText
        row.countText = countText
        row.roleText = roleText
        row.receivedText = receivedText
        row.statusText = statusText
        row.review = review

        self.inboxRows[rowIndex] = row
    end

    local selectedTitle =
        content:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
    selectedTitle:SetPoint(
        "TOPLEFT",
        header,
        "BOTTOMLEFT",
        4,
        -155
    )
    selectedTitle:SetWidth(720)
    selectedTitle:SetJustifyH("LEFT")
    selectedTitle:SetText(
        "Select a submission to review its items."
    )

    self.inboxSelectedTitle = selectedTitle

    local itemHeader = CreateFrame("Frame", nil, content)
    itemHeader:SetPoint(
        "TOPLEFT",
        selectedTitle,
        "BOTTOMLEFT",
        -4,
        -8
    )
    itemHeader:SetPoint(
        "TOPRIGHT",
        content,
        "TOPRIGHT",
        0,
        -205
    )
    itemHeader:SetHeight(22)
    UI:RegisterSkinnedFrame(
        itemHeader,
        "header"
    )

    local itemHeaderText =
        itemHeader:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
    itemHeaderText:SetPoint(
        "LEFT",
        itemHeader,
        "LEFT",
        8,
        0
    )
    itemHeaderText:SetText("Submitted Item")

    local decisionHeader =
        itemHeader:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
    decisionHeader:SetPoint(
        "RIGHT",
        itemHeader,
        "RIGHT",
        -70,
        0
    )
    decisionHeader:SetText("Decision")

    self.inboxItemRows = {}

    for rowIndex = 1, 5 do
        local row = CreateFrame(
            "Frame",
            nil,
            content
        )

        row:SetPoint(
            "TOPLEFT",
            itemHeader,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 31)
        )
        row:SetPoint(
            "TOPRIGHT",
            itemHeader,
            "BOTTOMRIGHT",
            0,
            -((rowIndex - 1) * 31)
        )
        row:SetHeight(29)

        SetRowBackdrop(
            row,
            (rowIndex % 2) == 0
        )

        local itemText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        itemText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            8,
            0
        )
        itemText:SetWidth(600)
        itemText:SetJustifyH("LEFT")

        local toggle =
            self:CreateTextButton(
                row,
                "Reject",
                70
            )
        toggle:SetPoint(
            "RIGHT",
            row,
            "RIGHT",
            -4,
            0
        )

        toggle:SetScript(
            "OnClick",
            function(self)
                if self.submissionKey
                    and self.itemID then

                    NLL.Communication:
                        ToggleExcludedItem(
                            self.submissionKey,
                            self.itemID
                        )
                end
            end
        )

        row.itemText = itemText
        row.toggle = toggle

        self.inboxItemRows[rowIndex] = row
    end

    local previousItem =
        self:CreateTextButton(
            content,
            "Prev Items",
            82
        )
    previousItem:SetPoint(
        "BOTTOMLEFT",
        content,
        "BOTTOMLEFT",
        0,
        0
    )

    local nextItem =
        self:CreateTextButton(
            content,
            "Next Items",
            82
        )
    nextItem:SetPoint(
        "LEFT",
        previousItem,
        "RIGHT",
        4,
        0
    )

    local itemPageText =
        content:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )
    itemPageText:SetPoint(
        "LEFT",
        nextItem,
        "RIGHT",
        8,
        0
    )

    previousItem:SetScript(
        "OnClick",
        function()
            if UI.inboxItemPage > 1 then
                UI.inboxItemPage =
                    UI.inboxItemPage - 1
                UI:RefreshInbox()
            end
        end
    )

    nextItem:SetScript(
        "OnClick",
        function()
            if UI.inboxItemPage
                < UI.inboxItemTotalPages then

                UI.inboxItemPage =
                    UI.inboxItemPage + 1
                UI:RefreshInbox()
            end
        end
    )

    local accept =
        self:CreateTextButton(
            content,
            "Accept",
            72
        )
    accept:SetPoint(
        "BOTTOMRIGHT",
        content,
        "BOTTOMRIGHT",
        -82,
        0
    )

    accept:SetScript(
        "OnClick",
        function()
            if UI.selectedSubmissionKey then
                NLL.Communication:
                    AcceptSubmission(
                        UI.selectedSubmissionKey
                    )
            end
        end
    )

    local reject =
        self:CreateTextButton(
            content,
            "Reject",
            72
        )
    reject:SetPoint(
        "LEFT",
        accept,
        "RIGHT",
        4,
        0
    )

    reject:SetScript(
        "OnClick",
        function()
            if UI.selectedSubmissionKey then
                NLL.Communication:
                    RejectSubmission(
                        UI.selectedSubmissionKey
                    )
            end
        end
    )

    self.inboxPreviousItem = previousItem
    self.inboxNextItem = nextItem
    self.inboxItemPageText = itemPageText
    self.inboxAcceptButton = accept
    self.inboxRejectButton = reject
    self.inboxPage = 1
    self.inboxItemPage = 1
    self.inboxItemTotalPages = 1
    self.inboxContent = content

    content:Hide()
end

function UI:RefreshInbox()
    local submissions =
        NLL.Communication:
            GetInboxSubmissions()

    local count = #submissions

    if NLL.Communication:IsSelfRaidLeader() then
        self.inboxStatus:SetText(
            tostring(count) ..
            " saved submission(s). " ..
            "Only the raid leader can receive new submissions."
        )
    else
        self.inboxStatus:SetText(
            tostring(count) ..
            " saved submission(s). " ..
            "|cffff9933You are not the current raid leader.|r"
        )
    end

    for rowIndex = 1, 4 do
        local row = self.inboxRows[rowIndex]
        local submission =
            submissions[rowIndex]

        if submission then
            local role =
                NLL.Database:
                    GetRoleAssignment(
                        submission.player
                    )

            row.playerText:SetText(
                submission.player or "Unknown"
            )
            row.countText:SetText(
                tostring(
                    #(submission.itemIDs or {})
                )
            )
            row.roleText:SetText(
                NLL:GetRoleLabel(role)
            )
            row.receivedText:SetText(
                submission.receivedAt or ""
            )
            row.statusText:SetText(
                submission.status or "PENDING"
            )
            row.review.submissionKey =
                submission.key

            row:Show()
        else
            row:Hide()
        end
    end

    local selected =
        self.selectedSubmissionKey
        and NLL.Communication:
            GetSubmission(
                self.selectedSubmissionKey
            )

    if not selected then
        self.inboxSelectedTitle:SetText(
            "Select a submission to review its items."
        )

        for i = 1, #self.inboxItemRows do
            self.inboxItemRows[i]:Hide()
        end

        self.inboxAcceptButton:Disable()
        self.inboxRejectButton:Disable()
        self.inboxPreviousItem:Disable()
        self.inboxNextItem:Disable()
        self.inboxItemPageText:SetText("")
        return
    end

    local conflicts =
        NLL.Communication:
            GetConflictCount(selected)

    self.inboxSelectedTitle:SetText(
        selected.player ..
        " - " ..
        tostring(
            #(selected.itemIDs or {})
        ) ..
        " submitted item(s), " ..
        tostring(conflicts) ..
        " existing manual/bot conflict(s)."
    )

    local totalItems =
        #(selected.itemIDs or {})

    local totalPages =
        math.ceil(totalItems / 5)

    if totalPages < 1 then
        totalPages = 1
    end

    self.inboxItemTotalPages = totalPages

    if self.inboxItemPage > totalPages then
        self.inboxItemPage = totalPages
    end

    local firstIndex =
        ((self.inboxItemPage - 1) * 5) + 1

    selected.excluded =
        selected.excluded or {}

    for rowIndex = 1, 5 do
        local row =
            self.inboxItemRows[rowIndex]

        local itemID =
            selected.itemIDs[
                firstIndex + rowIndex - 1
            ]

        if itemID then
            local item =
                NLL.Data.MoltenCore:
                    GetItem(itemID)

            local conflict =
                NLL.GearNeeds:
                    HasOtherSourceNeed(
                        selected.player,
                        selected.raidKey,
                        itemID
                    )

            local text =
                item
                and item.name
                or tostring(itemID)

            if conflict then
                text =
                    text ..
                    " |cffff9933[existing manual/bot need]|r"
            end

            row.itemText:SetText(text)
            row.toggle.submissionKey =
                selected.key
            row.toggle.itemID = itemID

            if selected.excluded[itemID] then
                row.toggle.label:SetText("Restore")
            else
                row.toggle.label:SetText("Reject")
            end

            if selected.status == "PENDING" then
                row.toggle:Enable()
            else
                row.toggle:Disable()
            end

            row:Show()
        else
            row:Hide()
        end
    end

    self.inboxItemPageText:SetText(
        "Page " ..
        self.inboxItemPage ..
        " / " ..
        totalPages
    )

    if self.inboxItemPage <= 1 then
        self.inboxPreviousItem:Disable()
    else
        self.inboxPreviousItem:Enable()
    end

    if self.inboxItemPage >= totalPages then
        self.inboxNextItem:Disable()
    else
        self.inboxNextItem:Enable()
    end

    if selected.status == "PENDING" then
        self.inboxAcceptButton:Enable()
        self.inboxRejectButton:Enable()
    else
        self.inboxAcceptButton:Disable()
        self.inboxRejectButton:Disable()
    end
end

function UI:RefreshWishlistPanel()
    if not self.wishlistPanel then
        return
    end

    self.localWishlistContent:Hide()
    self.gearPlansContent:Hide()
    self.inboxContent:Hide()
    if self.simulationWishlistContent then self.simulationWishlistContent:Hide() end
    local sim=NLL.DebugSimulator
    if sim and sim:IsActive() then
        self.wishlistMyButton:Disable()
        self.wishlistPlansButton:Disable()
        self.wishlistInboxButton:Disable()
        self.simulationWishlistContent:Show()
        self:RefreshSimulationWishlist()
        return
    end
    self.wishlistMyButton:Enable()
    self.wishlistPlansButton:Enable()
    self.wishlistInboxButton:Enable()

    self:SetButtonState(
        self.wishlistMyButton,
        "normal"
    )

    self:SetButtonState(
        self.wishlistPlansButton,
        "normal"
    )

    self:SetButtonState(
        self.wishlistInboxButton,
        "normal"
    )

    if self.wishlistMode == "plans" then
        self.gearPlansContent:Show()

        self:SetButtonState(
            self.wishlistPlansButton,
            "active"
        )

        self:RefreshGearPlans()
        return
    end

    if self.wishlistMode == "inbox" then
        self.inboxContent:Show()

        self:SetButtonState(
            self.wishlistInboxButton,
            "active"
        )

        self:RefreshInbox()
        return
    end

    self.wishlistMode = "local"
    self.localWishlistContent:Show()

    self:SetButtonState(
        self.wishlistMyButton,
        "active"
    )

    self:RefreshLocalWishlist()
end


-- Normal Wishlists window, but with a separate read-only, in-memory
-- fake Gear Plans view while a Debug Raid Simulator scenario is active.
function UI:CreateSimulationWishlistContent(parent)
    local panel=CreateFrame("Frame",nil,parent)
    panel:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-65)
    panel:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-8,8)
    local status=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("TOPLEFT",panel,"TOPLEFT",8,-4)
    status:SetWidth(740);status:SetJustifyH("LEFT")
    status:SetText("[SIMULATION] Fake Playerbot Gear Plans - no saved data")
    local header=CreateFrame("Frame",nil,panel)
    header:SetPoint("TOPLEFT",panel,"TOPLEFT",4,-27)
    header:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-4,-27)
    header:SetHeight(24);self:RegisterSkinnedFrame(header,"header")
    local function Head(txt,x,w)
        local f=header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        f:SetPoint("LEFT",header,"LEFT",x,0);f:SetWidth(w);f:SetText(txt)
        f:SetJustifyH("LEFT")
    end
    Head("Fake Playerbot",9,165);Head("Class / Role",180,183)
    Head("Wanted Loot",380,310);Head("Status",695,85)
    self.simulationWishlistRows={}
    for i=1,9 do
        local row=CreateFrame("Frame",nil,panel)
        row:SetPoint("TOPLEFT",header,"BOTTOMLEFT",0,-(i-1)*36)
        row:SetPoint("TOPRIGHT",header,"BOTTOMRIGHT",0,-(i-1)*36)
        row:SetHeight(34)
        self:RegisterSkinnedFrame(row,i%2==0 and "rowAlt" or "row")
        local fields={}
        for j,s in ipairs({{9,165},{180,183},{380,310},{695,85}}) do
            local f=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            f:SetPoint("LEFT",row,"LEFT",s[1],0)
            f:SetWidth(s[2]);f:SetJustifyH("LEFT")
            fields[j]=f
        end
        row.fields=fields;self.simulationWishlistRows[i]=row
    end
    local back=self:CreateTextButton(panel,"Previous",82)
    back:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",6,4)
    local nextB=self:CreateTextButton(panel,"Next",65)
    nextB:SetPoint("LEFT",back,"RIGHT",7,0)
    back:SetScript("OnClick",function()
        UI.simulationNeedsPage=math.max(1,(UI.simulationNeedsPage or 1)-1)
        UI:RefreshSimulationWishlist()
    end)
    nextB:SetScript("OnClick",function()
        UI.simulationNeedsPage=(UI.simulationNeedsPage or 1)+1
        UI:RefreshSimulationWishlist()
    end)
    self.simulationWishlistPrev=back;self.simulationWishlistNext=nextB
    local pages=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    pages:SetPoint("LEFT",nextB,"RIGHT",10,0)
    self.simulationWishlistPageText=pages
    self.simulationWishlistContent=panel
    panel:Hide()
end
function UI:RefreshSimulationWishlist()
    if not self.simulationWishlistContent then return end
    local S=NLL.DebugSimulator
    local rows=S and S:GetNeeds() or {}
    local count=#rows
    local pages=math.max(1,math.ceil(count/9))
    self.simulationNeedsPage=math.min(pages,math.max(1,self.simulationNeedsPage or 1))
    for i,row in ipairs(self.simulationWishlistRows) do
        local r=rows[(self.simulationNeedsPage-1)*9+i]
        if r then
            row.fields[1]:SetText(r.character)
            row.fields[2]:SetText(NLL:GetClassLabel(r.classFile).." / "..NLL:GetRoleLabel(r.role))
            row.fields[3]:SetText(r.itemName)
            row.fields[4]:SetText(r.state)
            row:Show()
        else row:Hide() end
    end
    self.simulationWishlistPageText:SetText("Page "..self.simulationNeedsPage.."/"..pages..
        " ("..count.." fake needs)")
    if self.simulationNeedsPage<=1 then self.simulationWishlistPrev:Disable()
    else self.simulationWishlistPrev:Enable() end
    if self.simulationNeedsPage>=pages then self.simulationWishlistNext:Disable()
    else self.simulationWishlistNext:Enable() end
end
