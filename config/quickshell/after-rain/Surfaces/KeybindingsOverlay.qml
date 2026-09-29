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
    readonly property var filteredBindings: controller.bindingsModel.filtered(search.text)

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
        width: Math.min(920, overlay.width - 48)
        height: Math.min(700, overlay.height - 48)

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
                spacing: Theme.gap

                Column {
                    width: parent.width - closeButton.width - Theme.gap
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

            Rectangle {
                width: parent.width
                height: 44
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
                        text: "搜索按键、动作、类别或 submap…"
                        visible: !search.text && !search.activeFocus
                        color: Theme.muted
                        font: search.font
                    }

                    Keys.onEscapePressed: overlay.controller.hideKeybindings()
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
                        && overlay.filteredBindings.length === 0
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
                        && overlay.filteredBindings.length > 0
                    contentWidth: width
                    contentHeight: bindingColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: bindingColumn
                        width: listView.width
                        spacing: 4

                        Repeater {
                            model: overlay.filteredBindings

                            delegate: Column {
                                required property var modelData

                                width: bindingColumn.width
                                spacing: 4

                                Text {
                                    visible: modelData.showCategory
                                    height: visible ? 34 : 0
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData.category
                                    color: Theme.accentWarm
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.captionSize
                                    font.bold: true
                                }

                                Rectangle {
                                    width: parent.width
                                    height: Theme.rowHeight
                                    radius: 10
                                    color: rowArea.containsMouse ? Theme.surfaceHigh : "transparent"

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: Theme.gap

                                        Column {
                                            width: parent.width - keycap.width - Theme.gap
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            Text {
                                                width: parent.width
                                                text: modelData.description
                                                color: Theme.foreground
                                                elide: Text.ElideRight
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.bodySize
                                            }

                                            Text {
                                                visible: modelData.submap !== "default" && modelData.submap !== ""
                                                text: `submap · ${modelData.submap}`
                                                color: Theme.muted
                                                font.family: Theme.monoFamily
                                                font.pixelSize: 10
                                            }
                                        }

                                        Keycap {
                                            id: keycap
                                            anchors.verticalCenter: parent.verticalCenter
                                            label: modelData.keys
                                        }
                                    }

                                    MouseArea {
                                        id: rowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
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
                text: `${overlay.filteredBindings.length} / ${overlay.controller.bindingsModel.count} · Hyprland 运行态 · Esc 关闭`
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
