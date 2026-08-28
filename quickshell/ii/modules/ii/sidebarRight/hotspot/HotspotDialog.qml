import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

WindowDialog {
    id: root
    backgroundHeight: 480

    property string ssidText: Hotspot.ssid
    property string passwordText: Hotspot.password
    property bool secured: Hotspot.secured
    property string band: Hotspot.band
    readonly property bool passwordValid: !secured || (passwordText.length >= 8 && passwordText.length <= 63)
    property string validationError: ""
    property bool saving: false

    Connections {
        target: Hotspot
        function onConfigApplied(success) {
            if (!root.saving) return;
            root.saving = false;
            if (success) {
                if (Hotspot.active) Hotspot.start();
                root.dismiss();
            }
        }
    }

    WindowDialogTitle {
        text: Translation.tr("Hotspot")
    }
    WindowDialogSeparator {}

    MaterialTextField {
        Layout.fillWidth: true
        placeholderText: Translation.tr("Network name")
        text: root.ssidText
        onTextChanged: root.ssidText = text
    }

    ConfigSwitch {
        Layout.fillWidth: true
        iconSize: Appearance.font.pixelSize.larger
        buttonIcon: "lock"
        text: Translation.tr("Require password (WPA2)")
        checked: root.secured
        onCheckedChanged: root.secured = checked
    }

    MaterialTextField {
        Layout.fillWidth: true
        visible: root.secured
        placeholderText: Translation.tr("Password (8-63 characters)")
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
        text: root.passwordText
        onTextChanged: root.passwordText = text
    }

    WindowDialogSectionHeader {
        text: Translation.tr("Band")
    }
    ConfigSelectionArray {
        Layout.fillWidth: true
        options: [
            { "displayName": Translation.tr("2.4 GHz"), "value": "bg" },
            { "displayName": Translation.tr("5 GHz"), "value": "a" }
        ]
        currentValue: root.band
        onSelected: (newValue) => { root.band = newValue; }
    }

    StyledText {
        Layout.fillWidth: true
        visible: text.length > 0
        color: Appearance.colors.colError
        wrapMode: Text.Wrap
        text: root.validationError || Hotspot.lastError
    }

    Item { Layout.fillHeight: true }

    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Cancel")
            onClicked: root.dismiss()
        }

        Item { Layout.fillWidth: true }

        DialogButton {
            buttonText: Translation.tr("Save")
            onClicked: {
                if (root.ssidText.length === 0) {
                    root.validationError = Translation.tr("Network name is required.");
                    return;
                }
                if (!root.passwordValid) {
                    root.validationError = Translation.tr("Password must be 8-63 characters.");
                    return;
                }
                root.validationError = "";
                root.saving = true;
                Hotspot.applyConfig(root.ssidText, root.passwordText, root.secured, root.band);
            }
        }
    }
}
