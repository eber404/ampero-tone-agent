import unittest
from pathlib import Path
from unittest import mock

from ampero_control.errors import NativeLibraryError
from ampero_control.installation import EditorInstallation
from ampero_control.native import NativeTransport, official_editor_is_running


class NativeTransportTests(unittest.TestCase):
    def test_macos_editor_process_is_detected(self):
        result = mock.Mock(returncode=0, stdout="")

        with mock.patch("sys.platform", "darwin"), mock.patch(
            "ampero_control.native.os.name", "posix"
        ), mock.patch(
            "ampero_control.native.subprocess.run", return_value=result
        ) as run:
            self.assertTrue(official_editor_is_running())

        run.assert_called_once_with(
            ["/usr/bin/pgrep", "-x", "Ampero II"],
            check=False,
            capture_output=True,
            text=True,
        )

    def test_macos_editor_process_absence_is_detected(self):
        result = mock.Mock(returncode=1, stdout="")

        with mock.patch("sys.platform", "darwin"), mock.patch(
            "ampero_control.native.os.name", "posix"
        ), mock.patch(
            "ampero_control.native.subprocess.run", return_value=result
        ):
            self.assertFalse(official_editor_is_running())

    def test_macos_editor_process_query_fails_closed(self):
        result = mock.Mock(returncode=2, stdout="permission denied")

        with mock.patch("sys.platform", "darwin"), mock.patch(
            "ampero_control.native.os.name", "posix"
        ), mock.patch(
            "ampero_control.native.subprocess.run", return_value=result
        ), self.assertRaises(NativeLibraryError):
            official_editor_is_running()

    def test_windows_editor_process_query_fails_closed(self):
        result = mock.Mock(returncode=2, stdout="ERROR")

        with mock.patch("sys.platform", "win32"), mock.patch(
            "ampero_control.native.os.name", "nt"
        ), mock.patch(
            "ampero_control.native.subprocess.run", return_value=result
        ), self.assertRaises(NativeLibraryError):
            official_editor_is_running()

    def test_macos_loads_vendor_dylib(self):
        installation = EditorInstallation(
            root=Path("/Applications/Ampero II.app"),
            executable=Path("/Applications/Ampero II.app/Contents/MacOS/Ampero II"),
            native_library=Path(
                "/Applications/Ampero II.app/Contents/Frameworks/HTUSBTools.dylib"
            ),
            catalog_directory=Path(
                "/Applications/Ampero II.app/Contents/Frameworks/"
                "App.framework/Resources/flutter_assets/assets/data"
            ),
        )

        with mock.patch("sys.platform", "darwin"), mock.patch(
            "ampero_control.native.os.name", "posix"
        ), mock.patch(
            "ampero_control.native.ctypes.CDLL"
        ) as load_library, mock.patch.object(
            NativeTransport, "_configure_functions"
        ):
            NativeTransport(installation)

        load_library.assert_called_once_with(str(installation.native_library))

    def test_connected_operations_require_dart_bridge(self):
        transport = NativeTransport.__new__(NativeTransport)

        with self.assertRaises(NativeLibraryError):
            transport.connect()
        with self.assertRaises(NativeLibraryError):
            transport.request(0x01040002)


if __name__ == "__main__":
    unittest.main()
