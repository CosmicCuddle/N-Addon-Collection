if not MultiBot then return end

local GroupActionsUI = MultiBot.GroupActionsUI or {}
MultiBot.GroupActionsUI = GroupActionsUI

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local ROLL_MENU_Y = 102
local ROLL_WINDOW_WIDTH = 240
local ROLL_WINDOW_HEIGHT = 245
local ROLL_CONTENT_SIDE_PADDING = 10
local ROLL_ITEM_LINK_MAX = 160

local MENU_BUTTONS = {
    { name = "Drink", x = 0, y = 0, icon = "inv_drink_24_sealwhey", tip = "tips.drink.group", command = "drink" },
    { name = "Release", x = 0, y = 34, icon = "achievement_bg_xkills_avgraveyard", tip = "tips.release.group", command = "release" },
    { name = "Revive", x = 0, y = 68, icon = "spell_holy_guardianspirit", tip = "tips.revive.group", command = "revive" },
}

local SUMMON_BUTTON = {
    name = "Summon",
    x = 68,
    y = 0,
    icon = "ability_hunter_beastcall",
    tip = "tips.summon.group",
    command = "summon",
}

local function trim(value)
    if type(value) ~= "string" then
        return ""
    end

    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function addRollBackdrop(window)
    if not window or not window.frame or not window.content then
        return
    end

    local backdrop = CreateFrame("Frame", nil, window.frame)
    backdrop:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 12, -32)
    backdrop:SetPoint("BOTTOMRIGHT", window.frame, "BOTTOMRIGHT", -12, 13)

    if backdrop.SetFrameLevel and window.frame.GetFrameLevel then
        backdrop:SetFrameLevel(window.frame:GetFrameLevel() + 1)
    end
    if window.content.SetFrameLevel and backdrop.GetFrameLevel then
        window.content:SetFrameLevel(backdrop:GetFrameLevel() + 1)
    end

    backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })

    if backdrop.SetBackdropColor then
        backdrop:SetBackdropColor(0.06, 0.06, 0.08, 0.90)
    end

    if backdrop.SetBackdropBorderColor then
        backdrop:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95)
    end

    window.content:ClearAllPoints()
    window.content:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 12 + ROLL_CONTENT_SIDE_PADDING, -42)
    window.content:SetPoint("BOTTOMRIGHT", window.frame, "BOTTOMRIGHT", -(12 + ROLL_CONTENT_SIDE_PADDING), 13)
    window.content.width = math.max(0, ROLL_WINDOW_WIDTH - (2 * (12 + ROLL_CONTENT_SIDE_PADDING)))
    window.rollBackdrop = backdrop
end

local function createGroupCommand(buttonHost, definition)
    local button = buttonHost.addButton(
        definition.name,
        definition.x,
        definition.y,
        definition.icon,
        MultiBot.L(definition.tip)
    )

    button.doLeft = function()
        MultiBot.ActionToGroup(definition.command)
    end

    return button
end

local function getRollStatusText(result)
    result = type(result) == "table" and result or {}
    local reason = string.upper(trim(result.reason or ""))

    if result.status == "ok" then
        return string.format(MultiBot.L("roll.status.sent"), tonumber(result.invoked or 0) or 0)
    end

    if result.status == "timeout" or reason == "TIMEOUT" then
        return MultiBot.L("roll.status.timeout")
    elseif reason == "NO_GROUP" then
        return MultiBot.L("roll.status.no_group")
    elseif reason == "NO_BOTS" then
        return MultiBot.L("roll.status.no_bots")
    elseif reason == "FORBIDDEN" then
        return MultiBot.L("roll.status.forbidden")
    elseif reason == "RATE_LIMIT" then
        return MultiBot.L("roll.status.rate_limit")
    elseif reason == "BAD_ITEM" or reason == "BAD_ENCODING" then
        return MultiBot.L("roll.status.bad_item")
    end

    return MultiBot.L("roll.status.failed")
end

function GroupActionsUI:SetRollStatus(text)
    if self.rollStatus and self.rollStatus.SetText then
        self.rollStatus:SetText(text or "")
    end
end

function GroupActionsUI:RunRoll(itemLink, requireItem)
    if self.rollPending then
        return false
    end

    if not MultiBot.Comm or type(MultiBot.Comm.RunGroupRoll) ~= "function" then
        self:SetRollStatus(MultiBot.L("roll.status.bridge_unavailable"))
        return false
    end

    itemLink = trim(itemLink or "")
    if requireItem and itemLink == "" then
        self:SetRollStatus(MultiBot.L("roll.status.bad_item"))
        return false
    end
    if itemLink ~= "" and (string.len(itemLink) > ROLL_ITEM_LINK_MAX or not string.find(itemLink, "|Hitem:", 1, true)) then
        self:SetRollStatus(MultiBot.L("roll.status.bad_item"))
        return false
    end

    self.rollPending = true
    self:SetRollStatus(MultiBot.L("roll.status.sending"))
    local token = MultiBot.Comm.RunGroupRoll(itemLink, function(result)
        GroupActionsUI.rollPending = false
        GroupActionsUI:SetRollStatus(getRollStatusText(result))
    end)

    if not token then
        self.rollPending = false
        self:SetRollStatus(MultiBot.L("roll.status.bridge_unavailable"))
        return false
    end

    return true
