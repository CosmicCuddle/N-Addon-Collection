-- ============================================================================
-- IndividualProgressionAddon - WoW 3.3.5a
-- Individual Progression Companion UI - Server Edition v5.2
-- Slash commands: /ip, /progression
--
-- Keeps the original server communication contract:
--   Client -> server: .ipsvc data
--   Server -> client: ##IPSVC##PD~<progression value>
-- ============================================================================

local ADDON_NAME = "IndividualProgressionAddon"
local MSG_PREFIX = "##IPSVC##"
local DELIMITER  = "~"

-- ============================================================================
-- COLORS / HELPERS
-- ============================================================================

local C = {
    gold   = "|cffffd100",
    white  = "|cffffffff",
    grey   = "|cff9a9a9a",
    dark   = "|cff666666",
    green  = "|cff55dd55",
    yellow = "|cffffcc55",
    red    = "|cffff6666",
    blue   = "|cff80c0ff",
    cyan   = "|cff6edcff",
    orange = "|cffff9f45",
    purple = "|cffc49cff",
    reset  = "|r",
}

local function H(text)
    return C.gold .. text .. C.reset
end

local function SH(text)
    return C.cyan .. text .. C.reset
end

local function Bullet(text, color)
    return (color or C.white) .. "  - " .. text .. C.reset
end

local function Priority(label, text, color)
    return (color or C.white) .. "[" .. label .. "] " .. C.reset .. text
end

local function Step(number, title)
    return C.gold .. "STEP " .. tostring(number) .. " - " .. title .. C.reset
end

local function Join(lines)
    return table.concat(lines, "\n")
end

-- ============================================================================
-- PROGRESSION DATA
--
-- The backend value represents the HIGHEST COMPLETED progression milestone.
-- Molten Core and Onyxia are separate player-facing tabs. Tier 1 remains
-- locked until Molten Core progression has been completed.
-- ============================================================================

local VANILLA_STAGES = {
    mc = {
        nav = "Tier 0     Molten Core",
        title = "Tier 0 - Molten Core",
        short = "Opening Vanilla Raid",
        icon = "Interface\\Icons\\Spell_Fire_Fire",
        minValue = 0,
        completeAt = 1,
        objective = "Defeat Ragnaros in Molten Core.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Molten Core is your first Vanilla progression milestone. The goal of this page is to take you from fresh level-60 preparation all the way to Ragnaros without leaving the important access and rune steps unexplained.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Ragnaros. His defeat advances the character to Tier 1 - Onyxia's Lair.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Prepare your character for level-60 raiding"),
                Bullet("Build a strong Pre-Raid set from Blackrock Depths, Lower/Upper Blackrock Spire, Scholomance, Stratholme, quests, professions and PvP."),
                Bullet("Dungeon Set 2 is enabled early on this server, so begin the upgrade chain now if it is useful to your class."),
                Bullet("Bring class consumables, food, bandages and Greater Fire Protection Potions. Make sure important weapon skills are capped."),
                "",
                Step(2, "Complete Attunement to the Core"),
                Priority("QUEST", "Pick up Attunement to the Core from Lothos Riftwaker in Blackrock Mountain.", C.yellow),
                Bullet("Enter Blackrock Depths and travel to the Molten Core portal near the end of the dungeon."),
                Bullet("Loot the Core Fragment beside the portal and return the quest to Lothos."),
                Priority("SERVER RULE", "Your first Molten Core entry must still be made through the internal Blackrock Depths entrance near the end of BRD.", C.orange),
                Bullet("After the attunement and first-entry requirement are satisfied, the Lothos shortcut can be used for later runs."),
                "",
                Step(3, "Start Hydraxian Waterlords before your raid gets stuck at Majordomo"),
                Priority("REQUIRED", "Rune dousing is manual on this server.", C.red),
                Bullet("Visit Duke Hydraxis in Azshara and work through the Hydraxian Waterlords questline while gaining reputation in Molten Core."),
                Bullet("Reach the point where Aqual Quintessence is available. At Revered, Eternal Quintessence becomes the reusable option."),
                Bullet("Do not leave this until the raid has already cleared the instance; you need dousing access before Majordomo can be summoned."),
                "",
                Step(4, "Clear the eight opening Molten Core bosses"),
                Bullet("Recommended boss route: Lucifron -> Magmadar -> Gehennas -> Garr -> Baron Geddon -> Shazzrah -> Sulfuron Harbinger -> Golemagg the Incinerator."),
                Bullet("The seven rune bosses are Magmadar, Gehennas, Garr, Baron Geddon, Shazzrah, Sulfuron Harbinger and Golemagg."),
                "",
                Step(5, "Douse every Firelord rune"),
                Priority("REQUIRED", "After each rune boss is dead, use Aqual/Eternal Quintessence on its rune.", C.red),
                Bullet("All seven runes must be doused before Majordomo Executus becomes available."),
                Bullet("Aqual Quintessence is single-use and unique, so plan several attuned raiders or return trips. Eternal Quintessence retains its normal 1-hour cooldown on this server."),
                "",
                Step(6, "Defeat Majordomo Executus"),
                Bullet("Once all required bosses are dead and all seven runes are doused, Majordomo appears."),
                Bullet("Defeat his guards to force him to submit; he then moves to Ragnaros' chamber and summons the Firelord."),
                "",
                Step(7, "Defeat Ragnaros"),
                Priority("FINAL STEP", "Kill Ragnaros to complete Tier 0 and unlock Tier 1.", C.red),
                "",
                SH("RECOMMENDED BEFORE ADVANCING"),
                Bullet("Keep Molten Core in the weekly schedule for Tier 1 gear, Tier 1 set pieces and important rare drops."),
                Bullet("Continue Argent Dawn naturally through Scholomance/Stratholme; it will matter much later for Naxxramas and also provides recipes/rewards."),
                Bullet("Thorium Brotherhood is worth progressing for relevant crafting plans and Fire Resistance-related recipes."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 1 - Onyxia's Lair becomes available only after Molten Core progression is complete.", C.green),
            })
        end,
    },

    onyxia = {
        nav = "Tier 1     Onyxia's Lair",
        title = "Tier 1 - Onyxia's Lair",
        short = "Onyxia attunement and raid",
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
        minValue = 1,
        completeAt = 2,
        objective = "Defeat Onyxia in Onyxia's Lair.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 1 is centred on completing the full Onyxia attunement, obtaining the Drakefire Amulet and defeating Onyxia. The raid is short; the attunement is the real preparation work.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Onyxia. Her defeat advances the character to Tier 2 - Blackwing Lair.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Begin the faction-specific Onyxia attunement"),
                Priority("REQUIRED", "Every raider needs a Drakefire Amulet in their inventory to enter Onyxia's Lair.", C.red),
                "",
                H("Horde route - main chain anchors"),
                Bullet("Start Warlord's Command and complete the Blackrock Spire objectives."),
                Bullet("Continue: Eitrigg's Wisdom -> For The Horde! -> What the Wind Carries -> The Champion of the Horde -> The Testament of Rexxar."),
                Bullet("Complete Oculus Illusions and the Emberstrife step."),
                Bullet("Finish the Test of Skulls objectives: Scryer, Somnus, Chronalis and Axtroz."),
                Bullet("Continue through Ascension... and Blood of the Black Dragon Champion, including the required Upper Blackrock Spire work."),
                "",
                H("Alliance route - main chain anchors"),
                Bullet("Start Dragonkin Menace and continue through The True Masters chain."),
                Bullet("Find Marshal Windsor in Blackrock Depths and continue through Abandoned Hope / A Crumpled Up Note / A Shred of Hope."),
                Bullet("Complete Jail Break!, then Stormwind Rendezvous and The Great Masquerade."),
                Bullet("Continue to The Dragon's Eye and finish the final Upper Blackrock Spire requirement for the Drakefire Amulet."),
                "",
                Step(2, "Finish the Upper Blackrock Spire portion"),
                Bullet("Both faction routes eventually require Upper Blackrock Spire progression before the final amulet is awarded."),
                Bullet("Use these runs to improve gear and prepare for the Blackrock content that follows Onyxia."),
                "",
                Step(3, "Obtain and carry the Drakefire Amulet"),
                Priority("ENTRY REQUIREMENT", "Do not bank the amulet before the raid. It must be in the character's inventory when entering Onyxia's Lair.", C.orange),
                "",
                Step(4, "Prepare for the Onyxia encounter"),
                Bullet("Bring normal raid consumables and make sure tanks/healers are prepared for a threat-resetting, multi-phase dragon encounter."),
                Bullet("Continue Molten Core farming alongside this tier; Onyxia does not replace MC in the weekly schedule."),
                "",
                Step(5, "Defeat Onyxia"),
                Priority("FINAL STEP", "Kill Onyxia to complete Tier 1 and unlock Blackwing Lair progression.", C.red),
                "",
                Step(6, "Use Onyxia's scales to prepare for Blackwing Lair"),
                Priority("IMPORTANT", "Begin producing Onyxia Scale Cloaks after Onyxia kills. Shadowflame protection becomes important in BWL.", C.orange),
                Bullet("Make enough cloaks for the raid rather than discovering the requirement halfway through BWL progression."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 2 - Blackwing Lair becomes your next required raid progression stage.", C.green),
            })
        end,
    },

    bwl = {
        nav = "Tier 2     Blackwing Lair",
        title = "Tier 2 - Blackwing Lair",
        short = "Blackwing Lair + Dire Maul",
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
        minValue = 2,
        completeAt = 3,
        objective = "Defeat Nefarian.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Blackwing Lair is the next major raid. This tier also brings Dire Maul and the first strong world-boss window into your normal gearing route.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Nefarian. His defeat advances the character to Tier 3 - Pre-AQ.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Complete Blackhand's Command"),
                Priority("QUEST", "Kill the Scarshield Quartermaster near the Blackrock Spire entrance and loot Blackhand's Command.", C.yellow),
                Bullet("Run Upper Blackrock Spire and defeat General Drakkisath."),
                Bullet("Use the Orb of Ascension behind Drakkisath to complete the quest."),
                "",
                Step(2, "Make the required first entry through Blackrock Spire"),
                Priority("SERVER RULE", "Your first Blackwing Lair entry must be made through the internal entrance inside Upper Blackrock Spire.", C.orange),
                Bullet("After the first-entry/access requirement is established, the Orb of Command outside Blackrock Spire becomes the convenient raid entrance."),
                "",
                Step(3, "Prepare Onyxia Scale Cloaks"),
                Priority("IMPORTANT", "Have cloaks ready before the Shadowflame portion of the raid.", C.orange),
                Bullet("Use Onyxia scales from Tier 1 farming to produce enough cloaks for the raid group."),
                "",
                Step(4, "Use Dire Maul to finish weak gear slots"),
                Priority("NOW RELEVANT", "Run Dire Maul East, West and North during this tier.", C.orange),
                Bullet("Look for class quests, librams/enchants, profession recipes and North Tribute rewards/buffs."),
                Bullet("Re-check old Pre-Raid BiS lists because several slots may now have better Dire Maul options."),
                "",
                Step(5, "Progress through Blackwing Lair in boss order"),
                Bullet("Razorgore the Untamed -> Vaelastrasz the Corrupt -> Broodlord Lashlayer."),
                Bullet("Firemaw -> Ebonroc -> Flamegor."),
                Bullet("Chromaggus -> Nefarian."),
                Bullet("Do not rush the later dragon section without the cloak/consumable preparation your raid needs."),
                "",
                Step(6, "Defeat Nefarian"),
                Priority("FINAL STEP", "Nefarian completes Tier 2 and starts the Pre-AQ phase.", C.red),
                "",
                SH("HIGH-VALUE SIDE CONTENT DURING THIS TIER"),
                Bullet("Azuregos in Azshara and Lord Kazzak in the Blasted Lands are worth attempting while their loot is still meaningful."),
                Bullet("Continue Molten Core and Onyxia where important items, legendaries or tier pieces are still needed."),
                "",
                SH("PREPARE BEFORE ADVANCING"),
                Bullet("Begin stockpiling likely War Effort materials rather than starting the entire collection from zero in Tier 3."),
                Bullet("Start thinking about Nature Resistance options and Greater Nature Protection Potions for later AQ progression."),
                Bullet("Keep raid consumable production sustainable across MC/Onyxia/BWL rather than exhausting supplies before AQ."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 3 - Pre-AQ: Zul'Gurub, the War Effort and Scarab Gong progression become the focus.", C.green),
            })
        end,
    },

    preaq = {
        nav = "Tier 3     Pre-AQ",
        title = "Tier 3 - Pre-AQ",
        short = "War Effort + Scarab Gong",
        icon = "Interface\\Icons\\Ability_Hunter_Pet_Silithid",
        minValue = 3,
        completeAt = 4,
        objective = "Complete the War Effort and ring the Scarab Gong.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 3 is not a normal raid tier. It is a personal War Effort + Scarab Gong progression stage. Zul'Gurub is available as supporting raid content while you complete the required event work.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("WAR EFFORT", "Complete every required personal resource turn-in at least once and finish the 1,500 Commendation Signet requirement.", C.red),
                Priority("SCARAB GONG", "Complete the gong route and ring the Scarab Gong through the full Scepter path or the server's Simply Bang a Gong! alternative.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Complete every required War Effort resource turn-in at least once"),
                Bullet("Each distinct required resource donation quest must be completed at least one time."),
                Bullet("Once every required resource category has been completed, continue working toward the Commendation Signet total."),
                "",
                Step(2, "Farm and turn in resources for Commendation Signets"),
                Priority("SERVER REQUIREMENT", "Your completion target is 1,500 Commendation Signets.", C.red),
                Bullet("Use gathered, crafted and auctioned materials efficiently; work through profession/gathering resources in parallel rather than one category at a time."),
                Bullet("Keep track of the resource quests you have already completed so you do not finish the signet total while still missing a required category."),
                "",
                Step(3, "Use Zul'Gurub as the raid-support path"),
                Priority("UNLOCKED", "Zul'Gurub opens after Blackwing Lair on this server.", C.orange),
                Bullet("Run ZG for strong side-grades/upgrades, class head/leg enchants, Zandalar Tribe reputation and profession rewards."),
                Bullet("ZG is important support content, but killing Hakkar does not replace the War Effort/Gong progression gate."),
                "",
                Step(4, "Choose how you will reach the Scarab Gong"),
                Priority("FULL ROUTE", "Complete the Scepter of the Shifting Sands / Scarab Lord questline and finish Bang a Gong!.", C.yellow),
                Bullet("Choose this route if you want the complete AQ opening quest journey and its associated Scarab Lord-style rewards."),
                Priority("SHORTCUT", "Use the custom Simply Bang a Gong! quest at the Scarab Gong after the War Effort instead of completing the full Scepter chain.", C.purple),
                Bullet("The shortcut currently requires the Mallet of Zul'Farrak to ring the gong."),
                Priority("NO SCARAB LORD REWARDS", "The shortcut quest is progression-only: it does not award the Scarab Lord mount or title rewards from the full route.", C.orange),
                Priority("IMPORTANT", "Whichever route you choose, the gong objective still has to be completed before Tier 3 is finished.", C.orange),
                "",
                Step(5, "Prepare the raid for the AQ opening"),
                Bullet("Build Cenarion Circle reputation in Silithus and start collecting AQ-related materials."),
                Bullet("Prepare Nature Resistance pieces only for characters/encounters that actually need them; do not destroy normal throughput unnecessarily."),
                Bullet("Stock Greater Nature Protection Potions and maintain general raid consumables."),
                "",
                Step(6, "Ring the Scarab Gong and complete the stage"),
                Priority("FINAL STEP", "Once the War Effort requirements are complete, finish the gong objective to move into the outdoor AQ War stage.", C.red),
                "",
                SH("OPTIONAL - BEST DONE NOW"),
                Bullet("Dragons of Nightmare - Ysondre, Emeriss, Lethon and Taerar fit naturally into the Pre-AQ window."),
                Bullet("Finish any remaining Azuregos/Kazzak goals while their rewards still matter."),
                Bullet("Keep Argent Dawn moving in the background for Naxxramas later."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 4 - the Gates are open and the outdoor AQ War begins. AQ20 and AQ40 become available.", C.green),
            })
        end,
    },

    aqwar = {
        nav = "Tier 4     AQ War",
        title = "Tier 4 - AQ War",
        short = "Gates Open / Outdoor War",
        icon = "Interface\\Icons\\Spell_Nature_InsectSwarm",
        minValue = 4,
        completeAt = 5,
        objective = "Complete 'Chaos and Destruction' during the AQ War.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "The Gates of Ahn'Qiraj are open and the outdoor war is active. AQ20 and AQ40 can be entered now, but the stage itself is completed through the war quest 'Chaos and Destruction'.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("STAGE QUEST", "Complete 'Chaos and Destruction'. This is the progression requirement that ends the outdoor war stage.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Report to Silithus after the gong event"),
                Bullet("Pick up the outdoor-war quests available around Cenarion Hold / the Scarab Wall and participate in the active Ten Hour War content."),
                Bullet("Do not treat the newly opened raid portals as the only content in this stage; the outdoor war is part of the intended progression."),
                "",
                Step(2, "Complete 'Chaos and Destruction'"),
                Priority("REQUIRED", "Follow the stage quest objectives until Chaos and Destruction can be turned in.", C.red),
                Bullet("Finishing this quest is what advances the personal progression state from the war phase into the normal AQ raid phase."),
                "",
                Step(3, "Begin AQ20 while the war is active"),
                Bullet("Use Ruins of Ahn'Qiraj for useful gear, class skill books, Cenarion Circle reputation and AQ practice."),
                Bullet("AQ20 is not the final progression gate, but it is one of the best places to strengthen weak raid members before deeper AQ40 progression."),
                "",
                Step(4, "Begin AQ40 if your raid is ready"),
                Bullet("Temple of Ahn'Qiraj is already open in this phase, so early AQ40 progression is allowed."),
                Bullet("Some later equipment/reward NPCs remain phased until the outdoor war is finished, so do not assume every AQ reward turn-in is available yet."),
                "",
                Step(5, "Build the two AQ reputations"),
                Bullet("Continue Cenarion Circle through Silithus/AQ activities."),
                Bullet("Begin Brood of Nozdormu reputation through AQ40. Save valuable turn-ins intelligently if normal trash still gives useful reputation."),
                "",
                Step(6, "Finish the outdoor war before treating AQ as a normal raid tier"),
                Priority("FINAL STEP", "Turn in Chaos and Destruction to end Tier 4 and fully transition into the Ahn'Qiraj raid stage.", C.red),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 5 - full AQ40 progression, post-war reward NPCs and the push to C'Thun.", C.green),
            })
        end,
    },

    aq = {
        nav = "Tier 5     Ahn'Qiraj",
        title = "Tier 5 - Ahn'Qiraj",
        short = "AQ40 Progression",
        icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_04",
        minValue = 5,
        completeAt = 6,
        objective = "Defeat C'Thun in AQ40.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "The outdoor AQ War is over. Tier 5 is the full Temple of Ahn'Qiraj progression stage, with C'Thun as the boss that advances the character to Naxxramas.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat C'Thun in AQ40.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Use the post-war Silithus reward system"),
                Bullet("Re-check Cenarion Hold and AQ quest NPCs now that the war is over; additional equipment/reward turn-ins are available in this phase."),
                Bullet("Use AQ20 skill books, reputation rewards and gear to fix weak raid slots before difficult AQ40 encounters."),
                "",
                Step(2, "Prepare AQ-specific consumables and resistance"),
                Bullet("Carry Greater Nature Protection Potions and encounter-specific consumables where your raid strategy calls for them."),
                Bullet("Build Nature Resistance sets only for the roles/encounters that need them; keep normal DPS/healing/tanking stats where possible."),
                "",
                Step(3, "Progress through the required AQ40 path"),
                Bullet("The Prophet Skeram -> Battleguard Sartura -> Fankriss the Unyielding -> Princess Huhuran."),
                Bullet("Continue to the Twin Emperors, then open the route to C'Thun."),
                Bullet("The Bug Trio, Viscidus and Ouro are valuable optional bosses; kill them when their loot/reputation is worth the raid time."),
                "",
                Step(4, "Build Brood of Nozdormu and Cenarion Circle reputation"),
                Bullet("Use AQ40 kills and turn-ins for Brood of Nozdormu ring/Tier 2.5 progression."),
                Bullet("Use Cenarion Circle for Silithus/AQ rewards and profession recipes."),
                "",
                Step(5, "Start Naxxramas preparation before C'Thun dies"),
                Priority("IMPORTANT", "Push Argent Dawn now rather than waiting until Tier 6.", C.orange),
                Bullet("At least Honored is required for the classic Naxxramas attunement; higher reputation reduces the material/gold cost."),
                Bullet("Start collecting Frost Resistance options, endgame consumables and profession materials for Naxx progression."),
                "",
                Step(6, "Defeat C'Thun"),
                Priority("FINAL STEP", "Kill C'Thun to complete Tier 5 and unlock Naxxramas / the Scourge Invasion stage.", C.red),
                "",
                SH("RECOMMENDED BEFORE ADVANCING"),
                Bullet("Finish important ZG class enchants/reputation rewards and remaining world-boss goals."),
                Bullet("Complete valuable AQ20/AQ40 side bosses and Tier 2.5 pieces you expect to use in Naxxramas."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 6 - Naxxramas 40 and the Scourge Invasion.", C.green),
            })
        end,
    },

    naxx = {
        nav = "Tier 6     Naxxramas",
        title = "Tier 6 - Naxxramas",
        short = "Naxxramas + Scourge Invasion",
        icon = "Interface\\Icons\\Spell_Shadow_AnimateDead",
        minValue = 6,
        completeAt = 7,
        objective = "Attune to Naxxramas and defeat Kel'Thuzad.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 6 is the final Vanilla raid tier. You must attune, make the special first entry through Stratholme, progress the four Naxxramas wings, defeat Sapphiron and finally defeat Kel'Thuzad.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Kel'Thuzad in Naxxramas 40.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Reach the required Argent Dawn reputation"),
                Priority("MINIMUM", "You must be at least Honored with the Argent Dawn to attune.", C.orange),
                Bullet("If you are short, farm Scholomance, Stratholme, Scourgestones and relevant quests/turn-ins before paying the attunement cost."),
                Bullet("Higher reputation also gives recipes and other rewards, so Revered/Exalted can be worthwhile beyond the cheaper attunement."),
                "",
                Step(2, "Complete The Dread Citadel - Naxxramas"),
                Priority("QUEST", "Take the attunement from Archmage Angela Dosantos at Light's Hope Chapel.", C.yellow),
                Bullet("Honored cost: 60g + 5 Arcane Crystals + 2 Nexus Crystals + 1 Righteous Orb."),
                Bullet("Revered cost: 30g + 2 Arcane Crystals + 1 Nexus Crystal."),
                Bullet("Exalted: free attunement."),
                "",
                Step(3, "Make the server-required first entry through Stratholme"),
                Priority("SERVER RULE", "Your first Naxxramas entry must be through the original entrance at the back of Stratholme.", C.red),
                Bullet("After that first successful entry, the Eastern Plaguelands teleport crystal can be used for future Naxxramas runs."),
                "",
                Step(4, "Prepare the raid before committing to Naxx progression"),
                Bullet("Stock flasks/elixirs, protection potions, food, bandages, class reagents and repair gold."),
                Bullet("Prepare Frost Resistance for the late Naxx path, especially Sapphiron, without sacrificing more normal stats than needed."),
                Bullet("Finish important profession-crafted endgame pieces before distributing scarce raid materials."),
                "",
                Step(5, "Progress the four wings"),
                H("Spider Wing"),
                Bullet("Anub'Rekhan -> Grand Widow Faerlina -> Maexxna."),
                H("Plague Wing"),
                Bullet("Noth the Plaguebringer -> Heigan the Unclean -> Loatheb."),
                H("Military Wing"),
                Bullet("Instructor Razuvious -> Gothik the Harvester -> The Four Horsemen."),
                H("Construct Wing"),
                Bullet("Patchwerk -> Grobbulus -> Gluth -> Thaddius."),
                "",
                Step(6, "Defeat Sapphiron"),
                Bullet("Once the four wings are complete, move into the Frostwyrm Lair and defeat Sapphiron."),
                "",
                Step(7, "Defeat Kel'Thuzad"),
                Priority("FINAL STEP", "Kel'Thuzad completes Tier 6 and the Vanilla raid journey.", C.red),
                "",
                SH("SCOURGE INVASION - DO NOT IGNORE"),
                Priority("IMPORTANT", "Complete the main Scourge Invasion content while this stage is active.", C.orange),
                Bullet("The six invasion dungeon bosses are enabled early on this server, so some may already have been killed; still check event rares, rewards and remaining objectives."),
                "",
                SH("WORLD / FLIGHT PATH CHECK"),
                Priority("UNPHASED BY NOW", "Ratchet, Marshal's Refuge, Emerald Sanctuary, The Bulwark and Thondroril River are all available by Tier 6.", C.green),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 7 - the Dark Portal invasion / Pre-TBC transition.", C.green),
            })
        end,
    },

    pretbc = {
        nav = "Tier 7     Pre-TBC",
        title = "Tier 7 - Pre-TBC",
        short = "Dark Portal Invasion",
        icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
        minValue = 7,
        completeAt = 8,
        objective = "Complete 'Into the Breach'.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 7 is a transition/event stage rather than another Vanilla raid. Complete the Dark Portal invasion objective, finish the Vanilla goals you still care about, then purchase the TBC expansion unlock from Chronomancer Vezrath when you are ready.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("STAGE QUEST", "Complete 'Into the Breach'.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Travel to the Dark Portal event"),
                Bullet("Report to the event NPCs in the Blasted Lands / Dark Portal area and pick up the invasion quests available for this stage."),
                "",
                Step(2, "Complete Into the Breach"),
                Priority("REQUIRED", "Participate in the invasion and finish the objectives for Into the Breach.", C.red),
                Bullet("Turning in the required stage quest completes the Pre-TBC progression milestone."),
                "",
                Step(3, "Finish any Vanilla goals before buying TBC access"),
                Bullet("Complete remaining MC / Onyxia / BWL / ZG / AQ / Naxx items you still care about."),
                Bullet("Finish valuable reputation rewards, rare profession recipes and world-boss targets."),
                Bullet("Buy or craft recipes/items that become inconvenient to return for later."),
                Bullet("All five later-Vanilla phased flight paths are already available at this point."),
                "",
                Step(4, "Prepare the character for the expansion change"),
                Bullet("Have enough gold for the expansion service and the early Outland costs that follow."),
                Bullet("Remember that Jewelcrafting becomes available in TBC, while Inscription remains locked until Wrath."),
                Bullet("Your talent rules change in TBC: Rows 1-8 fully open, middle of Row 9 only, Rows 10-11 blocked."),
                "",
                Step(5, "Visit Chronomancer Vezrath"),
                Priority("CHARACTER SERVICE", "Speak with Chronomancer Vezrath near the faction leader in any capital city.", C.orange),
                Bullet("Vanilla -> TBC unlock cost: 2,500 gold."),
                Bullet("Completing Into the Breach alone does not purchase the expansion unlock; the Vezrath service is a separate step."),
                "",
                Step(6, "Enter Outland and begin the TBC journey"),
                Priority("NEXT ERA", "After the expansion unlock, Outland and level-70 progression become your focus.", C.green),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 8 - Karazhan, Gruul's Lair and Magtheridon's Lair.", C.green),
            })
        end,
    },
}

