pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    // ── Server utama (keepOnReload: true untuk history) ──────────────────
    property NotificationServer server: NotificationServer {
        actionsSupported:    true
        bodySupported:       true
        bodyMarkupSupported: false
        imageSupported:      false
        keepOnReload:        true

        onNotification: notif => {
            notif.tracked = true
            
            // Tambah ke history
            historyModel.insert(0, { "notif": notif })
            
            // Potong kalau terlalu banyak (max 50)
            while (historyModel.count > 50) {
                historyModel.remove(historyModel.count - 1)
            }
            
            // Emit signal untuk popup
            root.newNotification(notif)
        }
    }

    // ── Model history untuk panel ────────────────────────────────────────
    property ListModel historyModel: ListModel {}

    // ── Signal untuk komponen lain ───────────────────────────────────────
    signal newNotification(var notification)

    // ── DND (Do Not Disturb) mode ────────────────────────────────────────
    property bool dnd: false

    // ── Functions ─────────────────────────────────────────────────────────
    function clearHistory() {
        for (let i = 0; i < historyModel.count; i++) {
            const item = historyModel.get(i)
            if (item?.notif) item.notif.dismiss()
        }
        historyModel.clear()
    }

    function removeFromHistory(index) {
        if (index >= 0 && index < historyModel.count) {
            const item = historyModel.get(index)
            if (item?.notif) item.notif.dismiss()
            historyModel.remove(index)
        }
    }
}
