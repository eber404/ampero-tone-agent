import unittest
from unittest import mock

from ampero_control import dart_bridge
from ampero_control.dart_bridge import DartBridgeTransport


class DartBridgeTransportTests(unittest.TestCase):
    def test_macos_uses_extensionless_executables(self):
        with mock.patch("sys.platform", "darwin"):
            self.assertEqual(
                getattr(dart_bridge, "_bridge_executable_name", lambda: None)(),
                "ampero_bridge",
            )
            self.assertEqual(
                getattr(dart_bridge, "_dart_executable_name", lambda: None)(), "dart"
            )

    def test_windows_uses_exe_executables(self):
        with mock.patch("sys.platform", "win32"):
            self.assertEqual(
                getattr(dart_bridge, "_bridge_executable_name", lambda: None)(),
                "ampero_bridge.exe",
            )
            self.assertEqual(
                getattr(dart_bridge, "_dart_executable_name", lambda: None)(),
                "dart.exe",
            )

    def test_connect_propagates_editor_override_to_scan(self):
        transport = DartBridgeTransport.__new__(DartBridgeTransport)
        scan = {
            "device_name": "Ampero II Stomp",
            "input_indices": [1],
            "output_indices": [2],
        }

        with mock.patch(
            "ampero_control.dart_bridge.official_editor_is_running", return_value=True
        ), mock.patch.object(transport, "scan", return_value=scan) as run_scan:
            transport.connect(1, 2, allow_editor_running=True)

        run_scan.assert_called_once_with(
            "Ampero II Stomp", allow_editor_running=True
        )


if __name__ == "__main__":
    unittest.main()
