# Repository Roadmap Template — Maintainer Standard

Use this as the starting structure when a new AzerothCore module, WoW addon, DBC-editing tool, resource website or support repository becomes an active project. Each repository should have its own root-level ROADMAP.md containing *actual* project details, not a generic copy of this template.

**Rule:** update ROADMAP.md in the **same pull request or commit** as each material code, SQL, DBC, data, build, workflow, configuration, packaging or documentation behavior change. Make a new project roadmap when work starts; do not wait until the first release. If one conversation ends unexpectedly, the next maintainer should be able to resume from the repository alone.

## A. Project identity and status

Record exact repository URL, main and development branch names, target client/core version, current release/tag, source commit, date, active feature branch and current deploy/test state. Clearly label **merged**, **released**, **automated-test only**, **in-game tested**, **blocked**, or **planned**. Never call a tool-supported simulation a confirmed live-server test.

## B. Scope and non-negotiable decisions

Write the actual intended functionality and exclusions. State any decisions that should not be reopened casually: expansion era logic, modular separation, mandatory versus optional addons, stable SavedVariables, SQL ownership, no AzerothCore core patches, no overlap with other modules, custom playerbot behavior, and server-side enforcement limitations. Link the exact files and upstream modules responsible.

## C. Current architecture

Use a table linking concrete paths to responsibilities. Include entry points such as CMakeLists.txt, loader files, SQL installation and uninstall scripts, Lua TOC files, GitHub workflow names, DBC dataset/config, and data migration procedures. Identify the *authoritative* source when multiple repositories interact.

## D. Implementation ledger

List work in chronological or milestone order with:
- What was changed and why.
- Exact source files or database rows, where relevant.
- PR/commit SHA, test workflow and version/tag.
- Evidence type: compiled, automated tests, player screenshot, GM commands, live 3.3.5a run, SQL queried, or still pending.
- Any migration, compatibility or backward-compatibility notes.

Do not erase prior decisions just because a later implementation superseded them. Briefly retain the cause of a reverted design.

## E. Next task — enough detail to start immediately

Give **one primary next action** at the top, then priorities for later work. The first action must identify the relevant files/modules, concrete acceptance criteria, how to test them, what dependencies may block the work, and how to undo it. If inputs or authoritative details are missing, name the exact information needed rather than guessing.

Suggested task block:

| Field | Information |
| --- | --- |
| Task | Specific change, not “continue development” |
| Why | User-visible problem or technical limitation |
| Files | Paths or named source systems |
| Acceptance | Observable behavior in WoW/server/browser |
| Tests | Offline regression, in-game checks, screenshots or SQL comparison |
| Blocking question | Any missing URL, credentials or DBC data needed |
| Rollback | Previous commit, package, backup tables or patch |

## F. Testing, backups and rollback

Document the exact command used to compile, test, regenerate DBC or package the addon. Include the configuration and server module prerequisites, target AzerothCore API/core fork when relevant, test account/character requirements, and whether a server restart is needed.

For SQL work, specify backup database/schema/table, migration scope, rollback/uninstall SQL, and how to verify that rows were restored. For DBC editing, record changed file names, Spell.dbc/Talent.dbc/SkillLineAbility.dbc IDs, original values if known, client patch relationships and revert steps. For WoW addons, back up Interface/AddOns and WTF SavedVariables before replacement. Never silently edit data with no undo path.

## G. Risks, compatibility and dependencies

Record unresolved test coverage, WoW 3.3.5a Lua limitations, server-side Individual Progression dependency, Playerbot module interaction, database overlap, client patches, expansion-specific rules, licensing and upstream snapshot versions. Separate what is known from what is assumed.

## H. Release / import procedure

Specify whether a GitHub Actions ZIP artifact is merely a test build or an official release. Document the tag naming convention, version source, current upstream SHA locks, packaging layout, checks for excluded modules, release note location, and how to restore an earlier release. Do not replace a published asset/tag as a shortcut.

## I. Handover update checklist

Before merging a change:

- [ ] ROADMAP.md reflects the new code/data state and version
- [ ] Completed work has evidence, not just a planned test
- [ ] The exact **next task** has been rewritten if necessary
- [ ] Known issues, dependency versions and compatibility are current
- [ ] Installation/rollback/backup instructions cover any new side effects
- [ ] PR includes links to test runs, screenshots and commit when available
- [ ] Release/maintainer documentation isn't contradicting the roadmap

**Style:** write as a maintainer's working notebook: plain, specific and practical. Avoid filler, AI conversation framing, vague praise or unverified “fully tested” statements. Make the roadmap readable enough to resume after months away.
