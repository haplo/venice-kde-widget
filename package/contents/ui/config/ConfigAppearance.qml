import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Dialogs
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: page

    // KCM auto-save: a property named `cfg_<entryName>` is read/written
    // by Plasma's config dialog, wiring Apply/Cancel/Defaults to KConfig.
    property alias cfg_transparentBackground: transparentCheckBox.checked
    property alias cfg_useThemeTextColor: useThemeCheckBox.checked
    property string cfg_customTextColor: "#ffffff"
    property alias cfg_textShadowEnabled: shadowCheckBox.checked
    property string cfg_textShadowColor: "#000000"
    property alias cfg_compactShowIcon: showIconCheckBox.checked
    property string cfg_compactTextMode: "percentage"

    readonly property var compactTextModes: [
        { value: "percentage", label: i18n("Percentage") },
        { value: "amount",     label: i18n("Available amount") },
        { value: "both",       label: i18n("Both") },
        { value: "none",       label: i18n("None") }
    ]

    function _indexForTextMode(value) {
        for (var i = 0; i < compactTextModes.length; ++i) {
            if (compactTextModes[i].value === value) return i
        }
        return 0
    }

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Kirigami.Units.largeSpacing
        }
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.CheckBox {
                id: transparentCheckBox
                Kirigami.FormData.label: i18n("Background:")
                text: i18n("Transparent")
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            QQC2.CheckBox {
                id: useThemeCheckBox
                Kirigami.FormData.label: i18n("Text color:")
                text: i18n("Use theme color")
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Custom color:")
                enabled: !useThemeCheckBox.checked
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    implicitWidth: Kirigami.Units.gridUnit * 2
                    implicitHeight: Kirigami.Units.gridUnit
                    radius: 2
                    border.width: 1
                    border.color: Kirigami.Theme.disabledTextColor
                    color: page.cfg_customTextColor
                }

                QQC2.Button {
                    text: i18n("Choose…")
                    icon.name: "color-picker"
                    onClicked: {
                        textColorDialog.selectedColor = page.cfg_customTextColor
                        textColorDialog.open()
                    }
                }

                QQC2.Label {
                    text: page.cfg_customTextColor
                    opacity: 0.7
                    font.family: "monospace"
                }
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            QQC2.CheckBox {
                id: shadowCheckBox
                Kirigami.FormData.label: i18n("Text shadow:")
                text: i18n("Enable shadow")
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Shadow color:")
                enabled: shadowCheckBox.checked
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    implicitWidth: Kirigami.Units.gridUnit * 2
                    implicitHeight: Kirigami.Units.gridUnit
                    radius: 2
                    border.width: 1
                    border.color: Kirigami.Theme.disabledTextColor
                    color: page.cfg_textShadowColor
                }

                QQC2.Button {
                    text: i18n("Choose…")
                    icon.name: "color-picker"
                    onClicked: {
                        shadowColorDialog.selectedColor = page.cfg_textShadowColor
                        shadowColorDialog.open()
                    }
                }

                QQC2.Label {
                    text: page.cfg_textShadowColor
                    opacity: 0.7
                    font.family: "monospace"
                }
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            QQC2.CheckBox {
                id: showIconCheckBox
                Kirigami.FormData.label: i18n("Compact view:")
                text: i18n("Display icon")
            }

            QQC2.ComboBox {
                id: textModeCombo
                Kirigami.FormData.label: i18n("Text:")
                textRole: "label"
                valueRole: "value"
                model: page.compactTextModes
                currentIndex: page._indexForTextMode(page.cfg_compactTextMode)
                onActivated: page.cfg_compactTextMode = page.compactTextModes[currentIndex].value

                Connections {
                    target: page
                    function onCfg_compactTextModeChanged() {
                        var idx = page._indexForTextMode(page.cfg_compactTextMode)
                        if (idx !== textModeCombo.currentIndex) {
                            textModeCombo.currentIndex = idx
                        }
                    }
                }
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("When the background is transparent, set a custom text color and/or shadow so the widget remains legible over any wallpaper.")
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("\"Available amount\" shows DIEM when your account has a DIEM allocation, otherwise USD. If both the icon and text are disabled, the icon is shown so the widget remains usable.")
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
    }

    ColorDialog {
        id: textColorDialog
        title: i18n("Choose text color")
        onAccepted: page.cfg_customTextColor = selectedColor.toString()
    }

    ColorDialog {
        id: shadowColorDialog
        title: i18n("Choose shadow color")
        onAccepted: page.cfg_textShadowColor = selectedColor.toString()
    }
}