local TBC_STAGES = {
    tbc8 = {
        nav = "Tier 8     Kara / Gruul / Mag",
        title = "Tier 8 - Karazhan / Gruul / Magtheridon",
        short = "Opening Burning Crusade raids",
        icon = "Interface\\Icons\\INV_Misc_Key_10",
        minValue = 8,
        completeAt = 9,
        objective = "Defeat Prince Malchezaar in Karazhan.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 8 starts when TBC is unlocked and ends when Prince Malchezaar is defeated. The intended route is: level to 70, unlock the dungeon network, obtain the Master's Key, clear the opening raids and start the Tier 9 attunements before you leave this stage.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Prince Malchezaar in Karazhan. This advances the character to Tier 9.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Level through Outland and build dungeon reputations"),
                Bullet("Level from 60 to 70 through quests and Normal dungeons; use dungeon runs to build Thrallmar/Honor Hold, Cenarion Expedition, Lower City, Keepers of Time and The Sha'tar."),
                Bullet("At level 70, finish any missing Heroic access requirements and begin Heroics for gear/reputation. Do not wait for every Heroic to be complete before starting Karazhan."),
                Bullet("Raise primary professions toward 375. Jewelcrafting is available; Inscription remains locked."),
                "",
                Step(2, "Complete the Karazhan Master's Key attunement"),
                Priority("REQUIRED", "Every character entering Karazhan must complete the restored Master's Key route.", C.red),
                Bullet("Archmage Alturus: Arcane Disturbances + Restless Activity."),
                Bullet("Continue Contact from Dalaran -> Khadgar -> Entry Into Karazhan."),
                Bullet("First Key Fragment: Shadow Labyrinth, near/after Murmur."),
                Bullet("Second Key Fragment: The Steamvault."),
                Bullet("Third Key Fragment: The Arcatraz."),
                Bullet("Complete the Caverns of Time access route through Old Hillsbrad so Black Morass is available."),
                Bullet("The Master's Touch: protect Medivh through The Black Morass, then Return to Khadgar and receive The Master's Key."),
                "",
                Step(3, "Begin Karazhan and unlock Nightbane"),
                Bullet("Progress the raid through Moroes / Opera / Curator / Chess and the other bosses your raid chooses to clear."),
                Priority("IMPORTANT", "Complete the Nightbane summon chain and defeat Nightbane; his Blazing Signet is needed for Serpentshrine Cavern attunement.", C.orange),
                Bullet("Treat optional Karazhan bosses as useful gearing/reputation content rather than skipping everything that is not required for Prince."),
                "",
                Step(4, "Clear Gruul's Lair"),
                Bullet("Defeat High King Maulgar, then Gruul the Dragonkiller."),
                Priority("KEEP THE DROP", "Gruul's Earthen Signet is needed for The Cudgel of Kar'desh / SSC attunement.", C.orange),
                "",
                Step(5, "Clear Magtheridon's Lair"),
                Bullet("Magtheridon's Lair has no separate entry attunement, but Magtheridon is later required by Trial of the Naaru: Magtheridon."),
                Bullet("Do not postpone him until after Prince if you want the Tempest Keep attunement ready on time."),
                "",
                Step(6, "Start the Serpentshrine Cavern attunement"),
                Bullet("Enter Heroic Slave Pens and speak to Skar'this the Heretic for The Cudgel of Kar'desh."),
                Bullet("You will need the Earthen Signet from Gruul and the Blazing Signet from Nightbane."),
                "",
                Step(7, "Start the Tempest Keep attunement"),
                Bullet("Complete the Shadowmoon Valley chain beginning with The Hand of Gul'dan and continue through Oronok Torn-heart / The Cipher of Damnation."),
                Bullet("This unlocks The Tempest Key and the Trial of the Naaru quests from A'dal."),
                Bullet("Work on the Heroic requirements during Tier 8: Shattered Halls, Steamvault, Shadow Labyrinth and Arcatraz."),
                "",
                Step(8, "Defeat Prince Malchezaar"),
                Priority("FINAL STEP", "Prince Malchezaar is the actual Individual Progression trigger for Tier 9.", C.red),
                "",
                SH("STRONGLY RECOMMENDED BEFORE ADVANCING"),
                Bullet("Have Gruul and Nightbane completed so SSC attunement can be finished quickly."),
                Bullet("Have Magtheridon completed or ready for the final Trial of the Naaru step."),
                Bullet("Have all five Heroic-access factions progressed far enough that the required Heroics are not blocked."),
                Bullet("Attempt Doom Lord Kazzak and Doomwalker during this tier if their loot is useful."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 9 - Serpentshrine Cavern and Tempest Keep: The Eye.", C.green),
            })
        end,
    },

    tbc9 = {
        nav = "Tier 9     SSC / Tempest Keep",
        title = "Tier 9 - Serpentshrine Cavern / Tempest Keep",
        short = "Serpentshrine Cavern and The Eye progression",
        icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2",
        minValue = 9,
        completeAt = 10,
        objective = "Defeat Kael'thas Sunstrider in The Eye.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 9 is where the TBC attunement network pays off. Finish SSC and Tempest Keep access, clear both raids, collect Vashj and Kael'thas' vial remnants and defeat Kael'thas to advance.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Kael'thas Sunstrider in The Eye.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Finish Serpentshrine Cavern attunement"),
                Priority("QUEST", "Complete The Cudgel of Kar'desh from Skar'this the Heretic in Heroic Slave Pens.", C.red),
                Bullet("Bring the Earthen Signet from Gruul the Dragonkiller."),
                Bullet("Bring the Blazing Signet from Nightbane in Karazhan."),
                Bullet("Return both signets to Skar'this to complete the SSC attunement."),
                "",
                Step(2, "Finish Tempest Keep attunement"),
                Priority("REQUIRED", "Complete The Cipher of Damnation route and all Trial of the Naaru quests.", C.red),
                Bullet("Trial of the Naaru: Mercy - Heroic Shattered Halls; complete the timed execution rescue and recover the Unused Axe of the Executioner."),
                Bullet("Trial of the Naaru: Strength - Heroic Steamvault for Kalithresh's Trident and Heroic Shadow Labyrinth for Murmur's Essence."),
                Bullet("Trial of the Naaru: Tenacity - Heroic Arcatraz; rescue Millhouse Manastorm and keep him alive."),
                Bullet("Trial of the Naaru: Magtheridon - defeat Magtheridon and return to A'dal for the restored final step / Tempest Key route."),
                "",
                Step(3, "Clear Serpentshrine Cavern properly"),
                Priority("SERVER RULE", "All SSC bosses must be defeated before Lady Vashj's console can be used.", C.orange),
                Bullet("Hydross the Unstable -> The Lurker Below -> Leotheras the Blind -> Fathom-Lord Karathress -> Morogrim Tidewalker -> Lady Vashj."),
                Bullet("Defeat Lady Vashj and keep her Vial Remnant for The Vials of Eternity."),
                "",
                Step(4, "Clear Tempest Keep: The Eye properly"),
                Priority("SERVER RULE", "All Tempest Keep bosses must be defeated before the path to Kael'thas is available.", C.orange),
                Bullet("Al'ar -> Void Reaver -> High Astromancer Solarian -> Kael'thas Sunstrider."),
                "",
                Step(5, "Complete The Vials of Eternity"),
                Priority("REQUIRED FOR NEXT TIER", "Collect the vial remnants from Lady Vashj and Kael'thas and complete The Vials of Eternity.", C.orange),
                Bullet("This is the restored Mount Hyjal access requirement. Do not wait until Tier 10 to discover you forgot one of the two raid items."),
                "",
                Step(6, "Continue the Black Temple attunement chain"),
                Bullet("Complete the Shadowmoon Valley Ashtongue/Akama chain through Akama's Promise before the raid continuation steps."),
                Bullet("You want the chain ready to continue as soon as SSC/TK objectives unlock the next pieces."),
                "",
                Step(7, "Defeat Kael'thas"),
                Priority("FINAL STEP", "Kael'thas advances the character to Tier 10 - Mount Hyjal / Black Temple.", C.red),
                "",
                SH("RECOMMENDED BEFORE ADVANCING"),
                Bullet("Finish Lady Vashj even if Kael'thas is your progression trigger; Hyjal access requires both vial remnants."),
                Bullet("Keep Aldor/Scryer reputation moving for shoulder enchants, recipes and Black Temple questing."),
                Bullet("Continue Violet Eye and useful Heroics only where they still give meaningful upgrades/attunement progress."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 10 - Battle for Mount Hyjal and Black Temple.", C.green),
            })
        end,
    },

    tbc10 = {
        nav = "Tier 10   Hyjal / Black Temple",
        title = "Tier 10 - Mount Hyjal / Black Temple",
        short = "Mount Hyjal and Black Temple progression",
        icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
        minValue = 10,
        completeAt = 12,
        objective = "Defeat Illidan Stormrage in Black Temple.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 10 combines Mount Hyjal and Black Temple. The important order is: finish Vials, clear Hyjal, finish the Black Temple attunement, obtain the Medallion of Karabor, then clear Black Temple and defeat Illidan.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Illidan Stormrage. The progression state jumps past the unused ZA tier and opens Tier 12 / Sunwell-era content.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Confirm The Vials of Eternity is complete"),
                Priority("MOUNT HYJAL ACCESS", "You need the vial remnants from Lady Vashj and Kael'thas and must complete The Vials of Eternity.", C.red),
                Bullet("If one vial is missing, return to the appropriate Tier 9 raid before planning a Hyjal clear."),
                "",
                Step(2, "Clear Battle for Mount Hyjal"),
                Bullet("Rage Winterchill -> Anetheron -> Kaz'rogal -> Azgalor -> Archimonde."),
                Bullet("Build Scale of the Sands reputation naturally while raiding; its ring/reward track is part of this tier's value."),
                "",
                Step(3, "Finish the Black Temple attunement chain"),
                Priority("REQUIRED", "Complete the restored Akama / Medallion of Karabor route.", C.red),
                Bullet("Early chain anchors: Tablets of Baa'ri -> Oronu the Elder -> The Ashtongue Corruptors -> The Warden's Cage -> Akama -> Seer Udalo -> A Mysterious Portent -> The Ata'mal Terrace -> Akama's Promise."),
                Bullet("Raid continuation: The Secret Compromised -> Ruse of the Ashtongue -> An Artifact From the Past -> The Hostage Soul -> Entry Into the Black Temple -> A Distraction for Akama."),
                Bullet("Receive the Medallion of Karabor and keep it available for the restored access requirement."),
                "",
                Step(4, "Use the server group attunement helper when appropriate"),
                Bullet("If your group is using the IP helper, an eligible attuned player can use `.ip attune blacktemple` to provide the required medallion to eligible group members under the server command rules."),
                "",
                Step(5, "Clear Black Temple in progression order"),
                Bullet("High Warlord Naj'entus -> Supremus -> Shade of Akama."),
                Bullet("Teron Gorefiend -> Gurtogg Bloodboil -> Reliquary of Souls."),
                Bullet("Mother Shahraz -> Illidari Council -> Illidan Stormrage."),
                "",
                Step(6, "Defeat Illidan"),
                Priority("FINAL STEP", "Illidan completes Tier 10 and unlocks the final TBC era on this server.", C.red),
                "",
                SH("SIDE CONTENT THAT OPENS / BECOMES BEST NOW"),
                Priority("ZUL'AMAN", "Zul'Aman is optional side progression and does not have its own required Individual Progression tier.", C.purple),
                Bullet("Run ZA for timed-event rewards and strong side-grade/catch-up gear before or during Sunwell preparation."),
                Bullet("Continue Ashtongue Deathsworn and Scale of the Sands reputation for raid rewards/recipes."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 12 - Isle of Quel'Danas, Magisters' Terrace and Sunwell Plateau.", C.green),
            })
        end,
    },

    tbc12 = {
        nav = "Tier 12   Sunwell Plateau",
        title = "Tier 12 - Sunwell Plateau",
        short = "Isle of Quel'Danas and final TBC raid",
        icon = "Interface\\Icons\\Spell_Holy_SummonLightwell",
        minValue = 12,
        completeAt = 13,
        objective = "Defeat Kil'jaeden in Sunwell Plateau.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "This is the final Burning Crusade stage. Progress the Isle of Quel'Danas, complete Magisters' Terrace access, use Shattered Sun reputation rewards and clear Sunwell Plateau through Kil'jaeden.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Kil'jaeden. This completes TBC progression and opens the Wrath transition.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Begin Isle of Quel'Danas progression"),
                Bullet("Complete the Isle quest/daily content and build Shattered Sun Offensive reputation."),
                Bullet("Your personal Isle phases as reputation increases: Friendly, Honored and Revered unlock later versions of the hub/content."),
                Bullet("Check each new reputation tier for vendors, recipes and newly visible quest content."),
                "",
                Step(2, "Complete Normal Magisters' Terrace"),
                Bullet("Follow the Magisters' Terrace quest chain on Normal first."),
                Priority("HEROIC ACCESS", "Complete the Normal chain through Hard to Kill before treating Heroic Magisters' Terrace as part of your farming route.", C.orange),
                Bullet("Use Magisters' Terrace for late-TBC gear, Shattered Sun-related progression and useful final-stage drops."),
                "",
                Step(3, "Use Zul'Aman as optional preparation"),
                Bullet("ZA is already available after Illidan. Use it for timed-run rewards and strong gear if Sunwell exposes weak slots."),
                Bullet("Zul'jin does not advance Individual Progression; Kil'jaeden remains the required final TBC boss."),
                "",
                Step(4, "Prepare specifically for Sunwell"),
                Bullet("Finish high-value TBC enchants, gems, professions, consumables and resistance/utility pieces your raid strategy needs."),
                Bullet("Shattered Sun Offensive becomes the main new reputation; continue older raid reputations only for rewards still useful to you."),
                "",
                Step(5, "Progress through Sunwell Plateau"),
                Bullet("Kalecgos -> Brutallus -> Felmyst."),
                Bullet("Eredar Twins -> M'uru / Entropius -> Kil'jaeden."),
                Bullet("Treat each boss as a real gear/coordination check; do not expect Magisters' Terrace or ZA gear alone to replace Tier 10 raid preparation."),
                "",
                Step(6, "Defeat Kil'jaeden"),
                Priority("FINAL STEP", "Kil'jaeden completes the Burning Crusade progression state.", C.red),
                "",
                Step(7, "Prepare for the Wrath transition"),
                Bullet("Finish any TBC raid/reputation/profession goals you want recorded as part of the character's journey."),
                Priority("CHARACTER SERVICE", "When ready, visit Chronomancer Vezrath and purchase the TBC -> Wrath unlock for 7,500 gold.", C.orange),
                "",
                SH("NEXT ERA"),
                Priority("UNLOCK", "Wrath of the Lich King - Northrend, level 80 and Tier 13 raid progression.", C.green),
            })
        end,
    },
}

local TBC_OVERVIEW_PAGE = {
    title = "The Burning Crusade Roadmap",
    short = "Level 60-70 progression and raid preparation",
    icon = "Interface\\Icons\\Spell_Arcane_TeleportShattrath",
    body = function()
        return Join({
            SH("ENTERING THE BURNING CRUSADE"),
            Bullet("Complete the Vanilla Tier 7 transition and purchase the 2,500g Vanilla -> TBC unlock from Chronomancer Vezrath."),
            Bullet("Outland progression then opens and the level cap becomes 70."),
            Bullet("Jewelcrafting is now available; Inscription remains locked until Wrath."),
            Bullet("TBC talent rules apply: Rows 1-8 are open, only the middle talent of Row 9 is allowed, and Rows 10-11 remain blocked."),
            "",
            H("TBC RAID ROADMAP"),
            C.green .. "Tier 8" .. C.reset .. "       Karazhan / Gruul's Lair / Magtheridon's Lair",
            Bullet("Primary progression boss: Prince Malchezaar."),
            Bullet("Build level-70 Pre-Raid gear, heroic access, Karazhan attunement and Tier 9 attunement prerequisites."),
            "",
            C.green .. "Tier 9" .. C.reset .. "       Serpentshrine Cavern / Tempest Keep",
            Bullet("Restored SSC and The Eye attunements are required."),
            Bullet("Primary progression boss: Kael'thas Sunstrider."),
            "",
            C.green .. "Tier 10" .. C.reset .. "     Mount Hyjal / Black Temple",
            Bullet("The Vials of Eternity and Medallion of Karabor are required for access."),
            Bullet("Primary progression boss: Illidan Stormrage."),
            "",
            C.purple .. "SIDE CONTENT" .. C.reset .. "   Zul'Aman",
            Bullet("Unlocks after Black Temple on your server and does not advance the main progression state."),
            "",
            C.green .. "Tier 12" .. C.reset .. "     Sunwell Plateau / Isle of Quel'Danas",
            Bullet("Final TBC stage; build Shattered Sun Offensive reputation and defeat Kil'jaeden."),
            "",
            SH("THE BIG TBC PREP RULE"),
            Priority("IMPORTANT", "Do not wait until Tier 9 to think about heroic keys and attunements.", C.orange),
            Bullet("Several later raid attunements require Heroic dungeon objectives, Gruul, Magtheridon, Nightbane, SSC, TK and Hyjal kills."),
            Bullet("The best TBC pathway is to level, build faction reputation, unlock dungeon access, finish Karazhan, then keep future attunements moving in parallel with current raids."),
            "",
            SH("SUPPORT PAGES"),
            Bullet("Dungeons & Heroic Keys - leveling route, dungeon keys and Heroic preparation."),
            Bullet("TBC Reputations - heroic-access factions, raid reputations and optional endgame factions."),
            Bullet("TBC Professions - 375 progression, specialisations and recipe sources."),
            Bullet("TBC PvP - Arena Season 1 and level-70 PvP gearing."),
            Bullet("TBC World Bosses - Doom Lord Kazzak and Doomwalker timing."),
            Bullet("Zul'Aman - optional side raid after Black Temple."),
            "",
            SH("WORLD BOSSES"),
            Bullet("Doom Lord Kazzak and Doomwalker are optional high-value Tier 8 targets and are best tackled before later raid gear reduces their progression value."),
            "",
            SH("END OF TBC"),
            Bullet("After Kil'jaeden, Chronomancer Vezrath handles the 7,500g unlock into Wrath of the Lich King when you are ready."),
        })
    end,
}

local TBC_DUNGEONS_PAGE = {
    title = "TBC Dungeons & Heroic Keys",
    short = "Leveling route, dungeon access and heroic preparation",
    icon = "Interface\\Icons\\INV_Misc_Key_14",
    body = function()
        return Join({
            SH("WHY DUNGEONS MATTER SO MUCH IN TBC"),
            "TBC raid attunements repeatedly send you through normal and Heroic dungeons. Treat dungeon keys and faction reputation as raid preparation rather than optional side grinds.",
            "",
            SH("SUGGESTED LEVELING / DUNGEON ORDER"),
            Bullet("60-62: Hellfire Ramparts -> The Blood Furnace."),
            Bullet("62-64: The Slave Pens -> The Underbog."),
            Bullet("64-66: Mana-Tombs -> Auchenai Crypts."),
            Bullet("66-68: Old Hillsbrad Foothills -> Sethekk Halls."),
            Bullet("68-70: Shadow Labyrinth -> The Steamvault -> The Shattered Halls."),
            Bullet("Level 70: The Mechanar -> The Botanica -> The Arcatraz -> The Black Morass."),
            "",
            SH("HEROIC-KEY REPUTATIONS"),
            Priority("IMPORTANT", "Thrallmar / Honor Hold -> Flamewrought Key for Hellfire Citadel Heroics.", C.orange),
            Priority("IMPORTANT", "Cenarion Expedition -> Reservoir Key for Coilfang Heroics.", C.orange),
            Priority("IMPORTANT", "Lower City -> Auchenai Key for Auchindoun Heroics.", C.orange),
            Priority("IMPORTANT", "Keepers of Time -> Key of Time for Caverns of Time Heroics.", C.orange),
            Priority("IMPORTANT", "The Sha'tar -> Warpforged Key for Tempest Keep Heroics.", C.orange),
            Bullet("Raise each faction to the reputation required by its quartermaster and buy the key before the related raid attunement step blocks you."),
            "",
            SH("WHEN SHOULD I DO HEROIC DUNGEONS?"),
            Priority("LEVEL 60-69", "Focus on Normal dungeons, questing and reputation. You do not need to stop leveling just to prepare Heroics.", C.green),
            Priority("LEVEL 70 / TIER 8 PREP", "This is when Heroics should become part of your regular gearing route. Finish missing Heroic keys, improve pre-raid gear, earn reputation and collect useful dungeon rewards.", C.orange),
            Bullet("You do NOT need to clear every Heroic before starting Karazhan. Begin Karazhan when your character and group are ready."),
            Priority("DURING TIER 8", "Complete the Heroics required for SSC and Tempest Keep attunements before you finish Tier 8.", C.red),
            Bullet("Heroic Slave Pens - reach Skar'this the Heretic for The Cudgel of Kar'desh and the SSC attunement."),
            Bullet("Heroic Shattered Halls - Trial of the Naaru: Mercy."),
            Bullet("Heroic Steamvault + Heroic Shadow Labyrinth - Trial of the Naaru: Strength."),
            Bullet("Heroic Arcatraz - Trial of the Naaru: Tenacity."),
            Priority("BEFORE TIER 9", "Your required Heroic attunement objectives should be complete or nearly complete. Do not arrive at SSC / Tempest Keep with the Trial chain untouched.", C.red),
            Priority("TIER 9+", "Heroics become supplementary rather than your main progression route. Continue them for gear, badges, reputation, recipes or unfinished objectives.", C.yellow),
            Priority("TIER 12", "Complete the normal Magisters' Terrace quest chain before adding Heroic Magisters' Terrace to your endgame farming.", C.purple),
            "",
            SH("OTHER IMPORTANT DUNGEON ACCESS"),
            Priority("IMPORTANT", "Plan for flying at level 70; Tempest Keep's dungeon complex and several Outland endgame routes are designed around flying access.", C.orange),
            Bullet("Shadow Labyrinth Key - obtained through Sethekk Halls access progression."),
            Bullet("Shattered Halls Key - complete the key questline for convenient entry."),
            Bullet("Key to the Arcatraz - complete the Netherstorm key chain unless your group has another valid way to open the door."),
            Bullet("Caverns of Time - complete Old Hillsbrad before The Black Morass becomes part of the Karazhan attunement route."),
            "",
            SH("ATTUNEMENT CONNECTIONS"),
            Bullet("Karazhan uses Shadow Labyrinth, Steamvault, Arcatraz and Black Morass."),
            Bullet("SSC attunement begins in Heroic Slave Pens."),
            Bullet("The Eye attunement requires Heroic Shattered Halls, Steamvault, Shadow Labyrinth and Arcatraz, then Magtheridon."),
            "",
            SH("RECOMMENDED APPROACH"),
            Bullet("Use leveling dungeons to build reputation before level 70 rather than leaving every faction grind until raid week."),
            Bullet("At 70, finish missing keys and attunement dungeons before repeatedly farming content that does not advance access."),
        })
    end,
}

