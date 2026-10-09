# Naxxramas Addon Collection

**WoW 3.3.5a (client build 12340; Interface 30300)** addons for the Naxxramas AzerothCore server.

This is a **curated, manually approved collection**. Development remains in each original repository. Changes do not appear here until the collection owner reviews and merges an import pull request.

## Included addons

| Installed folder | Addon | Original development repository | Notes |
| --- | --- | --- | --- |
| `IndividualProgressionAddon` | Individual Progression Companion | [Individual-Progression-Companion](https://github.com/CosmicCuddle/Individual-Progression-Companion) | Server-specific Vanilla, TBC and WotLK progression guidance. |
| `DungeonJournal` | Dungeon Journal | [Naxx-Dungeon-Journal](https://github.com/CosmicCuddle/Naxx-Dungeon-Journal) | Dungeon and raid handbook; Vanilla content is the primary completed section. |
| `MultiBot` | MultiBot Chatless (Naxxramas fork) | [MultiBot-Chatless-Naxxramas](https://github.com/CosmicCuddle/MultiBot-Chatless-Naxxramas) | Playerbot UI; bridge and certain Naxxramas server features require matching server modules. |
| `NaxxLootLottery` | Naxxramas Loot Ledger | [Naxxramas-Loot-Ledger](https://github.com/CosmicCuddle/Naxxramas-Loot-Ledger) | Raid loot planning and lottery; still under development and testing. |

**Not included:** the personal projects AutoWhisperReply and AutoHideMinimap.

## Download and install

Once the first reviewed import and bundle are published, download the ZIP from [Releases](https://github.com/CosmicCuddle/Naxxramas-Addon-Collection/releases). It contains the four addon folders directly at the ZIP root.

1. Exit World of Warcraft.
2. **Back up** any existing addon folders under `World of Warcraft/Interface/AddOns/` and the corresponding `WTF` SavedVariables files.
3. Extract the collection ZIP **into** `World of Warcraft/Interface/AddOns/`.
4. Verify these paths exist:
   - `Interface/AddOns/IndividualProgressionAddon/IndividualProgressionAddon.toc`
   - `Interface/AddOns/DungeonJournal/DungeonJournal.toc`
   - `Interface/AddOns/MultiBot/MultiBot.toc`
   - `Interface/AddOns/NaxxLootLottery/NaxxLootLottery.toc`
5. Start WoW 3.3.5a and enable the addons you want at character selection.

Do **not** install an extra `Naxxramas-Addon-Collection` folder around the four addons. For individual addon downloads, use the links to the original repositories above.

## How updates are approved

1. Finish developing and testing in the **original addon repository**.
2. Run **Actions → Stage approved addon update** in this repository. Choose one addon or `all`; optionally enter a particular source commit/tag for a single addon.
3. Review the generated pull request and exact source commit hashes recorded in [`sources.lock.json`](sources.lock.json).
4. Merge only when satisfied. Nothing is automatically copied from source changes.
5. To create a downloadable ZIP, run **Actions → Build or publish addon bundle**. A test artifact can be built without publishing a release; publication requires choosing `publish_release` explicitly.

The first import is also manual: the repository will not contain runtime addon files until an import pull request has been reviewed and merged.

See [Maintainer Guide](docs/MAINTAINER-GUIDE.md) for steps, workflow permissions, backups, rollback, and publishing.

## Server requirements and licences

These addons target a customised AzerothCore server and may depend on its Individual Progression, Playerbots, MultiBot bridge and Naxxramas Core features. Review the upstream READMEs for the specific requirements.

Each bundled addon keeps its own licence and attribution requirements. In particular:

- Dungeon Journal contains GPLv2-derived Atlas/AtlasLoot/AtlasQuest resources. Keep its `LICENSE-GPL-2.0.txt` and `CREDITS.txt`.
- MultiBot is a modified GPLv3 fork. Keep its `LICENSE` and original author/maintainer credits.

The collection does not supersede or relicense the original projects.
