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

            // Salin data notif ke plain object sebelum notif di-expire,
            // agar history panel tetap bisa baca summary/body/appName
            // meski objek Notification aslinya sudah expire.
            const snapshot = {
                appName: notif.appName  || "",
                summary: notif.summary  || "",
                body:    notif.body     || "",
                urgency: notif.urgency,
                // Simpan referensi asli hanya untuk keperluan dismiss
                _ref: notif
            }

            // Tambah ke history
            historyModel.insert(0, { "notif": snapshot })
            
            // Potong kalau terlalu banyak (max 50)
            while (historyModel.count > 50) {
                historyModel.remove(historyModel.count - 1)
            }
            
            // Emit signal untuk popup (kirim objek asli)
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
            const ref = item?.notif?._ref ?? (item?.notif?.dismiss ? item.notif : null)
            if (ref) try { ref.dismiss() } catch(e) {}
        }
        historyModel.clear()
    }

    function removeFromHistory(index) {
        if (index >= 0 && index < historyModel.count) {
            const item = historyModel.get(index)
            // Coba dismiss via referensi asli jika masih ada
            if (item?.notif?._ref) {
                try { item.notif._ref.dismiss() } catch(e) {}
            } else if (item?.notif?.dismiss) {
                try { item.notif.dismiss() } catch(e) {}
            }
            historyModel.remove(index)
        }
    }
}
