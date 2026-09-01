import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

WidgetCard {
    id: root
    title: Translation.tr("Media")
    icon: "music_note"

    // Quick-launch for the configured music app, always reachable from the
    // header regardless of what currently holds the active MPRIS player
    // (e.g. a browser tab) — see modules/nixos/apps.nix for the desktop id
    // (YouTube Music, packaged upstream as "Pear Desktop").
    // DesktopEntries.byId() isn't a tracked binding dependency, and the
    // desktop-entry scan finishes asynchronously after startup, so this
    // reads the (live, notifying) applications list directly instead —
    // otherwise the lookup freezes at whatever it resolved to (usually
    // null) before the scan completed.
    readonly property var musicAppEntry: {
        for (const e of DesktopEntries.applications.values) {
            if (e.id === "com.github.th_ch.youtube_music") return e;
        }
        return null;
    }

    headerAction: RippleButton {
        visible: !!root.musicAppEntry
        implicitWidth: 28
        implicitHeight: 28
        buttonRadius: Appearance.rounding.full
        contentItem: MaterialSymbol {
            text: "play_circle"
            iconSize: Appearance.font.pixelSize.normal
            horizontalAlignment: Text.AlignHCenter
            color: Appearance.colors.colOnLayer2
        }
        onClicked: root.musicAppEntry.execute()
    }

    Timer { // Force position refresh while playing, same trick as PlayerControl.qml
        running: MprisController.activePlayer?.playbackState === MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: MprisController.activePlayer?.positionChanged()
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        visible: !MprisController.activePlayer

        PagePlaceholder {
            title: Translation.tr("No player")
            icon: "music_off"
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: !!MprisController.activePlayer
        spacing: 10

        StyledImage {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            fillMode: Image.PreserveAspectCrop
            source: MprisController.activeTrack?.artUrl ?? ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: MprisController.activeTrack?.title ?? ""
                elide: Text.ElideRight
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                Layout.fillWidth: true
                text: MprisController.activeTrack?.artist ?? ""
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    StyledProgressBar {
        Layout.fillWidth: true
        visible: !!MprisController.activePlayer
        from: 0
        to: MprisController.activePlayer?.length ?? 0
        value: MprisController.activePlayer?.position ?? 0
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        visible: !!MprisController.activePlayer
        spacing: 20

        RippleButton {
            implicitWidth: 36
            implicitHeight: 36
            enabled: MprisController.canGoPrevious
            buttonRadius: Appearance.rounding.full
            contentItem: MaterialSymbol {
                text: "skip_previous"
                iconSize: Appearance.font.pixelSize.larger
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer2
            }
            onClicked: MprisController.previous()
        }
        RippleButton {
            implicitWidth: 44
            implicitHeight: 44
            enabled: MprisController.activePlayer?.canTogglePlaying ?? false
            buttonRadius: Appearance.rounding.full
            contentItem: MaterialSymbol {
                fill: 1
                text: MprisController.isPlaying ? "pause" : "play_arrow"
                iconSize: Appearance.font.pixelSize.huge
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer2
            }
            onClicked: MprisController.togglePlaying()
        }
        RippleButton {
            implicitWidth: 36
            implicitHeight: 36
            enabled: MprisController.canGoNext
            buttonRadius: Appearance.rounding.full
            contentItem: MaterialSymbol {
                text: "skip_next"
                iconSize: Appearance.font.pixelSize.larger
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer2
            }
            onClicked: MprisController.next()
        }
    }
}
