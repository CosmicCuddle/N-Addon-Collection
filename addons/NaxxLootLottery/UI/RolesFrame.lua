-- ============================================================
-- Naxxramas Loot Ledger
-- UI/RolesFrame.lua
-- Compact Phase 2 roster UI retained in Phase 3.
-- ============================================================

local NLL = NaxxLootLottery
local UI = NLL.UI

local ROWS_PER_PAGE = 11

local function RowBackdrop(row, alternate)
    UI:RegisterSkinnedFrame(
        row,
        alternate
            and "rowAlt"
            or "row"
    )
end

function UI:CreateRolesPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    local heading = panel:CreateFontString(
        nil, "OVERLAY", "GameFontNormal"
    )
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
    heading:SetText("Raid Roles")

    local status = panel:CreateFontString(
        nil, "OVERLAY", "GameFontHighlightSmall"
    )
    status:SetPoint("LEFT", heading, "RIGHT", 16, 0)
    status:SetWidth(430)
    status:SetJustifyH("LEFT")
    self.rolesRosterStatus = status

    local refresh = self:CreateTextButton(panel, "Refresh", 72)
    refresh:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -4)
    refresh:SetScript("OnClick", function()
        NLL.Roster:Refresh()
    end)

    local header = CreateFrame("Frame", nil, panel)
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -40)
    header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -40)
    header:SetHeight(22)
    UI:RegisterSkinnedFrame(
        header,
        "header"
    )

    local function HeaderText(text, x, width)
        local f = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f:SetPoint("LEFT", header, "LEFT", x, 0)
        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    HeaderText("Grp", 8, 35)
    HeaderText("Character", 50, 190)
    HeaderText("Class", 245, 115)
    HeaderText("Status", 365, 165)
    HeaderText("NLL Role", 535, 220)

    self.roleRows = {}

    for rowIndex = 1, ROWS_PER_PAGE do
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint(
            "TOPLEFT", header, "BOTTOMLEFT",
            0, -((rowIndex - 1) * 34)
        )
        row:SetPoint(
            "TOPRIGHT", header, "BOTTOMRIGHT",
            0, -((rowIndex - 1) * 34)
        )
        row:SetHeight(32)
        RowBackdrop(row, (rowIndex % 2) == 0)

        local groupText = row:CreateFontString(
            nil, "OVERLAY", "GameFontHighlightSmall"
        )
        groupText:SetPoint("LEFT", row, "LEFT", 8, 0)
        groupText:SetWidth(35)
        groupText:SetJustifyH("LEFT")

        local nameText = row:CreateFontString(
            nil, "OVERLAY", "GameFontHighlight"
        )
        nameText:SetPoint("LEFT", row, "LEFT", 50, 0)
        nameText:SetWidth(190)
        nameText:SetJustifyH("LEFT")

        local classText = row:CreateFontString(
            nil, "OVERLAY", "GameFontHighlightSmall"
        )
        classText:SetPoint("LEFT", row, "LEFT", 245, 0)
        classText:SetWidth(115)
        classText:SetJustifyH("LEFT")

        local statusText = row:CreateFontString(
            nil, "OVERLAY", "GameFontHighlightSmall"
        )
        statusText:SetPoint("LEFT", row, "LEFT", 365, 0)
        statusText:SetWidth(165)
        statusText:SetJustifyH("LEFT")

        local dropdownName =
            "NaxxLootLotteryRoleDropDownV3_" .. tostring(rowIndex)

        local dropdown = CreateFrame(
            "Frame", dropdownName, row, "UIDropDownMenuTemplate"
        )
        dropdown:SetPoint("LEFT", row, "LEFT", 515, -2)
        UIDropDownMenu_SetWidth(dropdown, 190)

        UIDropDownMenu_Initialize(dropdown, function()
            local currentRole = dropdown.currentRole

            local info = UIDropDownMenu_CreateInfo()
            info.text = "Unassigned"
            info.checked = currentRole == nil
            info.func = function()
                if dropdown.playerName then
                    NLL.Roster:SetRole(dropdown.playerName, nil)
                end
            end
            UIDropDownMenu_AddButton(info)

            for i = 1, #NLL.roles do
                local role = NLL.roles[i]
                local roleID = role.id

                info = UIDropDownMenu_CreateInfo()
                info.text = role.label
                info.checked = currentRole == roleID
                info.func = function()
                    if dropdown.playerName then
                        NLL.Roster:SetRole(dropdown.playerName, roleID)
                    end
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        row.groupText = groupText
        row.nameText = nameText
        row.classText = classText
        row.statusText = statusText
        row.dropdown = dropdown
        self.roleRows[rowIndex] = row
    end

    local previous = self:CreateTextButton(panel, "Previous", 76)
    previous:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 8, 8)
    previous:SetScript("OnClick", function()
        if UI.rolesPage > 1 then
            UI.rolesPage = UI.rolesPage - 1
            UI:RefreshRolesPanel()
        end
    end)

    local nextButton = self:CreateTextButton(panel, "Next", 64)
    nextButton:SetPoint("LEFT", previous, "RIGHT", 4, 0)
    nextButton:SetScript("OnClick", function()
        if UI.rolesPage < UI.rolesTotalPages then
            UI.rolesPage = UI.rolesPage + 1
            UI:RefreshRolesPanel()
        end
    end)

    local pageText = panel:CreateFontString(
        nil, "OVERLAY", "GameFontHighlightSmall"
    )
    pageText:SetPoint("LEFT", nextButton, "RIGHT", 10, 0)

    self.previousRolesButton = previous
    self.nextRolesButton = nextButton
    self.rolesPageText = pageText
    self.rolesPage = 1
    self.rolesTotalPages = 1
    self.rolesPanel = panel

    panel:Hide()
