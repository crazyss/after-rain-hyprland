import QtQuick
import qs.Generated

Rectangle {
    id: root

    required property string label

    implicitWidth: keyLabel.implicitWidth + 20
    implicitHeight: 30
    radius: 8
    color: Theme.keycap
    border.width: 1
    border.color: Theme.border

    Text {
        id: keyLabel
        anchors.centerIn: parent
        text: root.label
        color: Theme.foreground
        font.family: Theme.monoFamily
        font.pixelSize: Theme.captionSize
        font.weight: Font.DemiBold
    }
}
