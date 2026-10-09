-- Ensure the actual generated Lua data has not diverged from the website.
dofile("suite/NTalentCalculator/Data.lua")
local data = NTalentCalculatorData
assert(data and data.version == 1, "Expected approved DBC export v1")
assert(data.sourceCommit == "e2e861d05c4f3d13f850886c973cb66bc60cc849",
    "Incorrect source commit embedded in talent data")
local countClasses, countTrees, countTalents = 0, 0, 0
local foundRendFlurry = false
for class, trees in pairs(data.classes or {}) do
    countClasses = countClasses + 1
    assert(type(trees) == "table" and #trees == 3,
        class .. " must contain three specialization trees")
    for _, tree in ipairs(trees) do
        countTrees = countTrees + 1
        assert(type(tree[1]) == "number" and type(tree[2]) == "string")
        for _, talent in ipairs(tree[4]) do
            countTalents = countTalents + 1
            assert(type(talent[1]) == "number" and
                type(talent[2]) == "number" and
                type(talent[3]) == "number" and
                type(talent[4]) == "table" and
                type(talent[5]) == "string", "Malformed Talent.dbc talent")
            assert(talent[2] >= 0 and talent[2] <= 10,
                "Unexpected row in source DBC")
            assert(talent[3] >= 0 and talent[3] <= 3,
                "Unexpected column in source DBC")
            if talent[1] == 3000 then foundRendFlurry = true end
        end
    end
end
assert(countClasses == 10, "Must contain ten classes")
assert(countTrees == 30, "Must contain 30 talent trees")
assert(countTalents == 830, "Must contain all 830 custom server talents")
assert(foundRendFlurry, "Custom Rend Flurry talent (3000) is missing")
assert(type(data.icons) == "table" and type(data.tooltips) == "table")
local countIcons, countTooltips = 0, 0
for _ in pairs(data.icons) do countIcons = countIcons + 1 end
for _ in pairs(data.tooltips) do countTooltips = countTooltips + 1 end
assert(countIcons >= 600, "Missing approved SpellIcon data")
assert(countTooltips >= 2200, "Missing approved rank-specific Spell data")
print("Actual website DBC talent data verified: " ..
    countClasses .. " classes, " .. countTrees .. " trees, " ..
    countTalents .. " talents, " .. countTooltips .. " tooltips")
