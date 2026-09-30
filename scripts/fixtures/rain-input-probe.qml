//@ pragma ShellId after-rain-input-probe
//@ pragma AppId dev.afterrain.InputProbe
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    FloatingWindow {
        id: probe
        title: "After Rain input probe"
        implicitWidth: 420
        implicitHeight: 260
        color: "#131b27"
        visible: true
        property int motions: 0
        property int clicks: 0
        Text {
            anchors.centerIn: parent
            text: "Rain input probe\nMouse motion: " + probe.motions + "\nClicks: " + probe.clicks
            color: "white"
            font.pixelSize: 22
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: probe.motions++
            onClicked: probe.clicks++
        }
    }
    IpcHandler {
        target: "probe"
        function status(): string { return JSON.stringify({motions: probe.motions, clicks: probe.clicks}); }
        function setFullscreen(value: bool): void { probe.fullscreen = value; }
    }
}
