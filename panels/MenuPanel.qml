import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
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
            // Reset scroll position ke atas setiap kali menu dibuka
            if (appList) {
                appList.positionViewAtBeginning()
                appList.currentIndex = 0
            }
        } else {
            // Reset ke posisi default: filter kategori "All", PWA tampil,
            // index kategori awal, dan fokus kembali ke search.
            menuModel.category = "All"
            navState.categoryIndex = 0
            navState.showWebApps = true
            navState.focusArea = "search"
            // Reset scroll position saat menu ditutup juga untuk memastikan
            if (appList) {
                appList.positionViewAtBeginning()
                appList.currentIndex = 0
            }
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
                                     "Graphics","Network","Office","Settings","Utility","WebApps"]
        property bool showWebApps: true  // toggle untuk show/hide PWA
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

        // Helper function untuk deteksi PWA/Web apps dari berbagai browser
        function isWebApp(app) {
            if (!app) return false
            
            // Cek dari path .desktop file
            const desktopId = app.id || ""
            // Chrome, Chromium, Brave, Edge, Vivaldi, Opera
            if (desktopId.includes("chrome-") || 
                desktopId.includes("chromium-") || 
                desktopId.includes("brave-") ||
                desktopId.includes("msedge-") ||
                desktopId.includes("vivaldi-") ||
                desktopId.includes("opera-")) {
                return true
            }
            
            // Cek dari exec command
            const exec = app.exec || ""
            // Flag apps dari Chromium-based browsers
            if (exec.includes("--app-id=") || 
                exec.includes("--app=") ||
                exec.includes("--profile-directory=")) {
                return true
            }
            
            // Cek dari icon path (PWA biasanya punya icon di browser profile)
            const icon = app.icon || ""
            if ((icon.includes("chrome") || 
                 icon.includes("chromium") || 
                 icon.includes("brave") || 
                 icon.includes("edge") || 
                 icon.includes("vivaldi") ||
                 icon.includes("opera")) && 
                (icon.includes("Profile") || icon.includes("Default"))) {
                return true
            }
            
            return false
        }

        function update() {
            const q    = searchText.trim().toLowerCase()
            const src  = [...DesktopEntries.applications.values]
            const out  = []

            for (let i = 0; i < src.length; i++) {
                const a = src[i]
                if (!a) continue

                const isWebAppEntry = isWebApp(a)

                // filter kategori
                if (category === "WebApps") {
                    // Kategori WebApps: hanya tampilkan PWA
                    if (!isWebAppEntry) continue
                } else if (category !== "All") {
                    // Kategori lain: filter berdasarkan categories
                    const cats = a.categories || []
                    let found  = false
                    for (let j = 0; j < cats.length; j++) {
                        if (cats[j].toLowerCase() === category.toLowerCase()) {
                            found = true; break
                        }
                    }
                    if (!found) continue
                } else {
                    // Kategori "All": filter PWA berdasarkan toggle
                    if (isWebAppEntry && !navState.showWebApps) continue
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

        onSearchTextChanged:   {
            update()
            // Reset scroll ke atas setiap kali search berubah
            if (appList) {
                appList.positionViewAtBeginning()
                appList.currentIndex = 0
            }
        }
        onCategoryChanged:     {
            update()
            // Reset scroll ke atas setiap kali kategori berubah
            if (appList) {
                appList.positionViewAtBeginning()
                appList.currentIndex = 0
            }
        }
        onAllChanged:          update()
        Component.onCompleted: update()
    }
    
    // Update saat toggle WebApps berubah
    Connections {
        target: navState
        function onShowWebAppsChanged() { 
            menuModel.update()
            // Reset scroll ke atas saat toggle WebApps berubah
            if (appList) {
                appList.positionViewAtBeginning()
                appList.currentIndex = 0
            }
        }
    }

    // ── Kartu ─────────────────────────────────────────────────────────────
    FocusScope {
        id: card

        x:      100
        y:      5      // tepat di bawah bar (margin top 6px + bar 45px + gap 2px)
        width:  700
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
                    NumberAnimation  { target: cardTx; property: "y"; duration: Root.Appearance.animation.elementMoveEnter.duration; easing.type: Root.Appearance.animation.elementMoveEnter.type; easing.bezierCurve: Root.Appearance.animation.elementMoveEnter.bezierCurve }
                    OpacityAnimator  { target: card; duration: Root.Appearance.animation.elementMoveEnter.duration }
                }
            },
            // Animasi CLOSE: Slide up ke atas dengan fade out
            // Duration: 150ms untuk exit yang cepat
            // ScriptAction menyembunyikan panel setelah animasi selesai
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation  { target: cardTx; property: "y"; duration: Root.Appearance.animation.elementMoveExit.duration; easing.type: Root.Appearance.animation.elementMoveExit.type; easing.bezierCurve: Root.Appearance.animation.elementMoveExit.bezierCurve }
                        OpacityAnimator  { target: card; duration: Root.Appearance.animation.elementMoveExit.duration }
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
            Behavior on border.color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

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
                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "󰣇"
                            font.pixelSize: 20
                            color: Root.Colors.blue
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                        }
                        Text {
                            text: "Applications"
                            font.pixelSize: 15
                            font.bold: true
                            color: Root.Colors.text
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                        }
                        
                        // Toggle button untuk PWA
                        Rectangle {
                            visible: menuModel.category === "All"  // hanya tampil di kategori "All"
                            width: 28
                            height: 28
                            radius: 8
                            color: navState.showWebApps ? Root.Colors.green : Root.Colors.surface1
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "󰖟"  // icon Chrome/web
                                font.pixelSize: 14
                                color: navState.showWebApps ? Root.Colors.base : Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }
                            
                            MouseArea {
                                id: webAppToggle
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: navState.showWebApps = !navState.showWebApps
                            }
                            
                            // Hover effect
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: webAppToggle.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }
                        }
                        
                        Text {
                            text: menuModel.results.length + " apps"
                            font.pixelSize: 11
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                        }
                        
                        // Settings button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 8
                            color: Root.Colors.surface1
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "⚙️"
                                font.pixelSize: 14
                                color: Root.Colors.text
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }
                            
                            MouseArea {
                                id: settingsBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    console.log("[MenuPanel] Opening settings...")
                                    settingsProc.running = true
                                    root.closeRequested()
                                }
                            }
                            
                            // Hover effect
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: settingsBtn.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                            }
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
                    Behavior on border.color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.pixelSize: 16
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
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
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                        }

                        // Tombol clear
                        Rectangle {
                            visible: searchInput.text.length > 0
                            width: 18; height: 18; radius: 9
                            color: clearMa.containsMouse ? Root.Colors.surface2 : Root.Colors.surface1
                            Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
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

                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

                                    Text {
                                        id: catLbl
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 11
                                        color: (menuModel.category === modelData || (navState.focusArea === "categories" && navState.categoryIndex === index))
                                            ? Root.Colors.base
                                            : Root.Colors.subtext
                                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
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
                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }

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

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData ? (modelData.name || "") : ""
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Root.Colors.text
                                        elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                    }
                                    
                                    // Badge PWA
                                    Rectangle {
                                        visible: modelData && menuModel.isWebApp(modelData)
                                        Layout.preferredWidth: pwaText.implicitWidth + 8
                                        Layout.preferredHeight: 16
                                        radius: 4
                                        color: Root.Colors.green
                                        opacity: 0.9
                                        
                                        Text {
                                            id: pwaText
                                            anchors.centerIn: parent
                                            text: "PWA"
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Root.Colors.base
                                        }
                                    }
                                }
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData ? (modelData.genericName || "") : ""
                                    font.pixelSize: 11
                                    color: Root.Colors.subtext
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
                                }
                            }

                            Text {
                                text: "󰅂"
                                font.pixelSize: 14
                                color: Root.Colors.subtext
                                Behavior on color { ColorAnimation { duration: Root.Appearance.animation.elementMoveFast.duration; easing.type: Root.Appearance.animation.elementMoveFast.type; easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve } }
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
    
    // ── Settings launcher process ──────────────────────────────────────────
    Process {
        id: settingsProc
        command: ["sh", "-c", "cd ~/.config/quickshell && quickshell -p settings.qml &"]
    }
}
