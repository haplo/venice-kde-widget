import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

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
        loadStaticData()
    }

    function loadStaticData() {
        hasBalance = true
        canConsume = true
        consumptionCurrency = "DIEM"
        diemBalance = 90.5
        usdBalance = 25.0
        diemAllocation = 100

        if (diemAllocation > 0) {
            diemPct = (diemBalance / diemAllocation) * 100
        }

        if (diemPct > 75) {
            diemColor = "#2ecc71"
        } else if (diemPct >= 25) {
            diemColor = "#f1c40f"
        } else {
            diemColor = "#e74c3c"
        }
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
                color: root.diemColor
            }

            PlasmaComponents.Label {
                text: Math.round(root.diemPct) + "%"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                color: PlasmaCore.Theme.textColor
            }
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        implicitWidth: Kirigami.Units.gridUnit * 14
        implicitHeight: Kirigami.Units.gridUnit * 10

        ColumnLayout {
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.largeSpacing

            PlasmaExtras.Heading {
                level: 2
                text: "Venice.ai Credits"
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    width: Kirigami.Units.iconSizes.tiny
                    height: Kirigami.Units.iconSizes.tiny
                    radius: width / 2
                    color: root.canConsume ? "#2ecc71" : "#e74c3c"
                }

                PlasmaComponents.Label {
                    text: root.consumptionCurrency
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    color: PlasmaCore.Theme.textColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: "DIEM"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    color: PlasmaCore.Theme.textColor
                    opacity: 0.7
                }

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
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: "USD"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    color: PlasmaCore.Theme.textColor
                    opacity: 0.7
                }

                PlasmaComponents.Label {
                    text: root.usdBalance > 0 ? "$" + root.usdBalance.toFixed(2) : "\u2014"
                    font.pointSize: root.usdBalance > 0 ? root.balanceFontSize : root.smallBalanceFontSize
                    font.weight: Font.Bold
                    color: root.usdBalance > 0 ? PlasmaCore.Theme.textColor : Kirigami.Theme.disabledTextColor
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: root.canConsume ? "dialog-ok" : "dialog-error"
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: Kirigami.Units.iconSizes.smallMedium
                    color: root.canConsume ? "#2ecc71" : "#e74c3c"
                }

                PlasmaComponents.Label {
                    text: root.canConsume ? "Ready to consume" : "Insufficient balance"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: PlasmaCore.Theme.textColor
                }
            }
        }
    }
}
