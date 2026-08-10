import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../" as Root
import "../services"

// Panel kalender — Versi Lengkap dengan banyak fitur!
// Fitur:
//   • Navigasi bulan (prev/next) + tombol "Hari ini"
//   • Highlight hari ini & hari yang dipilih
//   • Event system dengan color picker
//   • Catatan harian (notes)
//   • Week numbers (ISO 8601)
//   • Hari libur nasional Indonesia
//   • Kalender Hijriyah
//   • Quick jump (dropdown tahun/bulan)
//   • Statistik bulanan
//   • Integrasi dengan todo widget
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    property bool showPanel: false
    onOpenChanged: {
        if (open) {
            showPanel = true
            const now = new Date()
            today     = now.getDate()
            thisMonth = now.getMonth()
            thisYear  = now.getFullYear()
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-calendar"
    WlrLayershell.exclusiveZone: 0

    // ── State internal kalender ────────────────────────────────────────────
    property int today:      new Date().getDate()
    property int thisMonth:  new Date().getMonth()      // 0-based
    property int thisYear:   new Date().getFullYear()

    property int viewMonth:  thisMonth
    property int viewYear:   thisYear
    property int selectedDay:   today
    property int selectedMonth: thisMonth
    property int selectedYear:  thisYear

    // UI state
    property bool showMonthPicker: false
    property bool showYearPicker: false
    property bool showStats: false

    // Nama bulan dalam Bahasa Indonesia
    readonly property var monthNames: [
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ]
    readonly property var dayShort: ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]

    // Jumlah hari dalam bulan
    function daysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate()
    }

    // Hari pertama bulan ini (0=Sun…6=Sat → convert ke Mon-first: 0=Mon…6=Sun)
    function firstDayOfWeek(month, year) {
        const d = new Date(year, month, 1).getDay() // 0=Sun
        return (d + 6) % 7 // Monday-first
    }

    // Navigasi
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

    // Cek apakah hari tertentu = hari ini
    function isToday(day) {
        return day === root.today
            && root.viewMonth === root.thisMonth
            && root.viewYear  === root.thisYear
    }

    // Cek apakah hari tertentu = hari dipilih
    function isSelected(day) {
        return day === root.selectedDay
            && root.viewMonth === root.selectedMonth
            && root.viewYear  === root.selectedYear
    }

    // Reset selected ke hari ini setiap kali panel dibuka — sudah di-handle di onOpenChanged atas

    // ── Klik luar untuk tutup ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeRequested()
    }

    // ── Kartu ──────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        // Posisi: tengah atas, tepat di bawah bar
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter

        width: 720
        height: Math.max(leftCol.implicitHeight, rightCol.implicitHeight) + 28
        radius: 18
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2

        // ── Animasi masuk/keluar ───────────────────────────────────────────
        opacity: 0
        transform: [
            Scale {
                id: cardScale
                xScale: 0.92
                yScale: 0.92
                origin.x: card.width / 2
                origin.y: 0
            },
            Translate { id: cardTranslate; y: -20 }
        ]

        states: State {
            name: "open"
            when: root.open
            PropertyChanges { target: card;          opacity: 1 }
            PropertyChanges { target: cardScale;     xScale: 1; yScale: 1 }
            PropertyChanges { target: cardTranslate; y: 0 }
        }

        transitions: [
            Transition {
                from: ""; to: "open"
                ParallelAnimation {
                    NumberAnimation { targets: [cardScale];     properties: "xScale,yScale"; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
                    NumberAnimation { target: cardTranslate;   property: "y";              duration: 220; easing.type: Easing.OutCubic }
                    OpacityAnimator { target: card;             duration: 180; easing.type: Easing.OutCubic }
                }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { targets: [cardScale];     properties: "xScale,yScale"; duration: 160; easing.type: Easing.InCubic }
                        NumberAnimation { target: cardTranslate;   property: "y";              duration: 160; easing.type: Easing.InCubic }
                        OpacityAnimator { target: card;             duration: 140; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation { duration: 150 } }

        // Blokir klik di dalam kartu
        MouseArea { anchors.fill: parent; onClicked: {} }

        RowLayout {
            id: mainRow
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 16

            // ═══════════════════════════════════════════════════════════════
            // LEFT COLUMN: Calendar
            // ═══════════════════════════════════════════════════════════════
            ColumnLayout {
                id: leftCol
                Layout.fillHeight: true
                Layout.preferredWidth: 420
                spacing: 14

            // ── Header: bulan + tahun + navigasi ──────────────────────────
            RowLayout {
                width: leftCol.width
                spacing: 0

                // Tombol prev
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: prevMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰍞"
                        font.family: "CaskaydiaCove Nerd Font"
                        font.pixelSize: 16
                        color: Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: prevMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevMonth()
                    }
                }

                Item { Layout.fillWidth: true }

                // Nama bulan (clickable untuk quick picker)
                Column {
                    spacing: 2
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: monthText.implicitWidth + 12
                        height: 26
                        radius: 6
                        color: monthMa.containsMouse ? Root.Colors.surface0 : "transparent"
                        
                        Text {
                            id: monthText
                            anchors.centerIn: parent
                            text: root.monthNames[root.viewMonth]
                            font.pixelSize: 16
                            font.bold: true
                            color: Root.Colors.text
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: monthMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showMonthPicker = !root.showMonthPicker
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: yearText.implicitWidth + 12
                        height: 20
                        radius: 6
                        color: yearMa.containsMouse ? Root.Colors.surface0 : "transparent"

                        Text {
                            id: yearText
                            anchors.centerIn: parent
                            text: root.viewYear
                            font.pixelSize: 12
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: yearMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showYearPicker = !root.showYearPicker
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Tombol next
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: nextMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰍟"
                        font.family: "CaskaydiaCove Nerd Font"
                        font.pixelSize: 16
                        color: Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: nextMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextMonth()
                    }
                }

                // Tombol stats
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: statsMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰄶"
                        font.family: "CaskaydiaCove Nerd Font"
                        font.pixelSize: 16
                        color: root.showStats ? Root.Colors.blue : Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: statsMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showStats = !root.showStats
                    }
                }
            }

            // ── Quick Pickers (Month & Year) ──────────────────────────────
            Rectangle {
                visible: root.showMonthPicker
                width: leftCol.width
                height: visible ? monthPickerGrid.implicitHeight + 12 : 0
                radius: 10
                color: Root.Colors.surface0
                clip: true

                Grid {
                    id: monthPickerGrid
                    anchors {
                        centerIn: parent
                        margins: 6
                    }
                    columns: 4
                    spacing: 4

                    Repeater {
                        model: root.monthNames
                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            width: 90
                            height: 28
                            radius: 6
                            color: {
                                if (index === root.viewMonth) return Root.Colors.blue
                                if (monthPickerMa.containsMouse) return Root.Colors.surface1
                                return "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 11
                                font.bold: index === root.viewMonth
                                color: index === root.viewMonth ? Root.Colors.base : Root.Colors.text
                            }

                            MouseArea {
                                id: monthPickerMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.viewMonth = index
                                    root.showMonthPicker = false
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.showYearPicker
                width: leftCol.width
                height: visible ? 140 : 0
                radius: 10
                color: Root.Colors.surface0
                clip: true

                Flickable {
                    anchors.fill: parent
                    contentHeight: yearPickerCol.implicitHeight
                    clip: true

                    Column {
                        id: yearPickerCol
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: 20
                            delegate: Rectangle {
                                required property int index
                                readonly property int year: root.thisYear - 10 + index
                                width: 100
                                height: 28
                                radius: 6
                                color: {
                                    if (year === root.viewYear) return Root.Colors.blue
                                    if (yearPickerMa.containsMouse) return Root.Colors.surface1
                                    return "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: year
                                    font.pixelSize: 12
                                    font.bold: year === root.viewYear
                                    color: year === root.viewYear ? Root.Colors.base : Root.Colors.text
                                }

                                MouseArea {
                                    id: yearPickerMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.viewYear = year
                                        root.showYearPicker = false
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Statistik Bulanan ──────────────────────────────────────────
            Rectangle {
                visible: root.showStats
                width: leftCol.width
                height: visible ? statsCol.implicitHeight + 16 : 0
                radius: 10
                color: Root.Colors.surface0
                clip: true

                Column {
                    id: statsCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 6

                    Text {
                        text: "󰃭 Statistik Bulan Ini"
                        font.pixelSize: 12
                        font.bold: true
                        color: Root.Colors.text
                        font.family: "CaskaydiaCove Nerd Font"
                    }

                    Row {
                        spacing: 20
                        readonly property var stats: CalendarService.getMonthStats(root.viewYear, root.viewMonth)

                        Column {
                            spacing: 2
                            Text {
                                text: stats.totalDays
                                font.pixelSize: 18
                                font.bold: true
                                color: Root.Colors.blue
                            }
                            Text {
                                text: "Total Hari"
                                font.pixelSize: 9
                                color: Root.Colors.subtext
                            }
                        }

                        Column {
                            spacing: 2
                            Text {
                                text: stats.workDays
                                font.pixelSize: 18
                                font.bold: true
                                color: Root.Colors.green
                            }
                            Text {
                                text: "Hari Kerja"
                                font.pixelSize: 9
                                color: Root.Colors.subtext
                            }
                        }

                        Column {
                            spacing: 2
                            Text {
                                text: stats.weekendDays
                                font.pixelSize: 18
                                font.bold: true
                                color: Root.Colors.red
                            }
                            Text {
                                text: "Weekend"
                                font.pixelSize: 9
                                color: Root.Colors.subtext
                            }
                        }

                        Column {
                            spacing: 2
                            Text {
                                text: stats.holidays
                                font.pixelSize: 18
                                font.bold: true
                                color: Root.Colors.peach
                            }
                            Text {
                                text: "Libur Nasional"
                                font.pixelSize: 9
                                color: Root.Colors.subtext
                            }
                        }

                        Column {
                            spacing: 2
                            Text {
                                text: stats.events
                                font.pixelSize: 18
                                font.bold: true
                                color: Root.Colors.mauve
                            }
                            Text {
                                text: "Events"
                                font.pixelSize: 9
                                color: Root.Colors.subtext
                            }
                        }
                    }
                }
            }
            // ── Header hari (Sen Sel Rab…) ─────────────────────────────────
            Row {
                width: leftCol.width
                spacing: 0

                // Week number column header
                Text {
                    width: 28
                    horizontalAlignment: Text.AlignHCenter
                    text: "W"
                    font.pixelSize: 10
                    font.bold: true
                    color: Root.Colors.overlay1
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Repeater {
                    model: root.dayShort
                    delegate: Text {
                        required property string modelData
                        required property int index

                        width: (leftCol.width - 28) / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: 11
                        font.bold: true
                        // Sabtu=5, Minggu=6 → merah
                        color: (index >= 5)
                            ? Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.85)
                            : Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // ── Grid hari dengan Week Numbers ─────────────────────────────
            Row {
                width: leftCol.width
                spacing: 0

                // Week numbers column
                Column {
                    width: 28
                    spacing: 2

                    Repeater {
                        model: Math.ceil((root.firstDayOfWeek(root.viewMonth, root.viewYear) + root.daysInMonth(root.viewMonth, root.viewYear)) / 7)
                        delegate: Item {
                            required property int index
                            width: 28
                            height: (leftCol.width - 28) / 7

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    const firstDay = index * 7 - root.firstDayOfWeek(root.viewMonth, root.viewYear) + 1
                                    const day = Math.max(1, Math.min(firstDay, root.daysInMonth(root.viewMonth, root.viewYear)))
                                    return CalendarService.getWeekNumber(root.viewYear, root.viewMonth, day)
                                }
                                font.pixelSize: 9
                                color: Root.Colors.overlay0
                            }
                        }
                    }
                }

                // Calendar grid
                Grid {
                    id: dayGrid
                    width: leftCol.width - 28
                    columns: 7
                    spacing: 2

                // Sel kosong sebelum hari pertama
                Repeater {
                    model: root.firstDayOfWeek(root.viewMonth, root.viewYear)
                    delegate: Item {
                        width:  (leftCol.width - 28) / 7
                        height: (leftCol.width - 28) / 7
                    }
                }

                // Sel hari
                Repeater {
                    model: root.daysInMonth(root.viewMonth, root.viewYear)

                    delegate: Item {
                        required property int index
                        readonly property int day: index + 1
                        readonly property int col: (root.firstDayOfWeek(root.viewMonth, root.viewYear) + index) % 7
                        readonly property bool hasEvent: CalendarService.hasEvents(root.viewYear, root.viewMonth, day)
                        readonly property bool hasNote: CalendarService.hasNote(root.viewYear, root.viewMonth, day)
                        readonly property string holiday: CalendarService.getHoliday(root.viewYear, root.viewMonth, day)

                        width:  (leftCol.width - 28) / 7
                        height: (leftCol.width - 28) / 7

                        // Lingkaran highlight
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) - 4
                            height: width
                            radius: width / 2
                            color: {
                                if (holiday !== "") 
                                    return Qt.rgba(Root.Colors.peach.r, Root.Colors.peach.g, Root.Colors.peach.b, 0.15)
                                if (root.isSelected(day) && root.isToday(day))
                                    return Root.Colors.blue
                                if (root.isSelected(day))
                                    return Root.Colors.surface1
                                if (root.isToday(day))
                                    return Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.22)
                                if (dayMa.containsMouse)
                                    return Root.Colors.surface0
                                return "transparent"
                            }
                            border.color: root.isToday(day) && !root.isSelected(day)
                                ? Root.Colors.blue
                                : holiday !== "" ? Root.Colors.peach : "transparent"
                            border.width: holiday !== "" ? 1.5 : (root.isToday(day) ? 1.5 : 0)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 1

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: day
                                    font.pixelSize: 12
                                    font.bold: root.isToday(day) || root.isSelected(day)
                                    color: {
                                        if (root.isSelected(day) && root.isToday(day))
                                            return Root.Colors.mantle
                                        if (root.isToday(day))
                                            return Root.Colors.blue
                                        if (holiday !== "")
                                            return Root.Colors.peach
                                        if (col >= 5)
                                            return Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.8)
                                        return Root.Colors.text
                                    }
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }

                                // Event & Note indicators
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 2
                                    visible: hasEvent || hasNote

                                    // Event dot
                                    Rectangle {
                                        visible: hasEvent
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: {
                                            const events = CalendarService.getEvents(root.viewYear, root.viewMonth, day)
                                            return events.length > 0 ? events[0].color : Root.Colors.blue
                                        }
                                    }

                                    // Note indicator
                                    Text {
                                        visible: hasNote
                                        text: "󰷈"
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: 6
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
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                root.selectedDay   = day
                                root.selectedMonth = root.viewMonth
                                root.selectedYear  = root.viewYear
                            }
                        }
                    }
                }
            }
        }

            // ── Footer: Date info & action buttons ────────────────────────
            RowLayout {
                width: leftCol.width
                spacing: 8

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: {
                            const d = new Date(root.selectedYear, root.selectedMonth, root.selectedDay)
                            const dayNames = ["Min","Sen","Sel","Rab","Kam","Jum","Sab"]
                            return dayNames[d.getDay()] + ", " + root.selectedDay + " " +
                                   root.monthNames[root.selectedMonth].substring(0, 3) + " " + root.selectedYear
                        }
                        font.pixelSize: 11
                        font.bold: true
                        color: Root.Colors.text
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        text: {
                            const hijri = CalendarService.toHijri(root.selectedYear, root.selectedMonth, root.selectedDay)
                            return `${hijri.day} ${hijri.monthName.substring(0, 10)} ${hijri.year} H`
                        }
                        font.pixelSize: 9
                        color: Root.Colors.green
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Quick action buttons
                Row {
                    spacing: 4

                    // Add event button
                    Rectangle {
                        width: 28; height: 28; radius: 7
                        color: addEventMa.containsMouse ? Root.Colors.blue : Root.Colors.surface0
                        Behavior on color { ColorAnimation { duration: 100 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 14
                            color: addEventMa.containsMouse ? Root.Colors.base : Root.Colors.blue
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: addEventMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: eventDialog.showing = true
                        }
                    }

                    // Add note button
                    Rectangle {
                        width: 28; height: 28; radius: 7
                        color: addNoteMa.containsMouse ? Root.Colors.yellow : Root.Colors.surface0
                        Behavior on color { ColorAnimation { duration: 100 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰷈"
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 14
                            color: addNoteMa.containsMouse ? Root.Colors.base : Root.Colors.yellow
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: addNoteMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: noteDialog.showing = true
                        }
                    }

                    // Today button
                    Rectangle {
                        visible: !(root.viewMonth === root.thisMonth && root.viewYear === root.thisYear)
                        width: todayLbl.implicitWidth + 10
                        height: 28
                        radius: 7
                        color: todayBtnMa.containsMouse ? Root.Colors.blue
                             : Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.18)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: todayLbl
                            anchors.centerIn: parent
                            text: "Hari ini"
                            font.pixelSize: 10
                            font.bold: true
                            color: todayBtnMa.containsMouse ? Root.Colors.mantle : Root.Colors.blue
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: todayBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.goToday()
                        }
                    }
                }
            }
        }  // End leftCol

            // ═══════════════════════════════════════════════════════════════
            // RIGHT COLUMN: Events & Notes
            // ═══════════════════════════════════════════════════════════════
            ColumnLayout {
                id: rightCol
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 260
                spacing: 12

                // Header with date & holiday
                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        width: parent.width
                        text: {
                            const d = new Date(root.selectedYear, root.selectedMonth, root.selectedDay)
                            const dayNames = ["Minggu","Senin","Selasa","Rabu","Kamis","Jumat","Sabtu"]
                            return dayNames[d.getDay()] + ", " + root.selectedDay + " " +
                                   root.monthNames[root.selectedMonth] + " " + root.selectedYear
                        }
                        font.pixelSize: 13
                        font.bold: true
                        color: Root.Colors.text
                        wrapMode: Text.Wrap
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        visible: text !== ""
                        text: {
                            const holiday = CalendarService.getHoliday(root.selectedYear, root.selectedMonth, root.selectedDay)
                            return holiday !== "" ? "󰙳 " + holiday : ""
                        }
                        font.pixelSize: 10
                        color: Root.Colors.peach
                        font.family: "CaskaydiaCove Nerd Font"
                        wrapMode: Text.Wrap
                        width: parent.width
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        visible: root.isToday(root.selectedDay) &&
                                 root.selectedMonth === root.thisMonth &&
                                 root.selectedYear  === root.thisYear
                        text: "● Hari ini"
                        font.pixelSize: 10
                        color: Root.Colors.blue
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Root.Colors.surface1
                }

                // Events section
                Column {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: " Events"
                        font.pixelSize: 11
                        font.bold: true
                        color: Root.Colors.subtext
                        font.family: "CaskaydiaCove Nerd Font"
                    }

                    // Events list or empty state
                    Column {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: CalendarService.getEvents(root.selectedYear, root.selectedMonth, root.selectedDay)
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: eventContent.implicitHeight + 12
                                radius: 8
                                color: Root.Colors.surface0

                                RowLayout {
                                    id: eventContent
                                    anchors {
                                        fill: parent
                                        margins: 6
                                    }
                                    spacing: 8

                                    Rectangle {
                                        width: 4
                                        Layout.fillHeight: true
                                        radius: 2
                                        color: modelData.color
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.title
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: Root.Colors.text
                                            wrapMode: Text.Wrap
                                            width: parent.width
                                        }

                                        Text {
                                            visible: modelData.time !== ""
                                            text: " " + modelData.time
                                            font.pixelSize: 9
                                            color: Root.Colors.subtext
                                            font.family: "CaskaydiaCove Nerd Font"
                                        }
                                    }

                                    Text {
                                        text: "󰆴"
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: 14
                                        color: deleteEventMa.containsMouse ? Root.Colors.red : Root.Colors.overlay0
                                        
                                        MouseArea {
                                            id: deleteEventMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                CalendarService.removeEvent(root.selectedYear, root.selectedMonth, root.selectedDay, modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Empty state
                        Text {
                            visible: !CalendarService.hasEvents(root.selectedYear, root.selectedMonth, root.selectedDay)
                            text: "Tidak ada event"
                            font.pixelSize: 10
                            color: Root.Colors.overlay0
                            font.italic: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Root.Colors.surface1
                }

                // Notes section
                Column {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Text {
                        text: "󰠮 Catatan"
                        font.pixelSize: 11
                        font.bold: true
                        color: Root.Colors.subtext
                        font.family: "CaskaydiaCove Nerd Font"
                    }

                    // Note display or empty state
                    Rectangle {
                        visible: CalendarService.hasNote(root.selectedYear, root.selectedMonth, root.selectedDay)
                        width: parent.width
                        height: Math.min(notePreviewText.implicitHeight + 16, 200)
                        radius: 8
                        color: Root.Colors.surface0

                        Flickable {
                            anchors {
                                fill: parent
                                margins: 8
                            }
                            contentHeight: notePreviewText.implicitHeight
                            clip: true

                            Text {
                                id: notePreviewText
                                width: parent.width
                                text: CalendarService.getNote(root.selectedYear, root.selectedMonth, root.selectedDay)
                                font.pixelSize: 10
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
                        visible: !CalendarService.hasNote(root.selectedYear, root.selectedMonth, root.selectedDay)
                        text: "Tidak ada catatan"
                        font.pixelSize: 10
                        color: Root.Colors.overlay0
                        font.italic: true
                    }
                }

                Item { Layout.fillHeight: true }
            }  // End rightCol
        }  // End mainRow
    }

    // ── Dialogs ────────────────────────────────────────────────────────────
    EventDialog {
        id: eventDialog
        anchors.fill: parent
        year: root.selectedYear
        month: root.selectedMonth
        day: root.selectedDay
        showing: false

        onAccepted: {
            CalendarService.addEvent(year, month, day, eventTitle, eventTime, eventColor)
            showing = false
        }

        onCancelled: {
            showing = false
        }
    }

    NoteDialog {
        id: noteDialog
        anchors.fill: parent
        year: root.selectedYear
        month: root.selectedMonth
        day: root.selectedDay
        noteText: CalendarService.getNote(root.selectedYear, root.selectedMonth, root.selectedDay)
        showing: false

        onAccepted: {
            CalendarService.setNote(year, month, day, noteText)
            showing = false
        }

        onCancelled: {
            showing = false
        }
    }

    // Connection to refresh dialogs when date changes
    Connections {
        target: root
        function onSelectedDayChanged() { noteDialog.noteText = CalendarService.getNote(root.selectedYear, root.selectedMonth, root.selectedDay) }
        function onSelectedMonthChanged() { noteDialog.noteText = CalendarService.getNote(root.selectedYear, root.selectedMonth, root.selectedDay) }
        function onSelectedYearChanged() { noteDialog.noteText = CalendarService.getNote(root.selectedYear, root.selectedMonth, root.selectedDay) }
    }
}
