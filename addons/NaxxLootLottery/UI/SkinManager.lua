-- ============================================================
-- Naxxramas Loot Ledger
-- UI/SkinManager.lua
--
-- Centralized appearance system.
-- Functionality and data never depend on the selected skin.
--
-- v0.1.0.7:
--   DARK     = current NLL interface
--   VANILLA  = parchment / old Blizzard-style interface
-- ============================================================

local NLL = NaxxLootLottery
NLL.UI = NLL.UI or {}
local UI = NLL.UI

UI.skinnedFrames = UI.skinnedFrames or {}

UI.skins = {
    DARK = {
        name = "NLL Dark",

        mainBackdrop = {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = {
                left = 3,
                right = 3,
                top = 3,
                bottom = 3
            }
        },

        contentBackdrop = {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            tile = true,
            tileSize = 16,
            edgeSize = 0,
            insets = {
                left = 0,
                right = 0,
                top = 0,
                bottom = 0
            }
        },

        main = { 0.035, 0.035, 0.045, 0.96 },
        mainBorder = { 0.28, 0.28, 0.32, 1 },

        content = { 0, 0, 0, 0.03 },

        title = { 0.08, 0.08, 0.10, 1 },
        header = { 0.12, 0.12, 0.14, 1 },

        row = { 0.045, 0.045, 0.055, 0.90 },
        rowAlt = { 0.075, 0.075, 0.09, 0.90 },

        button = { 0.09, 0.09, 0.11, 1 },
        buttonHover = { 0.17, 0.17, 0.20, 1 },
        buttonActive = { 0.22, 0.16, 0.05, 1 },
        buttonDanger = { 0.20, 0.09, 0.09, 1 },

        border = { 0.28, 0.28, 0.32, 1 }
    },

    VANILLA = {
        name = "Vanilla WoW",

        -- Old Blizzard dialog frame around the addon.
        mainBackdrop = {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 28,
            insets = {
                left = 9,
                right = 9,
                top = 9,
                bottom = 9
            }
        },

        -- Vanilla parchment artwork is rendered using the exact
        -- four textures from Wrath 3.3.5 QuestFramePanelTemplate.
        contentBackdrop = {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = false,
            edgeSize = 18,
            insets = {
                left = 6,
                right = 6,
                top = 6,
                bottom = 6
            }
        },

        main = { 0.95, 0.86, 0.67, 1 },
        mainBorder = { 1, 0.86, 0.42, 1 },

        -- Tint the QuestBG slightly warm rather than bright white.
        content = { 0.86, 0.67, 0.36, 1 },

        title = { 0.19, 0.105, 0.035, 0.98 },
        header = { 0.28, 0.16, 0.05, 0.58 },

        -- Let the parchment show through the list/table rows.
        row = { 0.16, 0.085, 0.025, 0.30 },
        rowAlt = { 0.24, 0.125, 0.035, 0.36 },

        border = { 0.85, 0.63, 0.22, 1 }
    }
}

local function ApplyColor(
    frame,
    methodName,
    color
)
    if not frame or not color then
        return
    end

    local method = frame[methodName]

    if not method then
        return
    end

    method(
        frame,
        color[1],
        color[2],
        color[3],
        color[4]
    )
end

local function ClearButtonTextures(button)
    button:SetNormalTexture(nil)
    button:SetPushedTexture(nil)
    button:SetHighlightTexture(nil)
end

local function ApplyVanillaButtonTextures(button)
    button:SetBackdrop(nil)

    local baseWidth =
        button.nllBaseWidth
        or button:GetWidth()
        or 90

    local baseHeight =
        button.nllBaseHeight
        or 22

    local wantedWidth = baseWidth

    if button.label
        and button.label.GetStringWidth then

        local textWidth =
            button.label:GetStringWidth()
            or 0

        wantedWidth =
            math.max(
                baseWidth,
                math.ceil(textWidth + 34)
            )
    end

    button:SetWidth(wantedWidth)

    button:SetHeight(
        math.max(
            baseHeight,
            24
        )
    )

    button:SetNormalTexture(
        "Interface\\Buttons\\UI-Panel-Button-Up"
    )

    button:SetPushedTexture(
        "Interface\\Buttons\\UI-Panel-Button-Down"
    )

    button:SetHighlightTexture(
        "Interface\\Buttons\\UI-Panel-Button-Highlight",
        "ADD"
    )

    local normal =
        button:GetNormalTexture()

    local pushed =
        button:GetPushedTexture()

    local highlight =
        button:GetHighlightTexture()

    if normal then
        normal:SetAllPoints(button)

        if button.nllButtonState == "danger" then
            normal:SetVertexColor(
                1,
                0.42,
                0.30,
                1
            )
        elseif button.nllButtonState == "active" then
            normal:SetVertexColor(
                1,
                0.80,
                0.25,
                1
            )
        else
            normal:SetVertexColor(
                1,
                1,
                1,
                1
            )
        end
    end

    if pushed then
        pushed:SetAllPoints(button)

        if button.nllButtonState == "danger" then
            pushed:SetVertexColor(
                0.90,
                0.28,
                0.20,
                1
            )
        elseif button.nllButtonState == "active" then
            pushed:SetVertexColor(
                0.95,
                0.67,
                0.18,
                1
            )
        else
            pushed:SetVertexColor(
                1,
                1,
                1,
                1
            )
        end
    end

    if highlight then
        highlight:SetAllPoints(button)
    end
