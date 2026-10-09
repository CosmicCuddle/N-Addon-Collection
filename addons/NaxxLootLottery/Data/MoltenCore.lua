-- ============================================================
-- Naxxramas Loot Ledger
-- Data/MoltenCore.lua
--
-- Molten Core item-name / item-ID / boss database.
-- Priority profiles are intentionally NOT assigned in Phase 3.
-- ============================================================

local NLL = NaxxLootLottery
NLL.Data = NLL.Data or {}
NLL.Data.MoltenCore = NLL.Data.MoltenCore or {}

local MC = NLL.Data.MoltenCore

MC.key = "MOLTEN_CORE"
MC.name = "Molten Core"
MC.items = {}
MC.itemList = {}

local function AddItem(itemID, name, boss, options)
    local item = MC.items[itemID]

    if not item then
        item = {
            itemID = itemID,
            name = name,
            raid = MC.name,
            raidKey = MC.key,
            bosses = {},
            priorityProfile = nil,
            manualOnly = false,
            legendary = false,
            allowedClasses = nil,
            classRestrictionSource = nil
        }

        MC.items[itemID] = item
        table.insert(MC.itemList, item)
    end

    local alreadyAdded = false
    for i = 1, #item.bosses do
        if item.bosses[i] == boss then
            alreadyAdded = true
            break
        end
    end

    if not alreadyAdded then
        table.insert(item.bosses, boss)
    end

    if options then
        if options.manualOnly then
            item.manualOnly = true
        end

        if options.legendary then
            item.legendary = true
        end
    end
end

-- Lucifron
AddItem(16800, "Arcanist Boots", "Lucifron")
AddItem(16805, "Felheart Gloves", "Lucifron")
AddItem(16829, "Cenarion Boots", "Lucifron")
AddItem(16837, "Earthfury Boots", "Lucifron")
AddItem(16859, "Lawbringer Boots", "Lucifron")
AddItem(16863, "Gauntlets of Might", "Lucifron")
AddItem(18870, "Helm of the Lifegiver", "Lucifron")
AddItem(17109, "Choker of Enlightenment", "Lucifron")
AddItem(19145, "Robe of Volatile Power", "Lucifron")
AddItem(19146, "Wristguards of Stability", "Lucifron")
AddItem(18872, "Manastorm Leggings", "Lucifron")
AddItem(18875, "Salamander Scale Pants", "Lucifron")
AddItem(18861, "Flamewaker Legplates", "Lucifron")
AddItem(18879, "Heavy Dark Iron Ring", "Lucifron")
AddItem(19147, "Ring of Spell Power", "Lucifron")
AddItem(17077, "Crimson Shocker", "Lucifron")
AddItem(18878, "Sorcerous Dagger", "Lucifron")
AddItem(16665, "Tome of Tranquilizing Shot", "Lucifron")

-- Magmadar
AddItem(16814, "Pants of Prophecy", "Magmadar")
AddItem(16796, "Arcanist Leggings", "Magmadar")
AddItem(16810, "Felheart Pants", "Magmadar")
AddItem(16822, "Nightslayer Pants", "Magmadar")
AddItem(16835, "Cenarion Leggings", "Magmadar")
AddItem(16847, "Giantstalker's Leggings", "Magmadar")
AddItem(16843, "Earthfury Legguards", "Magmadar")
AddItem(16855, "Lawbringer Legplates", "Magmadar")
AddItem(16867, "Legplates of Might", "Magmadar")
AddItem(18203, "Eskhandar's Right Claw", "Magmadar")
AddItem(17065, "Medallion of Steadfast Might", "Magmadar")
AddItem(18829, "Deep Earth Spaulders", "Magmadar")
AddItem(18823, "Aged Core Leather Gloves", "Magmadar")
AddItem(19143, "Flameguard Gauntlets", "Magmadar")
AddItem(19136, "Mana Igniting Cord", "Magmadar")
AddItem(18861, "Flamewaker Legplates", "Magmadar")
AddItem(19144, "Sabatons of the Flamewalker", "Magmadar")
AddItem(18824, "Magma Tempered Boots", "Magmadar")
AddItem(18821, "Quick Strike Ring", "Magmadar")
AddItem(18820, "Talisman of Ephemeral Power", "Magmadar")
AddItem(19142, "Fire Runed Grimoire", "Magmadar")
AddItem(17069, "Striker's Mark", "Magmadar")
AddItem(17073, "Earthshaker", "Magmadar")
AddItem(18822, "Obsidian Edged Blade", "Magmadar")

