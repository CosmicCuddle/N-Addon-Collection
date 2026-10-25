#!/usr/bin/env python3
"""Fail closed if a requested public suite tag disagrees with bundled metadata.

Used only for explicit manual publish requests. This does not create a release.
The WoW 3.3.5a bundle is still tested separately before any authorized release.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def require_publish_metadata_consistency(requested, toc_text, core_text, workflow_text):
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", requested):
        raise ValueError("Release requests must use an approved vMAJOR.MINOR.PATCH tag")

    toc = re.search(r"(?m)^##\s*Version:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*$", toc_text)
    core = re.search(r'(?m)^Suite\.version\s*=\s*"([0-9]+\.[0-9]+\.[0-9]+)"\s*$', core_text)
    notes = re.search(
        r"""print\(['"]## N Addon Suite (v[0-9]+\.[0-9]+\.[0-9]+)['"]\)""",
        workflow_text,
    )
    observed = {
        "NCore.toc": "v" + toc.group(1) if toc else None,
        "NCore/Core.lua": "v" + core.group(1) if core else None,
        "release note heading": notes.group(1) if notes else None,
    }
    if any(value != requested for value in observed.values()):
        raise ValueError(
            "Refusing public release with mismatched metadata: "
            + repr({"requested": requested, **observed})
        )
    return True


def check_release_version(requested, root=ROOT):
    return require_publish_metadata_consistency(
        requested,
        (root / "suite" / "NCore" / "NCore.toc").read_text(encoding="utf-8-sig"),
        (root / "suite" / "NCore" / "Core.lua").read_text(encoding="utf-8-sig"),
        (root / ".github" / "workflows" / "build-collection.yml").read_text(
            encoding="utf-8"
        ),
    )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: check_release_metadata.py vMAJOR.MINOR.PATCH")
    try:
        check_release_version(sys.argv[1])
    except ValueError as exc:
        raise SystemExit(str(exc))
    print("Release metadata agrees with requested tag; other approval gates still apply")
