-- Standalone WoW-API mock for suite settings; execute with Lua 5.1.
-- Catches missing methods/initialisation errors and checks panel sizing.
local controls = {checkbuttons = {}}
local frameMethods = {}
local function newObject()
    return setmetatable({shown = false}, {__index = frameMethods})
end

function frameMethods:SetWidth(value) self.width = value end
function frameMethods:SetHeight(value) self.height = value end
function frameMethods:SetPoint(...) self.point = {...} end
function frameMethods:ClearAllPoints() self.point = nil end
function frameMethods:SetText(text) self.text = text end
function frameMethods:SetBackdrop(bg) self.backdrop = bg end
function frameMethods:SetBackdropColor(...) self.backdropColor = {...} end
function frameMethods:SetBackdropBorderColor(...) self.borderColor = {...} end
function frameMethods:SetTexture(name) self.texture = name end
function frameMethods:SetVertexColor(...) self.vertexColor = {...} end
function frameMethods:SetTextColor(...) self.textColor = {...} end
function frameMethods:SetJustifyH(text) self.justify = text end
function frameMethods:SetScript(name, callback)
    self.scripts = self.scripts or {}
    self.scripts[name] = callback
end
function frameMethods:Show()
    self.shown = true
    if self.scripts and self.scripts.OnShow then
        self.scripts.OnShow(self)
    end
end
function frameMethods:Hide() self.shown = false end
function frameMethods:IsShown() return self.shown end
function frameMethods:Enable() self.disabled = false end
function frameMethods:Disable() self.disabled = true end
function frameMethods:SetChecked(checked) self.checked = checked end
function frameMethods:GetChecked() return self.checked end
function frameMethods:CreateFontString() return newObject() end
function frameMethods:CreateTexture() return newObject() end
function frameMethods:SetToplevel() end
function frameMethods:SetFrameStrata() end
function frameMethods:SetMovable() end
function frameMethods:EnableMouse() end
function frameMethods:RegisterForDrag() end
function frameMethods:SetClampedToScreen() end

UIParent = newObject()
function CreateFrame(kind, name)
    local obj = newObject()
    if name then _G[name] = obj end
    if kind == "CheckButton" then
        table.insert(controls.checkbuttons, obj)
    end
    return obj
end

local modules = {
    {folder="IndividualProgressionAddon",title="Individual Progression",description="Progression guides"},
    {folder="DungeonJournal",title="Dungeon Journal",description="Dungeon and raid guides"},
    {folder="MultiBot",title="MultiBot Chatless",description="Playerbot controls"},
    {folder="NaxxLootLottery",title="N Loot Ledger",description="WIP loot planning"}
}
local enabled = {}
for _, module in ipairs(modules) do enabled[module.folder] = true end
NCore = {
    version = "2.0.0-alpha.1",
    modules = modules,
    IsEnabled = function(self, folder) return enabled[folder], true end,
    SetEnabled = function(self, folder, active)
        enabled[folder] = active
        self.needsReload = true
        return true
    end,
    RequestReload = function(self) self.reloaded = true end,
    Print = function() end
}

dofile("suite/NCore/Settings.lua")
NCore:ToggleSettings()
local panel = NSuiteSettingsFrame
assert(panel and panel:IsShown(), "Settings did not open")
assert(panel.width == 620 and panel.height == 485, "Unexpected window dimensions")
assert(panel.backdrop and panel.backdrop.bgFile == "Interface\\Buttons\\WHITE8X8",
    "Window must use an opaque-compatible dark backing")
assert(panel.backdropColor and panel.backdropColor[4] >= 0.95,
    "Window background is too transparent")
assert(#controls.checkbuttons == 4, "Only four optional modules may have checkboxes")
assert(panel.notice.text == "Choose modules. Reload after changes.",
    "Compact footer instruction was not rendered")
assert(panel.reload.disabled == true, "Reload button should initially be disabled")

local check = controls.checkbuttons[1]
check:SetChecked(false)
check.scripts.OnClick(check)
assert(enabled.IndividualProgressionAddon == false, "The first checkbox toggled the wrong addon")
assert(NCore.needsReload == true, "Changing a module must request a UI reload")
assert(panel.reload.disabled == false, "Reload should be available after changing settings")
assert(panel.notice.text:find("Changes saved", 1, true), "Reload notice missing")

NCore:ToggleSettings()
assert(not panel:IsShown(), "Settings window did not close")
print("Lua 5.1 settings UI mock tests passed")
