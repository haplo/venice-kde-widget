import QtQuick 2.15
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-user"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-theme"
        source: "config/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Links")
        icon: "internet-web-browser"
        source: "config/ConfigLinks.qml"
    }
}
