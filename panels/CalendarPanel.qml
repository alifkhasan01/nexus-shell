import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../" as Root

// Panel kalender — slide dari tengah atas, anchor ke posisi clock.
// Fitur:
//   • Navigasi bulan (prev/next) + tombol "Hari ini"
//   • Highlight hari ini
//   • Highlight hari yang dipilih
//   • Mini-week header (Sen–Min)
//   • Tampilkan nama bulan + tahun di header
//   • Tahun bisa diklik untuk pindah cepat
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

        width: 320
        height: cardCol.implicitHeight + 14
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

        ColumnLayout {
            id: cardCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 16
                leftMargin: 16
                rightMargin: 16
            }
            spacing: 14

            // ── Header: bulan + tahun + navigasi ──────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                // Tombol prev
                Rectangle {
                    width: 30; height: 30; radius: 8
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

                // Nama bulan + tahun (klik untuk kembali ke hari ini)
                Column {
                    spacing: 0
                    Layout.alignment: Qt.AlignHCenter

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.monthNames[root.viewMonth]
                        font.pixelSize: 17
                        font.bold: true
                        color: Root.Colors.text
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.viewYear
                        font.pixelSize: 12
                        color: Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Item { Layout.fillWidth: true }

                // Tombol next
                Rectangle {
                    width: 30; height: 30; radius: 8
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
            }

            // ── Header hari (Sen Sel Rab…) ─────────────────────────────────
            Row {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: root.dayShort
                    delegate: Text {
                        required property string modelData
                        required property int index

                        width: (card.width - 32) / 7
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

            // ── Grid hari ─────────────────────────────────────────────────
            Grid {
                id: dayGrid
                Layout.fillWidth: true
                columns: 7
                spacing: 2

                // Sel kosong sebelum hari pertama
                Repeater {
                    model: root.firstDayOfWeek(root.viewMonth, root.viewYear)
                    delegate: Item {
                        width:  (card.width - 32) / 7
                        height: (card.width - 32) / 7
                    }
                }

                // Sel hari
                Repeater {
                    model: root.daysInMonth(root.viewMonth, root.viewYear)

                    delegate: Item {
                        required property int index
                        readonly property int day: index + 1
                        readonly property int col: (root.firstDayOfWeek(root.viewMonth, root.viewYear) + index) % 7

                        width:  (card.width - 32) / 7
                        height: (card.width - 32) / 7

                        // Lingkaran highlight
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) - 4
                            height: width
                            radius: width / 2
                            color: {
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
                                : "transparent"
                            border.width: 1.5
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: day
                                font.pixelSize: 13
                                font.bold: root.isToday(day) || root.isSelected(day)
                                color: {
                                    if (root.isSelected(day) && root.isToday(day))
                                        return Root.Colors.mantle   // teks putih/gelap kontras
                                    if (root.isToday(day))
                                        return Root.Colors.blue
                                    if (col >= 5)  // weekend
                                        return Qt.rgba(Root.Colors.red.r, Root.Colors.red.g, Root.Colors.red.b, 0.8)
                                    return Root.Colors.text
                                }
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                        }

                        MouseArea {
                            id: dayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedDay   = day
                                root.selectedMonth = root.viewMonth
                                root.selectedYear  = root.viewYear
                            }
                        }
                    }
                }
            }

            // ── Footer: info hari dipilih + tombol "Hari ini" ─────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Info hari dipilih
                Column {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: {
                            const d = new Date(root.selectedYear, root.selectedMonth, root.selectedDay)
                            const dayNames = ["Minggu","Senin","Selasa","Rabu","Kamis","Jumat","Sabtu"]
                            return dayNames[d.getDay()] + ", " + root.selectedDay + " " +
                                   root.monthNames[root.selectedMonth] + " " + root.selectedYear
                        }
                        font.pixelSize: 12
                        font.bold: true
                        color: Root.Colors.text
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        visible: root.isToday(root.selectedDay) &&
                                 root.selectedMonth === root.thisMonth &&
                                 root.selectedYear  === root.thisYear
                        text: "Hari ini"
                        font.pixelSize: 11
                        color: Root.Colors.blue
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Tombol "Hari ini"
                Rectangle {
                    visible: !(root.viewMonth === root.thisMonth && root.viewYear === root.thisYear)
                    width: todayLbl.implicitWidth + 16
                    height: 26
                    radius: 8
                    color: todayBtnMa.containsMouse ? Root.Colors.blue
                         : Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.18)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: todayLbl
                        anchors.centerIn: parent
                        text: "Hari ini"
                        font.pixelSize: 11
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

            // ── Spacer bawah ───────────────────────────────────────────────
            Item { implicitHeight: 4 }
        }
    }
}
