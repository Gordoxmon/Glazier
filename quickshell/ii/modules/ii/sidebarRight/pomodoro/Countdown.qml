import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 0

        // The countdown circle
        CircularProgress {
            Layout.alignment: Qt.AlignHCenter
            lineWidth: 8
            value: {
                return TimerService.countdownDuration > 0 ? TimerService.countdownSecondsLeft / TimerService.countdownDuration : 0;
            }
            implicitSize: 200
            enableAnimation: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        let minutes = Math.floor(TimerService.countdownSecondsLeft / 60).toString().padStart(2, '0');
                        let seconds = Math.floor(TimerService.countdownSecondsLeft % 60).toString().padStart(2, '0');
                        return `${minutes}:${seconds}`;
                    }
                    font.pixelSize: 40
                    color: Appearance.m3colors.m3onSurface
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: TimerService.countdownSecondsLeft <= 0 ? Translation.tr("Time's up!") : Translation.tr("Timer")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // The Start/Stop and Reset buttons
        RowLayout {
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            RippleButton {
                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: TimerService.countdownRunning ? Translation.tr("Pause") : (TimerService.countdownSecondsLeft === TimerService.countdownDuration) ? Translation.tr("Start") : Translation.tr("Resume")
                    color: TimerService.countdownRunning ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                }
                implicitHeight: 35
                implicitWidth: 90
                font.pixelSize: Appearance.font.pixelSize.larger
                onClicked: TimerService.toggleCountdown()
                colBackground: TimerService.countdownRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                colBackgroundHover: TimerService.countdownRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
            }

            RippleButton {
                implicitHeight: 35
                implicitWidth: 90

                onClicked: TimerService.resetCountdown()
                enabled: !TimerService.countdownRunning && TimerService.countdownSecondsLeft !== TimerService.countdownDuration

                font.pixelSize: Appearance.font.pixelSize.larger
                colBackground: Appearance.colors.colErrorContainer
                colBackgroundHover: Appearance.colors.colErrorContainerHover
                colRipple: Appearance.colors.colErrorContainerActive

                contentItem: StyledText {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr("Reset")
                    color: Appearance.colors.colOnErrorContainer
                }
            }
        }

        // Custom duration (minutes), only editable while paused
        RowLayout {
            Layout.topMargin: 8
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            enabled: !TimerService.countdownRunning

            ColumnLayout {
                spacing: 0
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Duration")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
                StyledSpinBox {
                    baseHeight: 28
                    value: Math.round(TimerService.countdownDuration / 60)
                    from: 1
                    to: 180
                    stepSize: 1
                    onValueChanged: TimerService.setCountdownDuration(value * 60)
                }
            }
        }
    }
}
