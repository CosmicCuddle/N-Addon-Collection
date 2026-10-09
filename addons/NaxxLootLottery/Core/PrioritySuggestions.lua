-- NLL Phase 8: optional, editable Tier 1 suggestions.
-- Applying a suggestion only changes the on-screen editor.
-- The user must explicitly choose Save Rule to persist it.
local NLL = NaxxLootLottery
NLL.PrioritySuggestions = NLL.PrioritySuggestions or {}
local Suggestions = NLL.PrioritySuggestions

local X = "EXCLUDE"
local function Make(primary, secondary)
    local selection = {}
    for i = 1, #NLL.roles do
        selection[NLL.roles[i].id] = X
    end
    selection[primary] = 1
    if secondary then selection[secondary] = 2 end
    return selection
end

local templates = {
    MAGE    = {"CASTER_DPS", nil, "Mage casting damage"},
    WARLOCK = {"CASTER_DPS", nil, "Warlock casting damage"},
    PRIEST  = {"HEALER", nil, "Priest healing"},
    ROGUE   = {"MELEE_DPS", nil, "Rogue melee damage"},
    HUNTER  = {"RANGED_PHYSICAL_DPS", nil, "Hunter ranged damage"},
    DRUID   = {"HEALER", nil, "Druid healing; review hybrid builds"},
    SHAMAN  = {"HEALER", nil, "Shaman healing; review hybrid builds"},
    PALADIN = {"HEALER", nil, "Paladin healing; review hybrid builds"},
    WARRIOR = {"MAIN_TANK", "TANK", "Warrior main tank, then other tanks"}
}

-- Curated starter recommendations from conventional Classic item functions.
-- These are editable ROLE opinions, never hard class restrictions.
-- Different server spell/talent/item changes may alter the best allocation.
local function RoleTiers(primary, secondary, third)
    local selected = {}
    for _, role in ipairs(NLL.roles) do selected[role.id] = X end
    if type(primary) == "table" then
        for _, id in ipairs(primary) do selected[id] = 1 end
    elseif primary then selected[primary] = 1 end
    if type(secondary) == "table" then
        for _, id in ipairs(secondary) do selected[id] = 2 end
    elseif secondary then selected[secondary] = 2 end
    if type(third) == "table" then
        for _, id in ipairs(third) do selected[id] = 3 end
    elseif third then selected[third] = 3 end
    return selected
end

