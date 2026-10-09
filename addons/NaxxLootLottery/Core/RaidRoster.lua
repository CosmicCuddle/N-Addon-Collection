-- ============================================================
-- Naxxramas Loot Ledger
-- Core/RaidRoster.lua
-- ============================================================

local NLL = NaxxLootLottery
NLL.Roster = NLL.Roster or {}
local Roster = NLL.Roster

Roster.members = {}
Roster.initialized = false

function Roster:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true
    self:Refresh()
end

function Roster:Refresh()
    self.members = {}

    local count = 0
    if GetNumRaidMembers then
        count = GetNumRaidMembers() or 0
    end

    for raidIndex = 1, count do
        local name, rank, subgroup, level, className, classFile,
              zone, online, isDead, nativeRaidRole, isMasterLooter =
            GetRaidRosterInfo(raidIndex)

        if name then
            local member = {
                raidIndex = raidIndex,
                name = name,
                rank = rank or 0,
                subgroup = subgroup or 0,
                level = level or 0,
                className = className or "Unknown",
                classFile = classFile,
                zone = zone,
                online = online and true or false,
                isDead = isDead and true or false,
                nativeRaidRole = nativeRaidRole,
                isMasterLooter = isMasterLooter and true or false
            }

            member.assignedRole =
                NLL.Database:GetRoleAssignment(name)

            NLL.Database:UpdateCharacterFromRoster(member)
            table.insert(self.members, member)
        end
    end

    NLL:Debug("Raid roster refreshed: " .. tostring(#self.members))

    if NLL.UI then
        if NLL.UI.RefreshOverview then
            NLL.UI:RefreshOverview()
        end

        if NLL.UI.RefreshRolesPanel then
            NLL.UI:RefreshRolesPanel()
        end
    end
end

function Roster:GetMembers()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return NLL.DebugSimulator:GetRoster()
    end
    return self.members
end

function Roster:GetCount()
    return #self:GetMembers()
end

function Roster:GetMemberByName(name)
    local members=self:GetMembers()
    for i = 1, #members do
        if members[i].name == name then
            return members[i]
        end
    end
    return nil
end

function Roster:SetRole(name, roleID)
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return NLL.DebugSimulator:AssignRole(name,roleID)
    end
    if roleID ~= nil and not NLL:IsValidRole(roleID) then
        return false
    end

    local member = self:GetMemberByName(name)

    if not NLL.Database:SetRoleAssignment(name, roleID, member) then
        return false
    end

    if member then
        member.assignedRole = roleID
    end

    if NLL.UI and NLL.UI.RefreshRolesPanel then
        NLL.UI:RefreshRolesPanel()
    end

    return true
end

local eventFrame = CreateFrame("Frame")
Roster.eventFrame = eventFrame

eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event)
    if NLL.initialized then
        Roster:Refresh()
    end
end)
