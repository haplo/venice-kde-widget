import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: page

    // KCM auto-save: a property named `cfg_<entryName>` is read/written
    // by Plasma's config dialog, wiring Apply/Cancel/Defaults to KConfig.
    property alias cfg_transparentBackground: transparentCheckBox.checked

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
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("When enabled, the widget is drawn directly over the wallpaper without the default themed panel. Useful for desktop placement.")
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
    }
}