end

function UI:RefreshRolesPanel()
    if not self.rolesPanel then
        return
    end

    local members = NLL.Roster:GetMembers() or {}
    local count = #members
    local totalPages = math.ceil(count / ROWS_PER_PAGE)

    if totalPages < 1 then
        totalPages = 1
    end

    self.rolesTotalPages = totalPages
    self.rolesPage = self.rolesPage or 1

    if self.rolesPage > totalPages then
        self.rolesPage = totalPages
    end

    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        self.rolesRosterStatus:SetText(
            "|cffffcc33[SIMULATION] |r"..count.." bots / "..
            math.ceil(count/5).." groups. Temporary data.")
    elseif count == 0 then
        self.rolesRosterStatus:SetText(
            "|cffaaaaaaNo raid detected.|r"
        )
    else
        self.rolesRosterStatus:SetText(
            tostring(count) ..
            " raid members. Assignments save immediately."
        )
    end

    local firstIndex =
        ((self.rolesPage - 1) * ROWS_PER_PAGE) + 1

    for rowIndex = 1, ROWS_PER_PAGE do
        local row = self.roleRows[rowIndex]
        local member = members[firstIndex + rowIndex - 1]

        if member then
            row.groupText:SetText(tostring(member.subgroup or "-"))
            row.nameText:SetText(member.name or "Unknown")

            local color =
                member.classFile and RAID_CLASS_COLORS
                and RAID_CLASS_COLORS[member.classFile]

            if color then
                row.nameText:SetTextColor(color.r, color.g, color.b)
            else
                row.nameText:SetTextColor(1, 1, 1)
            end

            row.classText:SetText(member.className or "Unknown")

            local status = member.online and "Online" or "Offline"
            if member.simulationOnly then status = "FAKE / "..status end

            if member.isDead then
                status = status .. " / Dead"
            end

            if member.isMasterLooter then
                status = status .. " / ML"
            elseif member.rank == 2 then
                status = status .. " / Leader"
            elseif member.rank == 1 then
                status = status .. " / Assist"
            end

            row.statusText:SetText(status)

            row.dropdown.playerName = member.name
            row.dropdown.currentRole = member.assignedRole

            UIDropDownMenu_SetText(
                row.dropdown,
                NLL:GetRoleLabel(member.assignedRole)
            )

            row:Show()
        else
            row:Hide()
        end
    end

    self.rolesPageText:SetText(
        "Page " .. self.rolesPage .. " / " .. totalPages
    )

    if self.rolesPage <= 1 then
        self.previousRolesButton:Disable()
    else
        self.previousRolesButton:Enable()
    end

    if self.rolesPage >= totalPages then
        self.nextRolesButton:Disable()
    else
        self.nextRolesButton:Enable()
    end
end
