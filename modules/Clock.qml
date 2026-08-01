import QtQuick
import Quickshell
import "../" as Root

Text {
    id: root

    property string timeFormat: "ddd, dd MMM  •  HH:mm:ss"
    signal clicked()

    text: Qt.formatDateTime(clock.date, timeFormat)
    color: Root.Colors.text
    font.pixelSize: 14
    font.bold: true

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