local nonSet = {
    -- Lucifron / shared early Flamewaker boss drops.
    [18879] = { {"MAIN_TANK", "TANK"}, nil, nil,
        "Defense and armor ring; defensive tanks share first priority." },
    [19147] = { "CASTER_DPS", "HEALER", nil,
        "Spell-power ring. Spell-damage roles first; healer use is reviewable." },
    [19145] = { "CASTER_DPS", "HEALER", nil,
        "Spell-power / critical-strike cloth robe. Check local item stats." },
    [17109] = { {"CASTER_DPS", "HEALER"}, nil, nil,
        "Spell damage-and-healing necklace: equal priority suggested." },
    [18872] = { "HEALER", "CASTER_DPS", nil,
        "Mana-regeneration cloth legs: healer first as a starting point." },
    [18875] = { "HEALER", nil, nil,
        "Healing-oriented leather legs; check armour proficiency." },
    [18870] = { "HEALER", "CASTER_DPS", nil,
        "Intellect/spell-power mail helm; confirm the raid's hybrid specs." },
    [18878] = { {"CASTER_DPS", "HEALER"}, nil, nil,
        "Spell-power dagger: equal caster/healer priority to start." },
    [19146] = { "MELEE_DPS", {"TANK", "MAIN_TANK"}, nil,
        "Strength leather bracers: melee first; review off-tank use." },
    [17077] = { "CASTER_DPS", "HEALER", nil,
        "Caster wand. Healer as an optional fallback." },
    -- Shared Magmadar/Garr/Golemagg/Baron item pools.
    [18820] = { "CASTER_DPS", "HEALER", nil,
        "Talisman of Ephemeral Power: temporary spell-power activation." },
    [19136] = { "CASTER_DPS", "HEALER", nil,
        "Mana Igniting Cord: spell-oriented waist item; review specs." },
    [18821] = { "MELEE_DPS", {"RANGED_PHYSICAL_DPS", "TANK"}, nil,
        "Quick Strike Ring: physical attack item. Review tanks and hunters." },
    [17066] = { {"MAIN_TANK", "TANK"}, nil, nil,
        "Drillborer Disk: shield-based defensive tank starting priority." },
    -- Later early raid encounters.
    [19140] = { "HEALER", nil, nil,
        "Cauterizing Band: +healing ring; healer-focused starting rule." },
    [18810] = { "HEALER", nil, nil,
        "Wild Growth Spaulders: healing shoulder item." },
    -- v0.1.0.18: research-based candidates for remaining items. Explicit
    -- optional advisory class policies prevent cloth casters receiving mail/plate.
    [19138] = { "HEALER", "CASTER_DPS", nil,
        "Band of Sulfuras: intellect/spirit ring; healer-first advisory; caster fallback." },
    [18817] = { "RANGED_PHYSICAL_DPS", "MELEE_DPS", nil,
        "Crown of Destruction: attack power and critical mail helm; hunter-first, hybrid physical fallback." },
    [18829] = { "CASTER_DPS", nil, nil,
        "Deep Earth Spaulders: Nature spell damage mail shoulders; elemental Shaman starting policy.", {"SHAMAN"} },
    [17107] = { {"MAIN_TANK","TANK"}, "MELEE_DPS", nil,
        "Dragon's Blood Cape: stamina, armour, resistances and strength; defensive proposal." },
    [18803] = { "HEALER", "CASTER_DPS", nil,
        "Finkle's Lava Dredger: 2H mace with intellect and mana regeneration; healer proposal; review feral use." },
    [18824] = { "HEALER", nil, nil,
        "Magma Tempered Boots: healing plate boots; Paladin healer starting policy.", {"PALADIN"} },
    [19144] = { "RANGED_PHYSICAL_DPS", "MELEE_DPS", nil,
        "Sabatons of the Flamewalker: attack-power mail boots; Hunter and enhancement Shaman candidates.", {"HUNTER","SHAMAN"} },
    [17110] = { "HEALER", "CASTER_DPS", nil,
        "Seal of the Archmagus: intellect, spirit and mana regeneration; healer-first advisory." },
    -- Shard of the Flame (17082) and Essence of the Pure Flame (18815) are
    -- utility trinkets with nonstandard priorities; leave them unconfigured.

    -- Additional Phase 8 advisory presets. No equip eligibility is inferred
    -- from armor type: these are deliberately optional role suggestions.
    [18823] = { "MELEE_DPS", {"TANK", "MAIN_TANK"}, nil,
        "Aged Core Leather Gloves: physical melee gloves; review tanks/feral specs." },
    [17105] = { "HEALER", nil, nil,
        "Aurastone Hammer: healing mace; check your raid's spec policy." },
    [17103] = { "CASTER_DPS", "HEALER", nil,
        "Azuresong Mageblade: spell-oriented sword, caster first as a proposal." },
    [17063] = { {"MAIN_TANK", "TANK"}, "MELEE_DPS", "RANGED_PHYSICAL_DPS",
        "Band of Accuria: physical hit ring; proposed tanks first, then physical DPS." },
    [17072] = { "RANGED_PHYSICAL_DPS", "MELEE_DPS", nil,
        "Blastershot Launcher: ranged weapon; hunter primary, melee stat-stick optional." },
    [17076] = { "MELEE_DPS", nil, nil,
        "Bonereaver's Edge: physical two-handed weapon; review warrior builds." },
    [18832] = { "MELEE_DPS", {"TANK", "MAIN_TANK"}, nil,
        "Brutality Blade: physical one-hand sword; review tank threat builds." },
    [18814] = { "CASTER_DPS", "HEALER", nil,
        "Choker of the Fire Lord: spell-oriented necklace; caster first, healers optional." },
    [17102] = { {"MELEE_DPS", "RANGED_PHYSICAL_DPS"}, {"MAIN_TANK", "TANK"}, nil,
        "Cloak of the Shrouded Mists: physical-agility cloak; tanks optional." },
    [18806] = { {"MAIN_TANK", "TANK"}, "MELEE_DPS", nil,
        "Core Forged Greaves: plate boots; proposed tank use first, review stats." },
    [18805] = { "MELEE_DPS", {"TANK", "MAIN_TANK"}, nil,
        "Core Hound Tooth: physical dagger; offhand/tank use is spec-dependent." },
    [17073] = { "MELEE_DPS", nil, nil,
        "Earthshaker: physical two-handed mace; review weapon specialists." },
    [18203] = { "MELEE_DPS", nil, nil,
        "Eskhandar's Right Claw: physical fist weapon; review dual-wield users." },
    [19142] = { "CASTER_DPS", "HEALER", nil,
        "Fire Runed Grimoire: spell-casting off-hand; review healers." },
    [19139] = { "MELEE_DPS", {"TANK", "MAIN_TANK"}, nil,
        "Fireguard Shoulders: physical leather shoulders; review feral/tanks." },
    [18811] = { {"MAIN_TANK", "TANK"}, nil, nil,
        "Fireproof Cloak: fire-resistance cloak; tank survivability priority proposal." },
    [19143] = { "MELEE_DPS", {"MAIN_TANK", "TANK"}, nil,
        "Flameguard Gauntlets: physical plate hands; review threat tank use." },
    [18861] = { "MELEE_DPS", {"MAIN_TANK", "TANK"}, nil,
        "Flamewaker Legplates: physical plate leggings; review tank itemization." },
    [18808] = { "CASTER_DPS", "HEALER", nil,
        "Gloves of the Hypnotic Flame: spell-oriented gloves; review healers." },
    [17071] = { "MELEE_DPS", nil, nil,
        "Gutgore Ripper: physical dagger; melee first." },
    [17106] = { {"MAIN_TANK", "TANK"}, "HEALER", nil,
        "Malistar's Defender: shield; defensive tanks first, shield healers reviewable." },
    [17065] = { {"MAIN_TANK", "TANK"}, nil, nil,
        "Medallion of Steadfast Might: defensive necklace for tank roles." },
    [18822] = { "MELEE_DPS", nil, nil,
        "Obsidian Edged Blade: physical two-hand sword; review warrior users." },
    [19137] = { "MELEE_DPS", {"MAIN_TANK", "TANK"}, nil,
        "Onslaught Girdle: physical plate belt; tank/threat use reviewable." },
    [18816] = { "MELEE_DPS", nil, nil,
        "Perdition's Blade: physical dagger; melee first." },
    [18809] = { "CASTER_DPS", "HEALER", nil,
        "Sash of Whispered Secrets: spell-oriented belt; review healer specs." },
    [17074] = { "MELEE_DPS", nil, nil,
        "Shadowstrike: physical polearm; review weapon builds." },
    [17104] = { "MELEE_DPS", nil, nil,
        "Spinal Reaper: physical two-hand axe; melee first." },
    [18842] = { "CASTER_DPS", "HEALER", nil,
        "Staff of Dominance: spell-oriented staff; review healing use." },
    [17069] = { "RANGED_PHYSICAL_DPS", "MELEE_DPS", nil,
        "Striker's Mark: physical ranged weapon; review melee stat-stick usage." },
    [18812] = { "RANGED_PHYSICAL_DPS", "MELEE_DPS", nil,
        "Wristguards of True Flight: hunter-oriented mail bracers; review other users." }
}