local TBC_REPUTATIONS_PAGE = {
    title = "TBC Reputations",
    short = "What to farm, when to farm it, and what each faction gives you",
    icon = "Interface\\Icons\\INV_Misc_Note_02",
    body = function()
        return Join({
            SH("HOW TO USE THIS PAGE"),
            "TBC reputation is part of progression, not just completionism. Some factions unlock Heroic dungeons, some provide powerful enchants and profession recipes, and others are tied directly to raids or optional endgame rewards.",
            "",
            Priority("FIRST PRIORITY", "While leveling and during Tier 8 preparation, focus first on the five dungeon factions connected to Heroic access.", C.red),
            Bullet("Do their zone quests while they are level-appropriate and run their normal dungeons while those dungeons are still useful for XP and gear."),
            Bullet("At level 70, finish any missing reputation needed to buy the related Heroic key and continue the factions that offer rewards important to your class or professions."),
            "",
            SH("CORE DUNGEON / HEROIC REPUTATIONS"),
            "These five factions are the most important early TBC reputations because their dungeon families feed directly into Heroic gearing and later raid attunements.",
            "",
            Priority("IMPORTANT", "Thrallmar / Honor Hold - Hellfire Peninsula", C.orange),
            Bullet("When: Start immediately after entering Outland. Hellfire quests, Hellfire Ramparts and The Blood Furnace make this one of the easiest reputations to begin while leveling."),
            Bullet("How: Quest through Hellfire Peninsula and use Ramparts / Blood Furnace early; The Shattered Halls and Heroic Hellfire Citadel dungeons continue the grind at higher level."),
            Bullet("Why: The quartermaster provides the Flamewrought Key for Hellfire Citadel Heroics, useful level-70 gear, profession recipes and an important role-specific head enchant."),
            Bullet("Progression value: Heroic Shattered Halls is later used by the Trial of the Naaru chain, so neglecting this reputation can delay Tempest Keep attunement."),
            "",
            Priority("IMPORTANT", "Cenarion Expedition - Zangarmarsh / Coilfang Reservoir", C.orange),
            Bullet("When: Start in Zangarmarsh and keep it moving through the 60s. It is particularly valuable for physical DPS, Feral tanks and several crafting professions."),
            Bullet("How: Cenarion quests, early Zangarmarsh turn-ins and the Coilfang dungeons all contribute. Slave Pens and Underbog are good leveling runs; Steamvault becomes a major level-70 reputation source."),
            Bullet("Why: The Reservoir Key opens Coilfang Heroics. The faction also offers strong gear, profession recipes and a highly useful physical-DPS head enchant; Feral Druids should also check the faction's weapon rewards."),
            Bullet("Progression value: Heroic Slave Pens begins the SSC attunement through Skar'this, while Heroic Steamvault is used in the Tempest Keep Trial chain."),
            "",
            Priority("IMPORTANT", "Lower City - Shattrath / Auchindoun", C.orange),
            Bullet("When: Begin while questing in Terokkar Forest and running Auchindoun. Do not leave it untouched until the week you want Heroic Shadow Labyrinth."),
            Bullet("How: Lower City quests, repeatable Arakkoa-related turn-ins and Auchindoun dungeons build reputation. Shadow Labyrinth becomes one of the main higher-level routes."),
            Bullet("Why: The Auchenai Key gives access to Auchindoun Heroics. The quartermaster also provides gear, profession recipes and a role-specific head enchant."),
            Bullet("Progression value: Heroic Shadow Labyrinth is required during the Trial of the Naaru: Strength step for Tempest Keep attunement."),
            "",
            Priority("IMPORTANT", "Keepers of Time - Caverns of Time", C.orange),
            Bullet("When: Begin as soon as Old Hillsbrad becomes appropriate and keep following the Caverns of Time quest chain into The Black Morass."),
            Bullet("How: Old Hillsbrad, Black Morass and their quests all award reputation. Unlike several other dungeon factions, these dungeons remain useful reputation sources for a long time."),
            Bullet("Why: The Key of Time opens Caverns of Time Heroics. The faction also provides useful gear, recipes and a tank-focused head enchant."),
            Bullet("Progression value: Completing Old Hillsbrad unlocks the path to Black Morass, and Black Morass is part of the Karazhan Master's Key attunement."),
            "",
            Priority("IMPORTANT", "The Sha'tar - Shattrath / Tempest Keep Dungeons", C.orange),
            Bullet("When: Start building it naturally once you reach Shattrath. Your Aldor or Scryer progression can help raise Sha'tar reputation before you begin serious Tempest Keep dungeon farming."),
            Bullet("How: Shattrath questing plus The Mechanar, The Botanica and The Arcatraz are the main practical sources at level 70."),
            Bullet("Why: The Warpforged Key opens Tempest Keep Heroics. The faction also supplies caster-focused rewards, profession recipes and an important spellcaster head enchant."),
            Bullet("Progression value: Heroic Arcatraz is part of Trial of the Naaru: Tenacity, and normal Arcatraz is also used during the Karazhan attunement route."),
            "",
            SH("SHATTRATH CHOICE / PROFESSION REPUTATIONS"),
            Priority("IMPORTANT CHOICE", "The Aldor OR The Scryers", C.orange),
            Bullet("When: Choose your allegiance after reaching Shattrath. Do this early enough that the items you collect while leveling can contribute to the faction you actually intend to keep."),
            Bullet("How: Each side uses its own repeatable signet/mark turn-ins plus Arcane Tomes or Fel Armaments at higher reputation, alongside quests in Shattrath, Netherstorm and Shadowmoon Valley."),
            Bullet("Why: Both factions provide powerful shoulder inscriptions, profession recipes, gear and access to faction-specific quest lines. Which is better depends on your class, spec and professions."),
            Bullet("Progression value: Your choice also feeds into later Shattrath content and parts of the Black Temple journey. Switching sides later is possible but deliberately time-consuming."),
            Bullet("Extra value: Building Aldor or Scryer reputation also helps your Sha'tar standing during the early part of that grind."),
            "",
            Priority("RECOMMENDED", "The Consortium - Nagrand / Netherstorm / Mana-Tombs", C.yellow),
            Bullet("When: Start casually in Nagrand and Mana-Tombs. Push it harder if you use Jewelcrafting, Enchanting or want its gem-related rewards."),
            Bullet("How: Mana-Tombs, Consortium quests, Obsidian Warbeads, Zaxxis Insignias and later Ethereum-related turn-ins can all be used."),
            Bullet("Why: The Consortium offers gear and recipes for several professions, especially Jewelcrafting. Higher standing also improves the monthly Membership Benefits gem package."),
            Bullet("High-value extra: At higher reputation you can access the additional Heroic Mana-Tombs boss Yor; Exalted eventually gives a permanent method of summoning him."),
            Bullet("Progression value: Useful and profitable, but not a main raid-progression gate. Prioritise it according to your professions and desired rewards."),
            "",
            SH("ZONE / OPTIONAL REPUTATIONS"),
            Priority("RECOMMENDED", "The Mag'har / Kurenai - Nagrand", C.yellow),
            Bullet("When: Work on your faction's version while leveling through Nagrand. Horde uses The Mag'har; Alliance uses Kurenai."),
            Bullet("How: Nagrand quests, Ogre / Kil'sorrow kills and Obsidian Warbead turn-ins can carry the reputation well beyond the normal quest path."),
            Bullet("Why: The main long-term rewards are Talbuk mounts, useful gear and profession recipes. Leatherworkers in particular should check the faction vendor."),
            Bullet("Progression value: Not required for raid access. Treat it as a strong leveling-side reputation and an optional mount/profession goal."),
            "",
            Priority("OPTIONAL", "Sporeggar - Zangarmarsh", C.purple),
            Bullet("When: Best started while you are already in Zangarmarsh, especially if you are killing Bog Lords, collecting Fertile Spores or running The Underbog."),
            Bullet("How: Early repeatable turn-ins raise the faction from its low starting reputation; later Fertile Spores, Sanguine Hibiscus and other repeatables can continue to Exalted."),
            Bullet("Why: Sporeggar uses Glowcaps as a vendor currency and offers unusual gear, consumables and profession recipes. It can be particularly worthwhile when a specific recipe is part of your profession plan."),
            Bullet("Progression value: Optional. Do not delay Heroic-key factions or raid attunements purely to finish Sporeggar."),
            "",
            Priority("OPTIONAL - MOUNTS", "Netherwing - Shadowmoon Valley", C.purple),
            Bullet("When: Start at level 70 once you have flying. Expert Riding is enough to begin the introductory chain, but Artisan Riding is required to continue the main reputation grind beyond Neutral."),
            Bullet("Where to begin: Find Mordenai in the Netherwing Fields of Shadowmoon Valley. The introductory story runs through Neltharaku, Dragonmaw Fortress, Karynaku and Zuluhed before Ally of the Netherwing raises you from Hated to Neutral."),
            Bullet("Neutral: Complete the Netherwing Ledge introduction and begin the first daily quests. Mining, Herbalism or Skinning can provide a profession-specific daily in addition to the normal daily route."),
            Bullet("Netherwing Eggs: Once unlocked, eggs found around Netherwing Ledge and related areas can be handed in repeatedly for extra reputation. They are particularly valuable because they speed up a grind otherwise limited heavily by daily quests."),
            Bullet("Friendly / Honored / Revered: More quest chains and daily quests unlock as your standing rises, so the reputation gain per day increases over time rather than staying fixed from Neutral to Exalted."),
            Bullet("How to approach it: Do the available dailies whenever you want steady progress, keep an eye out for Netherwing Eggs while on the Ledge, and complete each new reputation-rank quest chain as soon as it appears."),
            Bullet("Why: The main end reward is the Netherwing Drake collection. At Exalted you complete the final story and choose a Netherwing Drake; the other drake colours can then be obtained from the Netherwing mount vendor."),
            Bullet("Other value: The reputation chain provides substantial level-70 daily content and gold income, with additional quest rewards along the way. It is a long-term character goal rather than raid access."),
            Bullet("Progression value: Entirely optional. Do not delay Karazhan, Heroic attunements or required Tier 8 reputation work for Netherwing. It is best fitted around your raid progression once flying and your essential preparation are under control."),
            "",
            Priority("OPTIONAL - MOUNTS", "Sha'tari Skyguard - Skettis / Blade's Edge", C.purple),
            Bullet("When: Level 70 after gaining flying. It fits well as optional outdoor content alongside other daily reputations."),
            Bullet("How: Complete the Skettis quest chain, daily quests, mob farming and the Shadow Dust / Time-Lost Scroll summoning loop; later bosses culminate in Terokk."),
            Bullet("Why: Reputation unlocks gear and utility rewards, with Riding Nether Ray mounts as the main Exalted prize."),
            Bullet("Progression value: Optional. Useful for mounts and outdoor rewards, not a raid attunement requirement."),
            "",
            Priority("OPTIONAL", "Ogri'la - Blade's Edge Mountains", C.purple),
            Bullet("When: Level 70 after flying. Begin once your character can comfortably handle Blade's Edge endgame quests."),
            Bullet("How: Unlock the Ogri'la hub, then use daily quests and Apexis-related activities to build reputation."),
            Bullet("Why: Offers gear, profession-related rewards and Apexis Crystal content. Some activities overlap geographically with Sha'tari Skyguard progression."),
            Bullet("Progression value: Optional side progression. Good for extra rewards but not required for the main raid path."),
            "",
            SH("RAID REPUTATIONS"),
            Priority("IMPORTANT", "The Violet Eye - Karazhan", C.orange),
            Bullet("When: Tier 8. You do not need to stop and grind this separately; it rises naturally while completing the Karazhan attunement quests and clearing Karazhan."),
            Bullet("How: Karazhan quests, trash and bosses grant reputation all the way to Exalted."),
            Bullet("Why: The standout reward is the Violet Signet ring line, which upgrades as your reputation rises. Vendors also offer profession recipes and other raid-era rewards."),
            Bullet("Progression value: This is a natural Tier 8 raid reputation. Keep clearing Karazhan and remember to claim ring upgrades as they become available."),
            "",
            Priority("IMPORTANT", "The Scale of the Sands - Mount Hyjal", C.orange),
            Bullet("When: Tier 10, after completing The Vials of Eternity and gaining access to Mount Hyjal."),
            Bullet("How: Hyjal quests, trash and bosses build the reputation. Completing the Hyjal access quest gives you a strong starting boost."),
            Bullet("Why: The Band of Eternity ring is chosen early and upgraded through later reputation levels. The faction also provides Jewelcrafting recipes and sits alongside the Tier 6 token vendors."),
            Bullet("Progression value: Let it rise naturally with Hyjal clears; there is no reason to farm it before the raid is available."),
            "",
            Priority("IMPORTANT", "Ashtongue Deathsworn - Black Temple", C.orange),
            Bullet("When: Tier 10. The Black Temple attunement chain introduces the faction before you begin regular Black Temple clears."),
            Bullet("How: Attunement quests plus Black Temple trash and bosses build reputation to Exalted."),
            Bullet("Why: The faction sells numerous endgame crafting recipes, and Exalted unlocks class-specific Ashtongue Talisman trinkets."),
            Bullet("Progression value: A natural Black Temple reputation. It becomes increasingly valuable to raiders and crafters as Tier 10 farming continues."),
            "",
            Priority("IMPORTANT", "Shattered Sun Offensive - Isle of Quel'Danas", C.orange),
            Bullet("When: Tier 12 / Sunwell stage. This is the final major TBC reputation and should become a regular part of your endgame routine once the Isle is available."),
            Bullet("How: Isle questing, daily quests and Magisters' Terrace all provide reputation."),
            Bullet("Why: The quartermaster offers strong catch-up gear plus valuable Enchanting, Jewelcrafting, Alchemy and other profession rewards as your standing increases."),
            Bullet("Server-specific value: Your personal Shattered Sun reputation also controls parts of the Isle's phasing. Friendly, Honored and Revered progressively reveal later Isle content on this server."),
            Bullet("Progression value: High priority during the Sunwell stage because the reputation is both a reward track and part of how your personal Isle develops."),
            "",
            SH("SIMPLE PRIORITY BY STAGE"),
            Priority("LEVELING 60-69", "Thrallmar/Honor Hold -> Cenarion Expedition -> Lower City -> Keepers of Time, while choosing Aldor/Scryers and building useful side factions naturally.", C.green),
            Priority("LEVEL 70 / TIER 8", "Finish all five Heroic-key factions, add The Sha'tar, then let Violet Eye rise through Karazhan. Push Consortium or zone factions only when their rewards matter to you.", C.orange),
            Priority("TIER 9", "Keep Heroic-access factions healthy for unfinished attunements, but your main reputation work should now support current raids and professions.", C.yellow),
            Priority("TIER 10", "Scale of the Sands and Ashtongue Deathsworn become your natural raid reputations. Optional daily factions can be worked on between raids.", C.purple),
            Priority("TIER 12", "Shattered Sun Offensive becomes the main new reputation and should be progressed alongside Isle of Quel'Danas and Magisters' Terrace content.", C.red),
            "",
            SH("BOTTOM LINE"),
            "Do not try to Exalt every TBC faction before raiding. Build the reputations that unlock your next dungeon or raid step first, then push a faction further when its enchants, gear, profession recipes, mounts or other rewards are actually useful to your character.",
        })
    end,
}

local TBC_PROFESSIONS_PAGE = {
    title = "TBC Professions",
    short = "375 skill, standout crafts, specialisations and reputation recipes",
    icon = "Interface\\Icons\\Trade_Engineering",
    body = function()
        return Join({
            SH("PROFESSION CAP & TIMING"),
            Priority("IMPORTANT", "The Burning Crusade raises primary professions to 375. Work on them while leveling instead of waiting until every raid is open.", C.orange),
            Bullet("Jewelcrafting is available from TBC onward on this server. Inscription remains locked until Wrath."),
            Bullet("Profession value in TBC comes from three places: strong crafted gear, profession-only advantages and recipes locked behind reputations/raids."),
            "",
            SH("ALCHEMY"),
            Bullet("Why take it: reliable raid consumables, transmutes and one of the best self-sufficiency professions for repeated progression nights."),
            Bullet("Noteworthy crafts: Flask families, Super Mana / Healing style consumables, Elixir of Major Agility, Elixir of Major Shadow Power and meta-gem transmutes such as Skyfire and Earthstorm Diamond."),
            Priority("REPUTATIONS", "Thrallmar/Honor Hold, Cenarion Expedition, Lower City, The Sha'tar and Sporeggar are especially useful to Alchemists.", C.yellow),
            Bullet("Example: The Sha'tar at Revered offers the Alchemist's Stone recipe; Cenarion Expedition and Thrallmar/Honor Hold provide important transmute recipes."),
            Bullet("Specialisation choice matters: Potion, Elixir or Transmutation mastery can save a large amount of materials over a full expansion."),
            "",
            SH("BLACKSMITHING"),
            Bullet("Why take it: excellent for plate users and weapon users, with crafted weapons/armor that can remain competitive well into raiding."),
            Bullet("Noteworthy goals: the Weaponsmith lines that lead toward powerful crafted weapons such as the Deep Thunder / Stormherald and Dragonmaw / Dragonstrike families, plus high-end crafted armor."),
            Priority("REPUTATIONS", "Cenarion Expedition and your Aldor/Scryer choice are particularly worth checking for Blacksmithing plans.", C.yellow),
            Bullet("Cenarion Expedition offers useful sharpening/weightstone and resistance-oriented plans; later raid factions and Sunwell-era sources add endgame patterns."),
            "",
            SH("ENCHANTING"),
            Bullet("Why take it: every dungeon/raid upgrade needs enchants, while unwanted gear becomes materials instead of vendor trash."),
            Bullet("Noteworthy recipes include strong weapon, chest and glove enchants plus profession-only ring enchants."),
            Priority("REPUTATIONS", "The Sha'tar is especially important, with Cenarion Expedition, Thrallmar/Honor Hold and The Consortium also supplying valuable recipes.", C.yellow),
            Bullet("Examples include Exceptional Stats from Thrallmar/Honor Hold, Spell Strike from Cenarion Expedition and major healing-oriented recipes from The Sha'tar."),
            "",
            SH("ENGINEERING"),
            Bullet("Why take it: bombs, utility devices, target dummies, mote extraction and later TBC goggles provide unique utility rather than only raw stats."),
            Bullet("Engineering is less reputation-dependent than Alchemy/Enchanting/Jewelcrafting, so your priority is skill, materials, schematics and your Gnomish/Goblin choice."),
            Bullet("Flying-machine progression and profession gadgets also make it a strong quality-of-life profession for a character you play heavily."),
            "",
            SH("JEWELCRAFTING"),
            Priority("NEW IN TBC", "Jewelcrafting becomes a major gearing profession because every socketed upgrade creates demand for new cuts.", C.blue),
            Bullet("Noteworthy goals: useful gem cuts, figurines, rings/necks and high-end designs. Figurines such as the Nightseye Panther are examples of profession-specific utility items."),
            Priority("MOST REP-DEPENDENT TBC PROFESSION", "Check Thrallmar/Honor Hold, Cenarion Expedition, Aldor/Scryers, Consortium and Shattered Sun vendors whenever reputation increases.", C.red),
            Bullet("Cenarion Expedition provides Figurine - Nightseye Panther and later designs; Aldor/Scryers have different gem/jewelry recipes, so your Shattrath allegiance matters."),
            "",
            SH("LEATHERWORKING"),
            Bullet("Why take it: strong crafted leather/mail sets, armor kits and raid patterns; particularly natural for Druids, Rogues, Hunters and Shamans."),
            Bullet("Noteworthy value includes specialised crafted sets and Drums, which provide useful group utility depending on your server's TBC rules."),
            Priority("REPUTATIONS", "Cenarion Expedition, Lower City, Aldor/Scryers and later raid factions are worth checking for Leatherworking patterns.", C.yellow),
            "",
            SH("TAILORING"),
            Bullet("Why take it: some of TBC's strongest early caster crafted gear comes from Tailoring, making it much more than a bag profession."),
            Bullet("Noteworthy crafted paths include Spellfire, Frozen Shadoweave and Primal Mooncloth sets, plus Spellstrike pieces and later raid-crafted upgrades."),
            Priority("SPECIALISATION", "Spellfire, Shadoweave and Mooncloth specialisations affect cloth production and are worth choosing around the gear your character actually wants.", C.orange),
            Bullet("Aldor/Scryer and raid-faction vendors can also matter for patterns, so check them instead of assuming every Tailoring recipe comes from a trainer."),
            "",
            SH("GATHERING & SECONDARY PROFESSIONS"),
            Bullet("Mining feeds Blacksmithing, Engineering and Jewelcrafting; Herbalism feeds Alchemy; Skinning feeds Leatherworking."),
            Bullet("Cooking matters for raid food. Fishing supports Cooking and useful consumables. First Aid remains a practical emergency tool for classes without reliable self-healing."),
            "",
            SH("REPUTATION PRIORITY BY PROFESSION"),
            Priority("ALCHEMY", "Thrallmar/Honor Hold -> Cenarion Expedition -> Lower City -> The Sha'tar -> Sporeggar as needed.", C.green),
            Priority("ENCHANTING", "The Sha'tar -> Cenarion Expedition -> Thrallmar/Honor Hold -> Consortium, then raid factions.", C.green),
            Priority("JEWELCRAFTING", "Check almost every major faction; Aldor/Scryer choice and Shattered Sun are especially important.", C.green),
            Priority("BLACKSMITH / LEATHERWORKER / TAILOR", "Prioritise the factions that actually sell your desired pattern, then let raid reputations unlock later recipes naturally.", C.green),
            Priority("ENGINEERING", "Reputation is usually secondary to schematics, materials and skill progression.", C.green),
            "",
            SH("WHEN TO WORK ON THEM"),
            Priority("LEVEL 60-69", "Train Master rank, gather Outland materials and start reputation recipes naturally while leveling.", C.yellow),
            Priority("TIER 8", "Finish any crafted pre-raid pieces that are genuine upgrades; do not delay Karazhan just to reach 375 in everything.", C.orange),
            Priority("TIER 9-10", "Re-check raid reputation vendors and new patterns as SSC/TK/Hyjal/BT open.", C.yellow),
            Priority("TIER 12", "Shattered Sun and Sunwell-era recipes become the final TBC profession push.", C.red),
        })
    end,
}

local TBC_PVP_PAGE = {
    title = "TBC PvP",
    short = "Season 1, Honor gearing, Arena and world-PvP progression",
    icon = "Interface\\Icons\\INV_BannerPVP_02",
    body = function()
        return Join({
            SH("CURRENT ARENA SEASON"),
            Priority("SERVER SETTING", "The Burning Crusade is configured for Arena Season 1.", C.green),
            Bullet("Season 1 is the active Arena reward era; later-season vendor sets should not be treated as available progression gear."),
            "",
            SH("WHAT CHANGES IN TBC PVP"),
            Bullet("Resilience becomes the defining PvP defensive stat. It reduces the impact of enemy critical strikes and other player damage effects, so proper PvP gear is much more important than in Vanilla."),
            Bullet("Arenas are now a rated endgame path alongside Battlegrounds, giving dedicated PvP players a progression system separate from raids."),
            "",
            SH("STEP 1 - BUILD AN HONOR SET"),
            Priority("START AT 70", "Use Battlegrounds to build Honor and any required Battleground currency/marks for available off-pieces and entry PvP gear.", C.orange),
            Bullet("Warsong Gulch: Capture the Flag. Arathi Basin: node control. Alterac Valley: large-scale objective battle. Eye of the Storm: node control plus flag play."),
            Bullet("Battleground weekends are especially efficient when you want bonus Honor/reputation from that Battleground."),
            Bullet("Prioritise survivability and Resilience before chasing small damage gains if Arena is your goal."),
            "",
            SH("STEP 2 - ENTER ARENA"),
            Bullet("Rated 2v2, 3v3 and 5v5 provide Arena rating and Arena Points for Season 1 rewards."),
            Bullet("Use Battleground gear as your foundation, then replace pieces with Arena rewards as rating/currency permits."),
            Bullet("Weapons and high-end Arena pieces are especially valuable goals, but rating requirements may apply to the strongest rewards."),
            "",
            SH("STEP 3 - USE WORLD PVP AS SIDE CONTENT"),
            Bullet("Hellfire Peninsula fortifications, Zangarmarsh's Twin Spire Ruins, Terokkar Spirit Towers and Halaa in Nagrand provide extra outdoor PvP objectives."),
            Bullet("These are optional, but they add zone rewards/currencies and give PvP players something useful to do outside Battleground queues."),
            "",
            SH("PVP GEAR IN PVE"),
            Priority("USE WITH CARE", "PvP gear can be a very good stop-gap for weak slots, but Resilience usually replaces a PvE throughput stat.", C.yellow),
            Bullet("A strong PvP weapon or well-itemised piece can absolutely help early raids; compare the whole item rather than dismissing it because it is PvP gear."),
            Bullet("Do not delay Karazhan/Heroics/attunements simply to finish a complete PvP set unless PvP is your character's main goal."),
            "",
            SH("VANILLA TITLES AFTER ENTERING TBC"),
            Bullet("Vanilla PvP titles already earned remain on the character."),
            Priority("LOCKED", "New Vanilla Rank 1-14 titles can no longer be earned after leaving Vanilla progression.", C.orange),
            "",
            SH("WHEN IT IS MOST USEFUL"),
            Priority("TIER 8", "Highest PvE crossover value: use Honor/Arena pieces to fill poor pre-raid and early-raid slots.", C.yellow),
            Priority("TIER 9-10", "Continue Arena/Battleground progression if PvP is a real goal; PvE players usually become more selective about which PvP pieces remain upgrades.", C.yellow),
            Priority("TIER 12", "Mostly dedicated PvP/collection progression unless a specific available piece still fills a weakness.", C.purple),
        })
    end,
}

