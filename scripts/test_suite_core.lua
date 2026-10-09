-- Minimal Lua 5.1 test of the core's addon enable/disable contract.
-- No WoW client, UI objects or network connections are needed.

local installed = {
    "NCore", "IndividualProgressionAddon", "DungeonJournal",
    "MultiBot", "NaxxLootLottery"
}
local enabled = {}
for i = 1, #installed do enabled[i] = 1 end
SLASH_NSUITE1 = nil
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }

function GetNumAddOns() return #installed end
function GetAddOnInfo(index) return installed[index], installed[index], "", enabled[index] ~= 0 end
function GetAddOnEnableState(_, index) return enabled[index] end
function UnitName() return "TestCharacter" end
function EnableAddOn(index) enabled[index] = 1 end
function DisableAddOn(index) enabled[index] = 0 end
function InCombatLockdown() return false end
function ReloadUI() _G.__reloaded = true end

dofile("suite/NCore/Core.lua")
assert(#NCore.modules == 4, "Expected exactly four optional modules")
assert(NCore:FindIndex("NCore") == 1, "Missing core")
assert(NCore:FindIndex("NClassicBattlegrounds") == nil, "BG must be embedded, not standalone")

local ok, reason = NCore:SetEnabled("NCore", false)
assert(not ok and reason, "Core must be protected from in-suite toggles")
ok, reason = NCore:SetEnabled("NClassicBattlegrounds", false)
assert(not ok and reason, "Classic BG must be mandatory")
ok, reason = NCore:SetEnabled("Unknown", false)
assert(not ok and reason, "Unknown module should be rejected")

ok = NCore:SetEnabled("DungeonJournal", false)
assert(ok and enabled[3] == 0, "Optional module not disabled")
local state, present = NCore:IsEnabled("DungeonJournal")
assert(present and not state, "Disabled state not reflected")
assert(NCore.needsReload, "Must require Reload UI")
ok = NCore:SetEnabled("DungeonJournal", true)
assert(ok and enabled[3] == 1, "Optional module not reenabled")

NCore:RequestReload()
assert(_G.__reloaded, "Reload UI action was not triggered")
print("Lua 5.1 core API tests passed")
