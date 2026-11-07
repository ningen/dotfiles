import QtQuick

Item {
  id: root

  property real value: 0
  property real maxValue: 1
  property color accent: "#7aa2f7"
  property color trackColor: "#2a2e42"
  property bool muted: false

  signal moved(real value)

  implicitHeight: 22

  readonly property real fraction: Math.max(0, Math.min(1, value / maxValue))

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 6
    radius: 3
    color: root.trackColor
  }

  Rectangle {
    id: fill
    anchors.verticalCenter: parent.verticalCenter
    width: track.width * root.fraction
    height: track.height
    radius: track.radius
    color: root.muted ? "#565f89" : root.accent

    Behavior on width {
      enabled: !mouseArea.pressed
      NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
    }
  }

  Rectangle {
    id: knob
    width: 15
    height: 15
    radius: 7.5
    anchors.verticalCenter: parent.verticalCenter
    x: Math.max(0, Math.min(track.width - width, track.width * root.fraction - width / 2))
    color: root.muted ? "#3b4261" : "#c0caf5"
    border.width: 2
    border.color: root.muted ? "#565f89" : (mouseArea.containsMouse ? "#bb9af7" : root.accent)
    scale: mouseArea.pressed ? 1.15 : (mouseArea.containsMouse ? 1.08 : 1.0)

    Behavior on scale {
      NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    preventStealing: true

    function setFromX(x) {
      root.moved(Math.max(0, Math.min(root.maxValue, (x / width) * root.maxValue)))
    }

    onPressed: function(mouse) {
      setFromX(mouse.x)
    }

    onPositionChanged: function(mouse) {
      if (pressed) setFromX(mouse.x)
    }

    onWheel: function(wheel) {
      var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
      root.moved(Math.max(0, Math.min(root.maxValue, root.value + step)))
    }
  }
}
