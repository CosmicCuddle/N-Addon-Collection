-- Lua 5.1 regression tests: website NT1 compatibility and IP-era restrictions.
NTalentCalculatorData = {classes={}, icons={}, tooltips={}}
local D = NTalentCalculatorData

local primary = {
    {101,0,0,{1111,1112,1113,1114,1115},"Foundation", "Base effect",0,0,1},
    {102,1,0,{1121,1122,1123,1124,1125},"Second Row", "Second",0,0,2},
    {103,2,0,{1131,1132,1133,1134,1135},"Third Row","Third",0,0,3},
    {104,3,0,{1141,1142,1143,1144,1145},"Fourth Row","Fourth",0,0,4},
    {105,4,0,{1151,1152,1153,1154,1155},"Fifth Row","Fifth",0,0,5},
    {106,5,0,{1161,1162,1163,1164,1165},"Sixth Row","Sixth",0,0,6},
    {107,6,1,{1171},"Vanilla Capstone", "Capstone",0,0,7},
    {108,6,0,{1181},"Vanilla Side", "Side",0,0,8},
    {109,7,0,{1191},"TBC Eighth Row", "Extra",0,0,9},
    {110,8,1,{1201},"TBC Capstone", "Capstone",0,0,10},
    {111,8,0,{1211},"TBC Side", "Side",0,0,11},
    {112,10,1,{1221},"Wrath Capstone", "Final",0,0,12},
    {113,0,1,{1231},"Dependent", "Needs Foundation",101,4,13},
}
local classes = {
    "warrior","paladin","hunter","rogue","priest","deathknight",
    "shaman","mage","warlock","druid"
}
for _, class in ipairs(classes) do
    D.classes[class] = {
        {41,"Arms",0,primary},
        {61,"Fury",0,{}},
        {81,"Protection",0,{}}
    }
end

NTalentCalculatorDB = {builds={}}
function UnitClass() return "Warrior", "WARRIOR" end
DEFAULT_CHAT_FRAME = {AddMessage=function() end}

dofile("suite/NTalentCalculator/Engine.lua")
local M = NTalentCalculator
assert(M:Initialize(), "Talent engine init failed")
assert(M:SetProgression("vanilla", 0), "Vanilla tier not accepted")
assert(M.era == "vanilla" and M.tier == 0 and M.level == 60)
assert(M:Available(primary[1], D.classes.warrior[1]))
assert(M:Available(primary[7], D.classes.warrior[1]))
assert(not M:Available(primary[8], D.classes.warrior[1]), "Vanilla row-7 side must hide")
assert(not M:Available(primary[9], D.classes.warrior[1]), "Vanilla row-8 must hide")
assert(not M:Available(primary[10], D.classes.warrior[1]), "Vanilla row-9 must hide")

local good, reason = M:Adjust(101, 1)
assert(good, "First-rank talent should be purchasable: " .. tostring(reason))
assert(M.points[101] == 1)
local code = M:ExportCode()
assert(code == "NT1:vanilla:warrior:2t-1", "Website NT1 code format mismatch: " .. tostring(code))
M.points = {}
good, reason = M:ImportCode(code)
assert(good and M.points[101] == 1, "Website NT1 roundtrip failed: " .. tostring(reason))
good, reason = M:ImportCode("NT1:vanilla:warrior:2t-1.2t-1")
assert(not good, "Duplicate talent IDs must be rejected")
good, reason = M:ImportCode("NT1:vanilla:warrior:zzzzz-1")
assert(not good, "Unknown talent ID should be rejected")
good, reason = M:ImportCode("NT1:tbc:warrior:2t-1")
assert(not good, "Cross-era codes must not bypass IP tier")

local prereq = {[113]=1}
good = M:Validate(prereq)
assert(not good, "Missing prereq should reject import")
local impossible = {[112]=1}
good = M:Validate(impossible)
assert(not good, "Vanilla should reject Wrath final-row talent")

good, reason = M:SaveBuild("my raid test")
assert(good, "SavedVariables save failed: " .. tostring(reason))
M.points = {}
good, reason = M:LoadBuild("my raid test")
assert(good and M.points[101] == 1, "SavedVariables load failed: " .. tostring(reason))

M:SetProgression("tbc", 8)
assert(M.era == "tbc" and M.level == 70)
assert(M:Available(primary[9], D.classes.warrior[1]))
assert(M:Available(primary[10], D.classes.warrior[1]))
assert(not M:Available(primary[11], D.classes.warrior[1]))
assert(not M:Available(primary[12], D.classes.warrior[1]))
M:SetProgression("wotlk", 13)
assert(M.era == "wotlk" and M.level == 80)
assert(M:Available(primary[11], D.classes.warrior[1]))
assert(M:Available(primary[12], D.classes.warrior[1]))

-- Exceptions matching the user's website DBC.
assert(M:Available({901,6,0,{1},"Stormstrike"}, {263,"Enhancement",0,{}}, "vanilla"))
assert(M:Available({1022,6,0,{1},"Dark Pact"}, {302,"Affliction",0,{}}, "vanilla"))
assert(not M:Available({100,6,1,{1},"Wrong Centre"}, {263,"Enhancement",0,{}}, "vanilla"))
assert(M:Available({1747,8,0,{1},"Divine Illumination"}, {382,"Holy",0,{}}, "tbc"))

M:SetProgression("vanilla", 2)
local oldPoints = M.points
local _, more = M:Validate({[112]=1})
assert(more and more:find("unavailable"), "Blocked talent should give readable reason")
assert(M.points == oldPoints, "Failed check should not change build")
print("N Talent Calculator Lua 5.1 era, capstone, build-code and save tests passed")
