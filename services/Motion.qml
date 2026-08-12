pragma Singleton
import QtQuick

// ── Kurva easing MD3 (Material Design 3) ────────────────────────────────
// Dipakai lewat:  easing.type: Easing.Bezier
//                  easing.bezierCurve: Motion.<kurva>
// Sumber: https://m3.material.io/styles/motion/easing-and-duration
QtObject {
    // Standard emphasized — transisi umum / Behavior kecil
    readonly property var standard:      [0.20, 0.0, 0.0, 1.0]

    // Emphasized decelerate — elemen masuk (open / enter)
    readonly property var enter:         [0.05, 0.7, 0.1, 1.0]

    // Emphasized accelerate — elemen keluar (close / exit)
    readonly property var exit:          [0.30, 0.0, 1.0, 1.0]

    // Linear out slow in — transisi kontinu yang halus
    readonly property var linearOutSlowIn: [0.0, 0.0, 0.2, 1.0]
}