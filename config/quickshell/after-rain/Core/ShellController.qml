import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property BindingsModel bindingsModel: BindingsModel {}
    readonly property bool keybindingsVisible: ShellState.keybindingsVisible

    function markReady(): void {
        ShellState.ready = true;
    }

    function showKeybindings(): void {
        ShellState.activeSurface = "keybindings";
        bindingsModel.refresh();
    }

    function hideKeybindings(): void {
        if (ShellState.keybindingsVisible)
            ShellState.activeSurface = "";
    }

    function toggleKeybindings(): void {
        if (ShellState.keybindingsVisible)
            hideKeybindings();
        else
            showKeybindings();
    }

    function reloadBindings(): void {
        bindingsModel.refresh();
    }
}