local TBC_WORLD_BOSS_PAGE = {
    title = "TBC World Boss Timeline",
    short = "Doom Lord Kazzak and Doomwalker - timing, mechanics and rewards",
    icon = "Interface\\Icons\\Spell_Shadow_SummonInfernal",
    body = function()
        return Join({
            SH("WHY THESE BOSSES MATTER"),
            "TBC has two main outdoor raid bosses. Neither advances Individual Progression, but both can drop raid-quality epics that are most valuable during early and mid-TBC progression.",
            "",
            H("DOOM LORD KAZZAK - THRONE OF KIL'JAEDEN"),
            Priority("BEST WINDOW", "Tier 8 / early level-70 raiding, once the group has flying access and enough coordination to field a proper raid.", C.purple),
            Bullet("Location: Throne of Kil'jaeden in northern Hellfire Peninsula. The area is reached by flying."),
            Bullet("Key fight concern: deaths are extremely punishing because Kazzak can heal from player deaths. Mana users must react to Mark of Kazzak, and Twisted Reflection needs fast dispels."),
            Bullet("The fight has a hard pressure/enrage element, so clean execution and strong early damage matter more than a slow recovery strategy."),
            Bullet("Noteworthy loot examples include Hope Ender, Exodar Life-Staff, Ring of Flowing Light and other early raid-quality epics."),
            "",
            H("DOOMWALKER - BLACK TEMPLE GATES"),
            Priority("BEST WINDOW", "Tier 8 onward. Attempt him as soon as your level-70 raid can survive the heavy raid damage and tank pressure.", C.purple),
            Bullet("Location: Shadowmoon Valley outside the Black Temple entrance. You do not need Black Temple attunement to fight him."),
            Bullet("Key fight concerns include Earthquake-style raid damage/stuns, Overrun movement and very dangerous pressure as the boss becomes enraged."),
            Bullet("Players who die can receive Mark of Death, making repeated deaths especially disruptive."),
            Bullet("Noteworthy loot examples include Talon of the Tempest, Ethereum Nexus-Reaver, Archaic Charm of Presence and Fathom-Helm of the Deeps."),
            "",
            SH("OPEN-WORLD RULES"),
            Bullet("These are contested world bosses: they are not instanced, so another group can arrive and engage them."),
            Bullet("Organise the raid before pulling. A failed attempt can cost the spawn and is much less forgiving than wiping inside Karazhan."),
            "",
            SH("PRIORITY BY TIER"),
            Priority("TIER 8", "Highest-value window. Their loot can compete with early raid gear and patch weak slots quickly.", C.orange),
            Priority("TIER 9", "Still worthwhile if specific drops remain strong for your roster.", C.yellow),
            Priority("TIER 10+", "Usually completion, alt gearing or a specific-item hunt rather than a progression priority.", C.purple),
            "",
            SH("BOTTOM LINE"),
            Bullet("Do required raid/attunement work first, then use these bosses when the spawn is available and the loot can still genuinely improve the raid."),
        })
    end,
}

local ZULAMAN_PAGE = {
    title = "Zul'Aman",
    short = "Optional TBC side raid - unlocks after Black Temple",
    icon = "Interface\\Icons\\Ability_Druid_ChallangingRoar",
    body = function()
        return Join({
            SH("STATUS ON THIS SERVER"),
            Priority("SIDE CONTENT", "Zul'Aman is not a required progression tier.", C.purple),
            Priority("UNLOCK", "It becomes available after Black Temple / Illidan progression is complete.", C.green),
            Bullet("This is why the main raid progression jumps from Tier 10 to Tier 12 rather than treating Zul'Aman as a mandatory numbered tier."),
            "",
            SH("ACCESS"),
            Priority("NO RAID ATTUNEMENT", "Zul'Aman does not require a separate raid-entry attunement quest.", C.green),
            "",
            SH("WHY DO IT"),
            Bullet("Strong side-grade and catch-up-style gear while still remaining an authentic TBC raid experience."),
            Bullet("Timed-event rewards give the raid a different progression goal from standard boss clearing."),
            Bullet("Useful place to strengthen weaker slots before or during the Sunwell stage."),
            "",
            SH("PROGRESSION RULE"),
            Bullet("Defeating Zul'jin does not advance your Individual Progression stage on this server."),
            Bullet("Your required final TBC progression target remains Kil'jaeden in Sunwell Plateau."),
        })
    end,
}

local WORLD_BOSS_PAGE = {
    title = "Vanilla World Boss Timeline",
    short = "When to do each world boss",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_DragonHawk",
    body = function()
        return Join({
            SH("WHY THIS PAGE EXISTS"),
            "World bosses are easy to forget because they do not directly advance your main progression. This guide places them where their loot and difficulty are most useful to your character.",
            "",
            H("EARLY VANILLA - TIER 2 WINDOW"),
            Priority("OPTIONAL - HIGH VALUE", "Azuregos - Azshara", C.purple),
            Bullet("Recommended timing: as soon as the early post-opening world-boss unlock is available."),
            Bullet("Do not wait until AQ/Naxx if you want his loot to serve as real progression rather than collection gear."),
            Bullet("Notable for powerful caster/melee items and the Mature Blue Dragon Sinew for the Hunter epic quest path."),
            "",
            Priority("OPTIONAL - HIGH VALUE", "Lord Kazzak - Blasted Lands", C.purple),
            Bullet("Recommended timing: alongside Azuregos in the early post-opening / BWL-era window."),
            Bullet("Treat him as a raid target, not a solo rare. His mechanics punish deaths and poor control."),
            Bullet("His loot contains strong raid-era upgrades and profession-related value."),
            "",
            H("LATER VANILLA - PRE-AQ WINDOW"),
            Priority("OPTIONAL - HIGH VALUE", "Ysondre - Dragon of Nightmare", C.purple),
            Priority("OPTIONAL - HIGH VALUE", "Emeriss - Dragon of Nightmare", C.purple),
            Priority("OPTIONAL - HIGH VALUE", "Lethon - Dragon of Nightmare", C.purple),
            Priority("OPTIONAL - HIGH VALUE", "Taerar - Dragon of Nightmare", C.purple),
            Bullet("Recommended timing: during Tier 3 / Pre-AQ progression, when later-Vanilla outdoor content becomes the focus."),
            Bullet("Their Nature-themed rewards and difficulty make them a natural fit while preparing for AQ."),
            Bullet("Kill whichever dragon is active; do not treat them as four simultaneous permanent spawns."),
            "",
            SH("PRIORITY RULE"),
            Bullet("World bosses are not required to advance your main progression stage."),
            Bullet("They are still worth scheduling because delaying them too long makes the loot less meaningful."),
            Bullet("If raid time is limited: required tier boss > attunements/event gates > world bosses > repeat farming."),
            "",
            SH("REMEMBER"),
            "World bosses are optional progression, but their rewards are most meaningful when you tackle them during the stage shown here rather than saving them until much later.",
        })
    end,
}


-- ============================================================================
-- WRATH OF THE LICH KING
--
-- Progression values continue to represent the highest completed milestone:
-- 13 = TBC complete / opening Wrath stage
-- 14 = Kel'Thuzad defeated / Ulduar available
-- 15 = Yogg-Saron defeated / Trial of the Crusader era available
-- 16 = Anub'arak defeated / Frozen Halls + Icecrown Citadel available
-- 17 = Lich King defeated / Ruby Sanctum available
-- 18 = Halion defeated / Wrath progression complete
-- ============================================================================

local WOTLK_STAGES = {
    wrath13 = {
        nav = "Tier 13   Naxx / EoE / OS",
        title = "Tier 13 - Naxxramas / Eye of Eternity / Obsidian Sanctum",
        short = "Opening Wrath raid progression",
        icon = "Interface\\Icons\\Achievement_Boss_KelThuzad_01",
        minValue = 13,
        completeAt = 14,
        objective = "Defeat Kel'Thuzad in Naxxramas.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 13 begins the Wrath journey. The practical route is: unlock Wrath, level to 80, gear through Normal/Heroic dungeons, begin faction reputations, clear the opening raids and defeat Kel'Thuzad.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Kel'Thuzad in Wrath Naxxramas.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Purchase Wrath access and enter Northrend"),
                Priority("CHARACTER SERVICE", "If not already purchased, visit Chronomancer Vezrath and pay 7,500 gold for the TBC -> Wrath unlock.", C.orange),
                Bullet("The addon can see your IP progression value but cannot detect whether the separate Character Services purchase has already been made."),
                "",
                Step(2, "Level from 70 to 80 and unlock Wrath systems"),
                Bullet("The full 3.3.5 talent trees are now available."),
                Bullet("Inscription unlocks and primary professions can progress to 450."),
                Bullet("Work through Northrend Normal dungeons while levelling; at 77, obtain Cold Weather Flying when you can afford it for Storm Peaks/Icecrown travel."),
                "",
                Step(3, "At level 80, build a real Pre-Raid set"),
                Bullet("Finish strong level-80 Normal dungeon rewards, crafted items and quest chains, then move into Heroics immediately once your group is ready."),
                Bullet("Wrath Heroics do not use TBC-style reputation keys."),
                Bullet("Wear the relevant faction tabard in eligible level-80 dungeons to build reputation while gearing."),
                Bullet("Start Sons of Hodir in Storm Peaks early if you need their shoulder enchants."),
                "",
                Step(4, "Farm opening emblems and Heroics"),
                Priority("EMBLEMS", "Heroic dungeon bosses award Emblems of Heroism during this stage.", C.yellow),
                Bullet("Use emblem gear to replace weak slots rather than waiting for every upgrade to come from Naxxramas."),
                Bullet("Use Archmage Timear's Proof of Demise daily when available for extra dungeon value."),
                "",
                Step(5, "Begin Naxxramas progression"),
                Priority("ACCESS", "Wrath Naxxramas has no Argent Dawn attunement.", C.green),
                H("Arachnid Quarter"),
                Bullet("Anub'Rekhan -> Grand Widow Faerlina -> Maexxna."),
                H("Plague Quarter"),
                Bullet("Noth the Plaguebringer -> Heigan the Unclean -> Loatheb."),
                H("Military Quarter"),
                Bullet("Instructor Razuvious -> Gothik the Harvester -> Four Horsemen."),
                H("Construct Quarter"),
                Bullet("Patchwerk -> Grobbulus -> Gluth -> Thaddius."),
                Bullet("Finish Sapphiron, then Kel'Thuzad."),
                "",
                Step(6, "Complete Eye of Eternity while it is current"),
                Bullet("Obtain the appropriate Key to the Focusing Iris from Sapphiron in Naxxramas."),
                Bullet("Only one qualified raid member needs to activate the Malygos encounter, but the raid should still complete EoE while its rewards are useful."),
                "",
                Step(7, "Complete Obsidian Sanctum and use optional drake difficulty"),
                Bullet("Defeat Sartharion for opening-tier rewards."),
                Bullet("Leaving one, two or three drakes alive increases the challenge/reward; 3-drake is an optional mastery goal, not an IP gate."),
                "",
                Step(8, "Use Wintergrasp and Vault of Archavon"),
                Bullet("Queue for Wintergrasp for PvP rewards/quests and enter Vault when your faction controls the fortress."),
                Bullet("Archavon the Stone Watcher is the opening Vault boss for this stage."),
                "",
                Step(9, "Defeat Kel'Thuzad"),
                Priority("FINAL STEP", "Kel'Thuzad advances the character to Tier 14 and unlocks Ulduar.", C.red),
                "",
                SH("RECOMMENDED BEFORE ADVANCING"),
                Bullet("Complete Malygos and Sartharion even though neither is the IP progression trigger."),
                Bullet("Finish class-relevant head enchant reputations and Sons of Hodir shoulder-enchant progress."),
                Bullet("Have professions, enchants and gems in a stable place before Ulduar gear starts arriving."),
            })
        end,
    },

    wrath14 = {
        nav = "Tier 14   Ulduar",
        title = "Tier 14 - Ulduar",
        short = "Ulduar progression and hard modes",
        icon = "Interface\\Icons\\Achievement_Boss_YoggSaron_01",
        minValue = 14,
        completeAt = 15,
        objective = "Defeat Yogg-Saron in Ulduar.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 14 unlocks Ulduar. Normal-mode progression to Yogg-Saron is the required path; hard modes, Algalon and Val'anyr are high-value optional mastery goals.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Yogg-Saron.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Revisit your Heroic/emblem plan"),
                Bullet("Heroics remain useful for emblems, off-spec pieces and missing Pre-Raid/Naxx slots rather than becoming obsolete immediately."),
                Bullet("The restored emblem ladder advances with the tier; check the Emblems page for the current dungeon/raid currency behavior."),
                "",
                Step(2, "Enter Ulduar after Kel'Thuzad progression"),
                Priority("SERVER GATE", "Ulduar is blocked until Tier 13 / Kel'Thuzad progression is complete.", C.orange),
                Bullet("No separate attunement quest is required after the progression gate is met."),
                "",
                Step(3, "Progress the Siege of Ulduar"),
                Bullet("Flame Leviathan first."),
                Bullet("Ignis and Razorscale are useful side bosses; XT-002 Deconstructor is the key route forward."),
                "",
                Step(4, "Progress the Antechamber"),
                Bullet("Assembly of Iron / Kologarn / Auriaya as your raid opens the central complex."),
                Bullet("Use the easier encounters for gear before committing to the harder Keeper fights if your group needs it."),
                "",
                Step(5, "Defeat the four Keepers"),
                Bullet("Hodir, Thorim, Freya and Mimiron."),
                Bullet("Learn normal versions first; their hard modes are optional and can be added as the raid becomes comfortable."),
                "",
                Step(6, "Defeat General Vezax and Yogg-Saron"),
                Bullet("General Vezax opens the final path."),
                Priority("FINAL STEP", "Defeat Yogg-Saron to complete Tier 14 and unlock Trial-era content.", C.red),
                "",
                Step(7, "Pursue Ulduar hard modes only after normal progress is stable"),
                Bullet("Hard modes provide better rewards and contribute toward the Algalon access route."),
                Bullet("Algalon is optional high-value content; do not block normal tier completion waiting for an Algalon kill."),
                Bullet("If your raid is pursuing Val'anyr, decide the recipient early and keep Fragment of Val'anyr distribution consistent."),
                "",
                Step(8, "Revisit Vault of Archavon"),
                Priority("NEW VAULT BOSS", "Emalon becomes relevant during the Ulduar era.", C.purple),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 15 - Argent Tournament era, Trial of the Champion and Trial of the Crusader.", C.green),
            })
        end,
    },

    wrath15 = {
        nav = "Tier 15   Trial of the Crusader",
        title = "Tier 15 - Trial of the Crusader",
        short = "Argent Tournament / Crusader's Coliseum",
        icon = "Interface\\Icons\\Achievement_Boss_Anubarak",
        minValue = 15,
        completeAt = 16,
        objective = "Defeat Anub'arak in Trial of the Crusader.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 15 is the Crusader's Coliseum era. Trial of the Champion becomes your new 5-player catch-up dungeon, Trial of the Crusader is the main raid and the Argent Tournament becomes important side progression.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat Anub'arak in Trial of the Crusader.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Start the Argent Tournament era content"),
                Priority("SERVER GATE", "Trial/Tournament-era content is phased until Ulduar / Yogg-Saron progression is complete.", C.orange),
                Bullet("Begin or continue Aspirant -> Valiant -> Champion progression if you want mounts, pets, tabards, titles and Champion's Seal rewards."),
                "",
                Step(2, "Run Trial of the Champion"),
                Bullet("Use Normal/Heroic Trial of the Champion for quick upgrades, useful trinkets and catch-up gearing before the raid."),
                Bullet("Continue older Heroics when emblem farming or specific items are still useful."),
                "",
                Step(3, "Prepare for Trial of the Crusader"),
                Bullet("There is no conventional attunement quest once the Tier 15 server gate is open."),
                Bullet("Finish enchants/gems/consumables before raid night; ToC has no trash, so progression time is almost entirely boss attempts."),
                "",
                Step(4, "Clear Trial of the Crusader in order"),
                Bullet("Northrend Beasts."),
                Bullet("Lord Jaraxxus."),
                Bullet("Faction Champions."),
                Bullet("Twin Val'kyr."),
                Bullet("Anub'arak."),
                "",
                Step(5, "Use Trial of the Grand Crusader as optional mastery content"),
                Bullet("Heroic ToC/ToGC is not required to advance Individual Progression, but it is the natural difficulty step after normal ToC is stable."),
                "",
                Step(6, "Revisit Vault of Archavon"),
                Priority("NEW VAULT BOSS", "Koralon becomes relevant during the Trial era.", C.purple),
                "",
                Step(7, "Defeat Anub'arak"),
                Priority("FINAL STEP", "Anub'arak advances the character to Tier 16 and unlocks the Frozen Halls / Icecrown Citadel stage.", C.red),
                "",
                SH("RECOMMENDED BEFORE ADVANCING"),
                Bullet("Finish any class-relevant Ulduar hard-mode upgrades you still need; moving to ToC does not make every Ulduar reward worthless."),
                Bullet("Bring Sons of Hodir/class head-enchant reputations and profession bonuses up to date before ICC."),
                Bullet("Stock gold, gems, enchants and consumables because ICC will replace gear quickly."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 16 - Forge of Souls -> Pit of Saron -> Halls of Reflection and Icecrown Citadel.", C.green),
            })
        end,
    },

    wrath16 = {
        nav = "Tier 16   Icecrown Citadel",
        title = "Tier 16 - Icecrown Citadel",
        short = "Frozen Halls and Icecrown endgame",
        icon = "Interface\\Icons\\Achievement_Boss_LichKing",
        minValue = 16,
        completeAt = 17,
        objective = "Defeat the Lich King in Icecrown Citadel.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Tier 16 is the main Wrath endgame stage. Complete the Frozen Halls route, build Ashen Verdict reputation and progress the four ICC wings until the Lich King is available.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("PROGRESSION BOSS", "Defeat the Lich King in Icecrown Citadel.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Complete the Frozen Halls sequence"),
                Priority("SERVER GATE", "Forge of Souls / Icecrown content is blocked until Tier 15 progression is complete.", C.orange),
                Bullet("Start with Forge of Souls and complete its quest/story objectives."),
                Bullet("Continue into Pit of Saron."),
                Bullet("Finish with Halls of Reflection; the sequence is intended to be done in order rather than skipping straight to the final dungeon."),
                Bullet("Use Normal/Heroic versions for strong late-Wrath dungeon gear and story progression."),
                "",
                Step(2, "Begin Icecrown Citadel and Ashen Verdict reputation"),
                Bullet("There is no Vanilla/TBC-style raid attunement once the Tier 16 progression gate is met."),
                Priority("IMPORTANT", "Wear down ICC trash/bosses every week to progress Ashen Verdict reputation and the reputation-ring upgrades.", C.orange),
                "",
                Step(3, "Clear the Lower Spire"),
                Bullet("Lord Marrowgar -> Lady Deathwhisper -> Gunship Battle -> Deathbringer Saurfang."),
                "",
                Step(4, "Clear the three upper wings"),
                H("Plagueworks"),
                Bullet("Festergut + Rotface -> Professor Putricide."),
                H("Crimson Hall"),
                Bullet("Blood Prince Council -> Blood-Queen Lana'thel."),
                H("Frostwing Halls"),
                Bullet("Valithria Dreamwalker -> Sindragosa."),
                "",
                Step(5, "Unlock the Frozen Throne"),
                Bullet("Defeat the wing-end bosses required to open the path to the Lich King."),
                Bullet("Stabilise normal-mode kills before investing heavily in Heroic progression unless your raid is already overgeared/experienced."),
                "",
                Step(6, "Work on Shadowmourne only if your raid has chosen a recipient"),
                Priority("OPTIONAL LEGENDARY", "The Shadowmourne chain is a major raid-resource commitment and is not required for IP progression.", C.purple),
                Bullet("Choose the recipient before distributing scarce quest materials so the raid does not waste weeks of drops."),
                "",
                Step(7, "Use current Heroics/emblems and Vault"),
                Bullet("Heroic dungeon bosses are on the late-Wrath emblem tier, keeping older Heroics useful for alts/off-specs and weak slots."),
                Priority("NEW VAULT BOSS", "Toravon becomes the current Vault of Archavon boss during the ICC stage.", C.purple),
                "",
                Step(8, "Defeat the Lich King"),
                Priority("FINAL STEP", "The Lich King advances the character to Tier 17 - Ruby Sanctum.", C.red),
                "",
                SH("RECOMMENDED BEFORE ADVANCING"),
                Bullet("Continue ICC after the first Lich King kill for Ashen Verdict, Heroic progression, Shadowmourne and final gearing."),
                Bullet("Use Dalaran's active weekly raid quest for extra value alongside normal raid nights."),
                "",
                SH("NEXT TIER"),
                Priority("UNLOCK", "Tier 17 - Ruby Sanctum.", C.green),
            })
        end,
    },

    wrath17 = {
        nav = "Tier 17   Ruby Sanctum",
        title = "Tier 17 - Ruby Sanctum",
        short = "Final Wrath progression",
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
        minValue = 17,
        completeAt = 18,
        objective = "Defeat Halion in Ruby Sanctum.",
        body = function()
            return Join({
                SH("STAGE OVERVIEW"),
                "Ruby Sanctum is the final Individual Progression stage. It is deliberately short, but the page still gives you the exact raid route and the final cleanup goals that are worth doing before you call the character complete.",
                "",
                SH("REQUIRED TO ADVANCE"),
                Priority("FINAL PROGRESSION BOSS", "Defeat Halion.", C.red),
                "",
                SH("HOW TO COMPLETE THIS TIER"),
                Step(1, "Enter Ruby Sanctum after the Lich King"),
                Priority("SERVER GATE", "Ruby Sanctum is blocked until Tier 16 / Lich King progression is complete.", C.orange),
                Bullet("There is no separate conventional attunement quest after the progression gate is satisfied."),
                "",
                Step(2, "Clear the outer sanctum"),
                Bullet("Defeat Baltharus the Warborn."),
                Bullet("Defeat Saviana Ragefire."),
                Bullet("Defeat General Zarithrian once the outer encounters are handled."),
                "",
                Step(3, "Defeat Halion on Normal"),
                Bullet("Learn the Physical Realm, Twilight Realm and split-realm mechanics before treating Heroic as the target."),
                Priority("FINAL STEP", "A Halion kill advances the character to progression value 18 and completes the current Individual Progression journey.", C.red),
                "",
                Step(4, "Continue ICC and Ruby Sanctum for final gearing"),
                Bullet("Do not abandon ICC simply because the final progression boss is dead; ICC still contains many final-best-in-slot pieces, Ashen Verdict progress and legendary objectives."),
                "",
                Step(5, "Choose your optional mastery goals"),
                Bullet("Ruby Sanctum Heroic."),
                Bullet("ICC Heroic progression."),
                Bullet("Ulduar hard modes / Algalon."),
                Bullet("Trial of the Grand Crusader."),
                Bullet("Remaining achievements, reputations, mounts, profession recipes and legendary goals."),
                "",
                SH("WRATH / IP JOURNEY COMPLETE"),
                Priority("COMPLETE", "There is no later expansion stage in this 3.3.5 Individual Progression ruleset.", C.green),
            })
        end,
    },
}

local WOTLK_OVERVIEW_PAGE = {
    title = "Wrath of the Lich King Roadmap",
    short = "Level 70-80 progression, raid tiers and side systems",
    icon = "Interface\\Icons\\Spell_Frost_Frost",
    body = function()
        return Join({
            SH("ENTERING WRATH"),
            Priority("CHARACTER SERVICE", "After completing TBC, purchase the 7,500g TBC -> Wrath unlock from Chronomancer Vezrath if this character has not already done so.", C.orange),
            Bullet("Northrend is progression-protected and opens with the Wrath stage."),
            Bullet("Level cap: 80."),
            Bullet("Talent trees: the full 3.3.5 trees are available."),
            Bullet("Inscription is now available; all primary professions can progress to 450."),
            Bullet("Death Knights unlock at this era under the current server rules."),
            "",
            H("WRATH RAID ROADMAP"),
            C.blue .. "Tier 13" .. C.reset .. "     Naxxramas / Eye of Eternity / Obsidian Sanctum",
            Bullet("Progression boss: Kel'Thuzad."),
            Bullet("Heroics, faction tabards, Sons of Hodir and Wintergrasp are immediate level-80 priorities."),
            "",
            C.blue .. "Tier 14" .. C.reset .. "     Ulduar",
            Bullet("Progression boss: Yogg-Saron."),
            Bullet("Hard modes and Algalon are optional high-value mastery content."),
            "",
            C.blue .. "Tier 15" .. C.reset .. "     Trial of the Crusader",
            Bullet("Progression boss: Anub'arak."),
            Bullet("Trial of the Champion and the Argent Tournament era become active on this server at this stage."),
            "",
            C.blue .. "Tier 16" .. C.reset .. "     Icecrown Citadel",
            Bullet("Progression boss: the Lich King."),
            Bullet("Forge of Souls -> Pit of Saron -> Halls of Reflection opens as the Frozen Halls route."),
            "",
            C.blue .. "Tier 17" .. C.reset .. "     Ruby Sanctum",
            Bullet("Progression boss: Halion, the final progression milestone."),
            "",
            SH("SERVER CONTENT GATES"),
            Bullet("Ulduar waits for Kel'Thuzad."),
            Bullet("Trial of the Champion / Trial of the Crusader wait for Yogg-Saron."),
            Bullet("Forge of Souls / Icecrown Citadel wait for Anub'arak."),
            Bullet("Ruby Sanctum waits for the Lich King."),
            "",
            SH("WHAT TO PRIORITISE AT LEVEL 80"),
            Priority("1", "Finish strong dungeon gear and begin Heroics immediately.", C.yellow),
            Priority("2", "Choose the tabard reputation that gives your most useful head enchant/rewards and start Sons of Hodir for shoulder enchants.", C.yellow),
            Priority("3", "Finish profession skill, gems, enchants, consumables and crafted Pre-Raid upgrades.", C.yellow),
            Priority("4", "Begin Naxxramas while continuing Heroics, Wintergrasp and side raids rather than waiting for perfect Pre-Raid BiS.", C.yellow),
            "",
            SH("SUPPORT / SIDE CONTENT PAGES"),
            Bullet("Dungeons & Heroics - leveling route, level-80 Heroics and later dungeon unlocks."),
            Bullet("Emblems & Dalaran Quests - the server's restored emblem ladder and daily/weekly timing."),
            Bullet("Wrath Reputations - detailed faction priorities, enchants, recipes and rewards."),
            Bullet("Wrath Professions - 450 skill, profession bonuses, Inscription and raid crafting."),
            Bullet("Wrath PvP - Arena Season 5 and gearing options."),
            Bullet("Wintergrasp & Vault - outdoor PvP and the tier-by-tier Vault boss timeline."),
            Bullet("Argent Tournament - server-timed Tournament progression and rewards."),
        })
    end,
}

