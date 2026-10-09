#!/usr/bin/env python3
"""Translate the pinned website calculator's custom DBC snapshots to WoW Lua 5.1.

The client cannot fetch or decompress gzip at runtime, so the development
pipeline exports a standalone Lua file. No DBC files or source addons change.
"""
import argparse
import base64
import gzip
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PIN = ROOT / "config" / "talent-data.json"


def git_blob_sha(raw):
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()


def read_blob(path, expected_sha):
    raw = path.read_bytes()
    if git_blob_sha(raw) != expected_sha:
        raise ValueError(f"Unapproved talent data file or changed bytes: {path}")
    content = gzip.decompress(base64.b64decode(raw.strip(), validate=True))
    return json.loads(content)


def lua_string(value):
    """Quote UTF-8 and control characters in syntax valid for Lua 5.1."""
    escaped = []
    for char in value:
        if char == "\\":
            escaped.append("\\\\")
        elif char == '"':
            escaped.append('\\"')
        elif char == "\n":
            escaped.append("\\n")
        elif char == "\r":
            escaped.append("\\r")
        elif char == "\t":
            escaped.append("\\t")
        elif ord(char) < 32:
            escaped.append("\\%03d" % ord(char))
        else:
            escaped.append(char)
    return '"' + "".join(escaped) + '"'


def lua_value(value):
    if value is None:
        return "nil"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, str):
        return lua_string(value)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError("Non-finite number in DBC data")
        return repr(value)
    if isinstance(value, list):
        return "{" + ",".join(lua_value(item) for item in value) + "}"
    if isinstance(value, dict):
        return "{" + ",".join(
            "[" + lua_string(str(key)) + "]=" + lua_value(val)
            for key, val in sorted(value.items(), key=lambda item: str(item[0]))
        ) + "}"
    raise ValueError(f"Unsupported DBC data type: {type(value)}")


def generate(source_directory, destination):
    manifest = json.loads(PIN.read_text(encoding="utf-8"))
    base = Path(source_directory)
    talents = read_blob(base / manifest["talents_path"], manifest["talents_git_blob_sha"])
    visuals = read_blob(base / manifest["visuals_path"], manifest["visuals_git_blob_sha"])

    expected_classes = {
        "warrior", "paladin", "hunter", "rogue", "priest",
        "deathknight", "shaman", "mage", "warlock", "druid"
    }
    if talents.get("version") != 1 or set(talents.get("classes", {})) != expected_classes:
        raise ValueError("Expected the website's approved ten-class talent dataset")
    trees = [tree for class_trees in talents["classes"].values() for tree in class_trees]
    talent_count = sum(len(tree[3]) for tree in trees)
    if len(trees) != 30 or talent_count != 830:
        raise ValueError(f"DBC talent data changed unexpectedly: {len(trees)} trees, {talent_count} talents")
    if visuals.get("version") != 1 or len(visuals.get("icons", {})) < 600:
        raise ValueError("Expected approved server SpellIcon visuals")
    if len(visuals.get("tooltips", {})) < 2200:
        raise ValueError("Expected approved server Spell tooltips")

    data = {
        "classes": talents["classes"],
        "icons": visuals["icons"],
        "tooltips": visuals["tooltips"],
        "sourceCommit": manifest["source_commit"],
        "version": 1,
    }
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(
        "-- Generated from approved website DBC exports. Do not manually edit.\n"
        "NTalentCalculatorData = " + lua_value(data) + "\n",
        encoding="utf-8",
    )
    print(f"Generated {destination} ({len(trees)} trees / {talent_count} talents)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path,
                        help="Root of pinned Naxxramas-Resource-Hub checkout")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    generate(args.source, args.output)