end

function GroupActionsUI:EnsureRollWindow()
    if self.rollWindow then
        return self.rollWindow
    end

    if not AceGUI then
        return nil
    end

    local window = AceGUI:Create("Window")
    window:SetTitle(MultiBot.L("roll.window.title"))
    window:SetWidth(ROLL_WINDOW_WIDTH)
    window:SetHeight(ROLL_WINDOW_HEIGHT)
    window:EnableResize(false)
    window:SetLayout("Flow")

    addRollBackdrop(window)

    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel and window.frame then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then
        MultiBot.SetAceWindowCloseToHide(window)
    else
        window:SetCallback("OnClose", function(widget)
            if widget and widget.frame then
                widget.frame:Hide()
            end
        end)
    end

    if MultiBot.RegisterAceWindowEscapeClose then
        MultiBot.RegisterAceWindowEscapeClose(window, "GroupRoll")
    end
    if MultiBot.BindAceWindowPosition then
        MultiBot.BindAceWindowPosition(window, "group_roll_popup")
    end

    local normalButton = AceGUI:Create("Button")
    normalButton:SetText(MultiBot.L("roll.window.normal"))
    normalButton:SetFullWidth(true)
    normalButton:SetCallback("OnClick", function()
        GroupActionsUI:RunRoll("")
    end)
    window:AddChild(normalButton)

    local hint = AceGUI:Create("Label")
    hint:SetText(MultiBot.L("roll.window.item_hint"))
    hint:SetFullWidth(true)
    window:AddChild(hint)

    local itemEdit = AceGUI:Create("EditBox")
    itemEdit:SetLabel(MultiBot.L("roll.window.item_label"))
    itemEdit:SetFullWidth(true)
    itemEdit:SetMaxLetters(ROLL_ITEM_LINK_MAX)
    itemEdit:DisableButton(true)
    window:AddChild(itemEdit)

    local itemButton = AceGUI:Create("Button")
    itemButton:SetText(MultiBot.L("roll.window.item_button"))
    itemButton:SetFullWidth(true)
    itemButton:SetCallback("OnClick", function()
        GroupActionsUI:RunRoll(itemEdit:GetText() or "", true)
    end)
    window:AddChild(itemButton)

    local status = AceGUI:Create("Label")
    status:SetText(MultiBot.L("roll.status.ready"))
    status:SetFullWidth(true)
    window:AddChild(status)

    if window.frame then
        window.frame:Hide()
    end

    self.rollWindow = window
    self.rollItemEdit = itemEdit
    self.rollStatus = status
    return window
end

function GroupActionsUI:ShowRollWindow()
    local window = self:EnsureRollWindow()
    if not window or not window.frame then
        return false
    end

    window:SetTitle(MultiBot.L("roll.window.title"))
    window.frame:Show()
    window.frame:Raise()
    if not self.rollPending then
        self:SetRollStatus(MultiBot.L("roll.status.ready"))
    end

    if self.rollItemEdit and self.rollItemEdit.editbox then
        self.rollItemEdit.editbox:SetFocus()
    end

    return true
end

function MultiBot.InitializeGroupActionsUI(tRight)
    if GroupActionsUI.initialized then
        return GroupActionsUI
    end

    if not tRight or not tRight.addButton or not tRight.addFrame then
        return nil
    end

    local mainButton = tRight.addButton("GroupActions", 34, 0, "Spell_unused2", MultiBot.L("tips.group.group"))
    local menu = tRight.addFrame("GroupActionsMenu", 34, 34, 32, 130)
    menu:Hide()

    mainButton.doLeft = function(owner)
        local targetMenu = owner and owner.parent and owner.parent.frames and owner.parent.frames["GroupActionsMenu"]
        if not targetMenu then
            return
        end

        if targetMenu:IsShown() then
            targetMenu:Hide()
            return
        end

        targetMenu:Show()
    end

    for _, definition in ipairs(MENU_BUTTONS) do
        createGroupCommand(menu, definition)
    end

    local rollButton = menu.addButton("Roll", 0, ROLL_MENU_Y, "INV_Misc_Dice_01", MultiBot.L("tips.roll.group"))
    rollButton.doLeft = function()
        menu:Hide()
        GroupActionsUI:ShowRollWindow()
    end

    local summonButton = createGroupCommand(tRight, SUMMON_BUTTON)

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tRight, "RightRoot", {
            { name = "GroupActions", frameName = "GroupActionsMenu" },
            { name = "Summon" },
        })
    end

    GroupActionsUI.initialized = true
    GroupActionsUI.mainButton = mainButton
    GroupActionsUI.menu = menu
    GroupActionsUI.rollButton = rollButton
    GroupActionsUI.summonButton = summonButton

    return GroupActionsUI
end
