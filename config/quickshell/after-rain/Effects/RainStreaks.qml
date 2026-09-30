import QtQuick
import QtQuick.Particles
import qs.Generated

// Reserved implementation. Not instantiated by the current water-only renderer.
ParticleSystem {
    id: particles
    property string mode: "normal"
    property int liveCap: 198
    readonly property real fallSpeed: mode === "heavy" ? 1050 : mode === "light" ? 650 : 850
    readonly property int lifetime: Math.ceil((height + 100) / (fallSpeed - 80) * 1000)
    running: false
    ImageParticle {
        system: particles
        source: "../Assets/rain-streak.svg"
        color: Theme.accent
        alpha: particles.mode === "light" ? 0.12 : particles.mode === "heavy" ? 0.28 : 0.19
        alphaVariation: 0.05
    }
    Emitter {
        system: particles
        x: 0
        y: -50
        width: particles.width + 240
        height: 1
        emitRate: particles.liveCap * 1000 / lifeSpan
        maximumEmitted: particles.liveCap
        lifeSpan: particles.lifetime
        size: particles.mode === "heavy" ? 40 : 30
        sizeVariation: 10
        endSize: size
        velocity: PointDirection { x: -80; xVariation: 20; y: particles.fallSpeed; yVariation: 80 }
    }
}