end

local function RestoreDarkButtonSize(button)
    if button.nllBaseWidth then
        button:SetWidth(
            button.nllBaseWidth
        )
    end

    if button.nllBaseHeight then
        button:SetHeight(
            button.nllBaseHeight
        )
    end
end

function UI:GetSkinID()
    if NLL.db
        and NLL.db.settings
        and NLL.db.settings.skin == "VANILLA" then

        return "VANILLA"
    end

    return "DARK"
end

function UI:GetSkin()
    return self.skins[self:GetSkinID()]
        or self.skins.DARK
end

function UI:RegisterSkinnedFrame(
    frame,
    kind
)
    if not frame then
        return
    end

    frame.nllSkinKind = kind or "row"

    if not frame.nllSkinRegistered then
        frame.nllSkinRegistered = true

        table.insert(
            self.skinnedFrames,
            frame
        )
    end

    self:ApplySkinToFrame(frame)
end

function UI:SetButtonState(
    button,
    state
)
    if not button then
        return
    end

    button.nllButtonState =
        state or "normal"

    self:ApplySkinToFrame(button)
end

local function EnsureParchmentLayers(frame)
    if frame.nllQuestTopLeft
        and frame.nllQuestTopRight
        and frame.nllQuestBotLeft
        and frame.nllQuestBotRight then

        return
    end

    local base =
        frame:CreateTexture(
            nil,
            "BACKGROUND"
        )

    base:SetTexture(
        "Interface\\Buttons\\WHITE8X8"
    )

    base:SetAllPoints(frame)

    local topLeft =
        frame:CreateTexture(
            nil,
            "BACKGROUND"
        )

    topLeft:SetTexture(
        "Interface\\QuestFrame\\UI-QuestGreeting-TopLeft"
    )

    local topRight =
        frame:CreateTexture(
            nil,
            "BACKGROUND"
        )

    topRight:SetTexture(
        "Interface\\QuestFrame\\UI-QuestGreeting-TopRight"
    )

    local botLeft =
        frame:CreateTexture(
            nil,
            "BACKGROUND"
        )

    botLeft:SetTexture(
        "Interface\\QuestFrame\\UI-QuestGreeting-BotLeft"
    )

    local botRight =
        frame:CreateTexture(
            nil,
            "BACKGROUND"
        )

    botRight:SetTexture(
        "Interface\\QuestFrame\\UI-QuestGreeting-BotRight"
    )

    -- Wrath QuestFramePanelTemplate is 384 x 512:
    -- left textures are 256 px wide, right textures are 128 px.
    -- Preserve that 2/3 : 1/3 horizontal proportion while scaling.
    topLeft:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        0,
        0
    )

    topLeft:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "CENTER",
        frame:GetWidth() / 6,
        0
    )

    topRight:SetPoint(
        "TOPLEFT",
        topLeft,
        "TOPRIGHT",
        0,
        0
    )

    topRight:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "RIGHT",
        0,
        0
    )

    botLeft:SetPoint(
        "TOPLEFT",
        frame,
        "LEFT",
        0,
        0
    )

    botLeft:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOM",
        frame:GetWidth() / 6,
        0
    )

    botRight:SetPoint(
        "TOPLEFT",
        botLeft,
        "TOPRIGHT",
        0,
        0
    )

    botRight:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        0,
        0
    )

    frame.nllParchmentBase = base
    frame.nllQuestTopLeft = topLeft
    frame.nllQuestTopRight = topRight
    frame.nllQuestBotLeft = botLeft
    frame.nllQuestBotRight = botRight
end

local function ShowVanillaParchment(frame)
    EnsureParchmentLayers(frame)

    frame.nllParchmentBase:SetVertexColor(
        0.86,
        0.71,
        0.43,
        1
    )

    frame.nllParchmentBase:SetAlpha(1)
    frame.nllParchmentBase:Show()

    local pieces = {
        frame.nllQuestTopLeft,
        frame.nllQuestTopRight,
        frame.nllQuestBotLeft,
        frame.nllQuestBotRight
    }

    for i = 1, #pieces do
        pieces[i]:SetVertexColor(
            1,
            1,
            1,
            1
        )

        pieces[i]:SetAlpha(1)
        pieces[i]:Show()
    end
