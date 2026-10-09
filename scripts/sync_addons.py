#!/usr/bin/env python3
"""Stage selected source addon snapshots in addons/. Original repos are untouched."""
import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config" / "addons.json"
LOCK = ROOT / "sources.lock.json"
ADDONS = ROOT / "addons"

ROOT_EXCLUDE = {
    "README.md", "README.txt", "TODO.md", "AGENTS.md",
    ".coderabbit.yaml", ".editorconfig", ".gitignore",
    ".luacheckrc", "stylua.toml",
}
SKIP_DIRS = {".git", ".github", "docs", "tests"}


def git(*arguments):
    subprocess.run(["git", *map(str, arguments)], check=True)


def git_output(*arguments):
    return subprocess.check_output(
        ["git", *map(str, arguments)], text=True
    ).strip()


def copy_runtime_files(source, destination):
    """Copy addon content, not source-project CI or development documentation."""
    destination.mkdir(parents=True, exist_ok=True)
    for current, dirs, files in os.walk(source):
        relative = Path(current).relative_to(source)
        kept = []
        for dirname in dirs:
            path = Path(current) / dirname
            if path.is_symlink():
                raise ValueError(f"Unexpected symlink in source: {path}")
            if dirname.startswith(".") or (
                relative == Path(".") and dirname in SKIP_DIRS
            ):
                continue
            kept.append(dirname)
        dirs[:] = kept

        for filename in files:
            path = Path(current) / filename
            if path.is_symlink():
                raise ValueError(f"Unexpected symlink in source: {path}")
            if filename.startswith("."):
                continue
            if relative == Path(".") and filename in ROOT_EXCLUDE:
                continue
            output = destination / relative / filename
            output.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, output)


def validate_toc(destination, filename):
    toc = destination / filename
    if not toc.is_file():
        raise ValueError(f"Required addon manifest is missing: {toc}")
    content = toc.read_text(encoding="utf-8-sig", errors="replace")
    interface = re.search(r"^##\s*Interface:\s*(\S+)", content, re.M | re.I)
    if not interface or "30300" not in interface.group(1).split(","):
        raise ValueError(f"Expected WoW 3.3.5a interface 30300 in {toc}")
    version_match = re.search(r"^##\s*Version:\s*(.+)$", content, re.M | re.I)
    return version_match.group(1).strip() if version_match else "unspecified"


def validate_config(config):
    for name, details in config.items():
        if not re.fullmatch(r"[A-Za-z0-9_-]+", name):
            raise ValueError(f"Invalid addon folder: {name}")
        if not re.fullmatch(r"CosmicCuddle/[A-Za-z0-9_.-]+", details["repository"]):
            raise ValueError(f"Unexpected source repository for {name}")
        folder = Path(details["source_folder"])
        if folder.is_absolute() or ".." in folder.parts:
            raise ValueError(f"Unsafe source folder: {folder}")
        if Path(details["toc"]).name != details["toc"]:
            raise ValueError(f"Invalid TOC name for {name}")


def stage_one(name, details, requested_ref, lock):
    with tempfile.TemporaryDirectory(prefix="naxx-addon-") as tmp:
        tmp = Path(tmp)
        checkout = tmp / "source"
        stage = tmp / "staged"
        repository = details["repository"]
        git("clone", "--quiet", "--depth", "1", "--branch", details["branch"],
            f"https://github.com/{repository}.git", checkout)
        if requested_ref:
            git("-C", checkout, "fetch", "--quiet", "--depth", "1",
                "origin", requested_ref)
            git("-C", checkout, "checkout", "--quiet", "--detach", "FETCH_HEAD")
        sha = git_output("-C", checkout, "rev-parse", "HEAD")
        source = (checkout / details["source_folder"]).resolve()
        if not source.is_dir() or not source.is_relative_to(checkout.resolve()):
            raise ValueError(f"Invalid addon source path: {source}")
        if name == "NTalentCalculator":
            # This new canonical addon is fetched by *pinned commit* when
            # building the collection, rather than mirrored into addons/.
            # The verified generated DBC data is built with its own scripts.
            version = validate_toc(source, details["toc"])
            lock[name] = {"repository": repository, "commit": sha, "version": version}
            print(f"Pinned external {name} ({version}) at {sha[:12]}")
            return
        copy_runtime_files(source, stage)
        version = validate_toc(stage, details["toc"])
        destination = ADDONS / name
        ADDONS.mkdir(exist_ok=True)
        if destination.exists():
            shutil.rmtree(destination)
        shutil.copytree(stage, destination)
        lock[name] = {"repository": repository, "commit": sha, "version": version}
        print(f"Staged {name} ({version}) at {sha[:12]}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--addon", required=True)
    parser.add_argument("--ref", default="")
    args = parser.parse_args()
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    validate_config(config)
    if args.addon != "all" and args.addon not in config:
        parser.error(f"Unknown addon: {args.addon}")
    if args.addon == "all" and args.ref.strip():
        parser.error("--ref applies only when staging one addon")
    if args.ref and not re.fullmatch(r"[A-Za-z0-9_./-]{1,160}", args.ref):
        parser.error("Invalid Git reference")
    lock = json.loads(LOCK.read_text(encoding="utf-8")) if LOCK.exists() else {}
    selected = list(config) if args.addon == "all" else [args.addon]
    for name in selected:
        stage_one(name, config[name], args.ref, lock)
    LOCK.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8")


if __name__ == "__main__":
    main()
