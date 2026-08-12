import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../" as Root

PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }
    color: Qt.rgba(0, 0, 0, 0)  // Fully transparent (tidak ada warna putih)
    visible: showPanel

    property bool showPanel: false
    onOpenChanged: {
        if (open) {
            showPanel = true
            menuModel.searchText = ""
            searchInput.text = ""
            menuModel.update()  // refresh lagi saat dibuka, kalau DesktopEntries belum selesai dimuat
            navState.focusArea = "search"
            searchInput.forceActiveFocus()
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-menu"
    WlrLayershell.exclusiveZone: 0

    // ── Navigation state ──────────────────────────────────────────────────
    QtObject {
        id: navState
        property string focusArea: "search"  // "search", "categories", "applist"
        property int categoryIndex: 0
        property var categoryList: ["All","AudioVideo","Development","Game",
                                     "Graphics","Network","Office","Settings","Utility"]
    }

    // ── Background sync apps saat startup ──────────────────────────────────
    // Pastikan DesktopEntries sudah dimuat dan di-update saat pertama kali
    // quickshell dimulai, sehingga saat menu dibuka pertama kali, aplikasi
    // sudah tersedia tanpa perlu berpindah filter kategori.
    Component.onCompleted: {
        // Trigger initial sync dengan set kategori ke "All" dan update
        menuModel.category = "All"
        menuModel.update()
    }

    // ── Tutup klik di luar ────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeRequested()
    }

    // ── Model aplikasi ────────────────────────────────────────────────────
    QtObject {
        id: menuModel

        property string searchText: ""
        property string category:   "All"
        property var    results:    []

        readonly property var all: DesktopEntries.applications
        // DesktopEntries.applications terisi asinkron; count berubah → panggil update()
        property int appCount: DesktopEntries.applications.count || 0
        onAppCountChanged: update()

        function update() {
            const q    = searchText.trim().toLowerCase()
            const src  = [...DesktopEntries.applications.values]
            const out  = []

            for (let i = 0; i < src.length; i++) {
                const a = src[i]
                if (!a) continue

                // filter kategori
                if (category !== "All") {
                    const cats = a.categories || []
                    let found  = false
                    for (let j = 0; j < cats.length; j++) {
                        if (cats[j].toLowerCase() === category.toLowerCase()) {
                            found = true; break
                        }
                    }
                    if (!found) continue
                }

                // filter search
                if (q !== "") {
                    const haystack = [
                        a.name        || "",
                        a.genericName || "",
                        a.comment     || "",
                        (a.keywords   || []).join(" ")
                    ].join(" ").toLowerCase()
                    if (!haystack.includes(q)) continue
                }

                out.push(a)
            }

            out.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
            results = out
        }

        onSearchTextChanged:   update()
        onCategoryChanged:     update()
        onAllChanged:          update()
        Component.onCompleted: update()
    }

    // ── Kartu ─────────────────────────────────────────────────────────────
    FocusScope {
        id: card

        x:      12
        y:      6      // tepat di bawah bar (margin top 6px + bar 45px + gap 2px)
        width:  590
        height: Math.min(660, root.height - y - 12)
        focus: true

        // ── Animasi masuk / keluar ─────────────────────────────────────
        // Initial state: card tersembunyi dan sedikit di atas posisi final
        opacity: 0
        transform: Translate { id: cardTx; y: -10 }

        // State management untuk animasi open/close
        states: State {
            name: "open"; when: root.open
            PropertyChanges { target: card;   opacity: 1        }
            PropertyChanges { target: cardTx; y: 0              }
        }
        
        // Transisi animasi untuk menu panel
        transitions: [
            // Animasi OPEN: Slide down dari atas dengan fade in
            // Duration: 200ms untuk entrance yang cepat dan responsive
            Transition {
                from: ""; to: "open"
                ParallelAnimation {
                    NumberAnimation  { target: cardTx; property: "y";       duration: 200; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.enter }
                    OpacityAnimator  { target: card;                         duration: 180; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.enter }
                }
            },
            // Animasi CLOSE: Slide up ke atas dengan fade out
            // Duration: 150ms untuk exit yang cepat
            // ScriptAction menyembunyikan panel setelah animasi selesai
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation  { target: cardTx; property: "y";   duration: 150; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.exit }
                        OpacityAnimator  { target: card;                     duration: 140; easing.type: Easing.Bezier; easing.bezierCurve: Root.Motion.exit }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        // ── Global keyboard handler ────────────────────────────────────
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Tab) {
                event.accepted = true
                if (navState.focusArea === "search") {
                    navState.focusArea = "categories"
                    navState.categoryIndex = navState.categoryList.indexOf(menuModel.category)
                    if (navState.categoryIndex < 0) navState.categoryIndex = 0
                    categoryFocusItem.forceActiveFocus()
                } else if (navState.focusArea === "categories") {
                    navState.focusArea = "applist"
                    if (appList.count > 0) {
                        appList.currentIndex = 0
                        appList.forceActiveFocus()
                    } else {
                        navState.focusArea = "search"
                        searchInput.forceActiveFocus()
                    }
                } else if (navState.focusArea === "applist") {
                    navState.focusArea = "search"
                    searchInput.forceActiveFocus()
                }
            } else if (event.key === Qt.Key_Escape) {
                event.accepted = true
                root.closeRequested()
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color:  Root.Colors.base
            border.color: Root.Colors.surface1
            border.width: 1

            Behavior on color        { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            // blokir klik di dalam kartu
            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // ── Header ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: 10
                    color: Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "󰣇"
                            font.pixelSize: 20
                            color: Root.Colors.blue
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: "Applications"
                            font.pixelSize: 15
                            font.bold: true
                            color: Root.Colors.text
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: menuModel.results.length + " apps"
                            font.pixelSize: 11
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }

                // ── Search ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 10
                    color: Root.Colors.surface0
                    border.color: searchInput.activeFocus ? Root.Colors.blue : "transparent"
                    border.width: 1
                    Behavior on color        { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.pixelSize: 16
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholderText: "Search applications..."
                            placeholderTextColor: Root.Colors.subtext
                            color: Root.Colors.text
                            font.pixelSize: 13
                            background: null
                            selectByMouse: true
                            onTextChanged: menuModel.searchText = text
                            onActiveFocusChanged: {
                                if (activeFocus) navState.focusArea = "search"
                            }
                            Keys.onEscapePressed: root.closeRequested()
                            Keys.onDownPressed: {
                                // Pindah langsung ke app list saat arrow down
                                if (appList.count > 0) {
                                    navState.focusArea = "applist"
                                    appList.currentIndex = 0
                                    appList.forceActiveFocus()
                                }
                            }
                            Keys.onReturnPressed: {
                                // Enter di search: langsung jalankan app pertama jika ada
                                if (appList.count > 0 && menuModel.results[0]) {
                                    menuModel.results[0].execute()
                                    root.closeRequested()
                                }
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Tombol clear
                        Rectangle {
                            visible: searchInput.text.length > 0
                            width: 18; height: 18; radius: 9
                            color: clearMa.containsMouse ? Root.Colors.surface2 : Root.Colors.surface1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.pixelSize: 10
                                color: Root.Colors.subtext
                            }
                            MouseArea {
                                id: clearMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }

                // ── Categories ────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    implicitHeight: catRow.implicitHeight

                    // Invisible focus item untuk categories
                    Item {
                        id: categoryFocusItem
                        focus: navState.focusArea === "categories"
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Left) {
                                event.accepted = true
                                navState.categoryIndex = Math.max(0, navState.categoryIndex - 1)
                                menuModel.category = navState.categoryList[navState.categoryIndex]
                            } else if (event.key === Qt.Key_Right) {
                                event.accepted = true
                                navState.categoryIndex = Math.min(navState.categoryList.length - 1, navState.categoryIndex + 1)
                                menuModel.category = navState.categoryList[navState.categoryIndex]
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                event.accepted = true
                                // Just apply the current category (already applied via arrow keys)
                            }
                        }
                    }

                    Flickable {
                        anchors.fill: parent
                        contentWidth: catRow.implicitWidth
                        clip: true
                        interactive: contentWidth > width

                        Row {
                            id: catRow
                            spacing: 6

                            Repeater {
                                model: navState.categoryList

                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index

                                    height: 28
                                    width: catLbl.implicitWidth + 20
                                    radius: 8

                                    color: {
                                        if (navState.focusArea === "categories" && navState.categoryIndex === index)
                                            return Root.Colors.mauve
                                        if (menuModel.category === modelData)
                                            return Root.Colors.blue
                                        if (catMa.containsMouse)
                                            return Root.Colors.surface1
                                        return Root.Colors.surface0
                                    }

                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        id: catLbl
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 11
                                        color: (menuModel.category === modelData || (navState.focusArea === "categories" && navState.categoryIndex === index))
                                            ? Root.Colors.base
                                            : Root.Colors.subtext
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                    }

                                    MouseArea {
                                        id: catMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            menuModel.category = modelData
                                            navState.categoryIndex = index
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── App list ──────────────────────────────────────────────
                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 2
                    model: menuModel.results
                    highlightFollowsCurrentItem: true
                    keyNavigationEnabled: true

                    onActiveFocusChanged: {
                        if (activeFocus) navState.focusArea = "applist"
                    }

                    Keys.onUpPressed: {
                        // Jika di item pertama, kembali ke search
                        if (currentIndex === 0) {
                            navState.focusArea = "search"
                            searchInput.forceActiveFocus()
                        } else {
                            // Default behavior: pindah ke item atas
                            decrementCurrentIndex()
                        }
                    }

                    Keys.onReturnPressed: {
                        if (currentItem && currentItem.modelData) {
                            currentItem.modelData.execute()
                            root.closeRequested()
                        }
                    }

                    Keys.onEnterPressed: {
                        if (currentItem && currentItem.modelData) {
                            currentItem.modelData.execute()
                            root.closeRequested()
                        }
                    }

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        required property var  modelData
                        required property int  index

                        width: appList.width
                        height: 54
                        radius: 10
                        color: {
                            if (appList.currentIndex === index && navState.focusArea === "applist")
                                return Root.Colors.surface2
                            if (itemMa.containsMouse)
                                return Root.Colors.surface1
                            return "transparent"
                        }
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            IconImage {
                                Layout.preferredWidth:  34
                                Layout.preferredHeight: 34
                                source: modelData
                                    ? Quickshell.iconPath(modelData.icon, true)
                                    : ""
                                asynchronous: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData ? (modelData.name || "") : ""
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Root.Colors.text
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData ? (modelData.genericName || "") : ""
                                    font.pixelSize: 11
                                    color: Root.Colors.subtext
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            Text {
                                text: "󰅂"
                                font.pixelSize: 14
                                color: Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData) modelData.execute()
                                root.closeRequested()
                            }
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: appList.count === 0
                        text: "No apps found"
                        font.pixelSize: 13
                        color: Root.Colors.subtext
                    }
                }
            }
        }
    }
}
