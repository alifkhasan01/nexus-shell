import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * RotatingAlbumCover.qml
 * Spinning album cover component dengan shadow dan glow effects
 * 
 * Features:
 * - Smooth rotation animation
 * - Pause/resume animation saat pause
 * - Shadow & glow effects
 * - Customizable size
 * - Border styling
 */

Rectangle {
    id: root
    
    // Properties untuk customize
    property url albumArt: ""
    property bool isPlaying: true
    property real rotationSpeed: 20 // seconds untuk full rotation
    property real size: 280
    property color borderColor: "#9C6FDE"
    property real borderWidth: 8
    property real shadowBlur: 30
    
    width: size
    height: size
    radius: size / 2
    color: "transparent"
    
    // Background dark circle
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "#000000"
        opacity: 0.3
    }
    
    // Main rotating image
    Rectangle {
        id: albumContainer
        anchors.fill: parent
        radius: parent.radius
        color: "#1a1a2e"
        
        // Inner glow effect
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: root.borderColor
            border.width: root.borderWidth
            opacity: 0.6
        }
        
        Image {
            id: albumImage
            anchors.centerIn: parent
            width: parent.width - (root.borderWidth * 2)
            height: parent.height - (root.borderWidth * 2)
            sourceSize: Qt.size(width, height)
            source: root.albumArt
            fillMode: Image.PreserveAspectCrop
            
            // Smooth rotation
            transform: Rotation {
                id: imageRotation
                origin.x: albumImage.width / 2
                origin.y: albumImage.height / 2
                angle: 0
            }
            
            // Border radius clipping
            layer.enabled: true
            layer.effect: ShaderEffect {
                fragmentShader: "
                    uniform sampler2D source;
                    uniform float radius;
                    varying vec2 qt_TexCoord0;
                    
                    void main() {
                        vec2 tc = qt_TexCoord0;
                        float r = radius;
                        float d = distance(tc, vec2(0.5, 0.5));
                        
                        if (d > 0.5) {
                            discard;
                        }
                        
                        gl_FragColor = texture2D(source, tc);
                    }
                "
            }
        }
        
        // Outer glow/border styling
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: root.borderColor
            border.width: root.borderWidth
            
            // Glow effect dengan opacity gradient
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: root.borderColor
                border.width: 1
                opacity: 0.3
            }
        }
    }
    
    // Rotation animation - spins continuously when playing
    RotationAnimation {
        id: rotationAnim
        target: imageRotation
        from: 0
        to: 360
        duration: root.rotationSpeed * 1000
        running: root.isPlaying
        loops: Animation.Infinite
    }
    
    // Shadow effect di belakang
    Rectangle {
        id: shadow
        anchors.fill: albumContainer
        radius: albumContainer.radius
        color: root.borderColor
        opacity: 0.15
        z: -1
        
        // Blur shadow dengan offset
        transform: [
            Translate { x: 2; y: 4 }
        ]
    }
    
    // Deep shadow ring effect
    Rectangle {
        anchors.fill: albumContainer
        radius: albumContainer.radius
        color: "transparent"
        border.color: "#000000"
        border.width: 2
        opacity: 0.2
        z: -2
    }
    
    // Handle playing/pausing
    Connections {
        target: root
        function onIsPlayingChanged() {
            if (root.isPlaying) {
                rotationAnim.resume()
            } else {
                rotationAnim.pause()
            }
        }
    }
    
    // Mouse hover effect - slight scale up
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            hoverScale.start()
        }
        
        onExited: {
            hoverScale.stop()
            scaleAnim.to = 1.0
            scaleAnim.start()
        }
    }
    
    SequentialAnimation {
        id: hoverScale
        NumberAnimation {
            id: scaleAnim
            target: albumContainer
            property: "scale"
            to: 1.05
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
}
