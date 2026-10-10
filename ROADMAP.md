# N Addon Collection — Maintainer Roadmap

**Repository:** https://github.com/CosmicCuddle/N-Addon-Collection  
**Default branch:** main  
**Current public release:** v2.0.0 — https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v2.0.0  
**Previous rollback release:** v1.0.0 — https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v1.0.0  
**WoW target:** client 3.3.5a (Interface 30300)  
**Roadmap updated:** 10 October 2026  
**Next planned release:** not scheduled; do not invent a version until scope is approved

This is the working record for maintenance, releases and recovery. It is not release marketing. Read the **Current baseline**, **Next task**, **Source update procedure**, and **Recovery** sections before starting another change. Edit this file with every source, configuration, packaging or behavior PR: record what changed, how it was tested, and exactly what still needs doing.

## Current baseline — published v2.0.0

N Addon Collection is a curated, versioned installable suite, not five arbitrary GitHub repository ZIPs. The main package includes exactly **five addon folders**:

| Installed folder | Status in v2.0.0 | Canonical source | Approved version |
| --- | --- | --- | --- |
| NCore | **Required**, central settings, module switching, compatibility warnings, mandatory Classic Battlegrounds integration | Suite-owned framework; embedded N-ClassicBattlegrounds source | NCore 2.0.0; source Classic BG 1.0.0 |
| IndividualProgressionAddon | Optional | CosmicCuddle/Individual-Progression-Companion | 5.2.0 |
| DungeonJournal | Optional | CosmicCuddle/N-Dungeon-Journal | 0.6.1 |
| MultiBot | Optional | CosmicCuddle/N-MultiBot-Chatless | 4.0 |
| NaxxLootLottery | Optional, **work in progress** | CosmicCuddle/N-Loot-Ledger | 0.1.0.27 |

N Classic Battlegrounds code is packaged **inside NCore**, not as a standalone NClassicBattlegrounds folder. Its settings row cannot be disabled through /nsettings; this means only while NCore itself is enabled. It does not make it impossible for players to disable NCore at the client AddOns screen. Client-side battleground menu hiding is not server-side queue enforcement.

**N Talent Calculator is not included in the released v2.0.0 ZIP.** It has its own development repository at https://github.com/CosmicCuddle/N-Talent-Calculator-. Keep its development, website-derived data, alpha testing and release cadence separate. N Talent Calculator may enter a future collection only after an explicit scope decision and a *new* reviewed import/release; it is not silently added just because standalone code changes.

The public v2.0.0 is a **normal stable collection release**, although an included individual addon (N Loot Ledger) is unfinished. The complete real Master Loot award path remains insufficiently verified; state that limitation whenever bundling its snapshot.

## Exact approved source pins

The authoritative commit hashes and versions are in sources.lock.json. Current v2.0.0 source snapshot:

| Source repository | Commit | Snapshot version |
| --- | --- | --- |
| CosmicCuddle/Individual-Progression-Companion | 6872cc726052f7d271a28ba48baa9bb5c7ad36e9 | 5.2.0 |
| CosmicCuddle/N-Dungeon-Journal | a35e4404b421228d6b881a674a62d2167bf6187f | 0.6.1 |
| CosmicCuddle/N-MultiBot-Chatless | d1606832a083ebf660d67b629b07207b184590dd | 4.0 |
| CosmicCuddle/N-Loot-Ledger | 7169f5d7b8e959d1f0b86f9b7f98913d5288b1bb | 0.1.0.27 |
| CosmicCuddle/N-ClassicBattlegrounds | 74e45933454385b3b1168bf2c03da34ee1027985 | 1.0.0 |

Do not “refresh all” and unknowingly import new upstream work. Stage one source change at a time, compare source versions/SHAs and any relevant licence/credit files, and approve only after testing.

## Files, workflow and responsibilities