local WOTLK_DUNGEONS_PAGE = {
    title = "Wrath Dungeons & Heroics",
    short = "70-80 route, Heroic timing and later dungeon unlocks",
    icon = "Interface\\Icons\\INV_Misc_Key_15",
    body = function()
        return Join({
            SH("THE MAIN RULE"),
            "Wrath dungeons are your leveling backbone and the fastest bridge into opening raid gear. Unlike TBC, level-80 Heroics do not require faction keys, so begin them as soon as you reach 80 and your group can handle them.",
            "",
            SH("SUGGESTED NORMAL-DUNGEON ROUTE"),
            Bullet("70-72: Utgarde Keep and The Nexus."),
            Bullet("72-74: Azjol-Nerub and Ahn'kahet: The Old Kingdom."),
            Bullet("74-76: Drak'Tharon Keep."),
            Bullet("75-77: The Violet Hold."),
            Bullet("76-78: Gundrak."),
            Bullet("77-80: Halls of Stone and Utgarde Pinnacle."),
            Bullet("78-80: The Oculus and The Culling of Stratholme."),
            Bullet("79-80: Halls of Lightning."),
            Bullet("Exact order can change with quests and available groups; the important point is to keep dungeon quests and useful reputation rewards moving while leveling."),
            "",
            SH("LEVEL 80 - START HEROICS"),
            Priority("TIER 13 - CORE PRE-RAID CONTENT", "Begin Heroic dungeons immediately at 80 rather than waiting until after Naxxramas.", C.red),
            Bullet("Use Heroics for Pre-Raid gear, emblems, reputation through tabards and daily dungeon objectives."),
            Bullet("There are no TBC-style Revered Heroic keys to farm first."),
            Bullet("Your server has RDF enabled, so specific-dungeon queuing can be used where the core supports it."),
            "",
            SH("REPUTATION TABARDS"),
            Bullet("At Friendly, the four major dungeon factions can provide tabards used to direct reputation in eligible level-80 dungeons."),
            Bullet("Kirin Tor - usually the first focus for caster DPS who want its head enchant/rewards."),
            Bullet("Knights of the Ebon Blade - usually the first focus for physical DPS."),
            Bullet("Argent Crusade - usually the first focus for healers."),
            Bullet("Wyrmrest Accord - usually the first focus for tanks."),
            Bullet("See Wrath Reputations for the full explanation; choose by your character, not by a fixed universal order."),
            "",
            SH("HOW HEROICS AGE THROUGH THE TIERS"),
            Priority("TIER 13", "Major Pre-Raid gearing source. Heroic bosses award Emblems of Heroism.", C.orange),
            Priority("TIER 14", "Support Ulduar preparation, fill weak slots and farm upgraded Emblems of Valor.", C.yellow),
            Priority("TIER 15", "Catch-up / off-spec / emblem content. Heroic bosses move to Emblems of Conquest.", C.yellow),
            Priority("TIER 16+", "Older Heroics still pay Emblems of Triumph, while the Frozen Halls become the most important late-Wrath 5-player route.", C.yellow),
            "",
            SH("TRIAL OF THE CHAMPION - TIER 15"),
            Priority("SERVER-GATED", "Trial of the Champion is unavailable until Yogg-Saron has been defeated and Tier 15 begins.", C.orange),
            Bullet("Once open, run Normal/Heroic versions when their gear can replace weak slots or help prepare for Trial of the Crusader."),
            "",
            SH("FROZEN HALLS - TIER 16"),
            Priority("SERVER-GATED", "Forge of Souls does not open until Anub'arak has been defeated and Tier 16 begins.", C.orange),
            Bullet("Complete the story/access chain in order: Forge of Souls -> Pit of Saron -> Halls of Reflection."),
            Bullet("These are the strongest late-Wrath dungeon catch-up options and should be part of early ICC preparation."),
            "",
            SH("DAILY / WEEKLY VALUE"),
            Bullet("Early Wrath uses Dalaran daily Heroic objectives; the active quest system changes as later Wrath tiers arrive."),
            Bullet("Do the active dungeon or raid quest when the reward is worthwhile, but do not let a daily objective delay your current progression raid."),
        })
    end,
}

local WOTLK_EMBLEMS_PAGE = {
    title = "Wrath Emblems & Dalaran Quests",
    short = "What each emblem tier is for, where it comes from and when to spend it",
    icon = "Interface\\Icons\\INV_Misc_Coin_18",
    body = function()
        return Join({
            SH("WHY THIS SYSTEM MATTERS"),
            "This server restores the Wrath emblem ladder instead of exposing final-patch catch-up rewards immediately. Heroics and older raids therefore stay useful because their emblem rewards change as your progression advances.",
            "",
            SH("HEROIC DUNGEON EMBLEM LADDER"),
            Priority("TIER 13", "Heroic dungeon bosses award Emblems of Heroism.", C.yellow),
            Priority("TIER 14", "Heroic dungeon bosses award Emblems of Valor.", C.yellow),
            Priority("TIER 15", "Heroic dungeon bosses award Emblems of Conquest.", C.yellow),
            Priority("TIER 16+", "Heroic dungeon bosses award Emblems of Triumph once Icecrown is available.", C.yellow),
            Bullet("That means a Heroic you have already cleared can become valuable again after moving to a later tier."),
            "",
            SH("WHAT TO BUY"),
            Bullet("Dalaran emblem vendors provide armor, jewelry, trinkets, relics/librams/idols and other gearing options depending on class and emblem tier."),
            Bullet("Treat emblems as targeted bad-luck protection: buy the slot that your dungeon/raid drops have failed to replace rather than spending immediately just because you can."),
            Bullet("Set pieces or pieces that complete a strong set bonus can be worth saving for even when a cheaper item would be a small immediate upgrade."),
            "",
            SH("RAID EMBLEMS & OLD-TIER VALUE"),
            Priority("NAXXRAMAS", "Naxxramas begins as a Valor source and is adjusted again as later progression arrives.", C.blue),
            Priority("ULDUAR", "Ulduar introduces the next raid emblem step while it is current content.", C.blue),
            Bullet("The point of the server system is that older raids are not frozen in final-patch reward rules; their emblem value follows the progression era."),
            Bullet("This makes organised older-tier clears useful for alts, off-specs and players who missed specific pieces."),
            "",
            SH("ARCHMAGE TIMEAR - EARLY WRATH"),
            Priority("TIER 13-14", "Archmage Timear offers Proof of Demise daily Heroic quests during the early Wrath stages.", C.orange),
            Bullet("Each daily points you at a specific Heroic end boss. If possible, combine that target with a dungeon you also need for gear, reputation or achievements."),
            Bullet("The daily system is a reason to vary which Heroic you run instead of farming only the fastest instance every day."),
            "",
            SH("LATER DALARAN RAID QUESTS"),
            Priority("TIER 15+", "As the expansion advances, Dalaran shifts toward the later recurring raid-target system, including weekly raid objectives.", C.orange),
            Bullet("Pick up the active raid quest before your normal raid schedule so you do not lose free value for a boss you were already planning to kill."),
            Bullet("These quests are bonus progression rewards; they never replace the boss that actually advances your Individual Progression tier."),
            "",
            SH("SPENDING PLAN BY TIER"),
            Priority("TIER 13", "Use Heroism to remove major Pre-Raid weaknesses; do not hoard forever while entering Naxx with a very poor slot.", C.green),
            Priority("TIER 14", "Use Valor/current raid currency to support Ulduar readiness and valuable set bonuses.", C.green),
            Priority("TIER 15", "Conquest from Heroics makes off-spec/catch-up gearing much easier; spend around ToC progression needs.", C.green),
            Priority("TIER 16+", "Triumph from Heroics is excellent late catch-up. Save raid time for ICC while Heroics solve easier gear gaps.", C.green),
            "",
            SH("QUICK ROUTINE"),
            Bullet("1. Check the active Dalaran daily/weekly objective."),
            Bullet("2. Run a Heroic that gives both the objective and a useful gear/reputation result where possible."),
            Bullet("3. Check your current emblem vendor before buying anything."),
            Bullet("4. Spend on a meaningful weak slot or important set bonus, then return to the current raid tier."),
        })
    end,
}

local WOTLK_REPUTATIONS_PAGE = {
    title = "Wrath Reputations",
    short = "When to farm them, how to gain rep, and what they give you",
    icon = "Interface\\Icons\\INV_Misc_Note_02",
    body = function()
        return Join({
            SH("HOW TO USE THIS PAGE"),
            "Wrath reputations are easier to integrate into normal play than TBC Heroic-key reputations. Four major factions use dungeon tabards, Sons of Hodir is your main shoulder-enchant reputation, and later raid/tournament reputations become relevant only when their content opens.",
            "",
            Priority("LEVEL 80 PRIORITY", "Choose the faction that provides your most useful head enchant and wear its tabard while doing eligible level-80 dungeons. Work on Sons of Hodir in parallel if you need their shoulder enchants.", C.red),
            "",

            H("SONS OF HODIR - STORM PEAKS"),
            Priority("VERY HIGH PRIORITY - SHOULDER ENCHANTS", "Begin during late leveling / early Tier 13, especially for non-Scribes.", C.red),
            Bullet("Why it matters: Sons of Hodir provides the main Wrath reputation shoulder enchants. Honored unlocks lesser versions and Exalted unlocks the strongest versions."),
            Bullet("How to unlock it: complete the Storm Peaks/K3 quest route that eventually introduces the Sons of Hodir and repairs your standing with them."),
            Bullet("How to gain rep: continue their daily quests, turn in Relics of Ulduar and use Everfrost Chip turn-ins when available."),
            Bullet("What you gain: shoulder enchants for physical DPS, spell users/healers and tanks, plus profession recipes, gear and mammoth rewards."),
            Bullet("Who can deprioritise it: Inscription has profession-exclusive shoulder enchants, so Scribes are less dependent on Hodir for raid performance, though the faction still has completion/reward value."),
            "",

            H("KIRIN TOR - DALARAN / NORTHREND"),
            Priority("CASTER DPS HEAD ENCHANT / RECIPES", "Start naturally while leveling and finish at 80 with the Kirin Tor tabard if its rewards suit your class.", C.orange),
            Bullet("How to gain rep: Northrend quests involving the Kirin Tor, then dungeon championing with their tabard once available."),
            Bullet("Why it matters: Revered provides the major caster-focused head enchant; the faction also offers gear and profession recipes."),
            Bullet("Best for: caster DPS first, then anyone who wants a Kirin Tor recipe or vendor reward."),
            Bullet("Do not force Exalted immediately unless an Exalted reward matters to your character; Revered is often the practical combat milestone."),
            "",

            H("KNIGHTS OF THE EBON BLADE - ZUL'DRAK / ICECROWN"),
            Priority("PHYSICAL DPS HEAD ENCHANT", "High priority for melee and physical ranged DPS at level 80.", C.orange),
            Bullet("How to unlock it: progress the Ebon Blade questlines and establish the Shadow Vault in Icecrown so the quartermaster becomes usable."),
            Bullet("How to gain rep: quest through their hubs, then use the Ebon Blade tabard in eligible level-80 dungeons."),
            Bullet("What you gain: the major physical-DPS head enchant at Revered, gear and several profession recipes."),
            Bullet("Why to start early: unlocking Shadow Vault takes quest progress, so do not wait until raid night to discover you cannot reach the quartermaster."),
            "",

            H("ARGENT CRUSADE - ZUL'DRAK / ICECROWN"),
            Priority("HEALER HEAD ENCHANT / ENDGAME HUBS", "High priority for healers; useful supporting reputation for everyone else.", C.orange),
            Bullet("How to gain rep: quest through Argent Crusade story hubs, then champion them with the Argent Crusade tabard in eligible level-80 dungeons."),
            Bullet("What you gain: the healer-focused head enchant at Revered, gear and profession recipes."),
            Bullet("Why it remains relevant: the Crusade is tied heavily to Icecrown and later Argent Tournament content, so the reputation fits naturally into the Wrath story route."),
            "",

            H("THE WYRMREST ACCORD - DRAGONBLIGHT"),
            Priority("TANK HEAD ENCHANT / RED DRAKE", "High priority for tanks; optional-to-useful for other roles.", C.orange),
            Bullet("How to gain rep: Dragonblight quests and Wyrmrest dailies, then the Wyrmrest Accord tabard in eligible level-80 dungeons."),
            Bullet("What you gain: the major tanking head enchant at Revered, gear and profession rewards."),
            Bullet("Exalted reward: the Red Drake is a major faction mount goal."),
            Bullet("Practical target: tanks normally want Revered quickly; other roles can stop earlier unless a recipe, item or mount is desired."),
            "",

            H("HORDE EXPEDITION / ALLIANCE VANGUARD"),
            Priority("LEVELING / FACTION REWARDS", "Build this mostly through normal Northrend questing and faction sub-groups rather than a standard dungeon tabard grind.", C.yellow),
            Bullet("Why it matters: this umbrella reputation tracks your faction's wider Northrend war effort and unlocks useful vendor rewards as you advance."),
            Bullet("Profession value: Engineers pursuing the faction motorcycle mount schematic should pay particular attention to the appropriate faction vendor at high reputation."),
            Bullet("Recommended approach: let most of it rise naturally while leveling, then deliberately finish it only when a specific reward matters."),
            "",

            H("THE KALU'AK - COASTAL NORTHREND"),
            Priority("OPTIONAL - QUALITY OF LIFE / COLLECTION", "Work on it while leveling if you enjoy the questlines; finish later through its dailies if the rewards appeal to you.", C.purple),
            Bullet("How to gain rep: Kalu'ak quest hubs across Howling Fjord, Dragonblight and Borean Tundra plus their repeatable daily quests."),
            Bullet("What you gain: useful leveling/endgame items, a strong fishing pole at high reputation and collection rewards."),
            Bullet("Progression value: not required for raids, so do not delay Tier 13 just to reach Exalted."),
            "",

            H("THE ORACLES / FRENZYHEART TRIBE - SHOLAZAR BASIN"),
            Priority("OPTIONAL CHOICE", "Choose a side through the Sholazar questline, then use its dailies for faction-specific rewards.", C.purple),
            Bullet("The choice occurs after the Artruis the Heartless storyline and can later be changed if you want to pursue the other faction."),
            Bullet("The Oracles are famous for the Mysterious Egg reward path, which can produce pets and a rare mount."),
            Bullet("Frenzyheart provides its own consumables, trinket/toy-style rewards and collection goals."),
            Bullet("Neither faction is a raid requirement; treat them as a daily/collection project."),
            "",

            H("THE ASHEN VERDICT - ICECROWN CITADEL"),
            Priority("TIER 16 - VERY HIGH RAID VALUE", "Begin automatically as soon as ICC opens and keep it moving every raid.", C.red),
            Bullet("How to gain rep: kill enemies and bosses inside Icecrown Citadel."),
            Bullet("Why it matters: reputation upgrades the powerful Ashen Verdict ring through multiple stages."),
            Bullet("Profession value: later reputation levels also unlock important ICC-era crafting patterns and recipes."),
            Bullet("Do not treat this as a separate outdoor grind; it progresses naturally while you raid ICC."),
            "",

            H("THE SUNREAVERS / SILVER COVENANT - ARGENT TOURNAMENT"),
            Priority("TIER 15 SIDE CONTENT", "Relevant once the Argent Tournament stage opens on this server.", C.purple),
            Bullet("How to gain value: Tournament dailies and Champion progression tie into faction-city and Tournament rewards."),
            Bullet("What you gain: access to themed mounts, pets, tabards, titles and other Tournament purchases alongside Champion's Seals."),
            Bullet("Progression value: optional; do it because you want the Tournament rewards, not because Anub'arak requires it."),
            "",

            SH("REPUTATION PRIORITY BY STAGE"),
            Priority("LEVEL 70-79", "Let Kirin Tor, Wyrmrest, Argent Crusade and Ebon Blade rise naturally through questing. Unlock Sons of Hodir before or around level 80.", C.yellow),
            Priority("TIER 13", "Push the class-relevant head-enchant faction to Revered and build Sons of Hodir toward the shoulder enchant you need.", C.orange),
            Priority("TIER 14", "Finish remaining raid-performance enchants; optional factions can now be worked on between Ulduar raids."),
            Priority("TIER 15", "Argent Tournament factions become worthwhile side progression."),
            Priority("TIER 16", "Ashen Verdict becomes the new raid-reputation priority while ICC is current."),
            Priority("TIER 17", "Finish only the reputations whose final recipes, mounts, achievements or collection rewards you still want."),
        })
    end,
}

local WOTLK_PROFESSIONS_PAGE = {
    title = "Wrath Professions",
    short = "450 skill, standout items, profession bonuses and reputation dependencies",
    icon = "Interface\\Icons\\INV_Misc_EngGizmos_27",
    body = function()
        return Join({
            SH("WRATH PROFESSION GOAL"),
            "Raise your chosen professions toward 450 while leveling, then use their personal bonuses, crafted gear and recipe systems as part of raid preparation. In Wrath, professions are valuable even after you stop wearing their early crafted gear.",
            "",
            Priority("NEW IN WRATH", "Inscription is now available. Jewelcrafting remains available from TBC.", C.blue),
            "",
            SH("ALCHEMY"),
            Bullet("Why take it: one of the easiest ways to keep a raiding character supplied with flasks, potions and transmutes."),
            Bullet("Noteworthy items: Potion of Speed, Potion of Wild Magic, Flask of Endless Rage, Flask of the Frost Wyrm, Flask of Stoneblood and Flask of the North."),
            Bullet("Mixology improves flasks/elixirs you can make for yourself, making the profession bonus useful every raid night."),
            Bullet("Northrend Alchemy Research / discoveries and transmutes give the profession long-term recipe progression beyond simply reaching 450."),
            Priority("REP DEPENDENCE", "Relatively low compared with Jewelcrafting. Focus first on recipes/consumables your class uses, then collect faction recipes for completion.", C.yellow),
            "",
            SH("BLACKSMITHING"),
            Bullet("Why take it: excellent flexible personal stats plus plate, weapon and raid-crafting support."),
            Bullet("Noteworthy items: Eternal Belt Buckle for an extra belt socket, Titansteel-based early epics and later Ulduar/ToC/ICC crafted pieces."),
            Bullet("Personal bonus: extra sockets on bracers and gloves let you customise two additional gems around your current stat needs."),
            Priority("REP DEPENDENCE", "Usually less reputation-heavy than Jewelcrafting; raid drops/patterns and expensive materials become the bigger endgame gates.", C.yellow),
            "",
            SH("ENCHANTING"),
            Bullet("Why take it: every new raid piece needs an enchant, while unwanted dungeon/raid gear becomes materials such as Dream Shards and Abyss Crystals."),
            Bullet("Noteworthy enchants include Berserking, Black Magic and later raid-era weapon enchants, plus the Enchanter's profession-only ring enchants."),
            Bullet("This profession becomes especially convenient on a server where you repeatedly clear older raids and generate large quantities of disenchantable gear."),
            Priority("REP DEPENDENCE", "Moderate. Check faction vendors, but many of the most desirable enchants come from trainers, drops or later raid content rather than one mandatory reputation grind.", C.yellow),
            "",
            SH("ENGINEERING"),
            Bullet("Why take it: arguably the most unique raid/PvP utility profession in Wrath."),
            Bullet("Noteworthy tools: Hyperspeed Accelerators, Nitro Boosts, Flexweave Underlay, bombs, MOLL-E, Wormhole Generator: Northrend and later Jeeves."),
            Bullet("The Mechano-hog / Mekgineer's Chopper schematic is tied to high Horde Expedition / Alliance Vanguard reputation, making that reputation particularly relevant to Engineers who want the mount craft."),
            Priority("REP DEPENDENCE", "Low for combat power, but high faction reputation matters for specific collection crafts such as the motorcycle schematic.", C.yellow),
            "",
            SH("INSCRIPTION"),
            Priority("NEW PROFESSION", "Glyphs make Inscription immediately relevant to every class in Wrath.", C.blue),
            Bullet("Noteworthy items: glyphs, vellums, off-hands, Darkmoon cards and Darkmoon Card: Greatness-style deck crafting."),
            Bullet("Personal bonus: Master's Inscriptions provide strong profession-only shoulder enchants."),
            Priority("SONS OF HODIR", "Scribes can deprioritise Sons of Hodir for personal shoulder-enchant power because their profession supplies its own shoulder inscription.", C.green),
            Bullet("Research/discovery systems mean recipe collection continues after 450 rather than ending at the trainer."),
            "",
            SH("JEWELCRAFTING"),
            Bullet("Why take it: every new raid upgrade can create a new gemming problem, so Jewelcrafting stays relevant for the entire expansion."),
            Bullet("Noteworthy value: Dragon's Eye profession gems, a huge catalogue of cuts, crafted rings/necks and daily-token recipe progression."),
            Priority("MOST REP-DEPENDENT WRATH PROFESSION", "Jewelcrafting has useful designs spread across many factions, so reputation completion matters more here than for most professions.", C.red),
            Bullet("Examples: Argent Crusade, Kirin Tor, Knights of the Ebon Blade, Kalu'ak, Oracles/Frenzyheart, Sons of Hodir and Wyrmrest Accord all provide Jewelcrafting designs at various standings."),
            "",
            SH("LEATHERWORKING"),
            Bullet("Why take it: leather/mail gearing, armor kits and strong raiding support."),
            Bullet("Noteworthy items: Icescale Leg Armor and Frosthide Leg Armor plus later raid-crafted armor."),
            Bullet("Personal bonus: Fur Lining bracer enchants provide a strong profession-only stat increase."),
            Priority("REP DEPENDENCE", "Moderate-to-low; important patterns increasingly come from endgame/raid sources rather than one required reputation.", C.yellow),
            "",
            SH("TAILORING"),
            Bullet("Why take it: strong cloth crafting plus unique cloak procs that remain useful after early crafted armor is replaced."),
            Bullet("Noteworthy systems: Moonshroud, Spellweave and Ebonweave cloth; spellthreads; bags; later Ulduar/ToC/ICC cloth patterns."),
            Bullet("Personal bonuses: Lightweave Embroidery, Darkglow Embroidery and Swordguard Embroidery support different roles."),
            Priority("REPUTATIONS", "Kirin Tor, Knights of the Ebon Blade and Wyrmrest Accord are particularly worth checking for Tailoring recipes while you are already farming their head-enchant/reward tracks.", C.yellow),
            "",
            SH("GATHERING PROFESSIONS"),
            Bullet("Herbalism: Lifeblood is a personal heal; herbs feed Alchemy and Inscription."),
            Bullet("Mining: Toughness adds stamina; ore feeds Blacksmithing, Engineering and Jewelcrafting."),
            Bullet("Skinning: Master of Anatomy adds critical strike rating; leather feeds Leatherworking."),
            Bullet("They are easy to level while questing, but pure raiders may eventually prefer a crafting profession if the profession bonus matters more than self-supplied materials."),
            "",
            SH("SECONDARY PROFESSIONS"),
            Bullet("Cooking: Dalaran Cooking Awards and Northern Spices unlock important raid foods such as Fish Feast and strong stat foods. This is genuinely useful raid preparation."),
            Bullet("Fishing: supports Fish Feast/raid-food supply and Dalaran fishing dailies, while also providing collection rewards."),
            Bullet("First Aid: Heavy Frostweave Bandages remain useful emergency healing for characters without reliable self-heals."),
            "",
            SH("REPUTATION PRIORITY BY PROFESSION"),
            Priority("JEWELCRAFTING", "Pay the most attention to faction vendors; recipe collection is spread across many Wrath reputations.", C.red),
            Priority("TAILORING", "Kirin Tor / Ebon Blade / Wyrmrest are worth checking while farming their normal character rewards.", C.orange),
            Priority("ENGINEERING", "Horde Expedition / Alliance Vanguard becomes especially relevant if you want the motorcycle schematic.", C.orange),
            Priority("INSCRIPTION", "Sons of Hodir is less urgent for your own shoulder enchant because Master's Inscriptions cover that slot.", C.green),
            Priority("OTHER CRAFTS", "Check reputation vendors, but do not grind a faction to Exalted unless it actually sells a pattern or reward you intend to use.", C.green),
            "",
            SH("WHEN TO WORK ON PROFESSIONS"),
            Priority("70-79", "Gather Northrend materials and train new recipes while leveling.", C.yellow),
            Priority("TIER 13", "Secure your profession bonus and craft real pre-raid upgrades; start daily/research systems early.", C.orange),
            Priority("TIER 14-15", "Watch for Ulduar/ToC patterns and keep profession currency/research moving.", C.yellow),
            Priority("TIER 16", "ICC/Ashen Verdict-era crafting materials and patterns become the main endgame profession targets.", C.red),
            Priority("TIER 17", "Finish rare recipes and collection crafts you still care about; raid progression no longer depends on maximising every profession.", C.purple),
        })
    end,
}

