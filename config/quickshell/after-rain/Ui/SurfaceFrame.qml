import QtQuick
import qs.Generated

Rectangle {
    id: root

    default property alias content: contentHost.data
    property int padding: Theme.panelPadding

    color: Theme.overlay
    radius: Theme.radius
    border.width: 1
    border.color: Theme.border

    Item {
        id: contentHost
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
