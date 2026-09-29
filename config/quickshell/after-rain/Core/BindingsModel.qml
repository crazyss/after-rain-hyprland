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

        const match = /^\[(?:(\d{1,3})\|)?([^\]]+)\]\s*(.*)$/.exec(rawDescription);
        const sectionOrder = match && match[1] ? Number(match[1]) : 500;
        const category = match ? match[2] : "其他";
        const description = match ? match[3] : rawDescription;
        return {
            "keys": keyLabel(record),
            "description": description,
            "category": category,
            "sectionOrder": sectionOrder,
            "dispatcher": String(record.dispatcher || record.handler || ""),
            "submap": String(record.submap || "default"),
            "showCategory": false
        };
    }

    function modifierCount(keys): int {
        const parts = String(keys || "").split("+");
        let count = 0;
        const modifiers = ["Super", "Ctrl", "Alt", "Shift", "Mod2", "Mod3", "Mod5"];
        for (let index = 0; index < parts.length; index++) {
            if (modifiers.indexOf(parts[index]) >= 0)
                count++;
        }
        return count;
    }

    function combinationTier(keys): int {
        const parts = String(keys || "").split("+");
        const hasSuper = parts.indexOf("Super") >= 0;
        const hasShift = parts.indexOf("Shift") >= 0;
        const hasCtrl = parts.indexOf("Ctrl") >= 0;
        const hasAlt = parts.indexOf("Alt") >= 0;

        if (hasSuper) {
            if (!hasShift && !hasCtrl && !hasAlt)
                return 0;
            if (hasShift && !hasCtrl && !hasAlt)
                return 1;
            if (hasCtrl && !hasShift && !hasAlt)
                return 2;
            if (hasAlt && !hasShift && !hasCtrl)
                return 3;
            return 4 + modifierCount(keys);
        }
        if (hasCtrl && !hasShift && !hasAlt)
            return 10;
        if (hasAlt && !hasShift && !hasCtrl)
            return 11;
        if (hasShift && !hasCtrl && !hasAlt)
            return 12;
        if (modifierCount(keys) === 0)
            return String(keys).indexOf("XF86") === 0 ? 14 : 13;
        return 15 + modifierCount(keys);
    }

    function keyRank(keys): int {
        let withinComplexity = 1000;

        let match = /^Super\+(Shift\+)?([0-9])$/.exec(keys);
        if (match !== null) {
            const workspace = Number(match[2]) || 10;
            withinComplexity = 100 + workspace;
        }

        const directionOrder = {
            "Super+←": 300, "Super+→": 301, "Super+↑": 302, "Super+↓": 303,
            "Super+Shift+←": 400, "Super+Shift+→": 401,
            "Super+Shift+↑": 402, "Super+Shift+↓": 403,
            "Super+Ctrl+←": 500, "Super+Ctrl+→": 501,
            "Super+Ctrl+↑": 502, "Super+Ctrl+↓": 503,
            "Super+Ctrl+A": 600, "Super+Ctrl+W": 601, "Super+Ctrl+B": 602,
            "XF86AudioRaiseVolume": 700, "XF86AudioLowerVolume": 701,
            "XF86AudioMute": 702, "XF86AudioPlay": 710,
            "XF86AudioNext": 711, "XF86AudioPrev": 712
        };
        if (directionOrder[keys] !== undefined)
            withinComplexity = directionOrder[keys];
        return combinationTier(keys) * 10000 + withinComplexity;
    }

    function bindingRank(item): int {
        return keyRank(item.keys);
    }

    function compareBindings(left, right): int {
        const sectionDelta = left.sectionOrder - right.sectionOrder;
        if (sectionDelta !== 0)
            return sectionDelta;
        const categoryDelta = left.category.localeCompare(right.category, "zh-CN");
        if (categoryDelta !== 0)
            return categoryDelta;
        const keyDelta = bindingRank(left) - bindingRank(right);
        return keyDelta || left.keys.localeCompare(right.keys, "en");
    }

    function familyFor(item): string {
        if (item.category === "工作区") {
            if (/^工作区 \d+/.test(item.description))
                return "workspace-switch";
            if (/^移动窗口到工作区 \d+/.test(item.description))
                return "workspace-move";
        }
        if (item.category === "窗口") {
            if (/^移动焦点 /.test(item.description))
                return "direction-focus";
            if (/^移动窗口 (left|right|up|down)$/.test(item.description))
                return "direction-move";
            if (/^(缩窄|加宽|缩短|加高)窗口$/.test(item.description))
                return "direction-resize";
        }
        if (item.category === "应用"
                && /^打开(音频混音器|Wi-Fi 管理|蓝牙管理)$/.test(item.description))
            return "system-tools";
        if ((item.category === "通知" || item.category === "桌面")
                && /(通知|勿扰模式)$/.test(item.description))
            return "notifications";
        if (item.category === "硬件") {
            if (/(音量|静音)$/.test(item.description))
                return "volume";
            if (/^(播放或暂停|下一首|上一首)$/.test(item.description))
                return "media";
        }
        return "";
    }

    function copiedItem(item): var {
        return {
            "keys": item.keys,
            "description": item.description,
            "category": item.category,
            "sectionOrder": item.sectionOrder,
            "sourceCategory": item.category,
            "dispatcher": item.dispatcher,
            "submap": item.submap,
            "showCategory": false
        };
    }

    function makeSections(items, compact): var {
        const grouped = {};
        const totals = {};
        const orders = {};
        const familyCounts = {};
        for (let index = 0; index < items.length; index++) {
            const item = items[index];
            const category = item.category;
            if (grouped[category] === undefined) {
                grouped[category] = [];
                totals[category] = 0;
                orders[category] = item.sectionOrder;
            }
            totals[category]++;

            const family = compact ? familyFor(item) : "";
            if (family) {
                const familyIdentity = `${category}\u0000${family}`;
                const seen = familyCounts[familyIdentity] || 0;
                familyCounts[familyIdentity] = seen + 1;
                if (seen >= 2)
                    continue;
            }
            grouped[category].push(copiedItem(item));
        }

        const orderedCategories = Object.keys(grouped);
        orderedCategories.sort((left, right) => {
            const orderDelta = orders[left] - orders[right];
            return orderDelta || left.localeCompare(right, "zh-CN");
        });

        const sections = [];
        for (let categoryIndex = 0; categoryIndex < orderedCategories.length; categoryIndex++) {
            const category = orderedCategories[categoryIndex];
            const sectionItems = grouped[category] || [];
            if (sectionItems.length === 0)
                continue;
            sectionItems.sort((left, right) => {
                const keyDelta = bindingRank(left) - bindingRank(right);
                return keyDelta || left.keys.localeCompare(right.keys, "en");
            });
            sections.push({
                "category": category,
                "sectionOrder": orders[category],
                "items": sectionItems,
                "totalCount": totals[category],
                "hiddenCount": totals[category] - sectionItems.length
            });
        }
        return sections;
    }

    function sections(query): var {
        const needle = String(query || "").trim().toLowerCase();
        const matches = bindings.filter(item => {
            if (!needle)
                return true;
            const haystack = `${item.keys} ${item.description} ${item.category} ${item.submap}`.toLowerCase();
            return haystack.indexOf(needle) >= 0;
        });
        matches.sort(compareBindings);
        return makeSections(matches, !needle);
    }

    function distributeSections(sectionList, requestedColumns): var {
        const columnCount = Math.max(1, Number(requestedColumns) || 1);
        const columns = [];
        const weights = [];
        for (let column = 0; column < columnCount; column++) {
            columns.push([]);
            weights.push(0);
        }
        for (let index = 0; index < sectionList.length; index++) {
            let target = 0;
            for (let column = 1; column < columnCount; column++) {
                if (weights[column] < weights[target])
                    target = column;
            }
            columns[target].push(sectionList[index]);
            weights[target] += sectionList[index].items.length + 1.6;
        }
        return columns;
    }

    function sectionItemCount(sectionList): int {
        let total = 0;
        for (let index = 0; index < sectionList.length; index++)
            total += sectionList[index].items.length;
        return total;
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
        parsed.sort(compareBindings);
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
                "sectionOrder": item.sectionOrder,
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
