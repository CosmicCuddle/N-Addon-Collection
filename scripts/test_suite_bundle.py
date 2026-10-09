"""Offline layout and migration tests for the N Addon Suite v2 package."""
import tempfile
import unittest
import zipfile
from pathlib import Path

from build_bundle import (
    MANDATORY,
    OPTIONAL,
    ROOT,
    addon_toc_with_dependency,
    build,
    embed_classic_battlegrounds,
)


class TestSuitePackage(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory()
        cls.zip_path = build("v2.0.0-alpha.1", Path(cls.temporary.name))
        cls.archive = zipfile.ZipFile(cls.zip_path, "r")
        cls.names = set(cls.archive.namelist())

    @classmethod
    def tearDownClass(cls):
        cls.archive.close()
        cls.temporary.cleanup()

    def test_exact_install_folders(self):
        names = {name.split("/", 1)[0] for name in self.names}
        self.assertEqual(names, {"NCore", *OPTIONAL})
        self.assertNotIn(MANDATORY, names)

    def test_manifests_are_loadable(self):
        toc = self.archive.read("NCore/NCore.toc").decode()
        self.assertIn("## Interface: 30300", toc)
        self.assertIn("ClassicBattlegrounds\\NClassicBattlegrounds.lua", toc)
        for addon in OPTIONAL:
            manifest = (
                "NaxxLootLottery.toc" if addon == "NaxxLootLottery"
                else f"{addon}.toc" if addon != "IndividualProgressionAddon"
                else "IndividualProgressionAddon.toc"
            )
            if addon == "DungeonJournal":
                manifest = "DungeonJournal.toc"
            self.assertIn(f"{addon}/{manifest}", self.names)
            text = self.archive.read(f"{addon}/{manifest}").decode()
            self.assertIn("## Dependencies: NCore", text)
            self.assertIn("## Interface: 30300", text)

    def test_bg_is_integrated_and_mandatory(self):
        data = self.archive.read(
            "NCore/ClassicBattlegrounds/NClassicBattlegrounds.lua"
        ).decode()
        self.assertIn('local ADDON = "NCore"', data)
        self.assertIn("return true  -- mandatory while NCore is loaded", data)
        self.assertIn("mandatory in N Suite", data)
        self.assertNotIn('NClassicBGQueueSettings.enabled = false', data)
        self.assertNotIn('SlashCmdList["NSUITE"]', data)
        self.assertNotIn("local ADDON = \"NClassicBattlegrounds\"", data)

    def test_optional_sources_are_untouched(self):
        for addon in OPTIONAL:
            path = ROOT / "addons" / addon
            lua_paths = list(path.rglob("*.lua"))
            self.assertTrue(lua_paths, addon)
            check = lua_paths[0]
            arcname = f"{addon}/{check.relative_to(path).as_posix()}"
            self.assertEqual(self.archive.read(arcname), check.read_bytes())

    def test_original_saved_variables_preserved(self):
        for addon, saved_var in (
            ("IndividualProgressionAddon", "IndividualProgressionDB"),
            ("DungeonJournal", "DungeonJournalDB"),
            ("MultiBot", "MultiBotGlobalSave"),
            ("NaxxLootLottery", "NaxxLootLotteryDB"),
        ):
            toc_name = addon + ".toc"
            if addon == "DungeonJournal":
                toc_name = "DungeonJournal.toc"
            if addon == "NaxxLootLottery":
                toc_name = "NaxxLootLottery.toc"
            self.assertIn(saved_var, self.archive.read(f"{addon}/{toc_name}").decode())

    def test_licenses_are_kept(self):
        self.assertIn("DungeonJournal/LICENSE-GPL-2.0.txt", self.names)
        self.assertIn("DungeonJournal/CREDITS.txt", self.names)
        self.assertIn("MultiBot/LICENSE", self.names)

    def test_metadata_migration_helpers_reject_changed_code(self):
        with self.assertRaises(ValueError):
            embed_classic_battlegrounds(b'local ADDON = "ChangedAddon"')
        self.assertIn(
            "## Dependencies: NCore",
            addon_toc_with_dependency(b"## Interface: 30300\nAddon.lua\n").decode()
        )
        self.assertIn(
            "## Dependencies: Other, NCore",
            addon_toc_with_dependency(
                b"## Interface: 30300\n## Dependencies: Other\nAddon.lua\n"
            ).decode()
        )


if __name__ == "__main__":
    unittest.main()
