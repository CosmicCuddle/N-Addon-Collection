# Maintainer guide

**Always read and update [ROADMAP.md](../ROADMAP.md) with any source import, packaging change, workflow edit, or release.** It records the current baseline, blockers, tested steps, rollback and the next task.

## Core rule

The five original GitHub addon repositories are the **development sources**. This collection contains **approved snapshots only**. Changes to the collection never write back to the source repositories.

AutoWhisperReply and AutoHideMinimap are personal projects and are explicitly excluded.

## GitHub repository names verified

The shorter repository names are now active: `N-Dungeon-Journal`, `N-MultiBot-Chatless`, `N-Loot-Ledger`, `N-ClassicBattlegrounds`, and `N-Addon-Collection`. `Individual-Progression-Companion` retains its original name. All five addon sources are independent development repositories.

**Never change addon folder names, `.toc` filenames, Lua identifiers, or SavedVariables when merely renaming a GitHub repository.**

## First import (completed)

The initial five-source snapshot import was reviewed and merged as pull request #2. Source SHAs and versions are saved in `sources.lock.json`. The original collection candidate `v1.0.0-rc.1` is kept for historical rollback. The regular release is `v1.0.0`, with the **same addon snapshots** and a clear disclaimer about individual WIP projects.

The collection itself is not a pre-release merely because one included addon is WIP. Always describe unfinished or untested functionality accurately in the release notes and README.
### GitHub workflow permission

The staging workflow needs **Contents: read/write** and **Pull requests: read/write** permissions for the automatically supplied `GITHUB_TOKEN`. If GitHub disallows creating pull requests, review **Settings → Actions → General → Workflow permissions** and enable **Allow GitHub Actions to create and approve pull requests** (subject to account policies). Do not supply a personal access token unless necessary.

## Update one addon

1. Commit and test the feature in its individual source repository.
2. In this collection, choose **Actions → Stage approved addon update → Run workflow**.
3. Select the correct addon. Leave **source_ref** empty to stage the current source `main`, or provide an exact tested SHA/tag for a single addon.
4. Review the created PR, including the version and pinned commit in `sources.lock.json`.
5. **Update ROADMAP.md in the same staged PR** with the new source SHA, test status, known issues, rollback and next task. Merge when satisfied. No source repository is changed, and no public release is published by the staging workflow.

**Run staging updates one at a time.** They share a staging branch. Finish the current PR before starting another update.

## Build a ZIP or publish a release

1. Open **Actions → Build or publish addon bundle → Run workflow**.
2. Enter a unique collection version, for example `v1.0.0`.
3. Leave **publish_release** unchecked first. The workflow uploads a downloadable test ZIP in its run artifacts.
4. For **published v2.0.0**, verify exactly these top-level install folders: `NCore/`, `IndividualProgressionAddon/`, `DungeonJournal/`, `MultiBot/`, and `NaxxLootLottery/`. **NClassicBattlegrounds is embedded inside NCore**, and `NTalentCalculator` must not appear in v2.0.0.
5. If satisfied, run again with **publish_release** checked. Keep **prerelease** unchecked for normal collection releases. Mark individual addons' unfinished or unverified features prominently in the release notes. Enable the pre-release option only when the collection package itself is experimental.

Both v1.0.0 (original snapshot bundle) and **v2.0.0 (required NCore suite)** were published as normal releases. For **any later version**, inspect and update the v2.0.0-specific workflow title trigger, release note header, five-root guard and NCore version assertion; these must not silently mislabel or block a new package. Future releases should be manually triggered. Releases use a separate **collection version**. Individual addons keep the versions written in their own TOC files; `sources.lock.json` records the source SHA and addon version.

## Backup and undo

- **Before merging a staged PR:** close it; the published collection is untouched.
- **After merging:** revert the merge commit through GitHub (or make a new corrective PR) to restore the previous collection snapshot.
- **After releasing:** preserve old releases; rebuild a new, clearly versioned release using the restored or corrected collection. Do not silently replace an older ZIP.
- **On the WoW client:** back up the five addon folders and the appropriate `WTF` SavedVariables before installation or replacement. Restore those backups if rollback is needed.

## Source layout and licence handling

The source mapping is in `config/addons.json`. Individual Progression, Dungeon Journal and MultiBot keep addon files at their repository roots; N Loot Ledger installs from the `NaxxLootLottery` subfolder, and N Classic Battlegrounds installs from `NClassicBattlegrounds`. The import script excludes repository-level development materials such as `.github/`, `docs/` and `tests/` while preserving addon code and assets.

Retain Dungeon Journal's `LICENSE-GPL-2.0.txt` and `CREDITS.txt`, and MultiBot's GPLv3 `LICENSE` and upstream credits. Licence files must stay alongside their respective bundled addon. The collection does not change licences or claim original authorship of upstream work.

## Known functional dependencies

- Individual Progression Companion is designed for the customised Naxxramas/AzerothCore progression rules.
- MultiBot Chatless requires the corresponding server-side bridge for bridge functions and Naxxramas Core for its custom bot consumables integration.
- Naxxramas Loot Ledger remains in development; testing of its full real loot-awarding workflow must continue before calling it stable.
- N Classic Battlegrounds v1.0.0 is released and provides client-side interface control only; it **does not** enforce server queue restrictions. Additional era-specific client tests and optional server-side Battlemaster testing remain outstanding; document those limitations in each relevant release.
