pragma Singleton

import Quickshell

Singleton {
    property bool ready: false
    property string activeSurface: ""
    property string lastError: ""

    readonly property bool keybindingsVisible: activeSurface === "keybindings"
}