-- Gehennas
AddItem(16812, "Gloves of Prophecy", "Gehennas")
AddItem(16826, "Nightslayer Gloves", "Gehennas")
AddItem(16849, "Giantstalker's Boots", "Gehennas")
AddItem(16839, "Earthfury Gauntlets", "Gehennas")
AddItem(16860, "Lawbringer Gauntlets", "Gehennas")
AddItem(16862, "Sabatons of Might", "Gehennas")
AddItem(18870, "Helm of the Lifegiver", "Gehennas")
AddItem(19145, "Robe of Volatile Power", "Gehennas")
AddItem(19146, "Wristguards of Stability", "Gehennas")
AddItem(18872, "Manastorm Leggings", "Gehennas")
AddItem(18875, "Salamander Scale Pants", "Gehennas")
AddItem(18861, "Flamewaker Legplates", "Gehennas")
AddItem(18879, "Heavy Dark Iron Ring", "Gehennas")
AddItem(19147, "Ring of Spell Power", "Gehennas")
AddItem(17077, "Crimson Shocker", "Gehennas")
AddItem(18878, "Sorcerous Dagger", "Gehennas")

-- Garr
AddItem(18564, "Bindings of the Windseeker", "Garr", { manualOnly = true, legendary = true })
AddItem(16813, "Circlet of Prophecy", "Garr")
AddItem(16795, "Arcanist Crown", "Garr")
AddItem(16808, "Felheart Horns", "Garr")
AddItem(16821, "Nightslayer Cover", "Garr")
AddItem(16834, "Cenarion Helm", "Garr")
AddItem(16846, "Giantstalker's Helmet", "Garr")
AddItem(16842, "Earthfury Helmet", "Garr")
AddItem(16854, "Lawbringer Helm", "Garr")
AddItem(16866, "Helm of Might", "Garr")
AddItem(18829, "Deep Earth Spaulders", "Garr")
AddItem(18823, "Aged Core Leather Gloves", "Garr")
AddItem(19143, "Flameguard Gauntlets", "Garr")
AddItem(19136, "Mana Igniting Cord", "Garr")
AddItem(18861, "Flamewaker Legplates", "Garr")
AddItem(19144, "Sabatons of the Flamewalker", "Garr")
AddItem(18824, "Magma Tempered Boots", "Garr")
AddItem(18821, "Quick Strike Ring", "Garr")
AddItem(18820, "Talisman of Ephemeral Power", "Garr")
AddItem(19142, "Fire Runed Grimoire", "Garr")
AddItem(17066, "Drillborer Disk", "Garr")
AddItem(17071, "Gutgore Ripper", "Garr")
AddItem(17105, "Aurastone Hammer", "Garr")
AddItem(18832, "Brutality Blade", "Garr")
AddItem(18822, "Obsidian Edged Blade", "Garr")

-- Shazzrah
AddItem(16811, "Boots of Prophecy", "Shazzrah")
AddItem(16801, "Arcanist Gloves", "Shazzrah")
AddItem(16803, "Felheart Slippers", "Shazzrah")
AddItem(16824, "Nightslayer Boots", "Shazzrah")
AddItem(16831, "Cenarion Gloves", "Shazzrah")
AddItem(16852, "Giantstalker's Gloves", "Shazzrah")
AddItem(18870, "Helm of the Lifegiver", "Shazzrah")
AddItem(19145, "Robe of Volatile Power", "Shazzrah")
AddItem(19146, "Wristguards of Stability", "Shazzrah")
AddItem(18872, "Manastorm Leggings", "Shazzrah")
AddItem(18875, "Salamander Scale Pants", "Shazzrah")
AddItem(18861, "Flamewaker Legplates", "Shazzrah")
AddItem(18879, "Heavy Dark Iron Ring", "Shazzrah")
AddItem(19147, "Ring of Spell Power", "Shazzrah")
AddItem(17077, "Crimson Shocker", "Shazzrah")
AddItem(18878, "Sorcerous Dagger", "Shazzrah")

