import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: surface
    property bool configured: false
    property int liveCap: 0
    property string mode: "normal"
    readonly property string error: texture.status === Image.Error ? "TEXTURE_LOAD: glass-drop.svg" : ""

    visible: configured && liveCap > 0 && texture.status === Image.Ready
    updatesEnabled: visible
    color: "transparent"
    surfaceFormat.opaque: false
    mask: Region {}
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "after-rain-weather"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; right: true; bottom: true; left: true }

    Image {
        id: texture
        visible: false
        source: "../Assets/glass-drop.svg"
        sourceSize.width: 48
        sourceSize.height: 72
    }
    Loader {
        anchors.fill: parent
        active: surface.visible
        sourceComponent: GlassDroplets {
            mode: surface.mode
            beadCount: surface.liveCap
        }
    }
}
