import QtQuick
import Quickshell
import "../../" as Root

Text {
    id: root

    property string timeFormat: "HH:mm" // "ddd, dd MMM  •  HH:mm"
    signal clicked()
    signal rightClicked()

    text: Qt.formatDateTime(clock.date, timeFormat)
    color: Root.Colors.blue
    font.pixelSize: 16
    font.bold: true

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else root.clicked()
        }
    }
}
