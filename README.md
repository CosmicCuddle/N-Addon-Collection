# N Addon Collection

**WoW 3.3.5a (client build 12340; Interface 30300)** addons for the Naxxramas AzerothCore server.

**The collection is a normal release.** Some individual addons may still be works in progress. In particular, **N Loot Ledger v0.1.0.27 is WIP, not fully complete, and its real Master Loot awarding remains subject to further server testing.** Its inclusion does not mean that every Loot Ledger feature is production-ready.

This is a **curated, manually approved collection**. Development remains in each original repository. Changes do not appear here until the collection owner reviews and merges an import pull request.
## N Addon Suite v2.0.0

**Latest stable collection:** [N Addon Suite v2.0.0](https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v2.0.0). This is a normal GitHub release, with the ElvUI-inspired `NCore` settings interface.

The ZIP contains **exactly five installed addon folders**: mandatory `NCore`, plus optional `IndividualProgressionAddon`, `DungeonJournal`, `MultiBot`, and `NaxxLootLottery`.

**N Classic Battlegrounds is integrated inside `NCore`**, not shipped as a separate addon folder. It is always enabled while NCore is running, but users can still disable NCore itself at the WoW AddOns screen. Client-side interface restrictions do not replace tested server enforcement.

**N Talent Calculator is not included in v2.0.0.** It remains under independent development in [N-Talent-Calculator-](https://github.com/CosmicCuddle/N-Talent-Calculator-), with its inclusion in a *future* suite update planned separately.

Type `/nsettings` or `/nsuite` to open the module manager. The four optional addons can be switched on or off; apply changes with **Reload UI**. The suite silently checks for registered outdated/duplicate addon installations and warns when cleanup is needed. Commands: `/nsuite check`, `/nsuite status`, and `/nsuite check demo`.

## Included addons

| Installed folder | Addon | Original development repository | Notes |
| --- | --- | --- | --- |
| `NCore` | **N Addon Suite Core + Classic Battlegrounds** | [N-ClassicBattlegrounds](https://github.com/CosmicCuddle/N-ClassicBattlegrounds) | Required framework and progression-aware PvP interface. Classic Battlegrounds is embedded, not a separate installed folder. |
| `IndividualProgressionAddon` | Individual Progression Companion | [Individual-Progression-Companion](https://github.com/CosmicCuddle/Individual-Progression-Companion) | Optional; Vanilla, TBC and Wrath progression guidance. |
| `DungeonJournal` | Dungeon Journal | [N-Dungeon-Journal](https://github.com/CosmicCuddle/N-Dungeon-Journal) | Optional; dungeon and raid reference. |
| `MultiBot` | MultiBot Chatless | [N-MultiBot-Chatless](https://github.com/CosmicCuddle/N-MultiBot-Chatless) | Optional; may require matching server modules. |
| `NaxxLootLottery` | N Loot Ledger | [N-Loot-Ledger](https://github.com/CosmicCuddle/N-Loot-Ledger) | Optional; work in progress, real loot-awarding functionality not fully verified. |

The five original source projects are still maintained independently. The collection pins approved source revisions and assembles an installable suite. Personal projects AutoWhisperReply and AutoHideMinimap are not included.

## Download and install

**Download the [N Addon Suite v2.0.0 release](https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v2.0.0)**. The previous [v1.0.0 release](https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v1.0.0) remains available for rollback.

1. **Close World of Warcraft.**
2. Back up your current `Interface/AddOns` folders and relevant `WTF` SavedVariables.
3. **Remove any old standalone `NClassicBattlegrounds` addon folder** (or renamed legacy variants); it must not load alongside the embedded version in `NCore`. Also remove `ServerDungeonJournal` if an old copy is present.
4. Extract the release ZIP directly into `World of Warcraft/Interface/AddOns/`.
5. Verify `NCore/NCore.toc`, `IndividualProgressionAddon/IndividualProgressionAddon.toc`, `DungeonJournal/DungeonJournal.toc`, `MultiBot/MultiBot.toc`, and `NaxxLootLottery/NaxxLootLottery.toc` exist.
6. Launch WoW 3.3.5a. Use `/nsettings` to configure four optional addons; choose **Reload UI** after switching.

Do not nest these folders inside an additional `N-Addon-Collection` directory. Do not install any older standalone Battlegrounds folder alongside NCore. The suite does **not** include `NTalentCalculator` — its standalone version can be obtained from its separate repository.

If you need to return to v1.0.0, close WoW, remove the v2 suite folders, and restore the backed-up v1 addon directories and any saved settings required.

## How updates are approved

1. Finish developing and testing in the **original addon repository**.
2. Run **Actions → Stage approved addon update** in this repository. Choose one addon or `all`; optionally enter a particular source commit/tag for a single addon.
3. Review the generated pull request and exact source commit hashes recorded in [`sources.lock.json`](sources.lock.json).
4. Merge only when satisfied. Nothing is automatically copied from source changes.
5. To create a downloadable ZIP, run **Actions → Build or publish addon bundle**. A test artifact can be built without publishing a release; publication requires choosing `publish_release` explicitly.

The original five addon source snapshots remain under [`addons/`](addons/) with approved revisions pinned in [`sources.lock.json`](sources.lock.json). The v2 builder packages those snapshots as four optional addon folders plus the suite's required NCore; Classic Battlegrounds is embedded into NCore at build time.

See [Maintainer Guide](docs/MAINTAINER-GUIDE.md) for steps, workflow permissions, backups, rollback, and publishing.

## Server requirements and licences

These addons target a customised AzerothCore server and may depend on its Individual Progression, Playerbots, MultiBot bridge and Naxxramas Core features. Review the upstream READMEs for the specific requirements.

Classic Battlegrounds controls **client-side visibility only**; hiding the remote queue interface does not enforce server-side restrictions. The optional server-side Battlemaster rules must be separately configured and tested.

Each bundled addon keeps its own licence and attribution requirements. In particular:

- Dungeon Journal contains GPLv2-derived Atlas/AtlasLoot/AtlasQuest resources. Keep its `LICENSE-GPL-2.0.txt` and `CREDITS.txt`.
- MultiBot is a modified GPLv3 fork. Keep its `LICENSE` and original author/maintainer credits.

The collection does not supersede or relicense the original projects.