function Suggestions:GetCoverage(raidKey)
    if raidKey ~= "MOLTEN_CORE" then return 0 end
    local count = 0
    for _, item in ipairs(NLL.Data.MoltenCore:GetItems()) do
        if self:GetSuggestion(raidKey, item.itemID) then count=count+1 end
    end
    return count
end

function Suggestions:GetSuggestion(raidKey, itemID)
    if raidKey ~= "MOLTEN_CORE" then return nil end
    local item = NLL.Data.MoltenCore:GetItem(itemID)
    if not item or item.manualOnly then return nil end
    local custom = nonSet[item.itemID]
    if custom then
        local classEligibility = nil
        if type(custom[5]) == "table" then
            classEligibility = {}
            for _,class in ipairs(NLL.classes) do
                classEligibility[class.id] = false
            end
            for _,id in ipairs(custom[5]) do
                classEligibility[id] = true
            end
        end
        return {
            rolePriority = RoleTiers(custom[1], custom[2], custom[3]),
            classEligibility = classEligibility,
            note = custom[4] .. " Suggested only; review for this server.",
            itemID = item.itemID, kind = "NON_SET",
            requiresReview = true
        }
    end
    if item.classRestrictionSource ~= "TIER_ONE_SET" and
        item.classRestrictionSource ~= "TIER_TWO_SET" then return nil end
    local classFile
    for classID, allowed in pairs(item.allowedClasses or {}) do
        if allowed then classFile = classID break end
    end
    local template = classFile and templates[classFile]
    if not template then return nil end
    return {rolePriority = Make(template[1], template[2]),
            note = template[3] .. ". Suggested only; check your guild's specs.",
            itemID = item.itemID, classFile = classFile,
            kind = item.classRestrictionSource, requiresReview = true}
end
