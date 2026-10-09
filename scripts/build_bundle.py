#!/usr/bin/env python3
"""Build one install-ready N Addon Suite ZIP from pinned, approved sources.

v2 design:
- NCore always loads Classic Battlegrounds (embedded, no independent toggle).
- Four optional addons retain their original folders/TOCs/SavedVariables.
- Original source snapshots remain untouched under addons/.
- A normal install ZIP contains NCore + four optional addon folders.
"""
import argparse
import json
import os
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "suite" / "NCore"
SNAPSHOTS = ROOT / "addons"
MANDATORY = "NClassicBattlegrounds"
OPTIONAL = (
    "IndividualProgressionAddon",
    "DungeonJournal",
    "MultiBot",
    "NaxxLootLottery",
)
SUITE_PREFIX = "N-Addon-Collection"


def valid_file(path, base):
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"Missing or unsafe source file: {path}")
    if not path.resolve().is_relative_to(base.resolve()):
        raise ValueError(f"Unsafe source path: {path}")


def iter_files(directory):
    for current, dirs, files in os.walk(directory):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for filename in sorted(files):
            if filename.startswith("."):
                continue
            source = Path(current) / filename
            valid_file(source, directory)
            yield source, source.relative_to(directory).as_posix()


def require_exact(text, old, label):
    if text.count(old) != 1:
        raise ValueError(f"Classic BG integration changed: expected one {label}")
    return text


def embed_classic_battlegrounds(source):
    """Adapt a pinned upstream copy *only inside the output ZIP*.

    Retains PvP-era logic and slash status/refresh commands; its addon-loaded
    event is NCore, not a separate NClassicBattlegrounds addon. Removing the
    standalone off/on control enforces the mandatory suite policy.
    """
    text = source.decode("utf-8-sig")
    old_name = 'local ADDON = "NClassicBattlegrounds"'
    require_exact(text, old_name, "addon identifier")
    text = text.replace(old_name, 'local ADDON = "NCore"')

    old_enabled = (
        "return NClassicBGQueueSettings\n"
        "       and NClassicBGQueueSettings.enabled ~= false"
    )
    require_exact(text, old_enabled, "enable predicate")
    text = text.replace(old_enabled, "return true  -- mandatory while NCore is loaded")

    beginning = 'if message == "on" then'
    ending = 'elseif message == "refresh" then'
    require_exact(text, beginning, "on command")
    require_exact(text, ending, "refresh command")
    start = text.index(beginning)
    finish = text.index(ending, start)
    text = (
        text[:start]
        + 'if message == "on" or message == "off" then\n'
        + '        Log("Classic Battlegrounds is mandatory in N Suite and cannot be disabled separately.")\n'
        + '    '
        + text[finish:]
    )

    old_help = "Commands: /ncbg on, /ncbg off, /ncbg refresh, /ncbg status"
    require_exact(text, old_help, "slash command help")
    text = text.replace(old_help, "Commands: /ncbg refresh, /ncbg status (mandatory suite feature)")
    return text.encode("utf-8")


def addon_toc_with_dependency(source):
    """Require the core without changing the original addon manifest."""
    text = source.decode("utf-8-sig")
    if "## Interface: 30300" not in text:
        raise ValueError("Expected Interface 30300 in optional addon manifest")
    lines = text.splitlines(keepends=True)
    for index, line in enumerate(lines):
        found = re.match(r"^##\s*(RequiredDeps|Dependencies):\s*(.*)$", line, re.I)
        if found:
            parts = [p.strip() for p in found.group(2).split(",") if p.strip()]
            if "NCore" not in parts:
                parts.append("NCore")
            lines[index] = f"## Dependencies: {', '.join(parts)}\n"
            return "".join(lines).encode("utf-8")

    lines.insert(1, "## Dependencies: NCore\n")
    return "".join(lines).encode("utf-8")


def build(version, output_dir):
    config = json.loads((ROOT / "config" / "addons.json").read_text(encoding="utf-8"))
    lockfile = ROOT / "sources.lock.json"
    if not lockfile.exists():
        raise ValueError("Approved source snapshots are missing (sources.lock.json)")
    lock = json.loads(lockfile.read_text(encoding="utf-8"))
    expected = set(OPTIONAL) | {MANDATORY}
    if set(config) != expected or set(lock) != expected:
        raise ValueError("The source configuration and lock must contain the five approved addons")
    if not (CORE / "NCore.toc").is_file():
        raise ValueError("Missing NCore manifest")

    entries = {}
    for source, relative in iter_files(CORE):
        entries[f"NCore/{relative}"] = source.read_bytes()

    battleground_file = SNAPSHOTS / MANDATORY / "NClassicBattlegrounds.lua"
    valid_file(battleground_file, SNAPSHOTS / MANDATORY)
    embedded_name = "NCore/ClassicBattlegrounds/NClassicBattlegrounds.lua"
    if embedded_name in entries:
        raise ValueError("Embedded Classic Battlegrounds file must not be committed into suite/NCore")
    entries[embedded_name] = embed_classic_battlegrounds(battleground_file.read_bytes())

    for addon in OPTIONAL:
        details = config[addon]
        folder = SNAPSHOTS / addon
        toc = details["toc"]
        if not (folder / toc).is_file():
            raise ValueError(f"Missing optional addon manifest: {addon}/{toc}")

        for source, relative in iter_files(folder):
            arcname = f"{addon}/{relative}"
            data = source.read_bytes()
            if relative == toc:
                data = addon_toc_with_dependency(data)
            entries[arcname] = data

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    archive = output_dir / f"{SUITE_PREFIX}-{version}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for name, data in sorted(entries.items()):
            z.writestr(name, data)

    print(f"Created {archive} with {len(entries)} files (NCore + 4 optional modules)")
    return archive


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("version")
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+(?:[-.][A-Za-z0-9.-]+)?", args.version):
        parser.error("Expected a version like v2.0.0-alpha.1")
    build(args.version, args.output_dir)


if __name__ == "__main__":
    main()
