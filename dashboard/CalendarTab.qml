pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../" as Root
import "../services"
import "../panels" as Panels

// Tab Kalender di Dashboard — kalender lengkap + event + catatan.
// Content dipindah dari panels/CalendarPanel.qml (PanelWindow → tab).

Item {
    id: cal

    property bool active: false

    onActiveChanged: {
        if (active) {
            const now = new Date()
            today     = now.getDate()
            thisMonth = now.getMonth()
            thisYear  = now.getFullYear()
        }
    }

    // ── State internal kalender ────────────────────────────────────────────
    property int today:      new Date().getDate()
    property int thisMonth:  new Date().getMonth()
    property int thisYear:   new Date().getFullYear()

    property int viewMonth:  thisMonth
    property int viewYear:   thisYear
    property int selectedDay:   today
    property int selectedMonth: thisMonth
    property int selectedYear:  thisYear

    property bool showMonthPicker: false
    property bool showYearPicker: false
    property bool showStats: false

    readonly property var monthNames: [
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ]
    readonly property var dayShort: ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]

    function daysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate()
    }

    function firstDayOfWeek(month, year) {
        const d = new Date(year, month, 1).getDay()
        return (d + 6) % 7
    }

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear-- }
        else viewMonth--
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++ }
        else viewMonth++
    }
    function goToday() {
        const now = new Date()
        viewMonth = now.getMonth()
        viewYear  = now.getFullYear()
        selectedDay   = now.getDate()
        selectedMonth = now.getMonth()
        selectedYear  = now.getFullYear()
    }

    function isToday(day) {
        return day === cal.today
            && cal.viewMonth === cal.thisMonth
            && cal.viewYear  === cal.thisYear
    }

    function isSelected(day) {
        return day === cal.selectedDay
            && cal.viewMonth === cal.selectedMonth
            && cal.viewYear  === cal.selectedYear
    }

    RowLayout {
        anchors {
            fill: parent
            topMargin: 0
            bottomMargin: 0
            leftMargin: 0
            rightMargin: 0
        }
        spacing: 10

        // ═══════════════════════════════════════════════════════════════
        // LEFT: Calendar
        // ═══════════════════════════════════════════════════════════════
        ColumnLayout {
            id: leftCol
            Layout.fillHeight: true
            Layout.preferredWidth: 380
            Layout.topMargin: 0
            Layout.bottomMargin: 0
            spacing: 4

            // ── Header ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 0
                spacing: 0

                Rectangle {
                    width: 28; height: 28; radius: 7
                    color: prevMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰍞"
                        font.pixelSize: 14
                        color: Root.Colors.subtext
                    }
                    MouseArea {
                        id: prevMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cal.prevMonth()
                    }
                }

                Item { Layout.fillWidth: true }

                Column {
                    spacing: 1
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: monthText.implicitWidth + 10
                        height: 24
                        radius: 6
                        color: monthMa.containsMouse ? Root.Colors.surface0 : "transparent"

                        Text {
                            id: monthText
                            anchors.centerIn: parent
                            text: cal.monthNames[cal.viewMonth]
                            font.pixelSize: 14
                            font.bold: true
                            color: Root.Colors.text
                        }

                        MouseArea {
                            id: monthMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cal.showMonthPicker = !cal.showMonthPicker
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: yearText.implicitWidth + 10
                        height: 18
                        radius: 6
                        color: yearMa.containsMouse ? Root.Colors.surface0 : "transparent"

                        Text {
                            id: yearText
                            anchors.centerIn: parent
                            text: cal.viewYear
                            font.pixelSize: 11
                            color: Root.Colors.subtext
                        }

                        MouseArea {
                            id: yearMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cal.showYearPicker = !cal.showYearPicker
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 28; height: 28; radius: 7
                    color: nextMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰍟"
                        font.pixelSize: 14
                        color: Root.Colors.subtext
                    }
                    MouseArea {
                        id: nextMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cal.nextMonth()
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: 7
                    color: statsMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰄶"
                        font.pixelSize: 14
                        color: cal.showStats ? Root.Colors.blue : Root.Colors.subtext
                    }
                    MouseArea {
                        id: statsMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cal.showStats = !cal.showStats
                    }
                }
            }

            // ── Month Picker ───────────────────────────────────────────
            Rectangle {
                visible: cal.showMonthPicker
                Layout.fillWidth: true
                Layout.topMargin: 0
                Layout.bottomMargin: 0
                height: visible ? 90 : 0
                radius: 8
                color: Root.Colors.surface0
                clip: true

                Grid {
                    anchors.centerIn: parent
                    columns: 4
                    spacing: 2

                    Repeater {
                        model: cal.monthNames
                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            width: 84
                            height: 22
                            radius: 5
                            color: {
                                if (index === cal.viewMonth) return Root.Colors.blue
                                if (monthPickerMa.containsMouse) return Root.Colors.surface1
                                return "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 10
                                font.bold: index === cal.viewMonth
                                color: index === cal.viewMonth ? Root.Colors.base : Root.Colors.text
                            }

                            MouseArea {
                                id: monthPickerMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    cal.viewMonth = index
                                    cal.showMonthPicker = false
                                }
                            }
                        }
                    }
                }
            }

            // ── Year Picker ────────────────────────────────────────────
            Rectangle {
                visible: cal.showYearPicker
                Layout.fillWidth: true
                Layout.topMargin: 0
                Layout.bottomMargin: 0
                height: visible ? 110 : 0
                radius: 8
                color: Root.Colors.surface0
                clip: true

                Flickable {
                    anchors.fill: parent
                    contentHeight: yearPickerCol.implicitHeight
                    clip: true

                    Column {
                        id: yearPickerCol
                        anchors.centerIn: parent
                        spacing: 1

                        Repeater {
                            model: 20
                            delegate: Rectangle {
                                required property int index
                                readonly property int year: cal.thisYear - 10 + index
                                width: 90
                                height: 24
                                radius: 5
                                color: {
                                    if (year === cal.viewYear) return Root.Colors.blue
                                    if (yearPickerMa.containsMouse) return Root.Colors.surface1
                                    return "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: year
                                    font.pixelSize: 11
                                    font.bold: year === cal.viewYear
                                    color: year === cal.viewYear ? Root.Colors.base : Root.Colors.text
                                }

                                MouseArea {
                                    id: yearPickerMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        cal.viewYear = year
                                        cal.showYearPicker = false
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Stats ──────────────────────────────────────────────────
            Rectangle {
                visible: cal.showStats
                Layout.fillWidth: true
                Layout.topMargin: 0
                Layout.bottomMargin: 0
                height: visible ? 52 : 0
                radius: 8
                color: Root.Colors.surface0
                clip: true

                Row {
                    anchors.centerIn: parent
                    spacing: 14
                    readonly property var stats: CalendarService.getMonthStats(cal.viewYear, cal.viewMonth)

                    Column {
                        spacing: 1
                        Text {
                            text: stats.totalDays
                            font.pixelSize: 16
                            font.bold: true
                            color: Root.Colors.blue
                        }
                        Text {
                            text: "Total"
                            font.pixelSize: 8
                            color: Root.Colors.subtext
                        }
                    }

                    Column {
                        spacing: 1
                        Text {
                            text: stats.workDays
                            font.pixelSize: 16
                            font.bold: true
                            color: Root.Colors.green
                        }
                        Text {
                            text: "Kerja"
                            font.pixelSize: 8
                            color: Root.Colors.subtext
                        }
                    }

                    Column {
                        spacing: 1
                        Text {
                            text: stats.weekendDays
                            font.pixelSize: 16
                            font.bold: true
                            color: Root.Colors.red
                        }
                        Text {
                            text: "Weekend"
                            font.pixelSize: 8
                            color: Root.Colors.subtext
                        }
                    }

                    Column {
                        spacing: 1
                        Text {
                            text: stats.holidays
                            font.pixelSize: 16
                            font.bold: true
                            color: Root.Colors.peach
                        }
                        Text {
                            text: "Libur"
                            font.pixelSize: 8
                            color: Root.Colors.subtext
                        }
                    }

                    Column {
                        spacing: 1
                        Text {
                            text: stats.events
                            font.pixelSize: 16
                            font.bold: true
                            color: Root.Colors.mauve
                        }
                        Text {
                            text: "Events"
                            font.pixelSize: 8
                            color: Root.Colors.subtext
                        }
                    }
                }
            }

            // ── Day headers ────────────────────────────────────────────
            Row {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 1
                spacing: 0

                Text {
                    width: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: "W"
                    font.pixelSize: 9
                    font.bold: true
                    color: Root.Colors.overlay1
                }

                Repeater {
                    model: cal.dayShort
                    delegate: Text {
                        required property string modelData
                        required property int index

                        width: (leftCol.width - 24) / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: 10
                        font.bold: true
                        color: (index >= 5)
                            ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.85)
                            : Root.Colors.subtext
                    }
                }
            }

            // ── Calendar grid ──────────────────────────────────────────
            Row {
                Layout.fillWidth: true
                Layout.topMargin: 0
                spacing: 0

                // Week numbers
                Column {
                    width: 24
                    spacing: 1

                    Repeater {
                        model: Math.ceil((cal.firstDayOfWeek(cal.viewMonth, cal.viewYear) + cal.daysInMonth(cal.viewMonth, cal.viewYear)) / 7)
                        delegate: Item {
                            required property int index
                            width: 24
                            height: (leftCol.width - 24) / 7

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    const firstDay = index * 7 - cal.firstDayOfWeek(cal.viewMonth, cal.viewYear) + 1
                                    const day = Math.max(1, Math.min(firstDay, cal.daysInMonth(cal.viewMonth, cal.viewYear)))
                                    return CalendarService.getWeekNumber(cal.viewYear, cal.viewMonth, day)
                                }
                                font.pixelSize: 8
                                color: Root.Colors.overlay0
                            }
                        }
                    }
                }

                // Days grid
                Grid {
                    width: leftCol.width - 24
                    columns: 7
                    spacing: 1

                    Repeater {
                        model: cal.firstDayOfWeek(cal.viewMonth, cal.viewYear)
                        delegate: Item {
                            width:  (leftCol.width - 24) / 7
                            height: (leftCol.width - 24) / 7
                        }
                    }

                    Repeater {
                        model: cal.daysInMonth(cal.viewMonth, cal.viewYear)

                        delegate: Item {
                            required property int index
                            readonly property int day: index + 1
                            readonly property int col: (cal.firstDayOfWeek(cal.viewMonth, cal.viewYear) + index) % 7
                            readonly property bool hasEvent: CalendarService.hasEvents(cal.viewYear, cal.viewMonth, day)
                            readonly property bool hasNote: CalendarService.hasNote(cal.viewYear, cal.viewMonth, day)
                            readonly property string holiday: CalendarService.getHoliday(cal.viewYear, cal.viewMonth, day)

                            width:  (leftCol.width - 24) / 7
                            height: (leftCol.width - 24) / 7

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 3
                                height: width
                                radius: width / 2
                                color: {
                                    if (holiday !== "")
                                        return Qt.rgba(Root.Colors.peach.r, Root.Colors.peach.g, Root.Colors.peach.b, 0.15)
                                    if (cal.isSelected(day) && cal.isToday(day))
                                        return Root.Colors.blue
                                    if (cal.isSelected(day))
                                        return Root.Colors.surface1
                                    if (cal.isToday(day))
                                        return Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.22)
                                    if (dayMa.containsMouse)
                                        return Root.Colors.surface0
                                    return "transparent"
                                }
                                border.color: cal.isToday(day) && !cal.isSelected(day)
                                    ? Root.Colors.blue
                                    : holiday !== "" ? Root.Colors.peach : "transparent"
                                border.width: holiday !== "" ? 1.5 : (cal.isToday(day) ? 1.5 : 0)
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 0

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: day
                                        font.pixelSize: 10
                                        font.bold: cal.isToday(day) || cal.isSelected(day)
                                        color: {
                                            if (cal.isSelected(day) && cal.isToday(day))
                                                return Root.Colors.mantle
                                            if (cal.isToday(day))
                                                return Root.Colors.blue
                                            if (holiday !== "")
                                                return Root.Colors.peach
                                            if (col >= 5)
                                                return Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.8)
                                            return Root.Colors.text
                                        }
                                    }

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 1
                                        visible: hasEvent || hasNote

                                        Rectangle {
                                            visible: hasEvent
                                            width: 3
                                            height: 3
                                            radius: 1.5
                                            color: {
                                                const events = CalendarService.getEvents(cal.viewYear, cal.viewMonth, day)
                                                return events.length > 0 ? events[0].color : Root.Colors.blue
                                            }
                                        }

                                        Text {
                                            visible: hasNote
                                            text: "󰷈"
                                            font.pixelSize: 5
                                            color: Root.Colors.yellow
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: dayMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    cal.selectedDay   = day
                                    cal.selectedMonth = cal.viewMonth
                                    cal.selectedYear  = cal.viewYear
                                }
                            }
                        }
                    }
                }
            }

            // ── Footer ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 0
                spacing: 6

                Column {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: {
                            const d = new Date(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
                            const dayNames = ["Min","Sen","Sel","Rab","Kam","Jum","Sab"]
                            return dayNames[d.getDay()] + ", " + cal.selectedDay + " " +
                                   cal.monthNames[cal.selectedMonth].substring(0, 3) + " " + cal.selectedYear
                        }
                        font.pixelSize: 11
                        font.bold: true
                        color: Root.Colors.text
                    }

                    Text {
                        text: {
                            const hijri = CalendarService.toHijri(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
                            return `${hijri.day} ${hijri.monthName.substring(0, 10)} ${hijri.year} H`
                        }
                        font.pixelSize: 10
                        color: Root.Colors.green
                    }
                }

                Row {
                    spacing: 3

                    Rectangle {
                        width: 24; height: 24; radius: 6
                        color: addEventMa.containsMouse ? Root.Colors.blue : Root.Colors.surface0

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.pixelSize: 12
                            color: addEventMa.containsMouse ? Root.Colors.base : Root.Colors.blue
                        }

                        MouseArea {
                            id: addEventMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: eventDialog.showing = true
                        }
                    }

                    Rectangle {
                        width: 24; height: 24; radius: 6
                        color: addNoteMa.containsMouse ? Root.Colors.yellow : Root.Colors.surface0

                        Text {
                            anchors.centerIn: parent
                            text: "󰷈"
                            font.pixelSize: 12
                            color: addNoteMa.containsMouse ? Root.Colors.base : Root.Colors.yellow
                        }

                        MouseArea {
                            id: addNoteMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: noteDialog.showing = true
                        }
                    }

                    Rectangle {
                        visible: !(cal.viewMonth === cal.thisMonth && cal.viewYear === cal.thisYear)
                        width: todayLbl.implicitWidth + 8
                        height: 24
                        radius: 6
                        color: todayBtnMa.containsMouse ? Root.Colors.blue
                             : Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.18)

                        Text {
                            id: todayLbl
                            anchors.centerIn: parent
                            text: "Hari ini"
                            font.pixelSize: 9
                            font.bold: true
                            color: todayBtnMa.containsMouse ? Root.Colors.mantle : Root.Colors.blue
                        }

                        MouseArea {
                            id: todayBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cal.goToday()
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // RIGHT: Events & Notes
        // ═══════════════════════════════════════════════════════════════
        Flickable {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: 280
            Layout.topMargin: 0
            Layout.bottomMargin: 0
            contentHeight: rightCol.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: rightCol
                width: parent.width
                spacing: 6

                Column {
                    width: parent.width
                    spacing: 2

                    Text {
                        width: parent.width
                        text: {
                            const d = new Date(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
                            const dayNames = ["Minggu","Senin","Selasa","Rabu","Kamis","Jumat","Sabtu"]
                            return dayNames[d.getDay()] + ", " + cal.selectedDay + " " +
                                   cal.monthNames[cal.selectedMonth] + " " + cal.selectedYear
                        }
                        font.pixelSize: 12
                        font.bold: true
                        color: Root.Colors.text
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: text !== ""
                        text: {
                            const holiday = CalendarService.getHoliday(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
                            return holiday !== "" ? "󰙳 " + holiday : ""
                        }
                        font.pixelSize: 9
                        color: Root.Colors.peach
                        wrapMode: Text.Wrap
                        width: parent.width
                    }

                    Text {
                        visible: cal.isToday(cal.selectedDay) &&
                                 cal.selectedMonth === cal.thisMonth &&
                                 cal.selectedYear  === cal.thisYear
                        text: "● Hari ini"
                        font.pixelSize: 9
                        color: Root.Colors.blue
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Root.Colors.surface1
                }

                // Events section
                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: " Events"
                        font.pixelSize: 10
                        font.bold: true
                        color: Root.Colors.subtext
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: CalendarService.getEvents(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: eventContent.implicitHeight + 8
                                radius: 6
                                color: Root.Colors.surface0

                                RowLayout {
                                    id: eventContent
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 6

                                    Rectangle {
                                        width: 3
                                        Layout.fillHeight: true
                                        radius: 1.5
                                        color: modelData.color
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: modelData.title
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Root.Colors.text
                                            wrapMode: Text.Wrap
                                            width: parent.width
                                        }

                                        Text {
                                            visible: modelData.time !== ""
                                            text: " " + modelData.time
                                            font.pixelSize: 8
                                            color: Root.Colors.subtext
                                        }
                                    }

                                    Text {
                                        text: "󰆴"
                                        font.pixelSize: 12
                                        color: deleteEventMa.containsMouse ? Root.Colors.red : Root.Colors.overlay0

                                        MouseArea {
                                            id: deleteEventMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                CalendarService.removeEvent(cal.selectedYear, cal.selectedMonth, cal.selectedDay, modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: !CalendarService.hasEvents(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
                            text: "Tidak ada event"
                            font.pixelSize: 9
                            color: Root.Colors.overlay0
                            font.italic: true
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Root.Colors.surface1
                }

                // Notes section
                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: "󰠮 Catatan"
                        font.pixelSize: 10
                        font.bold: true
                        color: Root.Colors.subtext
                    }

                    Rectangle {
                        visible: CalendarService.hasNote(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
                        width: parent.width
                        height: Math.min(notePreviewText.implicitHeight + 12, 160)
                        radius: 6
                        color: Root.Colors.surface0

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 6
                            contentHeight: notePreviewText.implicitHeight
                            clip: true

                            Text {
                                id: notePreviewText
                                width: parent.width
                                text: CalendarService.getNote(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
                                font.pixelSize: 9
                                color: Root.Colors.text
                                wrapMode: Text.Wrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: noteDialog.showing = true
                        }
                    }

                    Text {
                        visible: !CalendarService.hasNote(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
                        text: "Tidak ada catatan"
                        font.pixelSize: 9
                        color: Root.Colors.overlay0
                        font.italic: true
                    }
                }
            }
        }
    }

    // ── Dialogs ────────────────────────────────────────────────────────────
    Panels.EventDialog {
        id: eventDialog
        anchors.fill: parent
        year: cal.selectedYear
        month: cal.selectedMonth
        day: cal.selectedDay
        showing: false

        onAccepted: {
            CalendarService.addEvent(year, month, day, eventTitle, eventTime, eventColor)
            showing = false
        }

        onCancelled: {
            showing = false
        }
    }

    Panels.NoteDialog {
        id: noteDialog
        anchors.fill: parent
        year: cal.selectedYear
        month: cal.selectedMonth
        day: cal.selectedDay
        noteText: CalendarService.getNote(cal.selectedYear, cal.selectedMonth, cal.selectedDay)
        showing: false

        onAccepted: {
            CalendarService.setNote(year, month, day, noteText)
            showing = false
        }

        onCancelled: {
            showing = false
        }
    }

    Connections {
        target: cal
        function onSelectedDayChanged() { noteDialog.noteText = CalendarService.getNote(cal.selectedYear, cal.selectedMonth, cal.selectedDay) }
        function onSelectedMonthChanged() { noteDialog.noteText = CalendarService.getNote(cal.selectedYear, cal.selectedMonth, cal.selectedDay) }
        function onSelectedYearChanged() { noteDialog.noteText = CalendarService.getNote(cal.selectedYear, cal.selectedMonth, cal.selectedDay) }
    }
}
