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
            try {
                notif.tracked = true

                // Simpan sebagai flat roles — ListModel tidak bisa menyimpan
                // nested JS object yang mengandung QObject pointer dengan aman.
                historyModel.insert(0, {
                    "appName": notif.appName || "",
                    "summary": notif.summary || "",
                    "body":    notif.body    || "",
                    "urgency": notif.urgency !== undefined ? notif.urgency : 1
                })

                // Potong kalau terlalu banyak (max 50)
                while (historyModel.count > 50) {
                    historyModel.remove(historyModel.count - 1)
                }

                // Emit signal untuk popup (kirim objek asli)
                root.newNotification(notif)
            } catch(e) {
                console.error("Error handling notification:", e)
            }
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
        historyModel.clear()
    }

    function removeFromHistory(index) {
        if (index >= 0 && index < historyModel.count) {
            historyModel.remove(index)
        }
    }
}
