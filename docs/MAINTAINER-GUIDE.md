# Maintainer guide

## Core rule

The five original GitHub addon repositories are the **development sources**. This collection contains **approved snapshots only**. Changes to the collection never write back to the source repositories.

AutoWhisperReply and AutoHideMinimap are personal projects and are explicitly excluded.

## GitHub repository names verified

The shorter repository names are now active: `N-Dungeon-Journal`, `N-MultiBot-Chatless`, `N-Loot-Ledger`, `N-ClassicBattlegrounds`, and `N-Addon-Collection`. `Individual-Progression-Companion` retains its original name. All five addon sources are independent development repositories.

**Never change addon folder names, `.toc` filenames, Lua identifiers, or SavedVariables when merely renaming a GitHub repository.**

## First import

1. Review and merge the setup pull request.
2. Open **Actions → Stage approved addon update → Run workflow**.
3. Select **all** and leave **source_ref** blank. The script checks out the current `main` revision of each source repository.
4. Inspect the generated pull request, the five addon folders, and the file `sources.lock.json`.
5. Confirm source versions and testing status, especially the **beta** addon(s), and merge only when satisfied.

The five addon folders will appear under `addons/`. Their names are the exact directories needed inside WoW's `Interface/AddOns/` directory.

### GitHub workflow permission

The staging workflow needs **Contents: read/write** and **Pull requests: read/write** permissions for the automatically supplied `GITHUB_TOKEN`. If GitHub disallows creating pull requests, review **Settings → Actions → General → Workflow permissions** and enable **Allow GitHub Actions to create and approve pull requests** (subject to account policies). Do not supply a personal access token unless necessary.

## Update one addon

1. Commit and test the feature in its individual source repository.
2. In this collection, choose **Actions → Stage approved addon update → Run workflow**.
3. Select the correct addon. Leave **source_ref** empty to stage the current source `main`, or provide an exact tested SHA/tag for a single addon.
4. Review the created PR, including the version and pinned commit in `sources.lock.json`.
5. Merge when happy. No source repository is changed, and no public release is published by the staging workflow.

**Run staging updates one at a time.** They share a staging branch. Finish the current PR before starting another update.

## Build a ZIP or publish a release

1. Open **Actions → Build or publish addon bundle → Run workflow**.
2. Enter a unique collection version, for example `v1.0.0`.
3. Leave **publish_release** unchecked first. The workflow uploads a downloadable test ZIP in its run artifacts.
4. Verify that the ZIP opens with exactly these top-level folders: `IndividualProgressionAddon/`, `DungeonJournal/`, `MultiBot/`, `NaxxLootLottery/`, `NClassicBattlegrounds/`.
5. If satisfied, run again with **publish_release** checked. Keep **prerelease** enabled for any development collection.

Releases use a separate **collection version**. Individual addons keep the versions written in their own TOC files; `sources.lock.json` records the source SHA and addon version.

## Backup and undo

- **Before merging a staged PR:** close it; the published collection is untouched.
- **After merging:** revert the merge commit through GitHub (or make a new corrective PR) to restore the previous collection snapshot.
- **After releasing:** preserve old releases; rebuild a new, clearly versioned release using the restored or corrected collection. Do not silently replace an older ZIP.
- **On the WoW client:** back up the five addon folders and the appropriate `WTF` SavedVariables before installation or replacement. Restore those backups if rollback is needed.

## Source layout and licence handling

The source mapping is in `config/addons.json`. Individual Progression, Dungeon Journal, MultiBot and Classic Battlegrounds keep their addon files at their repository roots; N Loot Ledger keeps its installable addon within the `NaxxLootLottery` subfolder. The import script excludes repository-level development materials such as `.github/`, `docs/` and `tests/` while preserving addon code and assets.

Retain Dungeon Journal's `LICENSE-GPL-2.0.txt` and `CREDITS.txt`, and MultiBot's GPLv3 `LICENSE` and upstream credits. Licence files must stay alongside their respective bundled addon. The collection does not change licences or claim original authorship of upstream work.

## Known functional dependencies

- Individual Progression Companion is designed for the customised Naxxramas/AzerothCore progression rules.
- MultiBot Chatless requires the corresponding server-side bridge for bridge functions and Naxxramas Core for its custom bot consumables integration.
- Naxxramas Loot Ledger remains in development; testing of its full real loot-awarding workflow must continue before calling it stable.
- N Classic Battlegrounds v0.2.1-beta is client-side interface control only; it **does not** enforce server queue restrictions. Additional era-specific client tests and optional server-side Battlemaster testing remain outstanding. Do not mark stable until verified.