| Path | Role | Non-negotiable |
| --- | --- | --- |
| suite/NCore/Core.lua | suite registry and optional-module enable state | Four optional modules in v2.0.0; no Talent Calculator in current release |
| suite/NCore/Settings.lua | central settings UI | N Classic BG shown as required, with no disabling checkbox |
| suite/NCore/LegacyCheck.lua | silent addon scan and visible legacy-folder warnings | Never delete addon files or SavedVariables automatically |
| suite/NCore/ClassicBattlegrounds/ | embedded Classic BG loader in installable package | No duplicate standalone battleground folder |
| config/addons.json | approved five canonical addon source locations | Preserve folder and TOC identities |
| sources.lock.json | approved source SHAs and versions | Changes require an explicit import/approval |
| addons/ | committed approved snapshots of original runtime files | Not the place to develop each independent addon |
| scripts/sync_addons.py | stage source snapshots and metadata | Do not silently change unrelated snapshots |
| scripts/build_bundle.py | deterministic suite package and NCore integration | ZIP roots must be exactly the five listed above for v2.0.0 |
| scripts/test_suite_bundle.py | package-level guards | Reject Talent Calculator and a separate Classic BG root in v2.0.0 |
| .github/workflows/stage-addon-updates.yml | stage approved source changes | Review PR before merge |
| .github/workflows/validate-collection.yml | validate snapshots, core, Lua and package | Required for code and integration changes |
| .github/workflows/build-collection.yml | build test ZIP; optionally publish a release | Publication is an explicit action, not the default |
| docs/SUITE-V2-TEST-PLAN.md | detailed installation and interactive regression checks | Record real-client results here |
| docs/MAINTAINER-GUIDE.md | routine import and release instructions | Keep it accurate for v2, not the obsolete v1 five-root package |

## Completed milestones

| Milestone | Recorded outcome | Verification |
| --- | --- | --- |
| Initial collection v1.0.0 | Five individual addon snapshots available as a standard ZIP | GitHub release retained for rollback |
| Central NCore v2.0.0 | Suite settings interface; optional modules enabled/disabled by reload; Classic BG embedded and always enabled within NCore | CI and user screenshots/module toggles from v2 development |
| Duplicate/obsolete install warning | Scan registered addon names and TOC metadata; warn when legacy ServerDungeonJournal or standalone BG conflicts appear | Lua regression tests; installer issue reproduced and resolved |
| Suite v2.0.0 published | Exactly five installed roots; mandatory NCore plus four optional modules | Published normal release; ZIP validation succeeded |
| Calculator separation | N Talent Calculator has a standalone source repository and test builds | **Explicitly excluded** from public collection v2.0.0 |
| Current handover standard | ROADMAP.md, source/verification checklist and requirement to record next task with each change | Documentation / workflow update in progress |

The calculator integration experiment was developed separately as N-Addon-Collection PR #5. It was based on the earlier v2 development branch and **must not be merged unreviewed**. Its source version and assumptions are now stale relative to the standalone addon. Rebase/reimplement as a new feature branch only if explicitly approved for a future collection.

## Next task — verify the released v2 package in the live client

**Priority 1: finish a focused, reproducible regression pass of published v2.0.0.** No repackaging is needed to test what is already published.

1. Install v2.0.0 in a clean WoW 3.3.5a AddOns directory after backing up old AddOns and WTF SavedVariables.
2. Confirm exactly the five expected addon roots; remove old ServerDungeonJournal and standalone NClassicBattlegrounds copies so the client does not load two /dj or battleground handlers.
3. Enter /nsettings and confirm the required Classic Battlegrounds row and four functioning optional toggles.
4. Toggle Dungeon Journal off; Reload UI; /dj must no longer open. Restore it and repeat at least once, preserving existing SavedVariables.
5. Toggle Individual Progression Companion, MultiBot and Loot Ledger individually; Reload UI after each. Check there are no Lua errors, broken slash commands or cross-module side effects.
6. Run /nsuite check on a clean installation and /nsuite check demo as a harmless visual exercise; no deletion should occur.
7. At Vanilla, TBC and Wrath IP tiers, check Classic BG UI restrictions and restoration. Test actual Battlemaster access separately from hidden menu controls.
8. Test at small resolution and large UI scale for labels, clipping and scrolling. Collect screenshots or a precise failure report.
9. Write each verified result in docs/SUITE-V2-TEST-PLAN.md and update this roadmap to the next open issue.

**Exit condition:** recorded in-game results, known limitations, and a clear decision whether a v2.0.1 hotfix is necessary. CI success alone is not proof of live-client behavior.

## Later work, in order

### Priority 2 — collection packaging and support quality

- Confirm every imported source retains attribution, licence and credits.
- Review the legacy-warning catalogue whenever an addon folder is renamed. The scanner can inspect only registered addons, not arbitrary filesystem content.
- When changed snapshots have new TOC version fields, regenerate the pinned manifest at package build time and rerun installer tests.
- Keep help text for /nsuite status, /nsuite check and module enable/reload accurate.
- Avoid changes to Playerbots, AzerothCore configuration or SQL as part of a packaging-only update.

### Priority 3 — independent addon releases and optional future imports