-- Baron Geddon
AddItem(18563, "Bindings of the Windseeker", "Baron Geddon", { manualOnly = true, legendary = true })
AddItem(16797, "Arcanist Mantle", "Baron Geddon")
AddItem(16807, "Felheart Shoulder Pads", "Baron Geddon")
AddItem(16836, "Cenarion Spaulders", "Baron Geddon")
AddItem(16844, "Earthfury Epaulets", "Baron Geddon")
AddItem(16856, "Lawbringer Spaulders", "Baron Geddon")
AddItem(18829, "Deep Earth Spaulders", "Baron Geddon")
AddItem(18823, "Aged Core Leather Gloves", "Baron Geddon")
AddItem(19143, "Flameguard Gauntlets", "Baron Geddon")
AddItem(19136, "Mana Igniting Cord", "Baron Geddon")
AddItem(18861, "Flamewaker Legplates", "Baron Geddon")
AddItem(19144, "Sabatons of the Flamewalker", "Baron Geddon")
AddItem(18824, "Magma Tempered Boots", "Baron Geddon")
AddItem(18821, "Quick Strike Ring", "Baron Geddon")
AddItem(17110, "Seal of the Archmagus", "Baron Geddon")
AddItem(18820, "Talisman of Ephemeral Power", "Baron Geddon")
AddItem(19142, "Fire Runed Grimoire", "Baron Geddon")
AddItem(18822, "Obsidian Edged Blade", "Baron Geddon")

-- Golemagg
AddItem(16815, "Robes of Prophecy", "Golemagg the Incinerator")
AddItem(16798, "Arcanist Robes", "Golemagg the Incinerator")
AddItem(16809, "Felheart Robes", "Golemagg the Incinerator")
AddItem(16820, "Nightslayer Chestpiece", "Golemagg the Incinerator")
AddItem(16833, "Cenarion Vestments", "Golemagg the Incinerator")
AddItem(16845, "Giantstalker's Breastplate", "Golemagg the Incinerator")
AddItem(16841, "Earthfury Vestments", "Golemagg the Incinerator")
AddItem(16853, "Lawbringer Chestguard", "Golemagg the Incinerator")
AddItem(16865, "Breastplate of Might", "Golemagg the Incinerator")
AddItem(17203, "Sulfuron Ingot", "Golemagg the Incinerator", { manualOnly = true, legendary = true })
AddItem(18829, "Deep Earth Spaulders", "Golemagg the Incinerator")
AddItem(18823, "Aged Core Leather Gloves", "Golemagg the Incinerator")
AddItem(19143, "Flameguard Gauntlets", "Golemagg the Incinerator")
AddItem(19136, "Mana Igniting Cord", "Golemagg the Incinerator")
AddItem(18861, "Flamewaker Legplates", "Golemagg the Incinerator")
AddItem(19144, "Sabatons of the Flamewalker", "Golemagg the Incinerator")
AddItem(18824, "Magma Tempered Boots", "Golemagg the Incinerator")
AddItem(18821, "Quick Strike Ring", "Golemagg the Incinerator")
AddItem(18820, "Talisman of Ephemeral Power", "Golemagg the Incinerator")
AddItem(19142, "Fire Runed Grimoire", "Golemagg the Incinerator")
AddItem(17072, "Blastershot Launcher", "Golemagg the Incinerator")
AddItem(17103, "Azuresong Mageblade", "Golemagg the Incinerator")
AddItem(18822, "Obsidian Edged Blade", "Golemagg the Incinerator")
AddItem(18842, "Staff of Dominance", "Golemagg the Incinerator")