end

local function HideVanillaParchment(frame)
    if frame.nllParchmentBase then
        frame.nllParchmentBase:Hide()
    end

    local pieces = {
        frame.nllQuestTopLeft,
        frame.nllQuestTopRight,
        frame.nllQuestBotLeft,
        frame.nllQuestBotRight
    }

    for i = 1, #pieces do
        if pieces[i] then
            pieces[i]:Hide()
        end
    end
end

function UI:ApplySkinToFrame(frame)
    if not frame then
        return
    end

    local skinID = self:GetSkinID()
    local skin = self:GetSkin()
    local kind =
        frame.nllSkinKind
        or "row"

    if kind == "button" then
        if skinID == "VANILLA" then
            ApplyVanillaButtonTextures(
                frame
            )
            return
        end

        RestoreDarkButtonSize(frame)
        ClearButtonTextures(frame)

        frame:SetBackdrop({
            bgFile =
                "Interface\\Buttons\\WHITE8X8",
            edgeFile =
                "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = {
                left = 2,
                right = 2,
                top = 2,
                bottom = 2
            }
        })

        local color = skin.button

        if frame.nllHover then
            color = skin.buttonHover
        elseif frame.nllButtonState ==
            "active" then

            color = skin.buttonActive
        elseif frame.nllButtonState ==
            "danger" then

            color = skin.buttonDanger
        end

        ApplyColor(
            frame,
            "SetBackdropColor",
            color
        )

        ApplyColor(
            frame,
            "SetBackdropBorderColor",
            skin.border
        )

        return
    end

    if not frame.SetBackdrop then
        return
    end

    if kind == "main" then
        frame:SetBackdrop(
            skin.mainBackdrop
        )

        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.main
        )

        ApplyColor(
            frame,
            "SetBackdropBorderColor",
            skin.mainBorder
        )

        return
    end

    if kind == "content" then
        if skinID == "VANILLA" then
            -- Border only. The actual parchment is rendered as
            -- texture layers so it is reliably visible in 3.3.5.
            frame:SetBackdrop({
                edgeFile =
                    "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = false,
                edgeSize = 18,
                insets = {
                    left = 6,
                    right = 6,
                    top = 6,
                    bottom = 6
                }
            })

            frame:SetBackdropColor(
                0,
                0,
                0,
                0
            )

            ApplyColor(
                frame,
                "SetBackdropBorderColor",
                skin.border
            )

            ShowVanillaParchment(
                frame
            )
        else
            HideVanillaParchment(
                frame
            )

            frame:SetBackdrop(
                skin.contentBackdrop
            )

            ApplyColor(
                frame,
                "SetBackdropColor",
                skin.content
            )

            frame:SetBackdropBorderColor(
                0,
                0,
                0,
                0
            )
        end

        return
    end

    frame:SetBackdrop({
        bgFile =
            "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 16,
        edgeSize = 0,
        insets = {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0
        }
    })

    if kind == "title" then
        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.title
        )
        return
    end

    if kind == "header" then
        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.header
        )
        return
    end

    if kind == "rowAlt" then
        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.rowAlt
        )
        return
    end

    if kind == "row" then
        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.row
        )
        return
    end
end

function UI:AttachButtonSkin(button)
    if not button then
        return
    end

    self:RegisterSkinnedFrame(
        button,
        "button"
    )

    button.nllButtonState =
        button.nllButtonState
        or "normal"

    button:SetScript(
        "OnEnter",
        function(self)
            self.nllHover = true
            UI:ApplySkinToFrame(self)
        end
    )

    button:SetScript(
        "OnLeave",
        function(self)
            self.nllHover = false
            UI:ApplySkinToFrame(self)
        end
    )
end

function UI:ApplySkin()
    for i = 1, #self.skinnedFrames do
        self:ApplySkinToFrame(
            self.skinnedFrames[i]
        )
    end

    if self.RefreshSettingsPanel then
        self:RefreshSettingsPanel()
    end
end

function UI:SetSkin(skinID)
    if skinID ~= "DARK"
        and skinID ~= "VANILLA" then

        return false
    end

    if not NLL.db
        or not NLL.db.settings then

        return false
    end

    NLL.db.settings.skin = skinID

    self:ApplySkin()

    NLL:Print(
        "UI skin changed to " ..
        self.skins[skinID].name ..
        "."
    )

    return true
end
