import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: page

    property alias cfg_showLinkChatV1: chatV1CheckBox.checked
    property alias cfg_showLinkChatV2: chatV2CheckBox.checked
    property alias cfg_showLinkStudio: studioCheckBox.checked
    property alias cfg_showLinkFeed: feedCheckBox.checked
    property alias cfg_showLinkApi: apiCheckBox.checked
    property alias cfg_showLinkPricing: pricingCheckBox.checked
    property alias cfg_showLinkToken: tokenCheckBox.checked

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
                id: chatV1CheckBox
                Kirigami.FormData.label: i18n("Show buttons:")
                text: i18n("Chat (v1)")
            }

            QQC2.CheckBox {
                id: chatV2CheckBox
                text: i18n("Chat (v2)")
            }

            QQC2.CheckBox {
                id: studioCheckBox
                text: i18n("Studio")
            }

            QQC2.CheckBox {
                id: feedCheckBox
                text: i18n("Feed")
            }

            QQC2.CheckBox {
                id: apiCheckBox
                text: i18n("API")
            }

            QQC2.CheckBox {
                id: pricingCheckBox
                text: i18n("Pricing")
            }

            QQC2.CheckBox {
                id: tokenCheckBox
                text: i18n("Token")
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Choose which quick-link buttons appear at the bottom of the widget popup. Each button opens the corresponding Venice.ai page in your default browser.")
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
    }
}