- Individual Progression, Dungeon Journal, MultiBot and N Loot Ledger continue development in their own repositories. Stage an updated snapshot only after that project's own tests and maintainer roadmap are current.
- N Loot Ledger's simulated raid/lottery behavior is not equivalent to validated **real** Master Loot awarding. Do not remove the WIP note until the actual server procedure is tested.
- N Talent Calculator is developed at CosmicCuddle/N-Talent-Calculator-, currently as alpha builds. Its next work is the in-game Saved Builds and Sharing interface; it is **not** a v2.0.0 collection task.
- For any future calculator inclusion, explicitly approve the import, compare the latest standalone commit and its pinned custom DBC data, make NCore dependency changes in the *bundle only*, and test the resulting six-root package independently. Do not casually change current v2.0.0's five-root guards.

### Priority 4 — a later collection version, when justified

- Identify the actual new feature/bugfix and source revisions.
- Choose a **new** semantic version; do not replace v2.0.0's existing tag or asset.
- Build a test ZIP first; verify root folder count and NCore version; exercise the in-game changes.
- Update release notes with exact source commits, complete install/upgrade path, compatibility requirements and WIP limitations.
- Use the manual Build or publish addon bundle workflow with publish_release=false for an artifact, then an explicit publish_release=true only after approval.
- The workflow currently contains a **one-time, v2.0.0-specific automatic push title trigger and pinned NCore version assertion**. Review and update these before a future release. Do not reuse the v2.0.0 merge-title publication technique by accident.

## Routine source update procedure

1. Back up or record the previous tested source SHA and ZIP.
2. Make and test the change in the addon-specific repository first, with that repository's own updated ROADMAP.md.
3. Open the collection staging workflow for **one** addon; provide an exact reviewed SHA when feasible.
4. Review imported files, addon folder and TOC names, licence and credits, config/addons.json, sources.lock.json, and the changed package contents.
5. **Update this ROADMAP.md in the same collection PR**, recording the source SHA, what players will notice, test evidence, rollback SHA and the *next action*.
6. Run validation; build a test ZIP without a release; confirm required modules and optional enable/disable behavior.
7. Merge only when verified. Publish a newly versioned normal release only when requested and reviewed.

No code changes should go straight from conversation text into a published ZIP without an intermediate tested branch.

## Installation and rollback — user-facing

**Backup before upgrading:** close the client. Copy the relevant Interface/AddOns directories and account/character WTF SavedVariables to a dated backup. Never assume UI Reload is enough before replacing source files.

For v2.0.0, extract the five bundled addon directories straight into Interface/AddOns. Delete previous standalone NClassicBattlegrounds or ServerDungeonJournal addon folders if they are installed alongside the suite. Do not wrap the whole package inside a sixth “collection” directory. In-game, use /nsettings and Reload UI.

**Rollback from v2 to v1:** shut down WoW, remove NCore and the four optional v2 directories, restore the earlier five v1 addon folders (including standalone Classic BG) from the preserved version/backup, and restore WTF settings only if required. Restoring old WTF can overwrite newer customisations; keep a separate copy.

**Rollback a not-yet-released PR:** close/revert the proposed change; keep the release untouched. After an accidental main-branch merge, revert with a new commit or corrective PR rather than rewriting public release history. Do not silently replace a published ZIP.

## Constraints and unresolved testing

| Area | What is known | What still requires testing |
| --- | --- | --- |
| Classic Battlegrounds | Required within NCore; client UI suppression by tier | Real server queue restrictions are not guaranteed |
| Module toggles | Reload applies optional addon disabled state | Complete clean-client regression across all four |
| Old addon folders | Silent scan can detect known registered names | Client Lua cannot enumerate non-addons/unregistered directories |
| MultiBot Chatless | Uses server bridge for certain features | Matching server modules and bot behavior |
| N Loot Ledger | WIP simulator and loot planning included | Real raid/loot awarding under controlled Master Loot settings |
| Installation | Tested automated five-root package | Small screen/UI-scale and previously installed addon combinations |
| N Talent Calculator | Standalone source, not bundled | Whether inclusion in a later collection will be desired |

## Roadmap upkeep — required for every change

Every PR that changes implementation, packaging, dependencies, source pins, tests or release workflows **must edit ROADMAP.md in that same PR**. At minimum:

1. Update the baseline/version if anything shipped or an approved snapshot moved.
2. Move the completed item to the history with the actual result and test status.
3. Rewrite **Next task** so a maintainer knows the first concrete file, action, acceptance criteria and blocker to address.
4. Record new limitations, server dependencies, data compatibility and rollback steps.
5. Link the PR/commit, GitHub Actions run and live-client evidence when they exist. Do not manufacture test results.

Keep this file useful after the entire chat history is gone: concrete identifiers, clear headings, verified status versus remaining tasks. The README is for players; this file is the authoritative maintainer handover.
