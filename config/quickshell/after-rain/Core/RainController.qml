import QtQuick
import Quickshell
import Quickshell.Io
import "RainPolicy.js" as Policy

Item {
    id: root
    property string mode: "normal"
    property string lastActiveMode: "normal"
    property string lastError: ""
    property bool initialized: false
    property var slots: []
    readonly property bool killSwitch: Quickshell.env("AFTER_RAIN_EFFECT") === "off"
    readonly property var caps: Policy.budgets(
        Quickshell.screens.map(s => s.width * s.height), mode)

    FileView {
        id: stateFile
        path: Quickshell.statePath("rain.json")
        atomicWrites: true
        blockWrites: true
        printErrors: false
        onLoaded: {
            if (root.initialized) return;
            try {
                const state = Policy.decode(text());
                root.mode = state.mode;
                root.lastActiveMode = state.lastActiveMode;
            } catch (error) {
                root.lastError = "STATE_INVALID: " + error;
            }
            root.initialized = true;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                root.lastError = "STATE_READ: " + FileViewError.toString(error);
            root.initialized = true;
        }
        onSaveFailed: error => root.lastError = "STATE_WRITE: " + FileViewError.toString(error)
    }

    function setMode(value: string): string {
        if (!Policy.validMode(value))
            return JSON.stringify({ok: false, error: {code: "INVALID_MODE", message: "Use off, light, normal or heavy"}});
        if (!initialized)
            return JSON.stringify({ok: false, error: {code: "STARTING", message: "Rain state is still loading"}});
        mode = value;
        if (value !== "off") lastActiveMode = value;
        lastError = "";
        stateFile.setText(JSON.stringify({schema: 1, mode: mode, lastActiveMode: lastActiveMode}) + "\n");
        if (lastError)
            return JSON.stringify({ok: false, error: {code: "STATE_WRITE", message: lastError}});
        return status();
    }

    function toggle(): string {
        return setMode(mode === "off" ? lastActiveMode : "off");
    }

    function registerSlot(slot): void { slots = slots.concat([slot]); }
    function unregisterSlot(slot): void { slots = slots.filter(s => s !== slot); }

    function status(): string {
        return JSON.stringify({ok: true, data: {schema: 1, requestedMode: mode,
            lastActiveMode: lastActiveMode, initialized: initialized,
            renderer: "glass-droplets", rainStreaks: false, killSwitch: killSwitch,
            statePath: stateFile.path, lastError: lastError,
            screens: slots.map(s => s.snapshot())}});
    }
}
