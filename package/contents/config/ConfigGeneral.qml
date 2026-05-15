import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: page

    // TODO(KWallet): Migrate apiKey storage to KWallet per AGENTS.md.
    // Currently stored in Plasmoid.configuration (KConfig) via main.xml schema.

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

            PlasmaComponents.TextField {
                Kirigami.FormData.label: "API Key:"
                Layout.fillWidth: true
                echoMode: TextInput.Password
                text: Plasmoid.configuration.apiKey
                placeholderText: "Enter your Venice.ai API key"
                onTextChanged: Plasmoid.configuration.apiKey = text
            }
        }
    }
}