local WOTLK_PVP_PAGE = {
    title = "Wrath PvP",
    short = "Arena Season 5, Honor gearing, Wintergrasp and PvP progression",
    icon = "Interface\\Icons\\Achievement_Arena_2v2_7",
    body = function()
        return Join({
            SH("ACTIVE ARENA SEASON"),
            Priority("SERVER SETTING", "Wrath Arena Season 5 is the active PvP era for this progression journey.", C.blue),
            Bullet("Season 5 is Wrath's first Arena season and uses the Savage, Hateful and Deadly Gladiator gear families rather than later Wrath season sets."),
            "",
            SH("HOW TO START AT LEVEL 80"),
            Step(1, "Build basic Resilience and Honor gear"),
            Bullet("Use Battlegrounds for Honor and available off-set/main-set purchases. A basic PvP set is much more comfortable than entering Arena in pure dungeon gear."),
            Bullet("Resilience is primarily a PvP stat; it improves survival against players but usually gives less raid throughput than a similarly strong PvE piece."),
            "",
            Step(2, "Use Wintergrasp every time it is practical"),
            Bullet("Wintergrasp gives large-scale objective PvP, Honor, quests and its own reward currencies while also deciding Vault of Archavon access."),
            Bullet("See the Wintergrasp page for the battle loop, currencies and Vault boss timeline."),
            "",
            Step(3, "Enter rated Arena"),
            Bullet("Rated Arena is the route to Season 5 Arena gear. Higher-end Deadly Gladiator rewards are the prestige/current-season goal, while easier gear tiers help you establish a working set."),
            Bullet("Build a composition around crowd control, defensive cooldowns, interrupts and kill windows rather than treating Arena like a short raid boss."),
            "",
            SH("SAVAGE / HATEFUL / DEADLY - SIMPLE MEANING"),
            Priority("SAVAGE", "Entry PvP gearing. Use it to get out of weak leveling gear and begin building Resilience.", C.green),
            Priority("HATEFUL", "Stronger Season 5-era gear and a realistic bridge between basic Honor gearing and top Arena rewards.", C.yellow),
            Priority("DEADLY", "Top Season 5 Gladiator gear; your main rated-PvP progression target.", C.red),
            Bullet("Exact vendor costs/requirements are controlled by the server's phased PvP vendors, so always check the active Season 5 vendors before planning a purchase."),
            "",
            SH("PVE CROSSOVER"),
            Bullet("Vault of Archavon can supply PvP set pieces while also dropping PvE tier pieces, making it unusually valuable to both kinds of player."),
            Bullet("PvP gear can patch a terrible PvE slot, but do not replace a strong raid item purely because the PvP item has a higher item level."),
            "",
            SH("VANILLA TITLE RULE"),
            Bullet("Previously earned Vanilla PvP titles remain on the character."),
            Priority("REMINDER", "New Vanilla Rank 1-14 titles cannot be earned after the character has left Vanilla progression.", C.orange),
            "",
            SH("WHEN TO DO PVP"),
            Priority("TIER 13", "Best time to establish your set. Battlegrounds + Wintergrasp + Arena can fill weak slots alongside Heroics/Naxx.", C.orange),
            Priority("TIER 14+", "Continue if PvP is a real character goal; otherwise use it selectively for useful rewards rather than letting it replace required raid progression.", C.yellow),
        })
    end,
}

local WINTERGRASP_PAGE = {
    title = "Wintergrasp & Vault of Archavon",
    short = "How the battle works, what you earn and when each Vault boss appears",
    icon = "Interface\\Icons\\Spell_Frost_FrostArmor02",
    body = function()
        return Join({
            SH("WHEN IT OPENS"),
            Priority("TIER 13", "Wintergrasp becomes available when Wrath progression begins.", C.green),
            Bullet("The server's Wintergrasp queue NPCs are progression-aware, so the system belongs to Wrath rather than appearing during earlier expansions."),
            "",
            SH("WHAT YOU ACTUALLY DO"),
            Bullet("Wintergrasp is an attacker-versus-defender siege battle. Attackers push toward Wintergrasp Fortress; defenders protect the fortress until the battle timer expires."),
            Bullet("Fight players and complete objectives to gain rank during the battle. Higher rank allows access to the siege vehicles needed to break or defend walls/towers."),
            Bullet("Work with the raid: destroying towers, protecting workshops, escorting vehicles and controlling the fortress matter more than chasing isolated kills."),
            "",
            SH("WHY RUN IT"),
            Bullet("Earn Honor and Wintergrasp-specific rewards while progressing normal PvP goals."),
            Bullet("Wintergrasp Marks of Honor are awarded for participation, with the winning side receiving more than the losing side."),
            Bullet("Stone Keeper's Shards are another useful reward currency and can be spent on items such as gems, enchants, heirlooms, Jewelcrafting designs and collection rewards."),
            Bullet("The winning faction controls Wintergrasp Keep and gains access to its vendors and Vault of Archavon until control changes."),
            "",
            SH("WINTERGRASP QUESTS"),
            Bullet("Pick up the available Wintergrasp PvP quests before the battle. They turn normal objectives such as kills, vehicles or zone actions into extra Honor/currency value."),
            Bullet("If you plan to PvP regularly, these quests make Wintergrasp one of the most efficient repeatable side activities in opening Wrath."),
            "",
            H("VAULT OF ARCHAVON BOSS TIMELINE"),
            Priority("TIER 13", "Archavon the Stone Watcher - opening Wrath Vault boss.", C.purple),
            Priority("TIER 14", "Emalon the Storm Watcher joins during Ulduar progression.", C.purple),
            Priority("TIER 15", "Koralon the Flame Watcher joins during Trial of the Crusader progression.", C.purple),
            Priority("TIER 16+", "Toravon the Ice Watcher joins once Icecrown progression begins.", C.purple),
            "",
            SH("WHY VAULT IS SO GOOD"),
            Bullet("Vault bosses can drop both PvE tier pieces and PvP set pieces, so a short raid can potentially save a large amount of emblem, Arena or raid-token grinding."),
            Bullet("Always kill the bosses currently available for your tier if their loot is still relevant; later bosses do not make the earlier ones disappear."),
            "",
            SH("SIMPLE ROUTINE"),
            Bullet("1. Pick up Wintergrasp quests."),
            Bullet("2. Join the battle and play the siege objectives."),
            Bullet("3. If your faction controls the fortress, check the vendors and run Vault."),
            Bullet("4. Revisit Vault whenever a new progression tier adds another boss."),
            "",
            SH("PROGRESSION PRIORITY"),
            Priority("OPTIONAL - HIGH VALUE", "Wintergrasp/Vault never replaces your required raid boss, but the reward-per-time can be excellent while its gear is current.", C.yellow),
        })
    end,
}

local ARGENT_TOURNAMENT_PAGE = {
    title = "Argent Tournament",
    short = "Tier 15 jousting progression, seals, city champions and rewards",
    icon = "Interface\\Icons\\Achievement_Zone_Icecrown_01",
    body = function()
        return Join({
            SH("SERVER TIMING"),
            Priority("TIER 15", "The Argent Tournament is phased to the Trial of the Crusader era on this server. Start it after Yogg-Saron rather than treating it as opening-Wrath content.", C.orange),
            "",
            SH("STEP 1 - BECOME AN ASPIRANT"),
            Bullet("Begin the introductory Tournament quests and learn the three jousting basics: melee strikes, charge and shield-breaking."),
            Bullet("Complete Aspirant dailies until you have earned 15 Aspirant's Seals."),
            Priority("RANK UP", "Turn in the Aspirant requirement and complete the Aspirant's Challenge to become a Valiant.", C.yellow),
            "",
            SH("STEP 2 - BECOME A VALIANT"),
            Bullet("Represent your starting city and complete the Valiant daily quests."),
            Bullet("Earn 25 Valiant's Seals, then complete the rank challenge to become Champion for that city."),
            Bullet("After becoming Champion, you can work through the Valiant path for the other cities in your faction without losing previous Champion progress."),
            "",
            SH("STEP 3 - CHAMPION'S SEALS"),
            Priority("MAIN CURRENCY", "Champion's Seals become the core Tournament reward currency once Champion progression is unlocked.", C.green),
            Bullet("Spend them on faction mounts, companion pets, tabards, banners, gear and other city-themed rewards."),
            Bullet("Champion's Writs can also support faction reputation through reputation-token purchases."),
            "",
            SH("STEP 4 - BECOME A CRUSADER IF YOU WANT THE FULL PATH"),
            Bullet("Champion all five home-faction cities and reach the required Argent Crusade standing to unlock the full Crusader-style Tournament progression."),
            Bullet("This is a long optional completion path. It is not required to kill Anub'arak or advance Individual Progression."),
            "",
            SH("SUNREAVERS / SILVER COVENANT"),
            Bullet("Horde characters work alongside the Sunreavers; Alliance characters work alongside the Silver Covenant."),
            Bullet("Their daily/vendor rewards become part of the Tournament-era routine and include additional themed purchases."),
            "",
            SH("THE BLACK KNIGHT"),
            Priority("RECOMMENDED", "Complete the Black Knight storyline while progressing the Tournament.", C.yellow),
            Bullet("It provides the story lead-in to the Black Knight encounter in Trial of the Champion and gives the Tournament more context than simply farming dailies."),
            "",
            SH("TRIAL OF THE CHAMPION"),
            Bullet("The 5-player Trial of the Champion opens in this era and is an efficient source of level-80 upgrades."),
            Bullet("Use it as catch-up/side gearing while your main progression target remains Trial of the Crusader."),
            "",
            SH("WHAT IS WORTH BUYING"),
            Bullet("Collectors: city mounts, faction pets, tabards and banners are the long-term reason to keep farming Seals."),
            Bullet("Progression-focused players: inspect the available gear first, then stop the grind when the remaining rewards are purely cosmetic."),
            "",
            SH("PRIORITY RULE"),
            Priority("OPTIONAL", "The Tournament is excellent side progression, but do not delay Anub'arak / Trial of the Crusader progression just to finish every city and mount.", C.purple),
        })
    end,
}

local GENERAL_PAGE = {
    title = "General Information",
    short = "Server rules, phasing, professions & travel",
    icon = "Interface\\Icons\\INV_Misc_Map_01",
    body = function()
        return Join({
            SH("WORLD & CONTENT PHASING"),
            "Some NPCs, profession systems and convenience travel points are intentionally phased so they appear at the appropriate point in the progression journey. If something listed here is missing, it is normally progression phasing rather than a bug.",
            "",
            SH("PHASED PROFESSIONS"),
            Priority("THE BURNING CRUSADE", "Jewelcrafting is unavailable during Vanilla. Its trainers, vendors and related NPCs are phased until The Burning Crusade becomes available.", C.green),
            Priority("WRATH OF THE LICH KING", "Inscription is unavailable during Vanilla and The Burning Crusade. Its trainers, vendors and related NPCs are phased until Wrath of the Lich King.", C.blue),
            "",
            SH("PHASED FLIGHT PATHS"),
            "Several later-added flight masters are intentionally unavailable during earlier Vanilla progression:",
            Bullet("Ratchet"),
            Bullet("Marshal's Refuge"),
            Bullet("Emerald Sanctuary"),
            Bullet("The Bulwark"),
            Bullet("Thondroril River"),
            Priority("BY TIER 6", "All five flight paths are unphased and available by the Naxxramas stage. Some may become available earlier as the Vanilla journey advances.", C.green),
            "",
            SH("GROUP PROGRESSION RULE"),
            Priority("IMPORTANT", "Characters may only group with others in the same progression phase.", C.orange),
            Bullet("If two characters cannot group normally, compare their Individual Progression stage before assuming the group system is broken."),
            "",
            SH("QUESTING"),
            Bullet("Quest-object markers and sparkles are disabled. Read quest text and objective descriptions carefully."),
            Bullet("Vanilla and TBC quest XP uses restored pre-catch-up values."),
            "",
            SH("REPUTATION GUIDANCE"),
            Bullet("Vanilla faction progression now has its own detailed guide under Vanilla Side Content. Use that page for Hydraxian Waterlords, Thorium Brotherhood, Argent Dawn, Zandalar Tribe, Cenarion Circle, Brood of Nozdormu and Timbermaw Hold."),
            "",
            SH("EARLY CONTENT OPTIONS"),
            Priority("AVAILABLE EARLY", "Dungeon Set 2 progression is enabled early, so the upgrade chain can be worked on before its normal later-Vanilla window.", C.yellow),
            Priority("AVAILABLE EARLY", "The six Scourge Invasion dungeon bosses are enabled early rather than being restricted only to the Naxxramas stage.", C.yellow),
            "",
            SH("EXPANSION-ERA CHARACTER OPTIONS"),
            Bullet("Blood Elves and Draenei unlock after Vanilla progression is completed and begin at the start of The Burning Crusade progression."),
            Bullet("Death Knights remain tied to completion of The Burning Crusade progression before Wrath-era play."),
        })
    end,
}

local TALENT_RULES_PAGE = {
    title = "Talent Rules",
    short = "Expansion-based 3.3.5 talent restrictions",
    icon = "Interface\\Icons\\INV_Misc_Book_07",
    body = function()
        return Join({
            SH("HOW TALENTS WORK"),
            "The server uses the Wrath of the Lich King 3.3.5 talent trees, but lower parts of each tree are blocked until the appropriate expansion.",
            "",
            SH("VANILLA / CLASSIC - LEVEL 1 TO 60"),
            Priority("ALLOWED", "Rows 1 through 6 are fully available.", C.green),
            Priority("ROW 7", "Only the middle talent is available. The left and right talents are blocked.", C.yellow),
            Priority("BLOCKED", "Rows 8 through 11 are unavailable.", C.red),
            Bullet("The middle Row 7 talent represents the old Vanilla-style 31-point talent."),
            "",
            SH("THE BURNING CRUSADE - LEVEL 61 TO 70"),
            Priority("ALLOWED", "Rows 1 through 8 are fully available.", C.green),
            Priority("ROW 9", "Only the middle talent is available. The left and right talents are blocked.", C.yellow),
            Priority("BLOCKED", "Rows 10 and 11 are unavailable.", C.red),
            Bullet("The middle Row 9 talent represents the old TBC-style 41-point talent."),
            "",
            SH("WRATH OF THE LICH KING - LEVEL 71 TO 80"),
            Priority("FULL TREE", "Rows 1 through 11 are available normally.", C.blue),
            "",
            SH("IMPORTANT"),
            Bullet("These restrictions apply separately to every talent tree."),
            Bullet("You may still split talent points between multiple trees."),
            Bullet("The restriction is based on the talent's position in the tree, not its name or whether it exists in the 3.3.5 calculator."),
        })
    end,
}

local REPUTATIONS_PAGE = {
    title = "Vanilla Reputations",
    short = "When to farm them, how to earn them, and what they give you",
    icon = "Interface\\Icons\\INV_Misc_Note_02",
    body = function()
        return Join({
            SH("HOW TO USE THIS PAGE"),
            "Vanilla reputations are not all equally urgent. Some directly support raid access or raid mechanics, while others are mainly valuable for profession recipes, enchants, gear or completion goals.",
            "",
            Priority("DO FIRST", "Prioritise Hydraxian Waterlords for Molten Core and begin Argent Dawn early enough that Naxxramas attunement never becomes a last-minute wall.", C.red),
            Bullet("Farm a reputation harder when its next reward actually helps your class, professions, raid role or current progression tier."),
            Bullet("Several reputations rise naturally from raids. Do not delay progression just to reach Exalted before the content that actually awards the reputation is available."),
            "",

            H("HYDRAXIAN WATERLORDS - AZSHARA / MOLTEN CORE"),
            Priority("TIER 0 - ESSENTIAL RAID SUPPORT", "Start immediately while preparing for and clearing Molten Core.", C.red),
            Bullet("Why it matters: your server uses manual Molten Core rune dousing. The Hydraxian quest line gives access to the Quintessence items needed to extinguish the runes and reach Majordomo Executus and Ragnaros."),
            Bullet("How to work on it: begin Duke Hydraxis' quests in Azshara, kill the required elemental enemies, then continue the chain into Molten Core. Molten Core bosses continue to award reputation as you raid."),
            Bullet("Important quest step: complete Hands of the Enemy by bringing Duke Hydraxis the hands from Lucifron, Gehennas, Shazzrah and Sulfuron Harbinger. This leads into your reusable access to Aqual Quintessence pickups."),
            Bullet("Aqual Quintessence: one-use dousing item. After using it you must obtain another from Duke Hydraxis before the next use."),
            Bullet("Revered reward: Eternal Quintessence gives you a permanent dousing item rather than consuming the item each time."),
            Bullet("Server rule: Eternal Quintessence keeps its normal 1-hour cooldown, so having several raid members able to douse is still useful."),
            Bullet("What you gain: the reputation is mainly about Molten Core access/mechanics rather than a huge gear vendor. Treat Revered as a very useful quality-of-life milestone for a regular MC raider."),
            "",

            H("THORIUM BROTHERHOOD - SEARING GORGE / BLACKROCK DEPTHS"),
            Priority("EARLY VANILLA - HIGH VALUE FOR CRAFTERS", "Start when Blackrock Mountain content becomes part of your level-60 route.", C.orange),
            Bullet("Why it matters: this is one of Vanilla's strongest profession reputations. Its vendor contains specialist fire-themed, Dark Iron and Molten Core-era recipes that can be valuable to both an individual character and the guild's raid crafting network."),
            Bullet("How to begin: Thorium Point quests and material turn-ins in Searing Gorge move you through the early reputation levels."),
            Bullet("Friendly to Honored: Dark Iron Residue from Blackrock Depths is the practical reputation route through Gaining Acceptance."),
            Bullet("Honored onward: Lokhtos Darkbargainer in the Grim Guzzler accepts high-end materials such as Dark Iron Ore, Fiery Cores, Lava Cores, Core Leather and Blood of the Mountain."),
            Bullet("What you gain: progressively stronger Blacksmithing, Leatherworking, Tailoring, Alchemy and Enchanting recipes. Examples include Dark Iron / Flarecore / Molten crafting and powerful weapon-enchant formulas."),
            Bullet("Who should push it: Blacksmiths, Leatherworkers, Tailors, Enchanters and guild-designated crafters should check every reputation breakpoint. A character with no useful recipe target can treat it as recommended rather than mandatory."),
            Bullet("Best timing: work on Friendly/Honored while BRD is still relevant, then use surplus Molten Core materials later instead of buying an expensive Exalted grind immediately."),
            "",

            H("ARGENT DAWN - PLAGUELANDS / SCHOLOMANCE / STRATHOLME"),
            Priority("START EARLY - IMPORTANT", "Begin during normal level-60 dungeon gearing and keep it moving toward Naxxramas.", C.red),
            Bullet("Why it matters: at least Honored is required for The Dread Citadel - Naxxramas attunement. Higher reputation makes that attunement substantially cheaper, and Exalted removes the material/gold cost."),
            Bullet("How to work on it: complete Argent Dawn quests in the Plaguelands, run Scholomance and Stratholme, and use the Argent Dawn Commission / Scourgestone turn-in system while farming undead content."),
            Bullet("Best approach: wear/work on the reputation while you are already farming dungeon gear, recipes, Righteous Orbs and other level-60 materials. That turns the grind into parallel progression instead of a Tier 6 emergency."),
            Bullet("What you gain: profession recipes, useful consumable/vendor rewards and resistance-focused shoulder enchants at the higher reputation levels."),
            Bullet("Profession value: the quartermasters include recipes for Alchemy, Blacksmithing, Leatherworking, Tailoring, First Aid and other useful crafts depending on reputation."),
            Bullet("Raid value: Revered and Exalted are not strictly required to enter Naxxramas, but they reduce or remove the attunement cost. Check the Naxxramas tab for the exact attunement requirements."),
            Bullet("Recommended target: reach Honored well before Tier 6. Continue toward Revered/Exalted if the cheaper attunement, recipes or resistance enchants are valuable to your character."),
            "",

            H("ZANDALAR TRIBE - ZUL'GURUB"),
            Priority("TIER 3 - IMPORTANT / HIGH VALUE", "Begin when Zul'Gurub unlocks after Blackwing Lair.", C.orange),
            Bullet("Why it matters: Zandalar reputation turns repeated Zul'Gurub clears into a long reward track containing enchants, profession recipes, consumables and class-related rewards."),
            Bullet("How to earn it: kill Zul'Gurub trash and bosses, collect Bijous and the different ZG coin sets, and use the repeatable turn-ins on Yojamba Isle."),
            Bullet("Efficiency: Bijous can be destroyed at the Altar of Zanza for reputation and Zandalar Honor Tokens; coin sets can also be turned in repeatedly. This lets raid drops continue your reputation outside the boss kills themselves."),
            Bullet("Friendly value: class-specific head/leg enchant progression becomes available and several profession recipes begin to appear."),
            Bullet("Revered value: Zanza consumables become one of the more distinctive ZG reputation rewards and can be useful for raid preparation."),
            Bullet("Exalted value: powerful Zandalar shoulder enchants become available, using Zandalar Honor Tokens."),
            Bullet("Profession value: Bloodvine and other ZG-era Tailoring, Leatherworking, Blacksmithing, Alchemy and Engineering recipes make this especially worthwhile for crafters."),
            Bullet("Best timing: simply keep clearing ZG while it is useful for gear. Push extra Bijou/coin turn-ins when you are close to a reward breakpoint you actually need."),
            "",

            H("CENARION CIRCLE - SILITHUS / AQ"),
            Priority("TIER 3-5 - IMPORTANT", "Begin serious work during Pre-AQ and continue through the Ahn'Qiraj stages.", C.orange),
            Bullet("Why it matters: Cenarion Circle ties together Silithus endgame quests, Twilight Cultist content, Nature Resistance preparation, profession recipes and Ahn'Qiraj reward systems."),
            Bullet("How to earn it: Silithus quests, Twilight Cultist kills and turn-ins, summoned Templar/Duke/Royal encounters, Field Duty-style activities when available, and later AQ20/AQ40 content all contribute."),
            Bullet("Nature Resistance value: the faction sells several important Nature Resistance crafting patterns and enchants. These are particularly relevant while preparing for AQ encounters where resistance sets may be useful."),
            Bullet("Profession value: Blacksmithing, Enchanting, Leatherworking and Tailoring all gain useful AQ-era recipes at different reputation levels."),
            Bullet("Gear value: Cenarion Circle quests and badge systems can produce strong endgame items in addition to the profession recipes, so check rewards as your reputation rises rather than treating it only as a bar to fill."),
            Bullet("Best timing: start during Pre-AQ, then let AQ20/AQ40 and Silithus activity continue the grind. There is little reason to force Exalted before the content that naturally awards the reputation is part of your progression."),
            "",

            H("BROOD OF NOZDORMU - AQ40"),
            Priority("TIER 5 - RAID REPUTATION", "Treat this as part of Temple of Ahn'Qiraj progression, not a prerequisite before entering AQ40.", C.orange),
            Bullet("Why it matters: Brood reputation directly powers major AQ40 rewards, especially the Signet Ring of the Bronze Dragonflight upgrade path and Tier 2.5 armor quests."),
            Bullet("Starting point: characters begin deeply Hated. AQ40 trash is designed to pull that reputation upward rapidly until you approach Neutral."),
            Bullet("How to earn it: AQ40 trash, bosses, Qiraji Lord's Insignias and Ancient Qiraji Artifacts are the main sources. AQ-related outdoor/event content can also contribute depending on the stage."),
            Bullet("Efficiency tip: ordinary AQ40 trash stops giving reputation at Neutral 2999/3000. Save Qiraji Lord's Insignias and Ancient Qiraji Artifacts until the trash reputation has done as much work as possible, then use turn-ins to continue."),
            Bullet("Ring rewards: at Neutral you can choose a Bronze Dragonflight ring path suited to your role; it is upgraded again at Friendly, Honored, Revered and Exalted."),
            Bullet("Tier 2.5 rewards: AQ40 class-set quests use Brood reputation gates - shoulders/boots begin at Neutral, helm/legs at Friendly and chest at Honored."),
            Bullet("Best timing: clear AQ40 normally and let the reputation rise with raid progression. Push saved turn-ins when they unlock your next ring or Tier 2.5 breakpoint."),
            "",

            H("TIMBERMAW HOLD - FELWOOD / WINTERSPRING"),
            Priority("OPTIONAL - PROFESSION / COMPLETION VALUE", "Work on this when its recipes or rewards are useful rather than because the raid path requires it.", C.purple),
            Bullet("Why it matters: Timbermaw is primarily a profession and completion reputation. It also makes travel through Timbermaw Hold safer once the furbolgs stop being hostile to you."),
            Bullet("How to earn it: kill Deadwood furbolgs in Felwood and Winterfall furbolgs in Winterspring, then use repeatable Deadwood Headdress Feather and Winterfall Spirit Bead turn-ins."),
            Bullet("Friendly rewards: useful recipes such as Transmute Earth to Water, 2H Weapon - Agility and Warbear Leatherworking patterns become available."),
            Bullet("Honored/Revered rewards: more Enchanting, Tailoring, Leatherworking and Blacksmithing recipes open, including weapon Agility and several Timbermaw-themed crafted pieces."),
            Bullet("Exalted reward: Defender of the Timbermaw provides a unique summon trinket and marks completion of the faction."),
            Bullet("Best timing: farm it alongside Felwood/Winterspring objectives, materials or profession goals. Do not delay a raid attunement or current-tier upgrade just to finish Timbermaw."),
            "",

            SH("SIMPLE PRIORITY BY STAGE"),
            Priority("TIER 0", "Hydraxian Waterlords is the immediate raid-mechanics priority. Start Argent Dawn in parallel and work Thorium Brotherhood if its profession recipes matter.", C.red),
            Priority("TIER 1-2", "Continue Argent Dawn whenever Scholomance/Stratholme are useful. Keep Hydraxian/Thorium progressing naturally through Blackrock content.", C.yellow),
            Priority("TIER 3", "Add Zandalar Tribe when Zul'Gurub opens and begin serious Cenarion Circle work in Silithus.", C.orange),
            Priority("TIER 4-5", "Cenarion Circle and then Brood of Nozdormu become the main AQ-era reputations. Use reputation rewards to support Nature Resistance, professions and Tier 2.5 progression.", C.orange),
            Priority("TIER 6", "Argent Dawn must already be at least Honored for Naxxramas attunement. Higher standing saves attunement cost and may unlock additional rewards.", C.red),
            Priority("OPTIONAL", "Timbermaw Hold can be fitted around the main progression path whenever its recipes, travel convenience or completion rewards matter to you.", C.purple),
            "",
            SH("BOTTOM LINE"),
            "Do not grind every reputation to Exalted just because it exists. Push the faction that unlocks your next raid mechanic, attunement, enchant, recipe or gear reward, and let raid reputations rise naturally while that content is current.",
        })
    end,
}

