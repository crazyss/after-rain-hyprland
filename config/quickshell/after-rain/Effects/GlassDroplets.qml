import QtQuick

// Capped population of attached water beads. No particle system.
// No desktop capture: edge light approximates glass without sampling other apps.
Item {
    id: glass
    property string mode: "normal"
    property int beadCount: 0
    property double previousTick: Date.now()

    // One bounded clock avoids a full-screen redraw at the monitor's native rate.
    Timer {
        interval: 33
        repeat: true
        running: glass.beadCount > 0
        onTriggered: {
            const now = Date.now();
            const delta = Math.max(0, Math.min(100, now - glass.previousTick));
            glass.previousTick = now;
            for (let i = 0; i < beads.count; ++i) {
                const bead = beads.itemAt(i);
                if (bead) bead.advance(delta);
            }
        }
    }

    Repeater {
        id: beads
        model: glass.beadCount
        delegate: Item {
            id: bead
            required property int index
            property real originX: 0
            property real originY: 0
            property real distance: 0
            property real age: 0
            readonly property real slideAge: Math.max(0, age - 1400 - holdTime)
            readonly property real progress: Math.min(1, slideAge / slideTime)
            readonly property real travel: distance * progress * progress * progress
            property real diameter: 10
            property real drift: 0
            property int holdTime: 2000
            property int slideTime: 6000
            property real strength: 0.8
            readonly property real appearance: Math.max(0, Math.min(1, age / 1400,
                1 - (slideAge - slideTime) / 900))
            readonly property bool moving: slideAge > 0
            property real bend: 0
            readonly property real growth: 0.65 + 0.47 * Math.pow(Math.max(0, Math.min(1, (age - 1400) / holdTime)), 2)

            x: originX + drift * (distance > 0 ? travel / distance : 0)
            y: originY + travel
            width: diameter
            height: diameter * (1.25 + 0.55 * Math.min(1, slideAge / 450))
            opacity: strength * appearance
            scale: growth

            function reseed() {
                originX = 24 + Math.random() * Math.max(1, glass.width - 48);
                originY = Math.random() * glass.height * 0.82;
                diameter = 5 + Math.pow(Math.random(), 2) * 18;
                distance = diameter < 9 ? 20 + Math.random() * 60
                    : 100 + Math.random() * Math.max(150, glass.height * 0.65);
                drift = (Math.random() - 0.5) * 16;
                holdTime = diameter < 9 ? 7000 + Math.random() * 12000 : 2200 + Math.random() * 6500;
                slideTime = 4300 + Math.random() * 5000;
                strength = 0.55 + Math.random() * 0.4;
                age = -Math.random() * 1800;
                bend = (Math.random() - 0.5) * 5;
            }

            function advance(delta) {
                age += delta;
                if (age > 1400 + holdTime + slideTime + 900) reseed();
            }

            // A narrow, faint residual film. The tail fades towards its origin.
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -height + bead.height * 0.4
                width: Math.max(1, bead.diameter * 0.13)
                height: Math.min(bead.travel, 50 + bead.diameter * 5)
                radius: width / 2
                opacity: 0.35
                gradient: Gradient {
                    GradientStop { position: 0; color: "#00e3f3ff" }
                    GradientStop { position: 0.65; color: "#12e3f3ff" }
                    GradientStop { position: 1; color: "#42e3f3ff" }
                }
            }
            Image {
                anchors.fill: parent
                source: "../Assets/glass-drop.svg"
                sourceSize.width: 48
                sourceSize.height: 72
                rotation: bead.moving ? bead.bend : 0
                smooth: true
            }
            Image {
                // A nearby bead converges as the main drop accumulates water.
                readonly property real separation: Math.max(0, 1 - (bead.growth - 0.65) / 0.47)
                visible: bead.index % 3 === 0 && !bead.moving
                x: bead.width * 0.65 * separation
                y: -bead.height * 1.3 * separation
                width: bead.width * 0.45
                height: width * 1.3
                opacity: separation * 0.7
                source: "../Assets/glass-drop.svg"
                sourceSize.width: 48
                sourceSize.height: 72
            }
            Component.onCompleted: reseed()
        }
    }
}
