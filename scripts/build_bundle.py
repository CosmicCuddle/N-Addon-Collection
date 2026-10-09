#!/usr/bin/env python3
"""Build ready-to-install addon ZIPs from approved checked-in snapshots."""
import argparse
import json
import os
import stat
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def build(version, output_dir):
    config = json.loads((ROOT / "config" / "addons.json").read_text())
    lockfile = ROOT / "sources.lock.json"
    if not lockfile.exists():
        raise ValueError("No approved snapshot: sources.lock.json is missing")
    lock = json.loads(lockfile.read_text())
    output_dir.mkdir(parents=True, exist_ok=True)
    archive = output_dir / f"N-Addon-Collection-{version}.zip"
    entries = []

    for addon, details in config.items():
        folder = ROOT / "addons" / addon
        if addon not in lock or not (folder / details["toc"]).is_file():
            raise ValueError(f"Missing approved addon files or TOC: {addon}")
        for directory, dirs, files in os.walk(folder):
            dirs[:] = sorted(d for d in dirs if not d.startswith("."))
            for name in sorted(files):
                source = Path(directory) / name
                if source.is_symlink() or not source.is_file():
                    raise ValueError(f"Unexpected addon file: {source}")
                if stat.S_ISLNK(source.lstat().st_mode):
                    raise ValueError(f"Unsafe symbolic link: {source}")
                relative = source.relative_to(ROOT / "addons")
                entries.append((source, relative.as_posix()))

    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for source, relative in sorted(entries, key=lambda pair: pair[1]):
            z.write(source, relative)
    print(f"Created {archive} with {len(entries)} files")
    return archive


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("version")
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    if not args.version.startswith("v") or "/" in args.version or "\\" in args.version:
        parser.error("Expected version like v1.0.0")
    build(args.version, args.output_dir)


if __name__ == "__main__":
    main()