local PVP_PAGE = {
    title = "Vanilla PvP",
    short = "Custom PvP ranks, battleground reputation & gearing",
    icon = "Interface\\Icons\\INV_BannerPVP_01",
    body = function()
        return Join({
            SH("VANILLA PVP RANKING"),
            "Vanilla PvP titles on this server are earned from lifetime honorable kills. Each rank unlocks when your character reaches the required kill total.",
            "",
            H("RANK REQUIREMENTS"),
            "Rank 1   Private / Scout                 - 100 honorable kills",
            "Rank 2   Corporal / Grunt                 - 200 honorable kills",
            "Rank 3   Sergeant / Sergeant              - 400 honorable kills",
            "Rank 4   Master Sergeant / Senior Sergeant - 800 honorable kills",
            "Rank 5   Sergeant Major / First Sergeant  - 1,400 honorable kills",
            "Rank 6   Knight / Stone Guard             - 2,000 honorable kills",
            "Rank 7   Knight-Lieutenant / Blood Guard  - 3,000 honorable kills",
            "Rank 8   Knight-Captain / Legionnaire     - 4,500 honorable kills",
            "Rank 9   Knight-Champion / Centurion      - 6,000 honorable kills",
            "Rank 10  Lieutenant Commander / Champion  - 8,000 honorable kills",
            "Rank 11  Commander / Lieutenant General   - 10,000 honorable kills",
            "Rank 12  Marshal / General                - 13,000 honorable kills",
            "Rank 13  Field Marshal / Warlord          - 18,000 honorable kills",
            "Rank 14  Grand Marshal / High Warlord     - 24,000 honorable kills",
            "",
            SH("IMPORTANT RULES"),
            Priority("PERSISTENT", "Vanilla PvP titles remain on the character after progressing into TBC/Wrath.", C.green),
            Priority("VANILLA ONLY", "New Vanilla PvP titles cannot be earned after the character leaves Vanilla progression.", C.orange),
            Bullet("If a high Vanilla rank is part of your character's goals, finish the required honorable kills before moving into TBC."),
            "",
            SH("BATTLEGROUND REPUTATIONS"),
            Bullet("Warsong Gulch: Warsong Outriders / Silverwing Sentinels."),
            Bullet("Arathi Basin: The Defilers / The League of Arathor."),
            Bullet("Alterac Valley: Frostwolf Clan / Stormpike Guard."),
            Bullet("Battleground reputation rewards can provide useful gearing alternatives alongside dungeon and raid progression."),
            "",
            SH("GEARING PATH"),
            Priority("OPTIONAL - HIGH VALUE", "PvP can be used as a real gearing route rather than only side content.", C.purple),
            Bullet("Compare PvP rewards against your current Pre-Raid, raid and reputation options before committing to a long grind."),
            Bullet("Ranks and battleground reputations are separate progression systems; work on whichever rewards your character actually needs."),
            "",
            SH("CHECK YOUR RANK"),
            Bullet("The server command .ip pvp reports current rank progress when your account permissions allow that command."),
        })
    end,
}

local CHARACTER_SERVICES_PAGE = {
    title = "Chronomancer Vezrath",
    short = "Character Services & progression catch-up",
    icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    body = function()
        return Join({
            SH("WHERE TO FIND HIM"),
            "Chronomancer Vezrath is a male Bronze Draconid stationed in every capital city, near that capital's faction leader.",
            "",
            SH("PROGRESSION CATCH-UP"),
            "If another character on your account has already completed progression, eligible characters can purchase previously achieved progression from Chronomancer Vezrath.",
            Priority("ACCOUNT-LIMITED", "You can never buy beyond the highest progression already achieved on your account.", C.orange),
            Priority("SERVER LIMIT", "Catch-up purchases are currently capped at AQ War Effort progression.", C.orange),
            "",
            H("CATCH-UP PRICES"),
            Bullet("Molten Core completion - 150 gold."),
            Bullet("Onyxia completion - 200 gold."),
            Bullet("Blackwing Lair completion - 250 gold."),
            Bullet("Pre-AQ completion - 300 gold."),
            Bullet("AQ War Effort completion - 500 gold."),
            Bullet("AQ, Naxxramas and later progression cannot currently be purchased through the catch-up service."),
            Bullet("Progression catch-up prices are per purchased tier and are not cumulative."),
            "",
            SH("EXPANSION UNLOCKS"),
            Priority("VANILLA -> TBC", "2,500 gold", C.gold),
            Bullet("After completing the Vanilla journey, speak with Chronomancer Vezrath when you are ready to advance into The Burning Crusade."),
            "",
            Priority("TBC -> WOTLK", "7,500 gold", C.gold),
            Bullet("After defeating Kil'jaeden and completing The Burning Crusade progression, return to Chronomancer Vezrath when you are ready to advance into Wrath of the Lich King."),
            Bullet("Inscription trainers and vendors become available with Wrath of the Lich King."),
            "",
            SH("OTHER CHARACTER SERVICES"),
            Bullet("Name Change - 50 gold."),
            Bullet("Appearance Change - 25 gold."),
            Bullet("Race Change - 150 gold."),
            Bullet("Faction Change - 750 gold."),
            "",
            SH("TBC RACES"),
            Bullet("Blood Elves and Draenei unlock for the account after Vanilla progression is completed."),
            Bullet("Those races begin at the start of The Burning Crusade progression on this server."),
        })
    end,
}

local COMMANDS_PAGE = {
    title = "Commands / Help",
    short = "Addon commands and Individual Progression server commands",
    icon = "Interface\\Icons\\INV_Misc_Note_05",
    body = function()
        return Join({
            SH("ADDON COMMANDS"),
            H("/ip"),
            Bullet("Toggle the Individual Progression guide."),
            H("/ip current"),
            Bullet("Open the progression stage your character is currently working on across Vanilla, TBC or Wrath."),
            H("/ip tbc"),
            Bullet("Open The Burning Crusade overview / roadmap."),
            H("/ip tbcdungeons"),
            Bullet("Open TBC dungeon, access and Heroic-key guidance."),
            H("/ip tbcreps"),
            Bullet("Open the TBC Reputations guide."),
            H("/ip tbcprofessions"),
            Bullet("Open the TBC Professions guide."),
            H("/ip tbcpvp"),
            Bullet("Open TBC PvP and Arena Season guidance."),
            H("/ip tbcworldbosses"),
            Bullet("Open the TBC World Boss Timeline."),
            H("/ip zulaman"),
            Bullet("Open Zul'Aman side-content guidance."),
            H("/ip wrath"),
            Bullet("Open the Wrath of the Lich King overview / roadmap."),
            H("/ip wrathdungeons"),
            Bullet("Open Wrath dungeon and Heroic timing guidance."),
            H("/ip wrathemblems"),
            Bullet("Open the Wrath emblem and Dalaran recurring-quest guide."),
            H("/ip wrathreps"),
            Bullet("Open the detailed Wrath Reputations guide."),
            H("/ip wrathprofessions"),
            Bullet("Open the Wrath Professions guide."),
            H("/ip wrathpvp"),
            Bullet("Open Wrath PvP / Arena Season 5 guidance."),
            H("/ip wintergrasp"),
            Bullet("Open Wintergrasp and Vault of Archavon guidance."),
            H("/ip tournament"),
            Bullet("Open Argent Tournament guidance."),
            H("/ip worldbosses"),
            Bullet("Open the Vanilla World Boss Timeline."),
            H("/ip general"),
            Bullet("Open General Information."),
            H("/ip talents"),
            Bullet("Open the expansion-based Talent Rules page."),
            H("/ip reputations"),
            Bullet("Open the Vanilla Reputations guide."),
            H("/ip pvp"),
            Bullet("Open the Vanilla PvP guide."),
            H("/ip services"),
            Bullet("Open Chronomancer Vezrath's Character Services page."),
            H("/ip vezrath"),
            Bullet("Open Chronomancer Vezrath's Character Services page."),
            H("/ip refresh"),
            Bullet("Request your current progression from the server again."),
            H("/ip commands"),
            Bullet("Open this command-reference page."),
            H("/ip help"),
            Bullet("Print the addon command list in chat."),
            Bullet("/progression can be used instead of /ip for addon commands."),
            "",
            SH("INDIVIDUAL PROGRESSION SERVER COMMANDS"),
            "These are dot-commands provided by Individual Progression. Most can be used by normal players; .ip set and .ip tele require GM permissions. Some commands also depend on server configuration.",
            "",
            H(".ip get [player]"),
            Bullet("Show the target/self progression value."),
            "",
            H(".ip set <value>"),
            Priority("GM", "Set the selected/self character to a progression value.", C.orange),
            "",
            H(".ip setbot"),
            Bullet("Synchronise grouped bot characters to the player's current progression state."),
            "",
            H(".ip pvp [player]"),
            Bullet("Show Vanilla PvP rank progress and honorable kills for the target/self."),
            "",
            H(".ip tele <onyxia|naxx>"),
            Priority("GM", "Teleport the target/self to the restored Vanilla raid when the required attunement/access conditions are met.", C.orange),
            Bullet("Aliases onyxia40 and naxx40 are also accepted."),
            "",
            H(".ip attune <onyxia|blacktemple>"),
            Bullet("Group attunement helper. The character using it must already meet the relevant attunement/item requirement."),
            Bullet("Aliases onyxia40 and bt are also accepted."),
            "",
            H(".ip pet <family>"),
            Bullet("Displays restored Hunter pet / Warlock demon spell-rank information for supported pet families."),
            "",
            H(".ip setrep"),
            Bullet("Account reputation synchronisation helper for configured factions."),
            Priority("DISABLED", "This command is currently disabled by your server configuration.", C.red),
            "",
            SH("IMPORTANT"),
            Bullet("Slash commands such as /ip open this addon."),
            Bullet("Dot commands such as .ip pvp are server commands handled by Individual Progression."),
            Bullet("Do not use .ip set unless you intentionally want to change progression."),
        })
    end,
}

local OVERVIEW_PAGE = {
    title = "Vanilla Progression Roadmap",
    short = "The complete level-60 journey",
    icon = "Interface\\Icons\\INV_Misc_Book_09",
    body = function()
        return Join({
            SH("HOW TO READ THIS GUIDE"),
            "The addon separates three different ideas: required progression, important supporting content, and optional content that is best done while it is still relevant.",
            "",
            C.red .. "[REQUIRED]" .. C.reset .. " Advances or directly enables progression.",
            C.orange .. "[IMPORTANT]" .. C.reset .. " Does not always advance your current stage, but should normally be done.",
            C.yellow .. "[RECOMMENDED]" .. C.reset .. " Strong preparation, reputations, professions or gearing.",
            C.purple .. "[OPTIONAL - HIGH VALUE]" .. C.reset .. " Side content worth doing in its intended tier.",
            "",
            H("VANILLA TIMELINE"),
            C.gold .. "Tier 0" .. C.reset .. "       Molten Core",
            Bullet("First tracked raid milestone. Complete MC access, manual rune dousing preparation and defeat Ragnaros."),
            "",
            C.gold .. "Tier 1" .. C.reset .. "       Onyxia's Lair",
            Bullet("Unlocks after Molten Core progression is completed. Complete the Drakefire Amulet attunement and defeat Onyxia."),
            "",
            C.gold .. "Tier 2" .. C.reset .. "       Blackwing Lair",
            Bullet("Dire Maul enters the gearing route; Azuregos + Lord Kazzak become world-boss targets."),
            Bullet("Onyxia Scale Cloak becomes strategically important for Shadowflame."),
            "",
            C.gold .. "Tier 3" .. C.reset .. "       Pre-AQ",
            Bullet("Zul'Gurub, War Effort, Scarab Gong route and later-Vanilla world-boss progression."),
            "",
            C.gold .. "Tier 4" .. C.reset .. "       AQ War",
            Bullet("Gates open, AQ outdoor war active, AQ20/AQ40 available; finish Chaos and Destruction."),
            "",
            C.gold .. "Tier 5" .. C.reset .. "       Ahn'Qiraj",
            Bullet("Full post-war AQ gearing/reputation ecosystem; defeat C'Thun."),
            "",
            C.gold .. "Tier 6" .. C.reset .. "       Naxxramas",
            Bullet("Argent Dawn attunement, Naxx40, Scourge Invasion; defeat Kel'Thuzad."),
            "",
            C.gold .. "Tier 7" .. C.reset .. "       Pre-TBC",
            Bullet("Dark Portal invasion; complete Into the Breach and finish your Vanilla journey."),
            "",
            SH("IMPORTANT UNLOCKS AT A GLANCE"),
            Bullet("Dire Maul: early post-opening / Tier 2 pathway."),
            Bullet("Azuregos + Lord Kazzak: early post-opening / Tier 2 pathway."),
            Bullet("Zul'Gurub: after Blackwing Lair, during Tier 3 / Pre-AQ."),
            Bullet("Dragons of Nightmare: later Vanilla / Pre-AQ pathway."),
            Bullet("AQ20 + AQ40: Tier 4 when the gates open."),
            Bullet("Naxxramas + Scourge Invasion: Tier 6."),
            "",
            SH("CHRONOMANCER VEZRATH"),
            Bullet("Found in every capital city near that capital's faction leader."),
            Bullet("Provides eligible account progression catch-up services."),
            Bullet("Required for the 2,500g Vanilla -> TBC and 7,500g TBC -> WotLK expansion unlocks."),
            "",
            SH("SERVER-SPECIFIC RULES"),
            Bullet("Talent access is restricted by expansion even though the client uses the full 3.3.5 talent trees. See the Talent Rules tab."),
            Bullet("Characters can only group with others in the same progression phase."),
            Bullet("Dungeon Set 2 progression is available early on this server."),
            Bullet("Six Scourge Invasion dungeon bosses are available early rather than being restricted only to the Naxxramas stage."),
            Bullet("Quest object markers and sparkles are disabled, so read quest text and objectives carefully."),
            Bullet("Your current progression stage is read automatically when this window opens."),
            "",
            SH("GUIDE SECTIONS"),
            Bullet("Vanilla Side Content now contains World Bosses, Vanilla Reputations and Vanilla PvP."),
            Bullet("Use the detailed Reputations page for when to farm each major Vanilla faction, how to earn it and what rewards make it worthwhile."),
            Bullet("Use Vanilla PvP for the custom Rank 1-14 requirements, title rules and battleground reputation path."),
            Bullet("General Information is reserved for server-wide systems such as profession phasing and flight-path phasing."),
            Bullet("Use Talent Rules for the Vanilla, TBC and Wrath talent-tree limits."),
        })
    end,
}

-- ============================================================================
-- DATA MODEL / SERVER COMMUNICATION
-- ============================================================================

local data = {
    currentValue = 0,
    loaded = false,
    selectedPage = "overview",
}

local function SendCommand(cmd)
    SendChatMessage(".ipsvc " .. cmd, "SAY")
end

local function RequestData()
    SendCommand("data")
end

local UpdateDisplay
local SelectPage

local function ParseMessage(payload)
    local parts = { strsplit(DELIMITER, payload) }
    if parts[1] == "PD" then
        data.currentValue = tonumber(parts[2]) or 0
        data.loaded = true
        UpdateDisplay()
    end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg, ...)
    if msg and msg:find("^##IPSVC##") then
        return true
    end
end)

-- ============================================================================
-- UI BACKDROPS
-- ============================================================================

local BACKDROP_MAIN = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
}

local BACKDROP_INNER = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- ============================================================================
-- MAIN FRAME
-- ============================================================================

local mainFrame = CreateFrame("Frame", "IndividualProgressionFrame", UIParent)
mainFrame:SetSize(900, 720)
mainFrame:SetPoint("CENTER")
mainFrame:SetBackdrop(BACKDROP_MAIN)
mainFrame:SetBackdropColor(0.035, 0.035, 0.055, 0.98)
mainFrame:SetBackdropBorderColor(0.55, 0.45, 0.22, 1)
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
mainFrame:SetFrameStrata("DIALOG")
mainFrame:SetClampedToScreen(true)
mainFrame:Hide()

local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 22, -18)
title:SetText(C.gold .. "Individual Progression Companion" .. C.reset)

local subtitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("LEFT", title, "RIGHT", 10, -1)
subtitle:SetText("")

local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)

local refreshBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
refreshBtn:SetSize(74, 22)
refreshBtn:SetPoint("TOPRIGHT", -42, -12)
refreshBtn:SetText("Refresh")
refreshBtn:SetScript("OnClick", RequestData)

-- Header status box
local headerBox = CreateFrame("Frame", nil, mainFrame)
headerBox:SetPoint("TOPLEFT", 18, -48)
headerBox:SetPoint("TOPRIGHT", -18, -48)
headerBox:SetHeight(72)
headerBox:SetBackdrop(BACKDROP_INNER)
headerBox:SetBackdropColor(0.08, 0.08, 0.11, 0.96)
headerBox:SetBackdropBorderColor(0.38, 0.33, 0.22, 0.8)

local characterText = headerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
characterText:SetPoint("TOPLEFT", 12, -10)
characterText:SetJustifyH("LEFT")

local currentText = headerBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
currentText:SetPoint("TOPLEFT", 12, -32)
currentText:SetJustifyH("LEFT")

local objectiveText = headerBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
objectiveText:SetPoint("TOPLEFT", 12, -51)
objectiveText:SetJustifyH("LEFT")
objectiveText:SetTextColor(0.78, 0.78, 0.78)

local jumpBtn = CreateFrame("Button", nil, headerBox, "UIPanelButtonTemplate")
jumpBtn:SetSize(105, 22)
jumpBtn:SetPoint("RIGHT", -12, 0)
jumpBtn:SetText("Current Stage")

-- Sidebar
local sidebar = CreateFrame("Frame", nil, mainFrame)
sidebar:SetPoint("TOPLEFT", 18, -128)
sidebar:SetPoint("BOTTOMLEFT", 18, 18)
sidebar:SetWidth(225)
sidebar:SetBackdrop(BACKDROP_INNER)
sidebar:SetBackdropColor(0.055, 0.055, 0.075, 0.96)
sidebar:SetBackdropBorderColor(0.33, 0.3, 0.22, 0.8)

local sidebarTitle = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sidebarTitle:SetPoint("TOPLEFT", 12, -12)
sidebarTitle:SetText(C.gold .. "PROGRESSION GUIDE" .. C.reset)

local navScroll = CreateFrame("ScrollFrame", "IPGuideNavScrollFrame", sidebar, "UIPanelScrollFrameTemplate")
navScroll:SetPoint("TOPLEFT", 4, -31)
navScroll:SetPoint("BOTTOMRIGHT", -27, 34)
navScroll:EnableMouseWheel(true)

local navScrollChild = CreateFrame("Frame", nil, navScroll)
navScrollChild:SetSize(188, 900)
navScroll:SetScrollChild(navScrollChild)
navScroll:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll() or 0
    local maxScroll = self:GetVerticalScrollRange() or 0
    local nextScroll = current - (delta * 45)
    if nextScroll < 0 then nextScroll = 0 end
    if nextScroll > maxScroll then nextScroll = maxScroll end
    self:SetVerticalScroll(nextScroll)
end)

-- Content panel
local contentPanel = CreateFrame("Frame", nil, mainFrame)
contentPanel:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
contentPanel:SetPoint("BOTTOMRIGHT", -18, 18)
contentPanel:SetBackdrop(BACKDROP_INNER)
contentPanel:SetBackdropColor(0.055, 0.055, 0.07, 0.96)
contentPanel:SetBackdropBorderColor(0.33, 0.3, 0.22, 0.8)

local headerArt = contentPanel:CreateTexture(nil, "BACKGROUND")
headerArt:SetPoint("TOPLEFT", 8, -7)
headerArt:SetPoint("TOPRIGHT", -8, -7)
headerArt:SetHeight(68)
headerArt:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
headerArt:SetTexCoord(0, 1, 0, 0.52)
headerArt:SetAlpha(0.18)

local pageIcon = contentPanel:CreateTexture(nil, "ARTWORK")
pageIcon:SetSize(48, 48)
pageIcon:SetPoint("TOPLEFT", 18, -12)
pageIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local pageTitle = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
pageTitle:SetPoint("TOPLEFT", 78, -14)
pageTitle:SetPoint("TOPRIGHT", -16, -14)
pageTitle:SetJustifyH("LEFT")

local pageSub = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
pageSub:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 0, -4)
pageSub:SetJustifyH("LEFT")
pageSub:SetTextColor(0.65, 0.65, 0.65)

local divider = contentPanel:CreateTexture(nil, "ARTWORK")
divider:SetPoint("TOPLEFT", 14, -72)
divider:SetPoint("TOPRIGHT", -14, -72)
divider:SetHeight(1)
divider:SetTexture(1, 0.82, 0, 0.22)

local scrollFrame = CreateFrame("ScrollFrame", "IPGuideScrollFrame", contentPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 14, -82)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 31)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(1, 1)
scrollFrame:SetScrollChild(scrollChild)

local bodyText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bodyText:SetPoint("TOPLEFT", 2, -2)
bodyText:SetJustifyH("LEFT")
bodyText:SetJustifyV("TOP")
bodyText:SetWordWrap(true)
bodyText:SetNonSpaceWrap(true)
bodyText:SetSpacing(3)

-- Long guide pages can exceed the reliable height of a single FontString on the
-- 3.3.5 client. Keep several smaller FontStrings stacked vertically instead.
local bodyTextBlocks = { bodyText }

local function ConfigureBodyBlock(fs)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetNonSpaceWrap(true)
    fs:SetSpacing(3)
end

local function SplitBodyText(text)
    local chunks = {}
    local lines = {}
    local chars = 0
    local maxLines = 18
    local maxChars = 1800

    for line in string.gmatch((text or "") .. "\n", "(.-)\n") do
        local add = string.len(line) + 1
        if table.getn(lines) > 0 and (table.getn(lines) >= maxLines or chars + add > maxChars) then
            table.insert(chunks, table.concat(lines, "\n"))
            lines = {}
            chars = 0
        end
        table.insert(lines, line)
        chars = chars + add
    end

    if table.getn(lines) > 0 then
        table.insert(chunks, table.concat(lines, "\n"))
    end

    if table.getn(chunks) == 0 then
        table.insert(chunks, "")
    end

    return chunks
end

local footerNote = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
footerNote:SetPoint("BOTTOMLEFT", 16, 10)
footerNote:SetPoint("BOTTOMRIGHT", -16, 10)
footerNote:SetJustifyH("LEFT")
footerNote:SetText(C.dark .. "Server progression companion - Vanilla, TBC and Wrath progression, attunements, side content and server rules in one guide." .. C.reset)

-- ============================================================================
-- NAVIGATION
-- ============================================================================

local navButtons = {}
local vanillaStageOrder = { "mc", "onyxia", "bwl", "preaq", "aqwar", "aq", "naxx", "pretbc" }
local tbcStageOrder = { "tbc8", "tbc9", "tbc10", "tbc12" }
local wrathStageOrder = { "wrath13", "wrath14", "wrath15", "wrath16", "wrath17" }

local function CreateNavButton(id, label, y)
    local btn = CreateFrame("Button", nil, navScrollChild)
    btn:SetSize(178, 28)
    btn:SetPoint("TOPLEFT", 10, y)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(1, 1, 1, 0.025)
    btn.bg = bg

    local navIcon = btn:CreateTexture(nil, "ARTWORK")
    navIcon:SetSize(20, 20)
    navIcon:SetPoint("LEFT", 5, 0)
    navIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if id == "overview" then
        navIcon:SetTexture(OVERVIEW_PAGE.icon)
    elseif id == "tbcoverview" then
        navIcon:SetTexture(TBC_OVERVIEW_PAGE.icon)
    elseif id == "tbcdungeons" then
        navIcon:SetTexture(TBC_DUNGEONS_PAGE.icon)
    elseif id == "tbcreputations" then
        navIcon:SetTexture(TBC_REPUTATIONS_PAGE.icon)
    elseif id == "tbcprofessions" then
        navIcon:SetTexture(TBC_PROFESSIONS_PAGE.icon)
    elseif id == "tbcpvp" then
        navIcon:SetTexture(TBC_PVP_PAGE.icon)
    elseif id == "tbcworldbosses" then
        navIcon:SetTexture(TBC_WORLD_BOSS_PAGE.icon)
    elseif id == "zulaman" then
        navIcon:SetTexture(ZULAMAN_PAGE.icon)
    elseif id == "wrathoverview" then
        navIcon:SetTexture(WOTLK_OVERVIEW_PAGE.icon)
    elseif id == "wrathdungeons" then
        navIcon:SetTexture(WOTLK_DUNGEONS_PAGE.icon)
    elseif id == "wrathemblems" then
        navIcon:SetTexture(WOTLK_EMBLEMS_PAGE.icon)
    elseif id == "wrathreputations" then
        navIcon:SetTexture(WOTLK_REPUTATIONS_PAGE.icon)
    elseif id == "wrathprofessions" then
        navIcon:SetTexture(WOTLK_PROFESSIONS_PAGE.icon)
    elseif id == "wrathpvp" then
        navIcon:SetTexture(WOTLK_PVP_PAGE.icon)
    elseif id == "wintergrasp" then
        navIcon:SetTexture(WINTERGRASP_PAGE.icon)
    elseif id == "argenttournament" then
        navIcon:SetTexture(ARGENT_TOURNAMENT_PAGE.icon)
    elseif id == "worldbosses" then
        navIcon:SetTexture(WORLD_BOSS_PAGE.icon)
    elseif id == "general" then
        navIcon:SetTexture(GENERAL_PAGE.icon)
    elseif id == "talents" then
        navIcon:SetTexture(TALENT_RULES_PAGE.icon)
    elseif id == "reputations" then
        navIcon:SetTexture(REPUTATIONS_PAGE.icon)
    elseif id == "pvp" then
        navIcon:SetTexture(PVP_PAGE.icon)
    elseif id == "vezrath" then
        navIcon:SetTexture(CHARACTER_SERVICES_PAGE.icon)
    elseif id == "commands" then
        navIcon:SetTexture(COMMANDS_PAGE.icon)
    elseif VANILLA_STAGES[id] then
        navIcon:SetTexture(VANILLA_STAGES[id].icon)
    elseif TBC_STAGES[id] then
        navIcon:SetTexture(TBC_STAGES[id].icon)
    elseif WOTLK_STAGES[id] then
        navIcon:SetTexture(WOTLK_STAGES[id].icon)
    end
    btn.icon = navIcon

    local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mark:SetPoint("LEFT", 28, 0)
    mark:SetWidth(31)
    mark:SetJustifyH("CENTER")
    btn.mark = mark

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", 61, 0)
    txt:SetPoint("RIGHT", -5, 0)
    txt:SetJustifyH("LEFT")
    txt:SetText(label)
    btn.text = txt

    btn:SetScript("OnEnter", function(self)
        if data.selectedPage ~= id then
            self.bg:SetTexture(1, 0.82, 0, 0.07)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if data.selectedPage ~= id then
            self.bg:SetTexture(1, 1, 1, 0.025)
        end
    end)
    btn:SetScript("OnClick", function() SelectPage(id) end)

    navButtons[id] = btn
    return btn
