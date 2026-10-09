# N Addon Suite v2 — installation and regression test plan

**Version 2.0.0:** The normal public release is available from [GitHub Releases](https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v2.0.0). This plan also retains historical alpha test steps for maintainers. Always back up the previous client version before upgrading.

## Goal

One downloadable ZIP containing exactly five WoW addon folders: `NCore/` plus the four optional addons `IndividualProgressionAddon/`, `DungeonJournal/`, `MultiBot/`, and `NaxxLootLottery/`.

`NCore` **always includes N Classic Battlegrounds**. There is no standalone `NClassicBattlegrounds/` directory in the v2 ZIP and no Battlegrounds toggle in the manager. The original fifth source repository remains the canonical development home for Battlegrounds, with its code adapted only while packaging.

## Backup before testing

1. Close the WoW 3.3.5a client.
2. Copy your complete `Interface/AddOns/` directory and the relevant account/character `WTF/` SavedVariables directory to a dated backup.
3. Specifically preserve any old `NClassicBattlegrounds`, `NaxxramasClassicBattlegrounds` or `N-ClassicBattlegrounds` folder and the related character `NClassicBattlegrounds.lua` SavedVariables file.
4. Keep the [v1.0.0 public collection release](https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v1.0.0) available for rollback.

## Install N Addon Suite v2.0.0

The standard downloadable release is the `N-Addon-Collection-v2.0.0.zip` attached to [v2.0.0](https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v2.0.0). The former `v2.0.0-alpha.1` Actions archive was a prerelease development artifact; do not mistake it for the current production package.

1. Exit WoW and back up your existing AddOns and SavedVariables.
2. Remove the old standalone `NClassicBattlegrounds` folder and any obsolete `ServerDungeonJournal` folder.
3. Extract the five folders `NCore/`, `IndividualProgressionAddon/`, `DungeonJournal/`, `MultiBot/`, and `NaxxLootLottery/` from the release ZIP **directly** into `World of Warcraft/Interface/AddOns/`.
4. Verify `Interface/AddOns/NCore/NCore.toc` and `Interface/AddOns/NCore/ClassicBattlegrounds/NClassicBattlegrounds.lua` exist.
5. In-game, type `/nsettings` and confirm only four optional modules appear. Classic Battlegrounds must show `ALWAYS ON`.
6. The independent **N Talent Calculator is deliberately absent** from the v2.0.0 release. Its development and optional future suite inclusion are tracked separately.

## Automatic older-addon warning

NCore checks the addon list **silently on each login**. A warning window appears only when it detects:

- `ServerDungeonJournal` (the previous Dungeon Journal folder).
- `NaxxramasClassicBattlegrounds` or a separate `NClassicBattlegrounds` addon (older/duplicate Classic BG installations).
- A version older than this collection's pinned `.toc` version for any of the four optional addons.

The expected versions come directly from `sources.lock.json` when the suite package is built. No hardcoded version table needs updating after future approved source imports. Disabled-but-still-installed obsolete addons are also listed so they cannot be accidentally re-enabled.

The warning only *reports* problems; it never deletes folders, modifies SavedVariables or disables addons. **Close WoW and delete the old addon folder(s)** identified by the warning from `Interface/AddOns`. If the flagged folder is an outdated current module, reinstall the latest N Addon Suite version afterward. Then launch WoW again. Use `/nsuite check` to manually rescan at any time. Use `/nsuite check demo` to preview the warning safely without installing an old addon; it clearly says **Example warning**. A clean install shows no popup. `/nsuite status` continues to provide module diagnostics.

**Limit:** WoW 3.3.5a cannot enumerate arbitrary files from Lua. Files or folders that WoW does not register as an addon (for example a renamed backup with no matching `.toc`) cannot be detected. An addon with no readable version metadata cannot reliably be identified as outdated, though known legacy folder names can still be detected.

### Older-version detection tests

- [ ] With only the five suite folders installed, log in: **no warning** appears.
- [ ] Type `/nsuite check demo` to preview an obviously simulated warning. Dismiss it and verify nothing was disabled or deleted.
- [ ] Add a backed-up copy of `ServerDungeonJournal` with its original valid `.toc`, log in: the warning names that old folder.
- [ ] Remove it, leaving only current `DungeonJournal`: the warning disappears on next login.
- [ ] With a standalone `NClassicBattlegrounds` folder installed as well as NCore, confirm the duplicate warning appears. Remove the standalone copy before continuing.
- [ ] Use `/nsuite check` after cleanup to confirm a clean registered addon list.
- [ ] Check that dismissed warnings do not delete files or erase settings.
## Functional tests

- [ ] WoW 3.3.5a shows **N Addon Suite** and the four optional addons in the character-selection AddOns list.
- [ ] Login succeeds with all modules enabled and **no Lua errors**; existing addon windows, commands and SavedVariables remain unchanged.
- [ ] `/nsettings` and `/nsuite` show a draggable N Suite settings window.
- [ ] N Classic Battlegrounds displays as **ALWAYS ON** and has **no toggle**.
- [ ] `/ncbg status` and `/ncbg refresh` work; `/ncbg off` reports mandatory integration and does not disable the feature.
- [ ] In Vanilla progression, appropriate battleground and arena sections hide, and Battlemaster NPC queues still work.
- [ ] In TBC progression, Arena controls return but remote BG tab and Wintergrasp remain restricted visually.
- [ ] In WotLK progression, Battleground tab and Wintergrasp are restored as intended.
- [ ] Disable only Dungeon Journal using suite settings; click **Reload UI**. Its code does not load, while NCore and Classic Battlegrounds still run.
- [ ] Re-enable Dungeon Journal, reload, and verify it works and the user's settings are retained.
- [ ] Repeat enable/disable and reload for Individual Progression, MultiBot, and Loot Ledger.
- [ ] Verify Loot Ledger UI and 40-character simulator if its optional module is enabled; do not treat real loot awarding as production-ready.
- [ ] Confirm the `/nsettings` panel has a dark, readable background even when a character or bright game scenery is behind it.
- [ ] Confirm descriptions, enabled labels and the Reload UI footer have no overlap, wrapping into adjacent rows or clipping at the bottom border.
- [ ] Confirm the window fits within the screen at higher UI scale and small resolutions, with a visible margin around the frame.
- [ ] Check UI accessibility at common WoW screen resolutions and UIScale levels.

**Important limitations:** A Lua addon cannot prevent users from disabling the *entire* `NCore` addon or modifying their client. Battleground queue restrictions require properly tested server-side enforcement. Individual addons cannot safely be *unloaded live* in WoW 3.3.5a, so changes take effect only after Reload UI. The original Battlegrounds per-character enabled flag is not migrated (and cannot disable the required core feature).

## Rollback

1. Exit WoW.
2. Remove the v2 `NCore` directory and all four suite-provided optional addon folders.
3. Restore the backed-up v1 addon directories, including standalone `NClassicBattlegrounds/` if it was previously installed.
4. Restore `WTF` SavedVariables only if necessary (keep a copy of newer user data before overwriting).
5. Restart the client and check each addon.

## Maintenance

All five original repositories remain separate development sources. A future collection import pins the newly approved source commits under `addons/`, and a test ZIP is built from those snapshots. Because the embedded Classic BG code requires deterministic adapter rules, a changed upstream Lua structure will cause packaging to fail rather than silently breaking mandatory behavior. All packaged optional `.toc` files receive the `NCore` dependency **inside the ZIP only**, keeping their original GitHub projects independently installable.
