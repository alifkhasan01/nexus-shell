import QtQml
import QtQuick
import Quickshell.Services.Pipewire

// Service untuk auto-promote bluetooth device sebagai default audio sink
// Saat perangkat bluetooth (headphone/dst) terhubung, sink audionya
// dijadikan default agar slider volume di Bar & Dashboard ikut
// mengontrol volume perangkat bluetooth tersebut.
Item {
    id: btPromotion
    visible: false

    Repeater {
        model: Pipewire.nodes

        delegate: Item {
            required property var modelData

            Component.onCompleted: promote()
            onModelDataChanged: promote()

            function promote() {
                try {
                    const sink = modelData
                    if (!sink || !sink.audio || !sink.isSink) return
                    const props = sink.properties || {}
                    if (props["device.bus"] !== "bluetooth") return

                    const cur = Pipewire.defaultAudioSink
                    if (!cur || cur.id !== sink.id) {
                        Pipewire.preferredDefaultAudioSink = sink
                        console.log("[BluetoothPromotion] Set default sink to:", sink.name || sink.id)
                    }
                } catch (e) {
                    console.error("[BluetoothPromotion] Error promoting device:", e.message)
                }
            }
        }
    }
}