-- Sulfuron Harbinger
AddItem(16816, "Mantle of Prophecy", "Sulfuron Harbinger")
AddItem(16823, "Nightslayer Shoulder Pads", "Sulfuron Harbinger")
AddItem(16848, "Giantstalker's Epaulets", "Sulfuron Harbinger")
AddItem(16868, "Pauldrons of Might", "Sulfuron Harbinger")
AddItem(18870, "Helm of the Lifegiver", "Sulfuron Harbinger")
AddItem(19145, "Robe of Volatile Power", "Sulfuron Harbinger")
AddItem(19146, "Wristguards of Stability", "Sulfuron Harbinger")
AddItem(18872, "Manastorm Leggings", "Sulfuron Harbinger")
AddItem(18875, "Salamander Scale Pants", "Sulfuron Harbinger")
AddItem(18861, "Flamewaker Legplates", "Sulfuron Harbinger")
AddItem(18879, "Heavy Dark Iron Ring", "Sulfuron Harbinger")
AddItem(19147, "Ring of Spell Power", "Sulfuron Harbinger")
AddItem(17077, "Crimson Shocker", "Sulfuron Harbinger")
AddItem(18878, "Sorcerous Dagger", "Sulfuron Harbinger")
AddItem(17074, "Shadowstrike", "Sulfuron Harbinger")

-- Majordomo Executus
AddItem(19139, "Fireguard Shoulders", "Majordomo Executus")
AddItem(18810, "Wild Growth Spaulders", "Majordomo Executus")
AddItem(18811, "Fireproof Cloak", "Majordomo Executus")
AddItem(18808, "Gloves of the Hypnotic Flame", "Majordomo Executus")
AddItem(18809, "Sash of Whispered Secrets", "Majordomo Executus")
AddItem(18812, "Wristguards of True Flight", "Majordomo Executus")
AddItem(18806, "Core Forged Greaves", "Majordomo Executus")
AddItem(19140, "Cauterizing Band", "Majordomo Executus")
AddItem(18805, "Core Hound Tooth", "Majordomo Executus")
AddItem(18803, "Finkle's Lava Dredger", "Majordomo Executus")
AddItem(18703, "Ancient Petrified Leaf", "Majordomo Executus")
AddItem(18646, "The Eye of Divinity", "Majordomo Executus")

-- Ragnaros
AddItem(17204, "Eye of Sulfuras", "Ragnaros", { manualOnly = true, legendary = true })
AddItem(19017, "Essence of the Firelord", "Ragnaros", { manualOnly = true, legendary = true })
AddItem(16922, "Leggings of Transcendence", "Ragnaros")
AddItem(16915, "Netherwind Pants", "Ragnaros")
AddItem(16930, "Nemesis Leggings", "Ragnaros")
AddItem(16909, "Bloodfang Pants", "Ragnaros")
AddItem(16901, "Stormrage Legguards", "Ragnaros")
AddItem(16938, "Dragonstalker's Legguards", "Ragnaros")
AddItem(16946, "Legplates of Ten Storms", "Ragnaros")
AddItem(16954, "Judgement Legplates", "Ragnaros")
AddItem(16962, "Legplates of Wrath", "Ragnaros")
AddItem(17082, "Shard of the Flame", "Ragnaros")
AddItem(18817, "Crown of Destruction", "Ragnaros")
AddItem(18814, "Choker of the Fire Lord", "Ragnaros")
AddItem(17102, "Cloak of the Shrouded Mists", "Ragnaros")
AddItem(17107, "Dragon's Blood Cape", "Ragnaros")
AddItem(19137, "Onslaught Girdle", "Ragnaros")
AddItem(17063, "Band of Accuria", "Ragnaros")
AddItem(19138, "Band of Sulfuras", "Ragnaros")
AddItem(18815, "Essence of the Pure Flame", "Ragnaros")
AddItem(17106, "Malistar's Defender", "Ragnaros")
AddItem(18816, "Perdition's Blade", "Ragnaros")
AddItem(17104, "Spinal Reaper", "Ragnaros")
AddItem(17076, "Bonereaver's Edge", "Ragnaros")

