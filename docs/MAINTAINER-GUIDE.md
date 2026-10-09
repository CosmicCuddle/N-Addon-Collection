# Maintainer guide

## Core rule

The four original GitHub repositories are the **development sources**. This collection contains **approved snapshots only**. Changes to the collection never write back to the source repositories.

AutoWhisperReply and AutoHideMinimap are personal projects and are explicitly excluded.

## Required GitHub renames before first import

Before running the first source import, rename these GitHub repositories in **Settings → General → Repository name**:

- `Naxx-Dungeon-Journal` → `N-Dungeon-Journal`
- `MultiBot-Chatless-Naxxramas` → `N-MultiBot-Chatless`
- `Naxxramas-Loot-Ledger` → `N-Loot-Ledger`
- `Naxxramas-Addon-Collection` → `N-Addon-Collection`

The setup pull request has already been prepared for these **future repository names**. Do not run the import before the source repositories are renamed. Do not change addon `.toc` filenames, installed folder names or SavedVariables.

## First import

1. Review and merge the setup pull request.
2. Open **Actions → Stage approved addon update → Run workflow**.
3. Select **all** and leave **source_ref** blank. The script checks out the current `main` revision of each source repository.
4. Inspect the generated pull request, the four addon folders, and the file `sources.lock.json`.
5. Confirm the versions have been tested and merge when satisfied.

The four addon folders will appear under `addons/`. Their names are the exact directories needed inside WoW's `Interface/AddOns/` directory.

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
4. Verify that the ZIP opens with exactly these top-level folders: `IndividualProgressionAddon/`, `DungeonJournal/`, `MultiBot/`, `NaxxLootLottery/`.
5. If satisfied, run again with **publish_release** checked. Keep **prerelease** enabled for any development collection.

Releases use a separate **collection version**. Individual addons keep the versions written in their own TOC files; `sources.lock.json` records the source SHA and addon version.

## Backup and undo

- **Before merging a staged PR:** close it; the published collection is untouched.
- **After merging:** revert the merge commit through GitHub (or make a new corrective PR) to restore the previous collection snapshot.
- **After releasing:** preserve old releases; rebuild a new, clearly versioned release using the restored or corrected collection. Do not silently replace an older ZIP.
- **On the WoW client:** back up the four addon folders and the appropriate `WTF` SavedVariables before installation or replacement. Restore those backups if rollback is needed.

## Source layout and licence handling

The source mapping is in `config/addons.json`. The first three source repositories keep their addon files at repository root; Naxxramas Loot Ledger keeps its installable addon within the `NaxxLootLottery` subfolder. The import script excludes repository-level development materials such as `.github/`, `docs/` and `tests/` while preserving addon code and assets.

Retain Dungeon Journal's `LICENSE-GPL-2.0.txt` and `CREDITS.txt`, and MultiBot's GPLv3 `LICENSE` and upstream credits. Licence files must stay alongside their respective bundled addon. The collection does not change licences or claim original authorship of upstream work.

## Known functional dependencies

- Individual Progression Companion is designed for the customised Naxxramas/AzerothCore progression rules.
- MultiBot Chatless requires the corresponding server-side bridge for bridge functions and Naxxramas Core for its custom bot consumables integration.
- Naxxramas Loot Ledger remains in development; testing of its full real loot-awarding workflow must continue before calling it stable.
