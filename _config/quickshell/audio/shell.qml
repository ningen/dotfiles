import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

ShellRoot {
  id: shell

  property bool showSources: false
  property bool deviceMenuOpen: false

  function appName(node) {
    return (node.properties["application.name"]
      || node.description
      || node.nickname
      || node.name
      || "Unknown").toString()
  }

  function deviceName(node) {
    return (node.description
      || node.nickname
      || node.name
      || "Unknown").toString()
  }

  function appIcon(node) {
    var name = appName(node).toLowerCase()
    if (name.indexOf("chrome") !== -1 || name.indexOf("chromium") !== -1) return "\uf268"
    if (name.indexOf("firefox") !== -1) return "\uf269"
    if (name.indexOf("discord") !== -1) return "\uf392"
    if (name.indexOf("steam") !== -1) return "\uf1b6"
    if (name.indexOf("spotify") !== -1) return "\uf1bc"
    if (name.indexOf("mpv") !== -1 || name.indexOf("vlc") !== -1) return "\uf008"
    return node.isSink ? "\uf001" : "\uf130"
  }

  readonly property var outputs: {
    var list = Pipewire.nodes.values.filter(function(node) {
      return !node.isStream && node.isSink && node.audio !== null
    })
    list.sort(function(a, b) {
      return deviceName(a).localeCompare(deviceName(b))
    })
    return list
  }

  readonly property var inputs: {
    var list = Pipewire.nodes.values.filter(function(node) {
      return !node.isStream && !node.isSink && node.audio !== null
    })
    list.sort(function(a, b) {
      return deviceName(a).localeCompare(deviceName(b))
    })
    return list
  }

  readonly property var devices: showSources ? inputs : outputs

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property var currentDevice: showSources ? source : sink
  readonly property var currentAudio: currentDevice ? currentDevice.audio : null

  readonly property var streams: {
    var list = Pipewire.nodes.values.filter(function(node) {
      if (!node.isStream || node.audio === null) return false
      return showSources ? !node.isSink : node.isSink
    })
    list.sort(function(a, b) {
      return appName(a).localeCompare(appName(b))
    })
    return list
  }

  PwObjectTracker {
    objects: Pipewire.nodes.values
  }

  PanelWindow {
    id: panel

    property bool opened: false

    visible: opened
    color: "transparent"
    implicitWidth: 380
    implicitHeight: content.implicitHeight + 32
    anchors {
      top: true
      right: true
    }
    margins {
      top: 46
      right: 16
    }
    exclusiveZone: 0
    aboveWindows: true
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-audio"
    WlrLayershell.keyboardFocus: panel.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      radius: 18
      color: Qt.rgba(26 / 255, 27 / 255, 38 / 255, 0.94)
      border.width: 1
      border.color: Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.28)
    }

    Item {
      id: contentRoot
      anchors.fill: parent
      anchors.margins: 16

      ColumnLayout {
        id: content
        width: parent.width
        spacing: 14

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 10
            color: shell.showSources
              ? Qt.rgba(158 / 255, 206 / 255, 106 / 255, 0.14)
              : Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.16)

            Text {
              anchors.centerIn: parent
              text: shell.showSources
                ? (shell.currentAudio && shell.currentAudio.muted ? "\uf131" : "\uf130")
                : (shell.currentAudio && shell.currentAudio.muted ? "\uf026" : "\uf028")
              color: shell.currentAudio && shell.currentAudio.muted
                ? "#f7768e"
                : (shell.showSources ? "#9ece6a" : "#7aa2f7")
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 16
            }
          }

          ColumnLayout {
            spacing: 1
            Layout.fillWidth: true

            Text {
              text: "Audio"
              color: "#c0caf5"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 15
              font.bold: true
            }

            Text {
              Layout.fillWidth: true
              Layout.maximumWidth: 250
              text: shell.currentDevice
                ? shell.deviceName(shell.currentDevice)
                : (shell.showSources ? "No input device" : "No output device")
              color: "#565f89"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 11
              elide: Text.ElideRight
            }
          }

          Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 7
            color: closeHover.hovered ? "#2f3549" : "transparent"

            HoverHandler { id: closeHover }

            Text {
              anchors.centerIn: parent
              text: "\uf00d"
              color: "#565f89"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 11
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.opened = false
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 34
          radius: 10
          color: "#1f2335"
          border.width: 1
          border.color: "#2f3549"

          RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 3

            TabButton {
              Layout.fillWidth: true
              text: "Playback"
              icon: "\uf028"
              active: !shell.showSources
              onClicked: {
                shell.showSources = false
                shell.deviceMenuOpen = false
              }
            }

            TabButton {
              Layout.fillWidth: true
              text: "Microphone"
              icon: "\uf130"
              active: shell.showSources
              onClicked: {
                shell.showSources = true
                shell.deviceMenuOpen = false
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: masterColumn.implicitHeight + 24
          radius: 14
          color: "#24283b"
          border.width: 1
          border.color: "#2f3549"

          ColumnLayout {
            id: masterColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: shell.showSources ? "Microphone" : "Master"
                color: "#c0caf5"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
              }

              Item { Layout.fillWidth: true }

              Text {
                text: Math.round((shell.currentAudio ? shell.currentAudio.volume : 0) * 100) + "%"
                color: shell.showSources ? "#9ece6a" : "#7aa2f7"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
              }

              MuteButton {
                muted: shell.currentAudio ? shell.currentAudio.muted : false
                onIcon: shell.showSources ? "\uf130" : "\uf028"
                offIcon: shell.showSources ? "\uf131" : "\uf026"
                onToggled: if (shell.currentAudio) shell.currentAudio.muted = !shell.currentAudio.muted
              }
            }

            VolumeSlider {
              Layout.fillWidth: true
              value: shell.currentAudio ? shell.currentAudio.volume : 0
              muted: shell.currentAudio ? shell.currentAudio.muted : false
              accent: shell.showSources ? "#9ece6a" : "#7aa2f7"
              onMoved: function(value) {
                if (shell.currentAudio) shell.currentAudio.volume = value
              }
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 1
              color: "#2f3549"
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 30
              radius: 8
              color: deviceHover.hovered ? "#2a2f45" : "transparent"

              HoverHandler { id: deviceHover }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 8

                Text {
                  text: shell.showSources ? "\uf130" : "\uf028"
                  color: shell.showSources ? "#9ece6a" : "#7aa2f7"
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 11
                }

                Text {
                  Layout.fillWidth: true
                  text: shell.currentDevice ? shell.deviceName(shell.currentDevice) : "No device"
                  color: "#a9b1d6"
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 11
                  elide: Text.ElideRight
                }

                Text {
                  text: shell.deviceMenuOpen ? "\uf077" : "\uf078"
                  color: "#565f89"
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 9
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: shell.deviceMenuOpen = !shell.deviceMenuOpen
              }
            }

            Repeater {
              model: shell.deviceMenuOpen ? shell.devices : []

              delegate: Rectangle {
                id: deviceRow
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 8
                color: deviceRowHover.hovered
                  ? "#2a2f45"
                  : (modelData.id === (shell.currentDevice ? shell.currentDevice.id : -1)
                    ? "#242a40"
                    : "transparent")

                HoverHandler { id: deviceRowHover }

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 8

                  Text {
                    Layout.fillWidth: true
                    text: shell.deviceName(deviceRow.modelData)
                    color: "#c0caf5"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                  }

                  Text {
                    visible: deviceRow.modelData.id === (shell.currentDevice ? shell.currentDevice.id : -1)
                    text: "\uf00c"
                    color: shell.showSources ? "#9ece6a" : "#7aa2f7"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (shell.showSources) {
                      Pipewire.preferredDefaultAudioSource = deviceRow.modelData
                    } else {
                      Pipewire.preferredDefaultAudioSink = deviceRow.modelData
                    }
                    shell.deviceMenuOpen = false
                  }
                }
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: 2

          Text {
            text: shell.showSources ? "MICROPHONE USERS" : "APPLICATIONS"
            color: "#565f89"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.letterSpacing: 1.6
            font.bold: true
          }

          Item { Layout.fillWidth: true }

          Text {
            text: shell.streams.length
            color: "#3b4261"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.bold: true
          }
        }

        Flickable {
          id: appsFlick
          Layout.fillWidth: true
          Layout.preferredHeight: Math.min(appsColumn.implicitHeight, 300)
          visible: shell.streams.length > 0
          contentWidth: width
          contentHeight: appsColumn.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: appsColumn
            width: appsFlick.width
            spacing: 8

            Repeater {
              model: shell.streams

              delegate: Rectangle {
                id: appRow
                required property var modelData

                width: appsColumn.width
                height: appColumn.implicitHeight + 22
                radius: 12
                color: rowHover.hovered ? "#242a40" : "#1f2335"
                border.width: 1
                border.color: rowHover.hovered ? "#2f3a5f" : "#24283b"

                HoverHandler { id: rowHover }

                ColumnLayout {
                  id: appColumn
                  anchors.fill: parent
                  anchors.margins: 11
                  spacing: 8

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                      Layout.preferredWidth: 28
                      Layout.preferredHeight: 28
                      radius: 8
                      color: shell.showSources
                        ? Qt.rgba(158 / 255, 206 / 255, 106 / 255, 0.12)
                        : Qt.rgba(187 / 255, 154 / 255, 247 / 255, 0.14)

                      Text {
                        anchors.centerIn: parent
                        text: shell.appIcon(appRow.modelData)
                        color: shell.showSources ? "#9ece6a" : "#bb9af7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                      }
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 1

                      Text {
                        Layout.fillWidth: true
                        text: shell.appName(appRow.modelData)
                        color: "#c0caf5"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                      }

                      Text {
                        Layout.fillWidth: true
                        text: appRow.modelData.audio ? Math.round(appRow.modelData.audio.volume * 100) + "%" : ""
                        color: "#565f89"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                      }
                    }

                    MuteButton {
                      muted: appRow.modelData.audio ? appRow.modelData.audio.muted : false
                      onIcon: shell.showSources ? "\uf130" : "\uf028"
                      offIcon: shell.showSources ? "\uf131" : "\uf026"
                      onToggled: if (appRow.modelData.audio) appRow.modelData.audio.muted = !appRow.modelData.audio.muted
                    }
                  }

                  VolumeSlider {
                    Layout.fillWidth: true
                    value: appRow.modelData.audio ? appRow.modelData.audio.volume : 0
                    muted: appRow.modelData.audio ? appRow.modelData.audio.muted : false
                    accent: shell.showSources ? "#9ece6a" : "#bb9af7"
                    onMoved: function(value) {
                      if (appRow.modelData.audio) appRow.modelData.audio.volume = value
                    }
                  }
                }
              }
            }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: 64
          visible: shell.streams.length === 0

          Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: shell.showSources ? "\uf130" : "\uf001"
              color: "#3b4261"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 22
            }

            Text {
              text: shell.showSources ? "No microphone users" : "No active playback"
              color: "#565f89"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 11
            }
          }
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      required property var modelData

      screen: modelData
      visible: panel.opened
      color: "transparent"
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusiveZone: 0
      aboveWindows: true
      focusable: false
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "quickshell-audio-backdrop"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      MouseArea {
        anchors.fill: parent
        onClicked: panel.opened = false
      }
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: panel.opened
    context: Qt.WindowShortcut
    onActivated: panel.opened = false
  }

  IpcHandler {
    target: "audio"

    function toggle(): void {
      panel.opened = !panel.opened
    }

    function toggleOn(screenName: string): void {
      var target = null
      var screens = Quickshell.screens
      for (var i = 0; i < screens.length; i++) {
        if (screens[i].name === screenName) {
          target = screens[i]
          break
        }
      }
      if (panel.opened && (!target || panel.screen === target)) {
        panel.opened = false
        return
      }
      if (target) panel.screen = target
      panel.opened = true
    }

    function open(): void {
      panel.opened = true
    }

    function openOn(screenName: string): void {
      var screens = Quickshell.screens
      for (var i = 0; i < screens.length; i++) {
        if (screens[i].name === screenName) {
          panel.screen = screens[i]
          break
        }
      }
      panel.opened = true
    }

    function close(): void {
      panel.opened = false
    }

    function setTab(tab: string): void {
      shell.showSources = tab === "mic" || tab === "microphone" || tab === "input"
      shell.deviceMenuOpen = false
    }

    function setMaster(volume: real): void {
      if (shell.currentAudio) shell.currentAudio.volume = volume
    }

    function setDefaultSink(id: int): void {
      var nodes = Pipewire.nodes.values
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].id === id && !nodes[i].isStream && nodes[i].isSink && nodes[i].audio !== null) {
          Pipewire.preferredDefaultAudioSink = nodes[i]
          return
        }
      }
    }

    function setDefaultSource(id: int): void {
      var nodes = Pipewire.nodes.values
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].id === id && !nodes[i].isStream && !nodes[i].isSink && nodes[i].audio !== null) {
          Pipewire.preferredDefaultAudioSource = nodes[i]
          return
        }
      }
    }
  }

  component TabButton: Rectangle {
    id: tab

    property string text: ""
    property string icon: ""
    property bool active: false

    signal clicked()

    radius: 8
    color: active
      ? (shell.showSources
        ? Qt.rgba(158 / 255, 206 / 255, 106 / 255, 0.16)
        : Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.16))
      : (tabHover.hovered ? "#242a40" : "transparent")
    border.width: 1
    border.color: active
      ? (shell.showSources
        ? Qt.rgba(158 / 255, 206 / 255, 106 / 255, 0.35)
        : Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.35))
      : "transparent"

    HoverHandler { id: tabHover }

    RowLayout {
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: tab.icon
        color: tab.active
          ? (shell.showSources ? "#9ece6a" : "#7aa2f7")
          : "#565f89"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
      }

      Text {
        text: tab.text
        color: tab.active ? "#c0caf5" : "#565f89"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.bold: tab.active
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: tab.clicked()
    }
  }

  component MuteButton: Rectangle {
    id: muteButton

    property bool muted: false
    property string onIcon: "\uf028"
    property string offIcon: "\uf026"

    signal toggled()

    implicitWidth: 30
    implicitHeight: 24
    radius: 7
    color: muted
      ? Qt.rgba(247 / 255, 118 / 255, 142 / 255, 0.16)
      : (muteHover.hovered ? "#2f3549" : "transparent")
    border.width: 1
    border.color: muted
      ? Qt.rgba(247 / 255, 118 / 255, 142 / 255, 0.5)
      : "#2f3549"

    HoverHandler { id: muteHover }

    Text {
      anchors.centerIn: parent
      text: muteButton.muted ? muteButton.offIcon : muteButton.onIcon
      color: muteButton.muted ? "#f7768e" : "#a9b1d6"
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 11
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: muteButton.toggled()
    }
  }
}

