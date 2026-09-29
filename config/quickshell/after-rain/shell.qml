//@ pragma ShellId after-rain
//@ pragma AppId dev.afterrain.Shell
//@ pragma StateDir $BASE/after-rain-shell
//@ pragma CacheDir $BASE/after-rain-shell
//@ pragma DropExpensiveFonts

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Core
import qs.Surfaces

ShellRoot {
    id: root

    ShellController {
        id: shellController
    }

    // Deliberately narrow: this endpoint cannot execute caller-supplied commands.
    IpcHandler {
        target: "shell"

        function ping(): string {
            return ShellState.ready && Hyprland.requestSocketPath.length > 0 ? "ok" : "starting";
        }

        function version(): string {
            return "mvp0";
        }

        function toggleKeybindings(): void {
            shellController.toggleKeybindings();
        }

        function showKeybindings(): void {
            shellController.showKeybindings();
        }

        function hideKeybindings(): void {
            shellController.hideKeybindings();
        }

        function reloadBindings(): void {
            shellController.reloadBindings();
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: KeybindingsOverlay {
            required property var modelData

            screen: modelData
            controller: shellController
        }
    }

    Component.onCompleted: shellController.markReady()
}
