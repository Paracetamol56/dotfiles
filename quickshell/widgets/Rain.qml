import QtQuick
import QtQuick.Particles

Item {
  id: rain
  anchors.fill: parent

  ParticleSystem {
    id: rainSystem
    anchors.fill: parent

    ImageParticle {
      autoRotation: true
      system: rainSystem
      source: Qt.resolvedUrl("../assets/raindrop.png")
      z: 1
      alpha: 1
      entryEffect: ImageParticle.None
    }

    Emitter {
      system: rainSystem
      emitRate: 50
      lifeSpan: 2000
      size: 26
      velocity: AngleDirection {
        angle: 75
        angleVariation: 5
        magnitude: 1200
        magnitudeVariation: 600
      }
      width: rain.width
      height: 1
      y: 0
      z: 1.5
    }
  }
}
