import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.plasma5support 2.0 as P5Support
import org.kde.kirigami 2.20 as Kirigami
import "../code/api.js" as API

PlasmoidItem {
    id: root

    // TODO: replace env-var lookup with KWallet-stored secret
    property string apiToken: ""

    property bool loading: true
    property bool hasBalance: false
    property bool canConsume: false
    property string consumptionCurrency: ""
    property real diemBalance: 0
    property real usdBalance: 0
    property real diemAllocation: 0
    property real diemPct: 0
    property color diemColor: "#2ecc71"
    property bool error: false
    property string errorMessage: ""

    property real balanceFontSize: Kirigami.Theme.defaultFont.pointSize + 4
    property real smallBalanceFontSize: Kirigami.Theme.defaultFont.pointSize + 1

    Component.onCompleted: {
        envSource.connectSource("printenv VENICE_API_TOKEN")
    }

    // Reads VENICE_API_TOKEN from the user's environment.
    // TODO: replace with a KWallet-stored secret.
    P5Support.DataSource {
        id: envSource
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)

            var stdout = (data["stdout"] || "").toString().trim()
            var exitCode = data["exit code"]

            if (exitCode === 0 && stdout.length > 0) {
                root.apiToken = stdout
            } else {
                root.loading = false
                root.error = true
                root.errorMessage = "VENICE_API_TOKEN environment variable is not set"
            }
        }
    }

    function refresh() {
        if (!apiToken) return
        loading = true
        API.fetchBalance(apiToken, onBalance)
    }

    function onBalance(success, data, errMsg) {
        loading = false

        if (!success) {
            error = true
            errorMessage = errMsg || "Unknown error"
            return
        }

        error = false
        errorMessage = ""
        hasBalance = true

        canConsume = !!data.canConsume
        consumptionCurrency = data.consumptionCurrency || ""

        var balances = data.balances || {}
        diemBalance = (balances.diem !== null && balances.diem !== undefined) ? balances.diem : 0
        usdBalance = (balances.usd !== null && balances.usd !== undefined) ? balances.usd : 0
        diemAllocation = (data.diemEpochAllocation !== null && data.diemEpochAllocation !== undefined) ? data.diemEpochAllocation : 0

        if (diemAllocation > 0) {
            diemPct = (diemBalance / diemAllocation) * 100
        } else {
            diemPct = 0
        }

        if (diemPct > 75) {
            diemColor = "#2ecc71"
        } else if (diemPct >= 25) {
            diemColor = "#f1c40f"
        } else {
            diemColor = "#e74c3c"
        }
    }

    Timer {
        id: pollTimer
        interval: 60000
        repeat: true
        running: root.apiToken !== ""
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    compactRepresentation: MouseArea {
        implicitWidth: Kirigami.Units.gridUnit * 4
        implicitHeight: Kirigami.Units.gridUnit * 2

        onClicked: root.expanded = !root.expanded

        RowLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                width: Kirigami.Units.iconSizes.small
                height: Kirigami.Units.iconSizes.small
                radius: width / 2
                color: root.error ? "#e74c3c"
                     : root.hasBalance ? root.diemColor
                     : Kirigami.Theme.disabledTextColor
            }

            PlasmaComponents.Label {
                text: root.error ? "—"
                    : root.hasBalance ? Math.round(root.diemPct) + "%"
                    : "…"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                color: PlasmaCore.Theme.textColor
            }
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        implicitWidth: Kirigami.Units.gridUnit * 16
        implicitHeight: Kirigami.Units.gridUnit * 12
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.minimumHeight: Kirigami.Units.gridUnit * 10

        ColumnLayout {
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.Heading {
                    level: 2
                    text: "Venice.ai Credits"
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Kirigami.Icon {
                    visible: root.error
                    source: "dialog-warning"
                    width: Kirigami.Units.iconSizes.small
                    height: Kirigami.Units.iconSizes.small

                    PlasmaComponents.ToolTip.visible: errorMouseArea.containsMouse
                    PlasmaComponents.ToolTip.text: root.errorMessage
                    PlasmaComponents.ToolTip.delay: 0

                    MouseArea {
                        id: errorMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }

            PlasmaComponents.Label {
                visible: root.loading && !root.hasBalance && !root.error
                text: "Loading…"
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.7
            }

            RowLayout {
                visible: root.hasBalance
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    width: Kirigami.Units.iconSizes.tiny
                    height: Kirigami.Units.iconSizes.tiny
                    radius: width / 2
                    color: root.canConsume ? "#2ecc71" : "#e74c3c"
                }
            }

            ColumnLayout {
                visible: root.hasBalance
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        text: root.diemBalance > 0 ? root.diemBalance.toFixed(1) : "\u2014"
                        font.pointSize: root.diemBalance > 0 ? root.balanceFontSize : root.smallBalanceFontSize
                        font.weight: Font.Bold
                        color: root.diemBalance > 0 ? root.diemColor : Kirigami.Theme.disabledTextColor
                    }

                    PlasmaComponents.Label {
                        text: root.diemBalance > 0 ? "/ " + root.diemAllocation.toFixed(0) : ""
                        font.pointSize: root.diemBalance > 0 ? root.balanceFontSize : root.smallBalanceFontSize
                        color: PlasmaCore.Theme.textColor
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: "DIEM"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        color: PlasmaCore.Theme.textColor
                        opacity: 0.7
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: Kirigami.Units.smallSpacing
                    radius: height / 2
                    color: Qt.rgba(root.diemColor.r, root.diemColor.g, root.diemColor.b, 0.2)

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: parent.width * Math.min(root.diemPct / 100, 1.0)
                        color: root.diemColor
                    }
                }

                PlasmaComponents.Label {
                    text: Math.round(root.diemPct) + "% remaining"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: PlasmaCore.Theme.textColor
                    opacity: 0.6
                }
            }

            ColumnLayout {
                visible: root.hasBalance
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    PlasmaComponents.Label {
                        text: root.usdBalance > 0 ? "$" + root.usdBalance.toFixed(2) : "\u2014"
                        font.pointSize: root.usdBalance > 0 ? root.balanceFontSize : root.smallBalanceFontSize
                        font.weight: Font.Bold
                        color: root.usdBalance > 0 ? PlasmaCore.Theme.textColor : Kirigami.Theme.disabledTextColor
                    }

                    PlasmaComponents.Label {
                        text: "USD"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        color: PlasmaCore.Theme.textColor
                        opacity: 0.7
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
