import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Core

Item {
    id: root
    required property var modelData
    required property RainController controller
    readonly property var monitor: Hyprland.monitorFor(modelData)
    readonly property int liveCap: controller.caps[Quickshell.screens.indexOf(modelData)] || 0
    readonly property string suppression: !controller.initialized ? "starting"
        : controller.killSwitch ? "kill-switch" : controller.mode === "off" ? "off"
        : !monitor || !monitor.activeWorkspace ? "monitor-unavailable"
        : monitor.activeWorkspace.hasFullscreen ? "fullscreen" : ""

    Component.onCompleted: controller.registerSlot(root)
    Component.onDestruction: controller.unregisterSlot(root)

    // URL loading isolates missing optional QML imports from ShellRoot readiness.
    Loader {
        id: renderer
        active: root.suppression === ""
        source: "RainSurface.qml"
        onLoaded: {
            item.screen = root.modelData;
            item.liveCap = Qt.binding(() => root.liveCap);
            item.mode = Qt.binding(() => root.controller.mode);
            item.configured = true;
        }
    }

    function snapshot() {
        const failed = renderer.status === Loader.Error;
        const error = failed ? "RENDERER_LOAD: check Shell journal"
            : renderer.item ? renderer.item.error : "";
        return {name: modelData.name, liveCap: liveCap,
            effective: suppression ? (suppression === "off" ? "disabled" : "suppressed")
                : error ? "unavailable" : renderer.item && renderer.item.visible ? "running" : "loading",
            suppressedBy: suppression ? [suppression] : [], lastError: error};
    }
}
