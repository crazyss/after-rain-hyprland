import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Core
import qs.Generated
import qs.Ui

PanelWindow {
    id: overlay

    required property ShellController controller

    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property bool targetScreen: hyprlandMonitor !== null && hyprlandMonitor !== undefined
        ? hyprlandMonitor.focused
        : Quickshell.screens.length > 0 && screen === Quickshell.screens[0]
    readonly property var bindingSections: controller.bindingsModel.sections(search.text)
    readonly property int columnCount: panel.width >= 1560 ? 5 : panel.width >= 1180 ? 4
        : panel.width >= 860 ? 3 : 2
    readonly property var sectionColumns: controller.bindingsModel.distributeSections(bindingSections, columnCount)
    readonly property int visibleBindingCount: controller.bindingsModel.sectionItemCount(bindingSections)

    visible: controller.keybindingsVisible && targetScreen
    color: "transparent"
    exclusiveZone: 0
    reloadableId: "after-rain-keybindings"

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.namespace: "after-rain-keybindings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Shortcut {
        sequence: "Escape"
        enabled: overlay.visible
        onActivated: overlay.controller.hideKeybindings()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim

        MouseArea {
            anchors.fill: parent
            onClicked: overlay.controller.hideKeybindings()
        }
    }

    SurfaceFrame {
        id: panel
        anchors.centerIn: parent
        width: Math.min(1720, overlay.width - 96)
        height: Math.min(700, overlay.height - 72)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: mouse => {
                mouse.accepted = true;
            }
        }

        Column {
            anchors.fill: parent
            spacing: Theme.gap

            Row {
                width: parent.width
                height: 44
                spacing: Theme.gap

                Column {
                    width: 226
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "KEYBINDINGS"
                        color: Theme.accent
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.captionSize
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    Text {
                        text: "快捷键总览"
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.titleSize
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width - 226 - closeButton.width - Theme.gap * 2
                    height: 42
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 10
                    color: Theme.surface
                    border.width: search.activeFocus ? 2 : 1
                    border.color: search.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.foreground
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.background
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodySize
                        clip: true

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "搜索按键、动作或领域；搜索时显示全部精确绑定…"
                            visible: !search.text && !search.activeFocus
                            color: Theme.muted
                            font: search.font
                        }

                        Keys.onEscapePressed: overlay.controller.hideKeybindings()
                    }
                }

                Rectangle {
                    id: closeButton
                    width: 36
                    height: 36
                    radius: 9
                    color: closeArea.containsMouse ? Theme.surfaceHigh : Theme.surface
                    border.width: 1
                    border.color: Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.foreground
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: overlay.controller.hideKeybindings()
                    }
                }
            }

            Item {
                width: parent.width
                height: parent.height - y - footer.height - Theme.gap

                Text {
                    anchors.centerIn: parent
                    visible: overlay.controller.bindingsModel.loading
                    text: "正在读取 Hyprland 运行态快捷键…"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodySize
                }

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 620)
                    spacing: 8
                    visible: !overlay.controller.bindingsModel.loading
                        && overlay.controller.bindingsModel.error.length > 0

                    Text {
                        width: parent.width
                        text: "无法载入快捷键"
                        color: Theme.urgent
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.titleSize
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: overlay.controller.bindingsModel.error
                        color: Theme.muted
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodySize
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: !overlay.controller.bindingsModel.loading
                        && !overlay.controller.bindingsModel.error
                        && overlay.visibleBindingCount === 0
                    text: search.text ? "没有匹配的快捷键" : "当前没有带 description 的快捷键"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodySize
                }

                Flickable {
                    id: listView
                    anchors.fill: parent
                    visible: !overlay.controller.bindingsModel.loading
                        && !overlay.controller.bindingsModel.error
                        && overlay.visibleBindingCount > 0
                    contentWidth: width
                    contentHeight: sectionRow.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: sectionRow
                        width: listView.width
                        spacing: Theme.gap

                        Repeater {
                            model: overlay.sectionColumns

                            delegate: Column {
                                required property var modelData

                                width: (sectionRow.width - Theme.gap * (overlay.columnCount - 1))
                                    / overlay.columnCount
                                spacing: Theme.gap

                                Repeater {
                                    model: modelData

                                    delegate: Rectangle {
                                        id: sectionCard
                                        required property var modelData

                                        width: parent.width
                                        height: sectionContent.implicitHeight + 24
                                        radius: 12
                                        color: Theme.surface
                                        border.width: 1
                                        border.color: modelData.category.indexOf("常用") === 0
                                            ? Theme.accent : Theme.border

                                        Column {
                                            id: sectionContent
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 12
                                            spacing: 5

                                            Row {
                                                width: parent.width
                                                height: 24

                                                Text {
                                                    width: parent.width - sectionCount.width
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.category
                                                    color: modelData.category.indexOf("常用") === 0
                                                        ? Theme.accent : Theme.accentWarm
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.captionSize
                                                    font.bold: true
                                                    font.letterSpacing: 1
                                                }

                                                Text {
                                                    id: sectionCount
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.hiddenCount > 0
                                                        ? `${modelData.items.length} 例 · 共 ${modelData.totalCount}`
                                                        : `${modelData.items.length}`
                                                    color: Theme.muted
                                                    font.family: Theme.monoFamily
                                                    font.pixelSize: 10
                                                }
                                            }

                                            Repeater {
                                                model: sectionCard.modelData.items

                                                delegate: Rectangle {
                                                    id: bindingRow
                                                    required property var modelData

                                                    width: parent.width
                                                    height: 38
                                                    radius: 8
                                                    color: bindingArea.containsMouse ? Theme.surfaceHigh : "transparent"

                                                    Row {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 7
                                                        anchors.rightMargin: 7
                                                        spacing: 8

                                                        Text {
                                                            width: parent.width - bindingKeycap.width - 8
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: modelData.description
                                                            color: Theme.foreground
                                                            elide: Text.ElideRight
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: Theme.captionSize
                                                        }

                                                        Keycap {
                                                            id: bindingKeycap
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            label: modelData.keys
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: bindingArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        acceptedButtons: Qt.NoButton
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }
            }

            Text {
                id: footer
                width: parent.width
                text: search.text
                    ? `${overlay.visibleBindingCount} 条匹配 / ${overlay.controller.bindingsModel.count} 条全部 · Hyprland 运行态 · Esc 关闭`
                    : `${overlay.visibleBindingCount} 条重点 / ${overlay.controller.bindingsModel.count} 条全部 · 区域由当前 Profile 定义 · 区内由简单到复杂 · Esc 关闭`
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.captionSize
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            search.text = "";
            search.forceActiveFocus();
        }
    }
}
