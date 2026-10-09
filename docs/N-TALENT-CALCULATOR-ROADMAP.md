# N Talent Calculator — N Addon Suite v2 development

## Why this is server-specific

The public website calculator at `CosmicCuddle/Naxxramas-Resource-Hub/talents/` is the source of truth. Its compressed `Talent.dbc`, `TalentTab.dbc`, `Spell.dbc` and `SpellIcon.dbc` derivatives come from the customized Naxxramas 3.3.5a server snapshot supplied on 8 October 2026: 830 talents, 30 trees, 10 classes, including custom Rend Flurry (Talent ID 3000). The suite pins an **exact website Git commit and two Git blob SHAs** in `config/talent-data.json`. During CI, `scripts/build_talent_data.py` converts those snapshots into a local Lua 5.1 data file without touching any live DB/DBC/server files.

**No live web requests inside the game.** The generated `Data.lua` lives in the installable ZIP. Approve upstream DBC edits via the website repository before explicitly updating the pinned commit and checksums.

## Era rules copied from the website

| Individual Progression | Level cap / points | Visible 3.3.5a talent rows |
| --- | --- | --- |
| Vanilla (tier 0-7) | 60 / 51 | All rows 1-6; only the tree capstone in row 7. |
| TBC (tier 8-12) | 70 / 61 | All rows 1-8; only the tree capstone in row 9. |
| WotLK (tier 13+) | 80 / 71 | All 11 rows and all positions. |

Side talents on the final Vanilla/TBC row and all rows below it are **not drawn at all**. All talents above the capped row stay visible regardless of their historical expansion release date, as on the website.

Preserve off-centre capstone exceptions from the exact DBC: Shaman Stormstrike `901`, Warlock Dark Pact `1022` for Vanilla, Paladin Divine Illumination `1747` for TBC. Require 5 lower-row points per row, real Talent.dbc prerequisite talent IDs and ranks, and the class/era level budget.

## Reading the player's tier

- The addon uses Individual Progression's existing read-only message contract: `.ipsvc data` → `##IPSVC##PD~<tier>`.
- The server tier value is the highest completed progression milestone. The era is calculated from the exact tier: `0-7`, `8-12`, or `13+`.
- If that message cannot be obtained, the mandatory NCore Classic Battlegrounds query makes completed hidden quests available. The calculator uses quest flags `66008+` (TBC) and `66013+` (Wrath) to determine **era only**, not an invented exact tier.
- The calculator stays locked while both methods are unavailable. A character's level is never treated as a trustworthy substitute for Individual Progression.

## In-game interface

The `NTalentCalculator` folder is an independent **optional module** in N Addon Suite. It depends on NCore, is enabled/disabled from `/nsettings` with Reload UI, and does not affect mandatory Classic Battlegrounds.

Commands: `/ntalent` or `/ntc` opens the planner; `/ntalent refresh` requests IP state again; `/ntalent code` selects the current build string for Ctrl+C; `/ntalent import NT1:...`; `/ntalent save NAME`; `/ntalent load NAME`.

The calculator shows three talent trees for the selected class (all 10 classes supported; Death Knight only in WotLK), visible talent icons, rank-specific server tooltip text, spent points and a share-code input. Left-click adds a talent rank; right-click removes one. It **never trains or refunds actual talents**. The selected level is the era's level cap for website parity, even if the character is currently lower.

### Share-code compatibility

`NT1:vanilla:warrior:2t-1` is an example. `NT1` matches the public Resource Hub's version 1 code format exactly: `NT1:<era>:<class>:<base36TalentId>-<rank>[.<base36TalentId>-<rank>...]`. The addon's importer verifies the current era, class, DBC talent IDs, required ranks, row rules, prerequisites and point budget. A later-era build cannot bypass the character's progression.

WoW 3.3.5a provides no safe clipboard-write API. **Show code** selects the string in an edit box for Ctrl+C. Paste a build into that box and click **Import**. Website URLs contain the NT1 code in their `code` parameter; you can share the same code across both applications.

## Backups and client testing

1. Preserve the original public collection **v1.0.0** and your working v2 prototype. Back up `Interface/AddOns/` and the appropriate `WTF/SavedVariables` files before testing.
2. Obtain the test ZIP from the GitHub Actions check on the talent-calculator pull request. It includes **NCore plus five optional folders**. Extract the inner collection ZIP into `Interface/AddOns/`.
3. Do not install the old `NClassicBattlegrounds` folder alongside NCore; remove obsolete `ServerDungeonJournal` to avoid duplicates.
4. Verify `/nsettings` shows Talent Calculator as optional and Classic Battlegrounds remains required.
5. Test Vanilla tier 0-7, TBC tier 8-12 and Wrath tier 13+ on corresponding characters, using the exact 7/9/11 row rules.
6. Test all 10 classes, icon textures, rank tooltips, point prerequisites, exceptional final-row capstones, browser-to-WoW NT1 import and WoW-to-browser import.
7. Test disabling the calculator via `/nsettings` and Reload UI. `/ntalent` should no longer open after reload, while other modules still work.
8. Confirm no talent points are actually spent, reset, or sent to the server and that saved builds survive `/reload`.

## Rollback

Close WoW, remove the new `NTalentCalculator` folder, and replace `NCore` with your previous working v2 backup. Restore other addons only if their directory contents changed. Your original individual addon repositories and public collection release are not modified by the prototype.

## Still to verify before release

- WoW 3.3.5a client layout, scale and input box behavior.
- Real `.ipsvc data` event delivery when the Individual Progression Companion is enabled or disabled.
- Real quest-event fallback and era transition without client restarts.
- Website NT1 round-trips for complex builds across all 10 classes.
- Generated DBC rank tooltip fidelity and representative custom talent behavior.

**Do not merge the prototype into main or publish a public release before these are tested.**
