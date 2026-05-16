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

    // -- Appearance -----------------------------------------------------
    Plasmoid.backgroundHints: Plasmoid.configuration.transparentBackground
        ? PlasmaCore.Types.NoBackground
        : PlasmaCore.Types.DefaultBackground

    readonly property color effectiveTextColor:
        Plasmoid.configuration.useThemeTextColor
            ? PlasmaCore.Theme.textColor
            : Plasmoid.configuration.customTextColor
    readonly property bool textShadowEnabled: Plasmoid.configuration.textShadowEnabled
    readonly property color textShadowColor: Plasmoid.configuration.textShadowColor

    // Drop-in replacement for PlasmaComponents.Label that renders an
    // optional 1px offset duplicate underneath for legibility over
    // wallpapers when the panel background is transparent.
    component ShadowedLabel : Item {
        id: shadowed
        property alias text: fg.text
        property alias font: fg.font
        property alias horizontalAlignment: fg.horizontalAlignment
        property alias verticalAlignment: fg.verticalAlignment
        property alias wrapMode: fg.wrapMode
        property color color: root.effectiveTextColor
        property real textOpacity: 1.0

        implicitWidth: fg.implicitWidth + (root.textShadowEnabled ? 1 : 0)
        implicitHeight: fg.implicitHeight + (root.textShadowEnabled ? 1 : 0)

        PlasmaComponents.Label {
            visible: root.textShadowEnabled
            text: fg.text
            font: fg.font
            color: root.textShadowColor
            opacity: 0.85 * shadowed.textOpacity
            horizontalAlignment: fg.horizontalAlignment
            verticalAlignment: fg.verticalAlignment
            wrapMode: fg.wrapMode
            x: 1
            y: 1
            width: fg.width
            height: fg.height
        }

        PlasmaComponents.Label {
            id: fg
            color: shadowed.color
            opacity: shadowed.textOpacity
            anchors.left: parent.left
            anchors.top: parent.top
        }
    }

    // -- Secret state ---------------------------------------------------
    property string apiToken: ""
    property bool loadingSecret: false
    property bool waitingForKWallet: false // true while probing kwallet readiness
    property bool needsToken: false        // true when no token or auth failed
    property bool savingToken: false
    property string secretError: ""

    readonly property int kwalletReadyDeadlineMs: 60000
    readonly property int kwalletReadyPollMs: 1000
    property bool _readyInFlight: false
    property double _readyStartedAt: 0

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
    readonly property bool hasDiem: diemAllocation > 0
    property bool error: false
    property string errorMessage: ""

    property real balanceFontSize: Kirigami.Theme.defaultFont.pointSize + 4
    property real smallBalanceFontSize: Kirigami.Theme.defaultFont.pointSize + 1

    // Pick a foreground color (near-black or near-white) that contrasts well
    // with the given background color, using a perceptual luminance estimate.
    function contrastTextFor(c) {
        var L = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
        return L > 0.6 ? Qt.rgba(0, 0, 0, 0.87) : Qt.rgba(1, 1, 1, 0.95)
    }

    // Absolute file path of the kwallet.sh helper. Qt.resolvedUrl returns
    // a "file://" URL; strip the scheme for the executable engine.
    readonly property string kwalletScript: {
        var url = Qt.resolvedUrl("../code/kwallet.sh").toString()
        if (url.indexOf("file://") === 0) return url.substring(7)
        return url
    }

    Component.onCompleted: {
        console.log("[venice] kwallet.sh =", kwalletScript)
        waitForKWalletReady()
    }

    // If the helper never reports back (kwalletd6 down, helper missing, etc.)
    // recover gracefully so the UI doesn't sit on "Reading KWallet…" forever.
    // Cancel any pending helper calls so a late response can't stomp on
    // user-visible state after we've given up.
    Timer {
        id: secretWatchdog
        interval: 10000
        repeat: false
        onTriggered: {
            if (!root.loadingSecret) return
            console.log("[venice] secret watchdog fired — KWallet helper did not respond")
            Secret.cancelAll(execSource)
            root.loadingSecret = false
            root.needsToken = true
            root.error = false
            root.errorMessage = ""
            root.secretError = "Could not read KWallet — set token manually."
        }
    }

    Timer {
        id: readyPoller
        interval: root.kwalletReadyPollMs
        repeat: true
        onTriggered: root._probeKWalletReady()
    }

    function waitForKWalletReady() {
        waitingForKWallet = true
        _readyStartedAt = Date.now()
        _readyInFlight = false
        _probeKWalletReady()
        readyPoller.start()
    }

    function _probeKWalletReady() {
        if (_readyInFlight) return
        if (!waitingForKWallet) {
            readyPoller.stop()
            return
        }
        if (Date.now() - _readyStartedAt >= kwalletReadyDeadlineMs) {
            console.log("[venice] kwallet readiness deadline reached — proceeding to load anyway")
            readyPoller.stop()
            waitingForKWallet = false
            loadSecret()
            return
        }
        _readyInFlight = true
        Secret.ready(execSource, kwalletScript, function(isReady, exitCode) {
            _readyInFlight = false
            if (!waitingForKWallet) return
            if (isReady || exitCode === 2) {
                // 0  = ready, load the secret.
                // 2  = indeterminate (no qdbus / non-KDE backend) — skip gate.
                readyPoller.stop()
                waitingForKWallet = false
                loadSecret()
            }
            // exitCode === 1: not ready yet. Keep polling until deadline.
        })
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
    // The onNewData handler is REQUIRED: secret.js dispatches its pending
    // callbacks from here. Without it every load/save/clear silently hangs.
    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => Secret.handleData(execSource, sourceName, data)
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
                     : root.hasBalance ? (root.hasDiem ? root.diemColor
                                                       : (root.canConsume ? "#2ecc71" : "#e74c3c"))
                     : Kirigami.Theme.disabledTextColor
            }

            ShadowedLabel {
                text: root.needsToken ? "Set token"
                    : root.error ? "—"
                    : root.hasBalance ? (root.hasDiem ? Math.round(root.diemPct) + "%"
                                                      : "$" + root.usdBalance.toFixed(2))
                    : "…"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                color: root.effectiveTextColor
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

                Item {
                    Layout.fillWidth: true
                    implicitHeight: heading.implicitHeight + (root.textShadowEnabled ? 1 : 0)

                    PlasmaExtras.Heading {
                        visible: root.textShadowEnabled
                        level: 2
                        text: heading.text
                        anchors.fill: parent
                        anchors.leftMargin: 1
                        anchors.topMargin: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: root.textShadowColor
                        opacity: 0.85
                    }

                    PlasmaExtras.Heading {
                        id: heading
                        level: 2
                        text: "Venice.ai Credits"
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        color: root.effectiveTextColor
                    }
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

                ShadowedLabel {
                    text: root.apiToken === "" ? "No API token set" : "API token is invalid or expired"
                    Layout.alignment: Qt.AlignHCenter
                    font.weight: Font.Bold
                    color: root.effectiveTextColor
                }

                ShadowedLabel {
                    text: "The token is stored securely in KWallet."
                    Layout.alignment: Qt.AlignHCenter
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: root.effectiveTextColor
                    textOpacity: 0.7
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
            ShadowedLabel {
                visible: !root.needsToken && (root.waitingForKWallet || root.loadingSecret || (root.loading && !root.hasBalance && !root.error))
                text: root.waitingForKWallet ? "Waiting for KWallet…"
                    : root.loadingSecret ? "Reading KWallet…"
                    : "Loading…"
                Layout.alignment: Qt.AlignHCenter
                color: root.effectiveTextColor
                textOpacity: 0.7
            }

            // ---------------- Balance display ---------------------------
            ColumnLayout {
                visible: root.hasBalance && !root.needsToken && root.hasDiem
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    ShadowedLabel {
                        text: root.diemBalance.toFixed(2)
                        font.pointSize: root.balanceFontSize
                        font.weight: Font.Bold
                        color: root.diemBalance > 0 ? root.diemColor : Kirigami.Theme.disabledTextColor
                    }

                    ShadowedLabel {
                        text: "/ " + root.diemAllocation.toFixed(2)
                        font.pointSize: root.balanceFontSize
                        color: root.effectiveTextColor
                        textOpacity: 0.6
                    }

                    ShadowedLabel {
                        text: "DIEM"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        color: root.effectiveTextColor
                        textOpacity: 0.7
                    }
                }

                Rectangle {
                    id: diemTrack
                    Layout.fillWidth: true
                    height: Math.round(Kirigami.Units.gridUnit * 1.3)
                    radius: height / 2
                    color: Qt.rgba(root.diemColor.r, root.diemColor.g, root.diemColor.b, 0.2)

                    readonly property real fillWidth: width * Math.min(root.diemPct / 100, 1.0)
                    readonly property string pctText: Math.round(root.diemPct) + "% remaining"
                    readonly property int pctPointSize: Kirigami.Theme.smallFont.pointSize

                    // Filled portion. Clips its child label so the "on-fill"
                    // text is only visible where the bar is colored.
                    Rectangle {
                        id: diemFill
                        height: parent.height
                        radius: parent.radius
                        width: diemTrack.fillWidth
                        color: root.diemColor
                        clip: true

                        PlasmaComponents.Label {
                            text: diemTrack.pctText
                            font.pointSize: diemTrack.pctPointSize
                            font.weight: Font.Bold
                            color: root.contrastTextFor(root.diemColor)
                            // Center within the track, not within the fill,
                            // so the text doesn't shift as the bar fills.
                            x: (diemTrack.width - width) / 2
                            y: (diemTrack.height - height) / 2
                        }
                    }

                    // Unfilled portion. A clipping Item covers everything to
                    // the right of the fill so this copy of the label is only
                    // visible over the faded track.
                    Item {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        x: diemTrack.fillWidth
                        width: Math.max(0, diemTrack.width - diemTrack.fillWidth)
                        clip: true

                        PlasmaComponents.Label {
                            text: diemTrack.pctText
                            font.pointSize: diemTrack.pctPointSize
                            font.weight: Font.Bold
                            color: root.effectiveTextColor
                            x: (diemTrack.width - width) / 2 - parent.x
                            y: (diemTrack.height - height) / 2
                        }
                    }
                }
            }

            ColumnLayout {
                visible: root.hasBalance && !root.needsToken
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    ShadowedLabel {
                        text: "$" + root.usdBalance.toFixed(2)
                        font.pointSize: root.balanceFontSize
                        font.weight: Font.Bold
                        color: root.usdBalance > 0 ? root.effectiveTextColor : Kirigami.Theme.disabledTextColor
                    }

                    ShadowedLabel {
                        text: "USD"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        color: root.effectiveTextColor
                        textOpacity: 0.7
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
