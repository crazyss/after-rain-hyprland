import QtQuick
import Quickshell.Io

Item {
    id: root
    required property RainController controller
    IpcHandler {
        target: "rain"
        function setMode(mode: string): string { return root.controller.setMode(mode); }
        function toggle(): string { return root.controller.toggle(); }
        function status(): string { return root.controller.status(); }
    }
}
