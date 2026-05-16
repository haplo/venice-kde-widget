import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support 2.0 as P5Support
import org.kde.kirigami 2.20 as Kirigami
import "../../code/secret.js" as Secret

Item {
    id: page

    // Resolve the absolute path of kwallet.sh relative to this file.
    readonly property string kwalletScript: {
        var url = Qt.resolvedUrl("../../code/kwallet.sh").toString()
        if (url.indexOf("file://") === 0) return url.substring(7)
        return url
    }

    property string statusMessage: ""
    property bool statusIsError: false
    property bool busy: false

    function showStatus(msg, isError) {
        statusMessage = msg
        statusIsError = !!isError
    }

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            Secret.handleData(execSource, sourceName, data)
        }
    }

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Kirigami.Units.largeSpacing
        }
        spacing: Kirigami.Units.largeSpacing

        PlasmaComponents.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "The Venice.ai API token is stored securely in KWallet (via the freedesktop Secret Service). You can set it from the widget popup or change it here."
            opacity: 0.8
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.TextField {
                id: tokenField
                Kirigami.FormData.label: "New API token:"
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: "Paste a Venice.ai API token to save"
                enabled: !page.busy
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Button {
                text: page.busy ? "Saving…" : "Save token"
                icon.name: "document-save"
                enabled: !page.busy && tokenField.text.length > 0
                onClicked: {
                    page.busy = true
                    page.showStatus("", false)
                    Secret.save(execSource, page.kwalletScript, tokenField.text, function(ok, err) {
                        page.busy = false
                        if (ok) {
                            tokenField.text = ""
                            page.showStatus("Token saved to KWallet.", false)
                        } else {
                            page.showStatus(err || "Failed to save token", true)
                        }
                    })
                }
            }

            PlasmaComponents.Button {
                text: "Clear stored token"
                icon.name: "edit-delete"
                enabled: !page.busy
                onClicked: {
                    page.busy = true
                    page.showStatus("", false)
                    Secret.clear(execSource, page.kwalletScript, function(ok, err) {
                        page.busy = false
                        if (ok) {
                            page.showStatus("Token removed from KWallet.", false)
                        } else {
                            page.showStatus(err || "Failed to clear token", true)
                        }
                    })
                }
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            visible: page.statusMessage !== ""
            text: page.statusMessage
            wrapMode: Text.WordWrap
            color: page.statusIsError ? "#e74c3c" : Kirigami.Theme.positiveTextColor
        }
    }
}
