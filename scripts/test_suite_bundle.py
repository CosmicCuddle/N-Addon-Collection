"""Offline layout and migration tests for the N Addon Suite v2 package."""
import hashlib
import json
import stat
import tempfile
import unittest
import zipfile
from pathlib import Path, PurePosixPath

from build_bundle import (
    CORE,
    MANDATORY,
    OPTIONAL,
    ROOT,
    SNAPSHOTS,
    ZIP_ENTRY_DATE_TIME,
    ZIP_FILE_MODE,
    addon_toc_with_dependency,
    build,
    embed_classic_battlegrounds,
    iter_files,
    make_version_manifest,
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

    def test_zip_metadata_is_stable_across_build_clock_times(self):
        # Merely recreating a ZIP must not stamp the current date on 796 entries.
        # 1980 is the earliest timestamp supported by the ZIP specification.
        infos = self.archive.infolist()
        self.assertTrue(infos)
        for member in infos:
            with self.subTest(name=member.filename):
                self.assertEqual(member.date_time, ZIP_ENTRY_DATE_TIME)
                self.assertEqual(member.compress_type, zipfile.ZIP_DEFLATED)
                self.assertEqual(member.create_system, 3)
                self.assertEqual(member.external_attr >> 16, ZIP_FILE_MODE)

    def test_repeated_builds_produce_identical_zip_bytes(self):
        initial = self.zip_path.read_bytes()
        original_hash = hashlib.sha256(initial).hexdigest()
        with tempfile.TemporaryDirectory() as tmp:
            repeated = build("v2.0.0-alpha.1", Path(tmp)).read_bytes()
        self.assertEqual(hashlib.sha256(repeated).hexdigest(), original_hash)
        self.assertEqual(repeated, initial)

    def test_every_archive_member_matches_source_or_approved_transform(self):
        """All files must match source snapshots, except documented transforms."""
        config = json.loads(
            (ROOT / "config" / "addons.json").read_text(encoding="utf-8")
        )
        lock = json.loads((ROOT / "sources.lock.json").read_text(encoding="utf-8"))
        self.assertEqual(set(config), {MANDATORY, *OPTIONAL})
        self.assertEqual(set(lock), set(config))

        expected = {}
        for file, relative in iter_files(CORE):
            expected["NCore/" + relative] = file.read_bytes()

        expected["NCore/ExpectedVersions.lua"] = make_version_manifest(lock)
        source = SNAPSHOTS / MANDATORY / "NClassicBattlegrounds.lua"
        expected["NCore/ClassicBattlegrounds/NClassicBattlegrounds.lua"] = (
            embed_classic_battlegrounds(source.read_bytes())
        )

        for addon in OPTIONAL:
            source_folder = SNAPSHOTS / addon
            toc = config[addon]["toc"]
            for file, relative in iter_files(source_folder):
                payload = file.read_bytes()
                if relative == toc:
                    payload = addon_toc_with_dependency(payload)
                expected[addon + "/" + relative] = payload

        actual_names = self.archive.namelist()
        self.assertEqual(len(actual_names), len(set(actual_names)),
                         "Archive must not contain duplicate file entries")
        self.assertEqual(set(actual_names), set(expected),
                         "ZIP contains a missing or unexpected source member")
        for name, source_bytes in expected.items():
            with self.subTest(name=name):
                self.assertEqual(
                    hashlib.sha256(self.archive.read(name)).digest(),
                    hashlib.sha256(source_bytes).digest(),
                    "Packaged member payload differs from approved source/transform"
                )

    def test_all_archive_member_paths_and_types_are_safe(self):
        """Protect extraction paths, including on Windows ZIP extractors."""
        for info in self.archive.infolist():
            with self.subTest(name=info.filename):
                self.assertFalse(info.is_dir(), "No directory-only archive entries")
                self.assertNotIn("\\", info.filename, "Use ZIP forward slashes")
                name = PurePosixPath(info.filename)
                self.assertFalse(name.is_absolute())
                self.assertNotIn("..", name.parts)
                self.assertEqual(str(name), info.filename)
                self.assertGreaterEqual(len(name.parts), 2)
                self.assertIn(name.parts[0], {"NCore", *OPTIONAL})
                self.assertFalse(
                    info.create_system == 3
                    and stat.S_ISLNK(info.external_attr >> 16),
                    "No symbolic-link archive members"
                )

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


    def test_silent_version_audit_is_bundled_and_pinned(self):
        toc = self.archive.read("NCore/NCore.toc").decode()
        self.assertIn("ExpectedVersions.lua", toc)
        self.assertIn("LegacyCheck.lua", toc)
        self.assertIn("NCore/LegacyCheck.lua", self.names)

        import json
        lock = json.loads((ROOT / "sources.lock.json").read_text(encoding="utf-8"))
        versions = self.archive.read("NCore/ExpectedVersions.lua").decode()
        self.assertIn("NCore.expectedVersions = {", versions)
        for addon in OPTIONAL:
            self.assertIn(f'["{addon}"] = "{lock[addon]["version"]}"', versions)
        self.assertNotIn("NClassicBattlegrounds", versions)

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
