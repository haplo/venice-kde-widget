import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.plasma5support 2.0 as P5Support
import org.kde.kirigami 2.20 as Kirigami
import "../code/api.js" as API
import "../code/secret.js" as Secret

PlasmoidItem {
    id: root

    // -- Secret state ---------------------------------------------------
    property string apiToken: ""
    property bool loadingSecret: true
    property bool needsToken: false        // true when no token or auth failed
    property bool savingToken: false
    property string secretError: ""

    // -- Balance state --------------------------------------------------
    property bool loading: false
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

    // Absolute file path of the kwallet.sh helper. Qt.resolvedUrl returns
    // a "file://" URL; strip the scheme for the executable engine.
    readonly property string kwalletScript: {
        var url = Qt.resolvedUrl("../code/kwallet.sh").toString()
        if (url.indexOf("file://") === 0) return url.substring(7)
        return url
    }

    Component.onCompleted: {
        console.log("[venice] kwallet.sh =", kwalletScript)
        secretWatchdog.restart()
        // Migrate legacy plaintext apiKey from KConfig, if present.
        var legacy = Plasmoid.configuration.apiKey || ""
        if (legacy && legacy.length > 0) {
            console.log("[venice] migrating legacy plaintext apiKey into KWallet")
            Secret.save(execSource, kwalletScript, legacy, function(ok, err) {
                // Always clear the plaintext copy; if migration failed the
                // user can re-enter the token via the widget UI.
                Plasmoid.configuration.apiKey = ""
                if (ok) {
                    secretWatchdog.stop()
                    root.apiToken = legacy
                    root.needsToken = false
                    root.loadingSecret = false
                    root.refresh()
                } else {
                    console.log("[venice] legacy migration failed:", err)
                    loadSecret()
                }
            })
        } else {
            loadSecret()
        }
    }

    // If the helper never reports back (kwalletd6 down, helper missing, etc.)
    // recover gracefully so the UI doesn't sit on "Reading KWallet…" forever.
    Timer {
        id: secretWatchdog
        interval: 5000
        repeat: false
        onTriggered: {
            if (!root.loadingSecret) return
            console.log("[venice] secret watchdog fired — KWallet helper did not respond")
            root.loadingSecret = false
            root.needsToken = true
            root.error = false
            root.errorMessage = ""
            root.secretError = "Could not read KWallet — set token manually."
        }
    }

    function loadSecret() {
        loadingSecret = true
        secretWatchdog.restart()
        Secret.load(execSource, kwalletScript, function(token, err) {
            secretWatchdog.stop()
            loadingSecret = false
            if (err) {
                error = true
                errorMessage = err
                needsToken = true
                return
            }
            if (!token) {
                needsToken = true
                return
            }
            apiToken = token
            needsToken = false
            refresh()
        })
    }

    function saveToken(token) {
        if (!token || token.length === 0) return
        savingToken = true
        secretError = ""
        Secret.save(execSource, kwalletScript, token, function(ok, err) {
            savingToken = false
            if (!ok) {
                secretError = err || "Failed to save token"
                return
            }
            apiToken = token
            needsToken = false
            error = false
            errorMessage = ""
            refresh()
        })
    }

    // Single DataSource shared by secret.js for all helper invocations.
    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
    }

    function refresh() {
        if (!apiToken) return
        loading = true
        API.fetchBalance(apiToken, onBalance)
    }

    function onBalance(success, data, errMsg, errKind) {
        loading = false

        if (!success) {
            if (errKind === "auth") {
                // Token is invalid/expired — prompt the user for a new one.
                needsToken = true
                hasBalance = false
                error = false
                errorMessage = ""
                return
            }
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
        running: root.apiToken !== "" && !root.needsToken
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

            Kirigami.Icon {
                visible: root.needsToken
                source: "dialog-password"
                width: Kirigami.Units.iconSizes.small
                height: Kirigami.Units.iconSizes.small
            }

            Rectangle {
                visible: !root.needsToken
                width: Kirigami.Units.iconSizes.small
                height: Kirigami.Units.iconSizes.small
                radius: width / 2
                color: root.error ? "#e74c3c"
                     : root.hasBalance ? root.diemColor
                     : Kirigami.Theme.disabledTextColor
            }

            PlasmaComponents.Label {
                text: root.needsToken ? "Set token"
                    : root.error ? "—"
                    : root.hasBalance ? Math.round(root.diemPct) + "%"
                    : "…"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                color: PlasmaCore.Theme.textColor
            }
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        implicitWidth: Kirigami.Units.gridUnit * 18
        implicitHeight: Kirigami.Units.gridUnit * 14
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12

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
                    visible: root.error && !root.needsToken
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

            // ---------------- "Set API token" prompt --------------------
            ColumnLayout {
                id: tokenPrompt
                visible: root.needsToken
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "dialog-password"
                    Layout.alignment: Qt.AlignHCenter
                    width: Kirigami.Units.iconSizes.large
                    height: Kirigami.Units.iconSizes.large
                }

                PlasmaComponents.Label {
                    text: root.apiToken === "" ? "No API token set" : "API token is invalid or expired"
                    Layout.alignment: Qt.AlignHCenter
                    font.weight: Font.Bold
                }

                PlasmaComponents.Label {
                    text: "The token is stored securely in KWallet."
                    Layout.alignment: Qt.AlignHCenter
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }

                QQC2.TextField {
                    id: tokenField
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    echoMode: TextInput.Password
                    placeholderText: "Paste your Venice.ai API token"
                    enabled: !root.savingToken
                    onAccepted: if (text.length > 0) root.saveToken(text)
                }

                PlasmaComponents.Label {
                    visible: root.secretError !== ""
                    text: root.secretError
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#e74c3c"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Button {
                        text: root.savingToken ? "Saving…" : "Save API token"
                        icon.name: "document-save"
                        enabled: !root.savingToken && tokenField.text.length > 0
                        onClicked: root.saveToken(tokenField.text)
                    }

                    PlasmaComponents.Button {
                        text: "Cancel"
                        visible: root.apiToken !== ""
                        enabled: !root.savingToken
                        onClicked: {
                            tokenField.text = ""
                            root.needsToken = false
                            root.refresh()
                        }
                    }
                }
            }

            // ---------------- Loading placeholder -----------------------
            PlasmaComponents.Label {
                visible: !root.needsToken && (root.loadingSecret || (root.loading && !root.hasBalance && !root.error))
                text: root.loadingSecret ? "Reading KWallet…" : "Loading…"
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.7
            }

            // ---------------- Balance display ---------------------------
            RowLayout {
                visible: root.hasBalance && !root.needsToken
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
                visible: root.hasBalance && !root.needsToken
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
                visible: root.hasBalance && !root.needsToken
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
