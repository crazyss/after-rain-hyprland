import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var bindings: []
    property bool loading: false
    property string error: ""
    readonly property int count: bindings.length

    function prettyKey(key): string {
        const value = String(key || "?");
        const aliases = {
            "return": "Enter",
            "escape": "Esc",
            "space": "Space",
            "left": "←",
            "right": "→",
            "up": "↑",
            "down": "↓",
            "comma": ",",
            "period": ".",
            "slash": "/"
        };
        return aliases[value.toLowerCase()] || value;
    }

    function keyLabel(record): string {
        const mask = Number(record.modmask || 0);
        const parts = [];
        const modifiers = [
            [64, "Super"],
            [4, "Ctrl"],
            [8, "Alt"],
            [1, "Shift"],
            [16, "Mod2"],
            [32, "Mod3"],
            [128, "Mod5"]
        ];
        for (let index = 0; index < modifiers.length; index++) {
            if (mask & modifiers[index][0])
                parts.push(modifiers[index][1]);
        }

        let key = record.key;
        if (key === undefined || key === null || String(key).length === 0)
            key = record.keycode !== undefined ? `code:${record.keycode}` : "?";
        parts.push(prettyKey(key));
        return parts.join("+");
    }

    function describedBinding(record): var {
        const rawDescription = String(record.description || "").trim();
        if (!rawDescription)
            return null;

        const match = /^\[([^\]]+)\]\s*(.*)$/.exec(rawDescription);
        const category = match ? match[1] : "其他";
        const description = match ? match[2] : rawDescription;
        return {
            "keys": keyLabel(record),
            "description": description,
            "category": category,
            "dispatcher": String(record.dispatcher || record.handler || ""),
            "submap": String(record.submap || "default"),
            "showCategory": false
        };
    }

    function parsePayload(payload): void {
        const start = payload.indexOf("[");
        if (start < 0)
            throw new Error("hyprctl 没有返回绑定列表");

        const records = JSON.parse(payload.slice(start));
        if (!Array.isArray(records))
            throw new Error("hyprctl binds 返回值不是数组");

        const unique = {};
        for (let index = 0; index < records.length; index++) {
            const item = describedBinding(records[index]);
            if (item === null)
                continue;
            const identity = `${item.keys}\u0000${item.description}\u0000${item.submap}`;
            unique[identity] = item;
        }

        const parsed = Object.keys(unique).map(key => unique[key]);
        parsed.sort((left, right) => {
            const categoryOrder = left.category.localeCompare(right.category, "zh-CN");
            return categoryOrder || left.keys.localeCompare(right.keys, "en");
        });
        let previousCategory = "";
        for (let index = 0; index < parsed.length; index++) {
            parsed[index].showCategory = parsed[index].category !== previousCategory;
            previousCategory = parsed[index].category;
        }

        bindings = parsed;
        error = "";
        loading = false;
    }

    function filtered(query): var {
        const needle = String(query || "").trim().toLowerCase();
        const result = [];
        let previousCategory = "";
        for (let index = 0; index < bindings.length; index++) {
            const item = bindings[index];
            const haystack = `${item.keys} ${item.description} ${item.category} ${item.submap}`.toLowerCase();
            if (needle && haystack.indexOf(needle) < 0)
                continue;
            result.push({
                "keys": item.keys,
                "description": item.description,
                "category": item.category,
                "dispatcher": item.dispatcher,
                "submap": item.submap,
                "showCategory": item.category !== previousCategory
            });
            previousCategory = item.category;
        }
        return result;
    }

    function refresh(): void {
        error = "";
        loading = true;
        timeout.restart();
        // Fixed argv only. No caller-controlled command reaches Process.
        hyprctl.exec(["hyprctl", "-j", "binds"]);
    }

    property Process hyprctlProcess: Process {
        id: hyprctl
        command: ["hyprctl", "-j", "binds"]

        stdout: StdioCollector {
            id: stdoutCollector
            onStreamFinished: {
                try {
                    root.parsePayload(text);
                } catch (exception) {
                    root.error = `无法解析运行态快捷键：${exception}`;
                    root.loading = false;
                }
            }
        }

        stderr: StdioCollector {
            id: stderrCollector
        }

        onExited: function(exitCode, exitStatus) {
            timeout.stop();
            if (exitCode !== 0) {
                const detail = stderrCollector.text.trim();
                root.error = detail ? `hyprctl 失败：${detail}` : `hyprctl 退出码 ${exitCode}`;
                root.loading = false;
            }
        }
    }

    property Timer timeoutTimer: Timer {
        id: timeout
        interval: 2500
        repeat: false
        onTriggered: {
            if (hyprctl.running)
                hyprctl.signal(15);
            root.error = "读取快捷键超时，请确认当前 Hyprland 会话可用。";
            root.loading = false;
        }
    }
}
