"""Static safety contract for the release workflow (no workflow dispatch).

The tests guard against accidentally restoring commit-message-triggered
publishing. They do not publish anything or prove GitHub's live permissions.
"""
import unittest
from pathlib import Path

from check_release_metadata import (check_release_version, require_publish_metadata_consistency)

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "build-collection.yml"


class TestManualOnlyReleaseWorkflow(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.contents = WORKFLOW.read_text(encoding="utf-8")
        cls.events = cls.contents.split("\non:\n", 1)[1].split(
            "\npermissions:\n", 1
        )[0]
        cls.bundle = cls.contents.split("\n  bundle:\n", 1)[1].split(
            "\n  publish:\n", 1
        )[0]
        cls.publish = cls.contents.split("\n  publish:\n", 1)[1]

    def test_publish_version_metadata_agrees_on_current_baseline(self):
        self.assertTrue(check_release_version("v2.0.0"))
        self.assertIn('python3 scripts/check_release_metadata.py "$VERSION"',
                      self.bundle)
        self.assertIn("""if [[ "$REQUEST_PUBLISH" == 'true' ]]; then""",
                      self.bundle)

    def test_publish_metadata_rejects_mismatched_or_missing_version(self):
        toc = "## Interface: 30300\n## Version: 2.0.0\n"
        core = 'Suite.version = "2.0.0"\n'
        notes = """print('## N Addon Suite v2.0.0')"""
        cases = [
            ("v2.0.1", toc, core, notes),
            ("v1.0.0", toc, core, notes),
            ("v2.0.0-alpha.1", toc, core, notes),
            ("v2.0.0", toc.replace("2.0.0", "2.0.1"), core, notes),
            ("v2.0.0", toc, core.replace("2.0.0", "2.0.1"), notes),
            ("v2.0.0", toc, core, notes.replace("v2.0.0", "v2.0.1")),
            ("v2.0.0", toc, "", notes),
            ("v2.0.0", toc, core, ""),
        ]
        for requested, t, c, n in cases:
            with self.subTest(requested=requested, toc=t, core=c, notes=n):
                with self.assertRaises(ValueError):
                    require_publish_metadata_consistency(requested, t, c, n)
        self.assertTrue(require_publish_metadata_consistency(
            "v2.0.0", toc, core, notes
        ))

    def test_only_manual_dispatch_can_trigger_release_workflow(self):
        self.assertIn("  workflow_dispatch:\n", self.events)
        self.assertNotIn("\n  push:\n", self.events)
        self.assertNotIn("\n  pull_request:\n", self.events)
        self.assertNotIn("startsWith(github.event.head_commit", self.contents)
        self.assertNotIn("VERSION='v2.0.0'", self.contents)

    def test_publish_flag_defaults_false(self):
        section = self.events.split("      publish_release:\n", 1)[1].split(
            "      prerelease:\n", 1
        )[0]
        self.assertIn("default: false", section)
        self.assertIn("type: boolean", section)

    def test_build_job_cannot_publish(self):
        self.assertIn("permissions:\n  contents: read", self.contents)
        self.assertIn("needs: bundle", self.publish)
        self.assertNotIn("gh release create", self.bundle)
        self.assertIn("name: addon-collection-${{ steps.meta.outputs.version }}", self.bundle)

    def test_publish_requires_manual_optin_and_main(self):
        self.assertIn(
            "if: ${{ inputs.publish_release && github.ref == 'refs/heads/main' }}",
            self.publish,
        )
        self.assertIn("permissions:\n      contents: write", self.publish)
        self.assertIn("gh release create", self.publish)
        self.assertIn('gh release view "$VERSION"', self.publish)

    def test_nonmain_publish_request_fails_not_silently_ignored(self):
        self.assertIn("REQUEST_PUBLISH: ${{ inputs.publish_release }}", self.bundle)
        self.assertIn("REQUEST_REF: ${{ github.ref }}", self.bundle)
        self.assertIn(
            """if [[ "$REQUEST_PUBLISH" == 'true' && "$REQUEST_REF" != 'refs/heads/main' ]]; then""",
            self.bundle,
        )

    def test_publish_uses_artifact_from_build_job(self):
        self.assertIn("actions/download-artifact@v4", self.publish)
        self.assertIn("path: dist", self.publish)
        self.assertIn("name: addon-collection-${{ inputs.version }}", self.publish)
        self.assertIn('dist/N-Addon-Collection-$VERSION.zip', self.publish)


if __name__ == "__main__":
    unittest.main()