-- All-boss recipes
AddItem(18264, "Plans: Elemental Sharpening Stone", "All bosses")
AddItem(18292, "Schematic: Core Marksman Rifle", "All bosses")
AddItem(18291, "Schematic: Force Reactive Disk", "All bosses")
AddItem(18290, "Schematic: Biznicks 247x128 Accurascope", "All bosses")
AddItem(18259, "Formula: Enchant Weapon - Spell Power", "All bosses")
AddItem(18260, "Formula: Enchant Weapon - Healing Power", "All bosses")
AddItem(18252, "Pattern: Core Armor Kit", "All bosses")
AddItem(18265, "Pattern: Flarecore Wraps", "All bosses")
AddItem(21371, "Pattern: Core Felcloth Bag", "All bosses")
AddItem(18257, "Recipe: Major Rejuvenation Potion", "All bosses")

-- Trash
AddItem(16817, "Girdle of Prophecy", "Trash")
AddItem(16802, "Arcanist Belt", "Trash")
AddItem(16806, "Felheart Belt", "Trash")
AddItem(16827, "Nightslayer Belt", "Trash")
AddItem(16828, "Cenarion Belt", "Trash")
AddItem(16851, "Giantstalker's Belt", "Trash")
AddItem(16838, "Earthfury Belt", "Trash")
AddItem(16858, "Lawbringer Belt", "Trash")
AddItem(16864, "Belt of Might", "Trash")
AddItem(17011, "Lava Core", "Trash")
AddItem(17010, "Fiery Core", "Trash")
AddItem(11382, "Blood of the Mountain", "Trash")
AddItem(17012, "Core Leather", "Trash")
AddItem(16819, "Vambraces of Prophecy", "Trash")
AddItem(16799, "Arcanist Bindings", "Trash")
AddItem(16804, "Felheart Bracers", "Trash")
AddItem(16825, "Nightslayer Bracelets", "Trash")
AddItem(16830, "Cenarion Bracers", "Trash")
AddItem(16850, "Giantstalker's Bracers", "Trash")
AddItem(16840, "Earthfury Bracers", "Trash")
AddItem(16857, "Lawbringer Bracers", "Trash")
AddItem(16861, "Bracers of Might", "Trash")


-- ============================================================
-- CLASS ELIGIBILITY
--
-- These are inherent item restrictions, not loot priorities.
-- Tier 1 class-set pieces are automatically restricted to the
-- class that can actually use that set.
-- ============================================================

function MC:SetAllowedClasses(
    itemID,
    classes,
    source
)
    local item =
        self.items[
            tonumber(itemID)
        ]

    if not item then
        return false
    end

    item.allowedClasses = {}

    for i = 1, #classes do
        item.allowedClasses[
            classes[i]
        ] = true
    end

    item.classRestrictionSource =
        source or "ITEM"

    return true
end

function MC:IsClassAllowed(
    item,
    classFile
)
    if not item then
        return false
    end

    if type(item.allowedClasses)
        ~= "table" then

        return true
    end

    if not classFile then
        return false
    end

    return item.allowedClasses[
        classFile
    ] == true
end

function MC:GetAllowedClassText(item)
    if not item
        or type(item.allowedClasses)
            ~= "table" then

        return "All classes"
    end

    local labels = {}

    for i = 1, #NLL.classes do
        local classInfo =
            NLL.classes[i]

        if item.allowedClasses[
            classInfo.id
        ] then

            table.insert(
                labels,
                classInfo.label
            )
        end
    end

    if #labels == 0 then
        return "No classes"
    end

    if #labels == 1 then
        return labels[1] ..
            " only"
    end

    return table.concat(
        labels,
        ", "
    )
end

