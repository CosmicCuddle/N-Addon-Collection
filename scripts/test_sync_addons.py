"""Fast, offline tests for the collection import and package rules."""
import json
import tempfile
import unittest
from pathlib import Path

from sync_addons import CONFIG, copy_runtime_files, validate_config, validate_toc


class TestAddonImport(unittest.TestCase):
    def test_copy_keeps_runtime_and_licence_but_not_development_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            destination = root / "output"
            (source / "Data").mkdir(parents=True)
            (source / ".github").mkdir()
            (source / "tests").mkdir()
            (source / "Core.lua").write_text("-- Lua addon")
            (source / "Data" / "Vanilla.lua").write_text("-- data")
            (source / "LICENSE").write_text("GPL notice")
            (source / "README.md").write_text("Development README")
            (source / ".github" / "workflow.yml").write_text("workflow")
            (source / "tests" / "test.lua").write_text("test")
            copy_runtime_files(source, destination)
            self.assertTrue((destination / "Core.lua").exists())
            self.assertTrue((destination / "Data" / "Vanilla.lua").exists())
            self.assertTrue((destination / "LICENSE").exists())
            self.assertFalse((destination / "README.md").exists())
            self.assertFalse((destination / ".github").exists())
            self.assertFalse((destination / "tests").exists())

    def test_collection_contains_six_approved_source_repositories(self):
        config = json.loads(CONFIG.read_text(encoding="utf-8"))
        validate_config(config)
        expected = {
            "IndividualProgressionAddon", "DungeonJournal", "MultiBot",
            "NaxxLootLottery", "NClassicBattlegrounds", "NTalentCalculator"
        }
        self.assertEqual(set(config), expected)
        self.assertEqual(
            config["NClassicBattlegrounds"]["repository"],
            "CosmicCuddle/N-ClassicBattlegrounds"
        )
        self.assertEqual(
            config["NClassicBattlegrounds"]["toc"],
            "NClassicBattlegrounds.toc"
        )

    def test_toc_requires_correct_interface(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            toc = folder / "MyAddon.toc"
            toc.write_text("## Interface: 30300\n## Version: 1.2.3\nCore.lua\n")
            self.assertEqual(validate_toc(folder, "MyAddon.toc"), "1.2.3")
            toc.write_text("## Interface: 110000\n## Version: 2.0\n")
            with self.assertRaises(ValueError):
                validate_toc(folder, "MyAddon.toc")


if __name__ == "__main__":
    unittest.main()
