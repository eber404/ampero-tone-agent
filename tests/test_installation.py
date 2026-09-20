import tempfile
import unittest
from pathlib import Path
from unittest import mock

from ampero_control.installation import _candidate_roots, locate_editor


class InstallationTests(unittest.TestCase):
    def _create_macos_editor(self, root: Path) -> None:
        executable = root / "Contents" / "MacOS" / "Ampero II"
        native_library = root / "Contents" / "Frameworks" / "HTUSBTools.dylib"
        catalog = (
            root
            / "Contents"
            / "Frameworks"
            / "App.framework"
            / "Resources"
            / "flutter_assets"
            / "assets"
            / "data"
        )
        executable.parent.mkdir(parents=True)
        executable.touch()
        native_library.parent.mkdir(parents=True)
        native_library.touch()
        catalog.mkdir(parents=True)

    def test_locates_macos_editor_bundle_layout(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "Ampero II.app"
            self._create_macos_editor(root)

            with mock.patch("sys.platform", "darwin"):
                installation = locate_editor(root)

            self.assertEqual(installation.root, root.resolve())
            self.assertEqual(
                installation.executable,
                (root / "Contents" / "MacOS" / "Ampero II").resolve(),
            )
            self.assertEqual(
                installation.native_library,
                (root / "Contents" / "Frameworks" / "HTUSBTools.dylib").resolve(),
            )
            self.assertEqual(
                installation.catalog_directory,
                (
                    root
                    / "Contents"
                    / "Frameworks"
                    / "App.framework"
                    / "Resources"
                    / "flutter_assets"
                    / "assets"
                    / "data"
                ).resolve(),
            )

    def test_macos_candidates_prefer_configured_root(self):
        configured = "/tmp/Configured Ampero II.app"

        with mock.patch.dict(
            "os.environ", {"AMPERO_EDITOR_DIR": configured}, clear=True
        ), mock.patch("sys.platform", "darwin"):
            candidates = list(_candidate_roots())

        self.assertEqual(candidates[0], Path(configured))
        self.assertIn(Path("/Applications/Ampero II.app"), candidates)
        self.assertIn(Path.home() / "Applications" / "Ampero II.app", candidates)


if __name__ == "__main__":
    unittest.main()
