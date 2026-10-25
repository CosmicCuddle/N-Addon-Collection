"""Offline layout and migration tests for the N Addon Suite v2 package."""
import hashlib
import json
import re
import stat
import tempfile
import xml.etree.ElementTree as ET
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


_WINDOWS_UNSAFE = re.compile(r'[<>:"\\|?*\x00-\x1f]')
_WINDOWS_DEVICES = {"CON", "PRN", "AUX", "NUL"} | {
    f"{prefix}{number}" for prefix in ("COM", "LPT") for number in range(1, 10)
}


def validate_windows_zip_member_names(names):
    """Fail closed on ambiguities that break Win32-based WoW AddOns extraction.

    Tests the *names* independent of the build: case-insensitive collisions,
    reserved device names, invalid characters, trailing dot/space, backslash,
    root escapes, empty/dot components, and accidental sixth addon roots.
    """
    expected_roots = {"NCore", *OPTIONAL}
    seen = set()
    for member in names:
        if not member or not isinstance(member, str):
            raise ValueError("Missing or invalid ZIP member name")
        if member.startswith("/") or member.endswith("/"):
            raise ValueError("Absolute or directory ZIP member: " + repr(member))
        if _WINDOWS_UNSAFE.search(member):
            raise ValueError("Invalid Windows ZIP character: " + repr(member))
        parts = member.split("/")
        if (
            len(parts) < 2 or parts[0] not in expected_roots or
            any(part in ("", ".", "..") for part in parts)
        ):
            raise ValueError("Invalid installed addon root/path: " + repr(member))
        for part in parts:
            if part != part.rstrip(". "):
                raise ValueError("Windows trailing dot or space: " + repr(member))
            if part.split(".", 1)[0].upper() in _WINDOWS_DEVICES:
                raise ValueError("Windows reserved device filename: " + repr(member))
        folded = member.casefold()
        if folded in seen:
            raise ValueError("Windows case-insensitive filename collision: " +
                             repr(member))
        seen.add(folded)
    return len(seen)


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

    def _toc_roots(self):
        config = json.loads(
            (ROOT / "config" / "addons.json").read_text(encoding="utf-8")
        )
        return {
            "NCore": "NCore/NCore.toc",
            **{
                addon: addon + "/" + config[addon]["toc"]
                for addon in OPTIONAL
            },
        }

    @staticmethod
    def _runtime_path(base, relative):
        """Resolve addon runtime file paths without allowing parent traversal."""
        normalized = relative.strip().replace("\\", "/")
        parts = PurePosixPath(normalized)
        if (
            not normalized or parts.is_absolute() or
            ".." in parts.parts or ":" in normalized or
            not normalized.lower().endswith((".lua", ".xml"))
        ):
            raise ValueError("Unsafe/non-runtime file reference: " + repr(relative))
        return str(PurePosixPath(base) / parts)

    def test_every_toc_load_entry_exists_in_the_built_zip(self):
        """Checks actual client loader entries for all five addon roots."""
        for addon, toc_name in self._toc_roots().items():
            self.assertIn(toc_name, self.names, toc_name)
            toc = self.archive.read(toc_name).decode("utf-8-sig")
            filenames = [
                line.strip()
                for line in toc.splitlines()
                if line.strip() and not line.lstrip().startswith("#")
            ]
            self.assertTrue(filenames, "TOC must load runtime files: " + addon)
            for filename in filenames:
                with self.subTest(addon=addon, filename=filename):
                    member = self._runtime_path(addon, filename)
                    self.assertIn(member, self.names, "TOC references missing file")

    def test_nested_xml_script_includes_exist_in_the_built_zip(self):
        """WoW's XML loader resolves scripts relative to the XML directory."""
        seen_xml = set()
        xml_to_visit = []
        for addon, toc_name in self._toc_roots().items():
            toc = self.archive.read(toc_name).decode("utf-8-sig")
            for filename in toc.splitlines():
                filename = filename.strip()
                if filename and not filename.startswith("#") and filename.lower().endswith(".xml"):
                    xml_to_visit.append(self._runtime_path(addon, filename))

        self.assertTrue(xml_to_visit, "Expected XML loader coverage in MultiBot")
        while xml_to_visit:
            xml_member = xml_to_visit.pop()
            if xml_member in seen_xml:
                continue
            seen_xml.add(xml_member)
            self.assertIn(xml_member, self.names, "XML loader file missing")
            root = ET.fromstring(self.archive.read(xml_member))
            addon = xml_member.split("/", 1)[0]
            for node in root.iter():
                tag_name = node.tag.rsplit("}", 1)[-1].lower()
                if tag_name not in ("script", "include"):
                    continue
                referenced = node.attrib.get("file")
                if not referenced:
                    continue  # WoW also supports inline <Script> elements.
                with self.subTest(xml=xml_member, reference=referenced):
                    relative = self._runtime_path(
                        str(PurePosixPath(xml_member).parent), referenced
                    )
                    self.assertEqual(
                        relative.split("/", 1)[0], addon,
                        "An XML include cannot escape its installed addon folder"
                    )
                    self.assertIn(relative, self.names, "XML loads a missing file")
                    if relative.lower().endswith(".xml"):
                        xml_to_visit.append(relative)

    def test_windows_addon_zip_file_names_are_unambiguous(self):
        """Every shipped file must remain uniquely extractable on Windows."""
        self.assertEqual(
            validate_windows_zip_member_names(self.archive.namelist()),
            len(self.archive.namelist()),
        )

    def test_windows_zip_safety_guard_rejects_adversarial_names(self):
        """Negative fixtures prove the guard rejects each high-risk class."""
        base = ["NCore/Core.lua", "MultiBot/MultiBot.toc"]
        bad_cases = {
            "casefold-collision": "NCore/core.LUA",
            "nested-repo-folder": "N-Addon-Collection/NCore/Core.lua",
            "separate-bg-root": "NClassicBattlegrounds/NClassicBattlegrounds.lua",
            "windows-device": "NCore/CON.lua",
            "windows-device-extension": "NCore/COM1.txt",
            "trailing-dot": "NCore/Test.",
            "trailing-space": "NCore/Test ",
            "backslash": r"NCore\Crash.lua",
            "drive-colon": "NCore/C:evil.lua",
            "absolute-root": "/NCore/Crash.lua",
            "parent-traversal": "NCore/../Crash.lua",
            "empty-segment": "NCore//Crash.lua",
            "dot-segment": "NCore/./Crash.lua",
            "control-character": "NCore/Bad\nfile.lua",
            "unexpected-top-folder": "Extras/file.lua",
            "directory-only": "NCore/",
        }
        for case, unsafe_name in bad_cases.items():
            with self.subTest(case=case, filename=unsafe_name):
                with self.assertRaises(ValueError):
                    validate_windows_zip_member_names(base + [unsafe_name])
        with self.assertRaisesRegex(ValueError, "collision"):
            validate_windows_zip_member_names(base + ["NCore/Core.lua"])

    def test_published_ncore_load_order_has_no_unreviewed_hunter_listener(self):
        """A future v2 Hunter source addition must be explicit, never silent."""
        toc = self.archive.read("NCore/NCore.toc").decode("utf-8-sig")
        load_order = [
            line.strip()
            for line in toc.splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        self.assertEqual(load_order, [
            "Core.lua",
            "ExpectedVersions.lua",
            r"ClassicBattlegrounds\NClassicBattlegrounds.lua",
            "Settings.lua",
            "LegacyCheck.lua",
        ])
        self.assertFalse(any(
            "HunterPetAutocast" in line or "PetAutocastKeeper" in line
            for line in load_order
        ))

    def test_unapproved_hunter_v1_protocol_is_not_accidentally_shipped(self):
        """Until server v2 sign-off, preserve BG without a v1 autocast hook."""
        self.assertNotIn("PetAutocastKeeper", {
            name.split("/", 1)[0] for name in self.names
        })
        self.assertFalse(any(
            name.startswith("NCore/HunterPetAutocast/")
            or name.startswith("NCore/PetAutocastKeeper/")
            for name in self.names
        ))
        self.assertIn(
            "NCore/ClassicBattlegrounds/NClassicBattlegrounds.lua",
            self.names,
        )
        for name in sorted(self.names):
            if name.startswith("NCore/") and name.lower().endswith(".lua"):
                with self.subTest(name=name):
                    self.assertNotIn(b"NXCPAK", self.archive.read(name),
                                     "No v1 addon whisper protocol in shipped NCore")

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