local TIER_ONE_CLASS_ITEMS = {
    PRIEST = {
        16811, 16812, 16813, 16814,
        16815, 16816, 16817, 16819
    },

    MAGE = {
        16795, 16796, 16797, 16798,
        16799, 16800, 16801, 16802
    },

    WARLOCK = {
        16803, 16804, 16805, 16806,
        16807, 16808, 16809, 16810
    },

    ROGUE = {
        16820, 16821, 16822, 16823,
        16824, 16825, 16826, 16827
    },

    DRUID = {
        16828, 16829, 16830, 16831,
        16833, 16834, 16835, 16836
    },

    HUNTER = {
        16845, 16846, 16847, 16848,
        16849, 16850, 16851, 16852
    },

    SHAMAN = {
        16837, 16838, 16839, 16840,
        16841, 16842, 16843, 16844
    },

    PALADIN = {
        16853, 16854, 16855, 16856,
        16857, 16858, 16859, 16860
    },

    WARRIOR = {
        16861, 16862, 16863, 16864,
        16865, 16866, 16867, 16868
    }
}

for classFile, itemIDs
    in pairs(
        TIER_ONE_CLASS_ITEMS
    ) do

    for i = 1, #itemIDs do
        MC:SetAllowedClasses(
            itemIDs[i],
            { classFile },
            "TIER_ONE_SET"
        )
    end
end

-- The Tome teaches a Hunter-only raid ability. This affects eligibility,
-- not its role priority. No automatic priority rule is stored for it.
MC:SetAllowedClasses(16665, { "HUNTER" }, "ITEM_CLASS")
-- Class spell-learning book: distribute to a Hunter deliberately, not a role lottery.
if MC.items[16665] then
    MC.items[16665].manualOnly = true
    MC.items[16665].manualReason = "Hunter spell book"
end

-- Ragnaros drops the nine class-specific Tier 2 leg pieces.
-- This is an inherent equipment restriction, NOT a priority.
local TIER_TWO_LEGGINGS = {
    [16922] = "PRIEST", [16915] = "MAGE", [16930] = "WARLOCK",
    [16909] = "ROGUE", [16901] = "DRUID", [16938] = "HUNTER",
    [16946] = "SHAMAN", [16954] = "PALADIN", [16962] = "WARRIOR"
}
for itemID, classFile in pairs(TIER_TWO_LEGGINGS) do
    MC:SetAllowedClasses(itemID, {classFile}, "TIER_TWO_SET")
end

-- Majordomo's class quests should be awarded deliberately.
-- Both quest items also have inherent class restrictions.
MC:SetAllowedClasses(18703, { "HUNTER" }, "CLASS_QUEST")
MC:SetAllowedClasses(18646, { "PRIEST" }, "CLASS_QUEST")
for _, id in ipairs({18703, 18646}) do
    if MC.items[id] then
        MC.items[id].manualOnly = true
        MC.items[id].manualReason = "Class quest"
    end
end

-- Profession recipes and crafting materials are not normal role
-- gear. A guild officer makes the allocation manually instead.
for _, item in ipairs(MC.itemList) do
    if string.match(item.name, "^Plans:")
        or string.match(item.name, "^Schematic:")
        or string.match(item.name, "^Formula:")
        or string.match(item.name, "^Pattern:")
        or string.match(item.name, "^Recipe:") then
        item.manualOnly = true
        item.manualReason = "Profession recipe"
    end
end
for _, id in ipairs({17011, 17010, 11382, 17012}) do
    if MC.items[id] then
        MC.items[id].manualOnly = true
        MC.items[id].manualReason = "Crafting material"
    end
end

function MC:Initialize()
    table.sort(self.itemList, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
end

function MC:GetItem(itemID)
    return self.items[tonumber(itemID)]
end

function MC:GetItems()
    return self.itemList
end

function MC:GetBossText(item)
    if not item or not item.bosses then
        return "Unknown"
    end

    local text = ""
    for i = 1, #item.bosses do
        if i > 1 then
            text = text .. ", "
        end
        text = text .. item.bosses[i]
    end
    return text
end