end

local navY = -2
local vanillaHeader = navScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
vanillaHeader:SetPoint("TOPLEFT", 8, navY)
vanillaHeader:SetText(C.gold .. "VANILLA" .. C.reset)
navY = navY - 22
CreateNavButton("overview", "Overview / Roadmap", navY)
navY = navY - 29
for _, id in ipairs(vanillaStageOrder) do
    CreateNavButton(id, VANILLA_STAGES[id].nav, navY)
    navY = navY - 29
end

local worldHeader = navScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
worldHeader:SetPoint("TOPLEFT", 8, navY - 2)
worldHeader:SetText(C.gold .. "VANILLA SIDE CONTENT" .. C.reset)
navY = navY - 24
CreateNavButton("worldbosses", "World Boss Timeline", navY)
navY = navY - 29
CreateNavButton("reputations", "Vanilla Reputations", navY)
navY = navY - 29
CreateNavButton("pvp", "Vanilla PvP", navY)
navY = navY - 36

local tbcHeader = navScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
tbcHeader:SetPoint("TOPLEFT", 8, navY - 2)
tbcHeader:SetText(C.green .. "THE BURNING CRUSADE" .. C.reset)
navY = navY - 24
CreateNavButton("tbcoverview", "TBC Overview / Roadmap", navY)
navY = navY - 29
for _, id in ipairs(tbcStageOrder) do
    CreateNavButton(id, TBC_STAGES[id].nav, navY)
    navY = navY - 29
end

local tbcSideHeader = navScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
tbcSideHeader:SetPoint("TOPLEFT", 8, navY - 2)
tbcSideHeader:SetText(C.green .. "TBC SUPPORT / SIDE CONTENT" .. C.reset)
navY = navY - 24
CreateNavButton("tbcdungeons", "Dungeons & Heroic Keys", navY)
navY = navY - 29
CreateNavButton("tbcreputations", "TBC Reputations", navY)
navY = navY - 29
CreateNavButton("tbcprofessions", "TBC Professions", navY)
navY = navY - 29
CreateNavButton("tbcpvp", "TBC PvP", navY)
navY = navY - 29
CreateNavButton("tbcworldbosses", "TBC World Bosses", navY)
navY = navY - 29
CreateNavButton("zulaman", "Zul'Aman", navY)
navY = navY - 36

local wrathHeader = navScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
wrathHeader:SetPoint("TOPLEFT", 8, navY - 2)
wrathHeader:SetText(C.blue .. "WRATH OF THE LICH KING" .. C.reset)
navY = navY - 24
CreateNavButton("wrathoverview", "Wrath Overview / Roadmap", navY)
navY = navY - 29
for _, id in ipairs(wrathStageOrder) do
    CreateNavButton(id, WOTLK_STAGES[id].nav, navY)
    navY = navY - 29
end

local wrathSideHeader = navScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
wrathSideHeader:SetPoint("TOPLEFT", 8, navY - 2)
wrathSideHeader:SetText(C.blue .. "WRATH SUPPORT / SIDE CONTENT" .. C.reset)
navY = navY - 24
CreateNavButton("wrathdungeons", "Dungeons & Heroics", navY)
navY = navY - 29
CreateNavButton("wrathemblems", "Emblems & Dalaran Quests", navY)
navY = navY - 29
CreateNavButton("wrathreputations", "Wrath Reputations", navY)
navY = navY - 29
CreateNavButton("wrathprofessions", "Wrath Professions", navY)
navY = navY - 29
CreateNavButton("wrathpvp", "Wrath PvP", navY)
navY = navY - 29
CreateNavButton("wintergrasp", "Wintergrasp & Vault", navY)
navY = navY - 29
CreateNavButton("argenttournament", "Argent Tournament", navY)
navY = navY - 36

local generalHeader = navScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
generalHeader:SetPoint("TOPLEFT", 8, navY - 2)
generalHeader:SetText(C.gold .. "GENERAL" .. C.reset)
navY = navY - 24
CreateNavButton("general", "General Information", navY)
navY = navY - 29
CreateNavButton("talents", "Talent Rules", navY)
navY = navY - 29
CreateNavButton("vezrath", "Chronomancer Vezrath", navY)
navY = navY - 29
CreateNavButton("commands", "Commands / Help", navY)
navY = navY - 34
navScrollChild:SetHeight(math.max(900, -navY + 10))

local legend = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
legend:SetPoint("BOTTOMLEFT", 12, 10)
legend:SetJustifyH("LEFT")
legend:SetText(C.green .. "DONE" .. C.reset .. "   " .. C.gold .. "NOW" .. C.reset .. "   " .. C.dark .. "LOCKED" .. C.reset)

-- ============================================================================
-- PAGE / STATUS LOGIC
-- ============================================================================

local function GetCurrentStageId(cv)
    if cv == 0 then return "mc" end
    if cv == 1 then return "onyxia" end
    if cv == 2 then return "bwl" end
    if cv == 3 then return "preaq" end
    if cv == 4 then return "aqwar" end
    if cv == 5 then return "aq" end
    if cv == 6 then return "naxx" end
    if cv == 7 then return "pretbc" end
    if cv == 8 then return "tbc8" end
    if cv == 9 then return "tbc9" end
    if cv == 10 or cv == 11 then return "tbc10" end
    if cv == 12 then return "tbc12" end
    if cv == 13 then return "wrath13" end
    if cv == 14 then return "wrath14" end
    if cv == 15 then return "wrath15" end
    if cv == 16 then return "wrath16" end
    if cv == 17 then return "wrath17" end
    return nil
end

local function GetStageTable(id)
    return VANILLA_STAGES[id] or TBC_STAGES[id] or WOTLK_STAGES[id]
end

local function GetStageState(id, cv)
    local stage = GetStageTable(id)
    if not stage then return "guide" end
    if cv >= stage.completeAt then return "done" end
    local current = GetCurrentStageId(cv)
    if current == id then return "current" end
    if cv < stage.minValue then return "locked" end
    return "available"
end

local function UpdateNavStates()
    for id, btn in pairs(navButtons) do
        if data.selectedPage == id then
            btn.bg:SetTexture(1, 0.82, 0, 0.13)
        else
            btn.bg:SetTexture(1, 1, 1, 0.025)
        end

        if id == "overview" or id == "worldbosses" or id == "tbcoverview" or id == "tbcdungeons" or id == "tbcreputations" or id == "tbcprofessions" or id == "tbcpvp" or id == "tbcworldbosses" or id == "zulaman" or id == "wrathoverview" or id == "wrathdungeons" or id == "wrathemblems" or id == "wrathreputations" or id == "wrathprofessions" or id == "wrathpvp" or id == "wintergrasp" or id == "argenttournament" or id == "general" or id == "talents" or id == "reputations" or id == "pvp" or id == "vezrath" or id == "commands" then
            btn.mark:SetText(C.blue .. "i" .. C.reset)
            btn.text:SetTextColor(0.92, 0.92, 0.92)
        else
            local state = GetStageState(id, data.currentValue)
            if state == "done" then
                btn.mark:SetText(C.green .. "OK" .. C.reset)
                btn.text:SetTextColor(0.45, 0.85, 0.45)
            elseif state == "current" then
                btn.mark:SetText(C.gold .. ">>" .. C.reset)
                btn.text:SetTextColor(1.0, 0.82, 0.0)
            elseif state == "available" then
                btn.mark:SetText(C.yellow .. "--" .. C.reset)
                btn.text:SetTextColor(0.9, 0.8, 0.45)
            else
                btn.mark:SetText(C.dark .. "--" .. C.reset)
                btn.text:SetTextColor(0.36, 0.36, 0.36)
            end
        end
    end
end

local function SetPageContent(titleText, subText, text, iconTexture)
    pageTitle:SetText(C.gold .. titleText .. C.reset)
    pageSub:SetText(subText or "")
    pageIcon:SetTexture(iconTexture or "Interface\\Icons\\INV_Misc_Book_09")

    local width = scrollFrame:GetWidth() - 8
    if width < 400 then width = 560 end

    local chunks = SplitBodyText(text or "")
    local yOffset = 2

    for i = 1, table.getn(chunks) do
        local fs = bodyTextBlocks[i]
        if not fs then
            fs = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            ConfigureBodyBlock(fs)
            bodyTextBlocks[i] = fs
        end

        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 2, -yOffset)
        fs:SetWidth(width)
        fs:SetText(chunks[i])
        fs:Show()

        local blockHeight = fs:GetStringHeight() or 0
        if blockHeight < 1 then blockHeight = 16 end
        yOffset = yOffset + blockHeight + 6
    end

    for i = table.getn(chunks) + 1, table.getn(bodyTextBlocks) do
        bodyTextBlocks[i]:SetText("")
        bodyTextBlocks[i]:Hide()
    end

    scrollChild:SetSize(width, yOffset + 16)
    scrollFrame:SetVerticalScroll(0)
end

SelectPage = function(id)
    data.selectedPage = id or "overview"
    IndividualProgressionDB = IndividualProgressionDB or {}
    IndividualProgressionDB.lastPage = data.selectedPage

    if data.selectedPage == "overview" then
        SetPageContent(OVERVIEW_PAGE.title, OVERVIEW_PAGE.short, OVERVIEW_PAGE.body(), OVERVIEW_PAGE.icon)
    elseif data.selectedPage == "tbcoverview" then
        SetPageContent(TBC_OVERVIEW_PAGE.title, TBC_OVERVIEW_PAGE.short, TBC_OVERVIEW_PAGE.body(), TBC_OVERVIEW_PAGE.icon)
    elseif data.selectedPage == "tbcdungeons" then
        SetPageContent(TBC_DUNGEONS_PAGE.title, TBC_DUNGEONS_PAGE.short, TBC_DUNGEONS_PAGE.body(), TBC_DUNGEONS_PAGE.icon)
    elseif data.selectedPage == "tbcreputations" then
        SetPageContent(TBC_REPUTATIONS_PAGE.title, TBC_REPUTATIONS_PAGE.short, TBC_REPUTATIONS_PAGE.body(), TBC_REPUTATIONS_PAGE.icon)
    elseif data.selectedPage == "tbcprofessions" then
        SetPageContent(TBC_PROFESSIONS_PAGE.title, TBC_PROFESSIONS_PAGE.short, TBC_PROFESSIONS_PAGE.body(), TBC_PROFESSIONS_PAGE.icon)
    elseif data.selectedPage == "tbcpvp" then
        SetPageContent(TBC_PVP_PAGE.title, TBC_PVP_PAGE.short, TBC_PVP_PAGE.body(), TBC_PVP_PAGE.icon)
    elseif data.selectedPage == "tbcworldbosses" then
        SetPageContent(TBC_WORLD_BOSS_PAGE.title, TBC_WORLD_BOSS_PAGE.short, TBC_WORLD_BOSS_PAGE.body(), TBC_WORLD_BOSS_PAGE.icon)
    elseif data.selectedPage == "zulaman" then
        SetPageContent(ZULAMAN_PAGE.title, ZULAMAN_PAGE.short, ZULAMAN_PAGE.body(), ZULAMAN_PAGE.icon)
    elseif data.selectedPage == "wrathoverview" then
        SetPageContent(WOTLK_OVERVIEW_PAGE.title, WOTLK_OVERVIEW_PAGE.short, WOTLK_OVERVIEW_PAGE.body(), WOTLK_OVERVIEW_PAGE.icon)
    elseif data.selectedPage == "wrathdungeons" then
        SetPageContent(WOTLK_DUNGEONS_PAGE.title, WOTLK_DUNGEONS_PAGE.short, WOTLK_DUNGEONS_PAGE.body(), WOTLK_DUNGEONS_PAGE.icon)
    elseif data.selectedPage == "wrathemblems" then
        SetPageContent(WOTLK_EMBLEMS_PAGE.title, WOTLK_EMBLEMS_PAGE.short, WOTLK_EMBLEMS_PAGE.body(), WOTLK_EMBLEMS_PAGE.icon)
    elseif data.selectedPage == "wrathreputations" then
        SetPageContent(WOTLK_REPUTATIONS_PAGE.title, WOTLK_REPUTATIONS_PAGE.short, WOTLK_REPUTATIONS_PAGE.body(), WOTLK_REPUTATIONS_PAGE.icon)
    elseif data.selectedPage == "wrathprofessions" then
        SetPageContent(WOTLK_PROFESSIONS_PAGE.title, WOTLK_PROFESSIONS_PAGE.short, WOTLK_PROFESSIONS_PAGE.body(), WOTLK_PROFESSIONS_PAGE.icon)
    elseif data.selectedPage == "wrathpvp" then
        SetPageContent(WOTLK_PVP_PAGE.title, WOTLK_PVP_PAGE.short, WOTLK_PVP_PAGE.body(), WOTLK_PVP_PAGE.icon)
    elseif data.selectedPage == "wintergrasp" then
        SetPageContent(WINTERGRASP_PAGE.title, WINTERGRASP_PAGE.short, WINTERGRASP_PAGE.body(), WINTERGRASP_PAGE.icon)
    elseif data.selectedPage == "argenttournament" then
        SetPageContent(ARGENT_TOURNAMENT_PAGE.title, ARGENT_TOURNAMENT_PAGE.short, ARGENT_TOURNAMENT_PAGE.body(), ARGENT_TOURNAMENT_PAGE.icon)
    elseif data.selectedPage == "worldbosses" then
        SetPageContent(WORLD_BOSS_PAGE.title, WORLD_BOSS_PAGE.short, WORLD_BOSS_PAGE.body(), WORLD_BOSS_PAGE.icon)
    elseif data.selectedPage == "general" then
        SetPageContent(GENERAL_PAGE.title, GENERAL_PAGE.short, GENERAL_PAGE.body(), GENERAL_PAGE.icon)
    elseif data.selectedPage == "talents" then
        SetPageContent(TALENT_RULES_PAGE.title, TALENT_RULES_PAGE.short, TALENT_RULES_PAGE.body(), TALENT_RULES_PAGE.icon)
    elseif data.selectedPage == "reputations" then
        SetPageContent(REPUTATIONS_PAGE.title, REPUTATIONS_PAGE.short, REPUTATIONS_PAGE.body(), REPUTATIONS_PAGE.icon)
    elseif data.selectedPage == "pvp" then
        SetPageContent(PVP_PAGE.title, PVP_PAGE.short, PVP_PAGE.body(), PVP_PAGE.icon)
    elseif data.selectedPage == "vezrath" or data.selectedPage == "services" then
        data.selectedPage = "vezrath"
        SetPageContent(CHARACTER_SERVICES_PAGE.title, CHARACTER_SERVICES_PAGE.short, CHARACTER_SERVICES_PAGE.body(), CHARACTER_SERVICES_PAGE.icon)
    elseif data.selectedPage == "commands" then
        SetPageContent(COMMANDS_PAGE.title, COMMANDS_PAGE.short, COMMANDS_PAGE.body(), COMMANDS_PAGE.icon)
    else
        local stage = GetStageTable(data.selectedPage)
        if stage then
            local state = GetStageState(data.selectedPage, data.currentValue)
            local stateText
            if state == "done" then
                stateText = C.green .. "Completed" .. C.reset
            elseif state == "current" then
                stateText = C.gold .. "CURRENT STAGE" .. C.reset
            elseif state == "locked" then
                stateText = C.dark .. "Locked / Future" .. C.reset
            else
                stateText = C.yellow .. "Available" .. C.reset
            end
            SetPageContent(stage.title, stateText .. "   |   Goal: " .. stage.objective, stage.body(), stage.icon)
        else
            data.selectedPage = "overview"
            SetPageContent(OVERVIEW_PAGE.title, OVERVIEW_PAGE.short, OVERVIEW_PAGE.body(), OVERVIEW_PAGE.icon)
        end
    end

    UpdateNavStates()
end

UpdateDisplay = function()
    local name = UnitName("player") or "Player"
    local className, classToken = UnitClass("player")
    local level = UnitLevel("player") or 0

    local classColor = RAID_CLASS_COLORS and classToken and RAID_CLASS_COLORS[classToken]
    if classColor then
        characterText:SetText(string.format("%s%s|r   %s%s|r   %sLevel %d|r", classColor.colorStr and "|c" .. classColor.colorStr or C.white, name, C.grey, className or "", C.grey, level))
    else
        characterText:SetText(C.white .. name .. C.reset .. "   " .. C.grey .. (className or "") .. "   Level " .. level .. C.reset)
    end

    if not data.loaded then
        currentText:SetText(C.grey .. "Reading progression from server..." .. C.reset)
        objectiveText:SetText("")
        UpdateNavStates()
        return
    end

    local currentId = GetCurrentStageId(data.currentValue)
    if currentId then
        local stage = GetStageTable(currentId)
        local eraLabel
        local eraColor
        if data.currentValue >= 13 then
            eraLabel = "Current Wrath Stage: "
            eraColor = C.blue
        elseif data.currentValue >= 8 then
            eraLabel = "Current TBC Stage: "
            eraColor = C.green
        else
            eraLabel = "Current Vanilla Stage: "
            eraColor = C.blue
        end
        currentText:SetText(eraColor .. eraLabel .. C.reset .. C.gold .. stage.title .. C.reset)
        objectiveText:SetText("Next progression goal: " .. stage.objective)
    elseif data.currentValue >= 18 then
        currentText:SetText(C.blue .. "Wrath of the Lich King progression complete." .. C.reset .. "  " .. C.grey .. "Halion defeated - full progression journey complete." .. C.reset)
        objectiveText:SetText("Review optional hard modes, achievements, reputations, professions and collection goals as desired.")
    else
        currentText:SetText(C.grey .. "Progression state unavailable." .. C.reset)
        objectiveText:SetText("")
    end

    UpdateNavStates()
    SelectPage(data.selectedPage)
end

jumpBtn:SetScript("OnClick", function()
    local id = GetCurrentStageId(data.currentValue)
    if id then
        SelectPage(id)
    elseif data.currentValue >= 18 then
        SelectPage("wrathoverview")
    else
        SelectPage("overview")
    end
end)

-- ============================================================================
-- EVENTS
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:SetScript("OnEvent", function(self, event, msg)
    if event == "CHAT_MSG_SYSTEM" and msg and msg:find("^" .. MSG_PREFIX) then
        ParseMessage(msg:sub(#MSG_PREFIX + 1))
    end
end)

mainFrame:SetScript("OnShow", function()
    data.loaded = false
    IndividualProgressionDB = IndividualProgressionDB or {}
    data.selectedPage = IndividualProgressionDB.lastPage or "overview"
    UpdateDisplay()
    RequestData()
end)

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

SLASH_INDIVIDUALPROGRESSION1 = "/progression"
SLASH_INDIVIDUALPROGRESSION2 = "/ip"

SlashCmdList["INDIVIDUALPROGRESSION"] = function(msg)
    msg = strtrim((msg or ""):lower())

    if msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage(C.gold .. "Individual Progression" .. C.reset .. " commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip              - Toggle the progression guide")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip current      - Open your current progression stage")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip tbc          - Open the TBC overview")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip tbcdungeons  - Open TBC dungeon / heroic-key guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip tbcreps      - Open TBC reputation guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip tbcprofessions - Open TBC profession guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip tbcpvp       - Open TBC PvP / Arena Season guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip tbcworldbosses - Open TBC world-boss guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip zulaman      - Open Zul'Aman guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip wrath         - Open the Wrath overview")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip wrathdungeons - Open Wrath dungeon / Heroic guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip wrathemblems  - Open Wrath emblem / Dalaran quest guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip wrathreps     - Open Wrath reputation guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip wrathprofessions - Open Wrath profession guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip wrathpvp      - Open Wrath PvP / Arena Season 5 guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip wintergrasp   - Open Wintergrasp / Vault guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip tournament    - Open Argent Tournament guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip worldbosses  - Open the Vanilla world-boss timeline")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip general      - Open general server information")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip talents      - Open expansion talent rules")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip reputations  - Open Vanilla reputation guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip pvp          - Open Vanilla PvP guidance")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip services     - Open Chronomancer Vezrath services")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip vezrath      - Open Chronomancer Vezrath services")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip commands     - Open the addon command reference")
        DEFAULT_CHAT_FRAME:AddMessage("  /ip refresh      - Refresh progression from the server")
        return
    elseif msg == "current" then
        mainFrame:Show()
        local id = GetCurrentStageId(data.currentValue)
        if id then
            SelectPage(id)
        elseif data.currentValue >= 18 then
            SelectPage("wrathoverview")
        else
            SelectPage("overview")
        end
        return
    elseif msg == "tbc" or msg == "outland" then
        mainFrame:Show()
        SelectPage("tbcoverview")
        return
    elseif msg == "tbcdungeons" or msg == "heroics" or msg == "heroickeys" then
        mainFrame:Show()
        SelectPage("tbcdungeons")
        return
    elseif msg == "tbcreps" or msg == "tbcreputations" then
        mainFrame:Show()
        SelectPage("tbcreputations")
        return
    elseif msg == "tbcprofessions" or msg == "tbcprof" or msg == "tbcprofs" then
        mainFrame:Show()
        SelectPage("tbcprofessions")
        return
    elseif msg == "tbcpvp" or msg == "tbcarena" then
        mainFrame:Show()
        SelectPage("tbcpvp")
        return
    elseif msg == "tbcworldbosses" or msg == "tbcbosses" then
        mainFrame:Show()
        SelectPage("tbcworldbosses")
        return
    elseif msg == "zulaman" or msg == "za" then
        mainFrame:Show()
        SelectPage("zulaman")
        return
    elseif msg == "wrath" or msg == "wotlk" or msg == "northrend" then
        mainFrame:Show()
        SelectPage("wrathoverview")
        return
    elseif msg == "wrathdungeons" or msg == "wrathheroics" then
        mainFrame:Show()
        SelectPage("wrathdungeons")
        return
    elseif msg == "wrathemblems" or msg == "emblems" then
        mainFrame:Show()
        SelectPage("wrathemblems")
        return
    elseif msg == "wrathreps" or msg == "wrathreputations" then
        mainFrame:Show()
        SelectPage("wrathreputations")
        return
    elseif msg == "wrathprofessions" or msg == "wrathprof" or msg == "wrathprofs" then
        mainFrame:Show()
        SelectPage("wrathprofessions")
        return
    elseif msg == "wrathpvp" or msg == "wratharena" then
        mainFrame:Show()
        SelectPage("wrathpvp")
        return
    elseif msg == "wintergrasp" or msg == "wg" or msg == "vault" then
        mainFrame:Show()
        SelectPage("wintergrasp")
        return
    elseif msg == "tournament" or msg == "argenttournament" then
        mainFrame:Show()
        SelectPage("argenttournament")
        return
    elseif msg == "worldbosses" or msg == "bosses" then
        mainFrame:Show()
        SelectPage("worldbosses")
        return
    elseif msg == "general" or msg == "info" then
        mainFrame:Show()
        SelectPage("general")
        return
    elseif msg == "talents" or msg == "talent" then
        mainFrame:Show()
        SelectPage("talents")
        return
    elseif msg == "reputations" or msg == "reputation" or msg == "reps" then
        mainFrame:Show()
        SelectPage("reputations")
        return
    elseif msg == "pvp" or msg == "pvpguide" then
        mainFrame:Show()
        SelectPage("pvp")
        return
    elseif msg == "services" or msg == "vezrath" then
        mainFrame:Show()
        SelectPage("vezrath")
        return
    elseif msg == "commands" or msg == "command" then
        mainFrame:Show()
        SelectPage("commands")
        return
    elseif msg == "refresh" then
        if not mainFrame:IsShown() then mainFrame:Show() end
        RequestData()
        return
    end

    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

-- ============================================================================
-- MINIMAP BUTTON (preserved from original addon)
-- ============================================================================

local minimapBtn = CreateFrame("Button", "IPAddonMinimapButton", Minimap)
minimapBtn:SetSize(33, 33)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local minimapOverlay = minimapBtn:CreateTexture(nil, "OVERLAY")
minimapOverlay:SetSize(53, 53)
minimapOverlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapOverlay:SetPoint("TOPLEFT")

local minimapIcon = minimapBtn:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetSize(21, 21)
minimapIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
minimapIcon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 1)

IndividualProgressionDB = IndividualProgressionDB or { minimapAngle = 190 }
if IndividualProgressionDB.minimapAngle == nil then
    IndividualProgressionDB.minimapAngle = 190
end

local function UpdateMinimapPosition()
    local angle = math.rad(IndividualProgressionDB.minimapAngle or 190)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        IndividualProgressionDB.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
        UpdateMinimapPosition()
    end)
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

minimapBtn:SetScript("OnClick", function()
    if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(C.gold .. "Individual Progression" .. C.reset)
    GameTooltip:AddLine("Click to toggle the progression guide.", 1, 1, 1)
    GameTooltip:AddLine("Drag to reposition this button.", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("/ip help for commands.", 0.55, 0.8, 1)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    UpdateMinimapPosition()
end)

DEFAULT_CHAT_FRAME:AddMessage(C.gold .. "Individual Progression" .. C.reset .. " Server Companion loaded. Type " .. C.green .. "/ip" .. C.reset .. " to open.")
