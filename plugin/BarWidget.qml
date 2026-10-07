import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Ui
import qs.Commons

// Always-visible Spotify widget. Left click opens the now-playing popup,
// middle click toggles playback, scroll skips tracks. Window/process control
// goes through ~/.local/bin/spotify-ctl (show / hide / quit).
BarWidget {
  id: root
  moduleName: "kima.spotify"

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var player: findSpotify(players)
  readonly property bool running: player !== null
  readonly property bool hasTrack: running && (player.trackTitle || player.trackArtist)
  readonly property bool playing: running && player.isPlaying
  readonly property string title: running ? (player.trackTitle || "") : ""
  readonly property string artist: running ? (player.trackArtist || "") : ""
  readonly property string album: running ? (player.trackAlbum || "") : ""
  readonly property string artUrl: running ? (player.trackArtUrl || "") : ""
  readonly property real trackLength: running && player.lengthSupported ? player.length : 0
  readonly property real maxLabelWidth: Number(setting("maxLabelWidth", 180))

  property bool popupOpen: false
  // Opened from IPC/keybind: no pointer focus, so skip the outside-click grab.
  property bool openedByIpc: false
  onPopupOpenChanged: if (!popupOpen) openedByIpc = false
  property real position: 0

  function close() { popupOpen = false }

  function findSpotify(list) {
    for (var i = 0; i < list.length; i++) {
      var p = list[i]
      var name = String(p.dbusName || "").toLowerCase()
      if (name.indexOf("spotify") !== -1 || String(p.identity || "").toLowerCase() === "spotify") return p
    }
    return null
  }

  function ctl(action) {
    Quickshell.execDetached(["bash", "-lc", "spotify-ctl " + action])
  }

  function formatTime(seconds) {
    var s = Math.max(0, Math.floor(seconds || 0))
    var m = Math.floor(s / 60)
    s = s % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  function cycleLoop() {
    if (!running || !player.loopSupported) return
    if (player.loopState === MprisLoopState.None) player.loopState = MprisLoopState.Playlist
    else if (player.loopState === MprisLoopState.Playlist) player.loopState = MprisLoopState.Track
    else player.loopState = MprisLoopState.None
  }

  // omarchy-shell kima.spotify toggle
  IpcHandler {
    target: "kima.spotify"
    function toggle(): void {
      root.openedByIpc = !root.popupOpen
      root.popupOpen = !root.popupOpen
    }
  }

  // MPRIS does not push position updates; poll while the popup is visible.
  Timer {
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: root.popupOpen && root.running
    onTriggered: {
      root.player.positionChanged()
      root.position = root.player.position
    }
  }

  implicitWidth: row.implicitWidth + Style.space(14)
  implicitHeight: barSize

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      id: glyph
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      text: "󰓇"
      color: root.playing ? "#1DB954" : (root.running ? root.bar.barForeground : Qt.darker(root.bar.barForeground, 1.8))
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
      Behavior on color { ColorAnimation { duration: 160 } }
    }

    Item {
      id: scrollClip
      width: Math.min(root.maxLabelWidth, labelText.implicitWidth)
      height: glyph.height
      clip: true
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.vertical && root.hasTrack

      Text {
        id: labelText
        textFormat: Text.PlainText
        text: root.title + (root.artist ? "  ·  " + root.artist : "")
        color: root.playing ? root.bar.barForeground : Qt.darker(root.bar.barForeground, 1.5)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter

        property bool needsScroll: implicitWidth > scrollClip.width
        onTextChanged: x = 0

        NumberAnimation on x {
          running: labelText.needsScroll && root.playing && !root.popupOpen && !root.vertical
          loops: Animation.Infinite
          duration: Math.max(6000, labelText.implicitWidth * 25)
          from: scrollClip.width
          to: -labelText.implicitWidth
          easing.type: Easing.Linear
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) {
        if (root.running) root.player.togglePlaying()
      } else if (mouse.button === Qt.RightButton) {
        root.ctl("toggle")
      } else {
        root.popupOpen = !root.popupOpen
      }
    }
    onWheel: function(wheel) {
      if (!root.running) return
      if (wheel.angleDelta.y > 0) root.player.previous()
      else if (wheel.angleDelta.y < 0) root.player.next()
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    triggerMode: root.openedByIpc ? "hover" : "click"
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      // Now playing — click to bring up the Spotify window.
      Item {
        width: parent.width
        height: Style.space(72)

        Row {
          anchors.fill: parent
          spacing: Style.space(12)

          BorderSurface {
            width: Style.space(72)
            height: Style.space(72)
            radius: Style.spacing.labelGap
            color: Style.normalFillFor(root.bar.foreground, Color.accent)
            borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

            Image {
              anchors.fill: parent
              anchors.margins: Style.space(2)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              source: root.artUrl
              visible: source !== ""
            }

            Text {
              anchors.centerIn: parent
              visible: root.artUrl === ""
              text: "󰓇"
              color: root.running ? "#1DB954" : root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.displayLarge
            }
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)
            width: parent.width - Style.space(84)

            Text {
              textFormat: Text.PlainText
              text: !root.running ? "Spotify is not running" : (root.title || "Nothing playing")
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: !root.running ? "Click to launch" : root.artist
              color: Qt.darker(root.bar.foreground, 1.3)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              width: parent.width
              visible: text !== ""
            }

            Text {
              textFormat: Text.PlainText
              text: root.album
              color: Qt.darker(root.bar.foreground, 1.6)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              width: parent.width
              visible: text !== ""
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.ctl("show")
            root.close()
          }
        }
      }

      // Progress
      Column {
        width: parent.width
        spacing: Style.space(2)
        visible: root.hasTrack && root.trackLength > 0

        PanelSlider {
          bar: root.bar
          width: parent.width
          minimum: 0
          maximum: Math.max(1, root.trackLength)
          step: 1
          value: root.position
          enabled: root.running && root.player.canSeek
          onReleased: function(v) {
            root.player.position = v
            root.position = v
          }
        }

        Item {
          width: parent.width
          height: elapsed.implicitHeight

          Text {
            id: elapsed
            anchors.left: parent.left
            text: root.formatTime(root.position)
            color: Qt.darker(root.bar.foreground, 1.5)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            anchors.right: parent.right
            text: root.formatTime(root.trackLength)
            color: Qt.darker(root.bar.foreground, 1.5)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }

      // Transport
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)
        visible: root.running

        Button {
          iconText: root.running && root.player.shuffle ? "󰒝" : "󰒞"
          tooltipText: "Shuffle"
          foreground: root.bar.foreground
          active: root.running && root.player.shuffle
          enabled: root.running && root.player.shuffleSupported
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.player.shuffle = !root.player.shuffle
        }

        Button {
          iconText: "󰒮"
          foreground: root.bar.foreground
          enabled: root.running && root.player.canGoPrevious
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.player.previous()
        }

        Button {
          iconText: root.playing ? "󰏤" : "󰐊"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.panelGap
          iconSize: Style.font.iconLarge
          enabled: root.running && (root.player.canTogglePlaying || root.player.canPlay || root.player.canPause)
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.player.togglePlaying()
        }

        Button {
          iconText: "󰒭"
          foreground: root.bar.foreground
          enabled: root.running && root.player.canGoNext
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.player.next()
        }

        Button {
          iconText: !root.running || root.player.loopState === MprisLoopState.None ? "󰑗"
            : root.player.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
          tooltipText: !root.running || root.player.loopState === MprisLoopState.None ? "Repeat: off"
            : root.player.loopState === MprisLoopState.Track ? "Repeat: track" : "Repeat: all"
          foreground: root.bar.foreground
          active: root.running && root.player.loopState !== MprisLoopState.None
          enabled: root.running && root.player.loopSupported
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.cycleLoop()
        }
      }

      // Volume
      Row {
        width: parent.width
        spacing: Style.space(8)
        visible: root.running && root.player.volumeSupported

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "󰕾"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
        }

        PanelSlider {
          bar: root.bar
          width: parent.width - Style.space(28)
          minimum: 0
          maximum: 1
          step: 0.05
          value: root.running ? root.player.volume : 0
          onMoved: function(v) { if (root.running) root.player.volume = v }
        }
      }

      PanelSeparator { foreground: root.bar.foreground }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)

        Button {
          iconText: "󰖯"
          text: root.running ? "Show" : "Launch Spotify"
          foreground: root.bar.foreground
          onClicked: {
            root.ctl("show")
            root.close()
          }
        }

        Button {
          iconText: "󰈉"
          text: "Hide"
          foreground: root.bar.foreground
          visible: root.running
          onClicked: {
            root.ctl("hide")
            root.close()
          }
        }

        Button {
          iconText: "󰐥"
          text: "Quit Spotify"
          foreground: root.bar.foreground
          visible: root.running
          onClicked: {
            root.ctl("quit")
            root.close()
          }
        }
      }
    }
  }
}
