# N Addon Collection

**WoW 3.3.5a (client build 12340; Interface 30300)** addons for the Naxxramas AzerothCore server.

**The collection is a normal release.** Some individual addons may still be works in progress. In particular, **N Loot Ledger v0.1.0.27 is WIP, not fully complete, and its real Master Loot awarding remains subject to further server testing.** Its inclusion does not mean that every Loot Ledger feature is production-ready.

This is a **curated, manually approved collection**. Development remains in each original repository. Changes do not appear here until the collection owner reviews and merges an import pull request.
## N Addon Suite v2 — under development

**The current public v1.0.0 release remains unchanged.** The v2 development branch adds an ElvUI-inspired central settings addon called `NCore` and switches the installer to **six folders total:** `NCore`, `IndividualProgressionAddon`, `DungeonJournal`, `MultiBot`, `NaxxLootLottery`, and `NTalentCalculator`.

**N Classic Battlegrounds is mandatory within NCore**, not an independently switchable module. It is still maintained in its own source repository but embedded into NCore during approved collection packaging. Its previous standalone folder must be removed before using the v2 suite (both versions would register overlapping PvP hooks).

**Five other addons are optional**, including the new server-aware **N Talent Calculator**. Players can enable or disable them using `/nsuite` or `/nsettings` and then click **Reload UI**. WoW 3.3.5a cannot reliably unload Lua modules that are already running. Each optional addon preserves its original folder name, `.toc` file, SavedVariables and commands.

**Silent old-addon check:** On login, NCore checks registered addon folder names and versions. It stays quiet on clean installations and only opens a warning for known duplicate/renamed addons or versions older than the suite's approved source snapshots. It never removes files or changes SavedVariables; players are asked to close WoW and delete outdated/duplicate addon folders (reinstalling the current module from the suite when appropriate). For manual checks use `/nsuite check`; use `/nsuite check demo` for a safe, clearly labelled example warning. WoW Lua cannot inspect arbitrary folders that the client has not registered as addons.

The experimental [standalone N Talent Calculator](https://github.com/CosmicCuddle/N-Talent-Calculator-) (`NTalentCalculator`) is maintained in its own repository. The collection pins a reviewed source commit instead of duplicating its Lua files. It reuses the approved Resource Hub's custom 830-talent DBC snapshot, checks Individual Progression era, hides the Vanilla/TBC final-row side talents and later rows, and shares **NT1 codes** with the website. Type `/ntalent` to open it, `/ntalent code` to select a code for Ctrl+C, or `/ntalent import NT1:...` to load one. Its additional implementation and test plan is in [N Talent Calculator Roadmap](docs/N-TALENT-CALCULATOR-ROADMAP.md).

This is a **test-only alpha design** pending real WoW gameplay verification. Follow the [v2 backup, testing and rollback instructions](docs/SUITE-V2-TEST-PLAN.md) before installing a test artifact. The original addon repositories are not modified, and v1.0.0 continues to be the stable public download.


## Included addons

| Installed folder | Addon | Original development repository | Notes |
| --- | --- | --- | --- |
| `IndividualProgressionAddon` | Individual Progression Companion | [Individual-Progression-Companion](https://github.com/CosmicCuddle/Individual-Progression-Companion) | Server-specific Vanilla, TBC and WotLK progression guidance. |
| `DungeonJournal` | Dungeon Journal | [N-Dungeon-Journal](https://github.com/CosmicCuddle/N-Dungeon-Journal) | Dungeon and raid handbook; Vanilla content is the primary completed section. |
| `MultiBot` | MultiBot Chatless (Naxxramas fork) | [N-MultiBot-Chatless](https://github.com/CosmicCuddle/N-MultiBot-Chatless) | Playerbot UI; bridge and certain Naxxramas server features require matching server modules. |
| `NaxxLootLottery` | Naxxramas Loot Ledger | [N-Loot-Ledger](https://github.com/CosmicCuddle/N-Loot-Ledger) | Raid loot planning and lottery; still under development and testing. |
| `NClassicBattlegrounds` | N Classic Battlegrounds | [N-ClassicBattlegrounds](https://github.com/CosmicCuddle/N-ClassicBattlegrounds) | Expansion-aware PvP UI for Individual Progression; **v1.0.0** released; progression transition and server-side queue enforcement tests remain outstanding. |

**Not included:** the personal projects AutoWhisperReply and AutoHideMinimap.

## Download and install

**Latest collection release: [v1.0.0](https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v1.0.0)** — contains the five addon folders directly at the ZIP root. The earlier `v1.0.0-rc.1` pre-release remains available in [release history](https://github.com/CosmicCuddle/N-Addon-Collection/releases) for comparison and rollback.

1. Exit World of Warcraft.
2. **Back up** any existing addon folders under `World of Warcraft/Interface/AddOns/` and the corresponding `WTF` SavedVariables files.
3. Extract the collection ZIP **into** `World of Warcraft/Interface/AddOns/`.
4. Verify these paths exist:
   - `Interface/AddOns/IndividualProgressionAddon/IndividualProgressionAddon.toc`
   - `Interface/AddOns/DungeonJournal/DungeonJournal.toc`
   - `Interface/AddOns/MultiBot/MultiBot.toc`
   - `Interface/AddOns/NaxxLootLottery/NaxxLootLottery.toc`
   - `Interface/AddOns/NClassicBattlegrounds/NClassicBattlegrounds.toc`
5. Start WoW 3.3.5a and enable the addons you want at character selection.

Do **not** install an extra `N-Addon-Collection` folder around the five addons. For individual addon downloads, use the links to the original repositories above.

## How updates are approved

1. Finish developing and testing in the **original addon repository**.
2. Run **Actions → Stage approved addon update** in this repository. Choose one addon or `all`; optionally enter a particular source commit/tag for a single addon.
3. Review the generated pull request and exact source commit hashes recorded in [`sources.lock.json`](sources.lock.json).
4. Merge only when satisfied. Nothing is automatically copied from source changes.
5. To create a downloadable ZIP, run **Actions → Build or publish addon bundle**. A test artifact can be built without publishing a release; publication requires choosing `publish_release` explicitly.

The initial import has been completed and reviewed. All five runtime addon folders are now stored under [`addons/`](addons/), with their exact source revisions recorded in [`sources.lock.json`](sources.lock.json).

See [Maintainer Guide](docs/MAINTAINER-GUIDE.md) for steps, workflow permissions, backups, rollback, and publishing.

## Server requirements and licences

These addons target a customised AzerothCore server and may depend on its Individual Progression, Playerbots, MultiBot bridge and Naxxramas Core features. Review the upstream READMEs for the specific requirements.

Classic Battlegrounds controls **client-side visibility only**; hiding the remote queue interface does not enforce server-side restrictions. The optional server-side Battlemaster rules must be separately configured and tested.

Each bundled addon keeps its own licence and attribution requirements. In particular:

- Dungeon Journal contains GPLv2-derived Atlas/AtlasLoot/AtlasQuest resources. Keep its `LICENSE-GPL-2.0.txt` and `CREDITS.txt`.
- MultiBot is a modified GPLv3 fork. Keep its `LICENSE` and original author/maintainer credits.

The collection does not supersede or relicense the original projects.
