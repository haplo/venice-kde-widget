import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

PlasmaComponents.Page {
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10

    TabBar {
        id: tabBar
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        TabButton {
            text: "General"
        }
    }

    StackLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: tabBar.bottom
            bottom: parent.bottom
        }
        currentIndex: tabBar.currentIndex

        ConfigGeneral {}
    }
}
