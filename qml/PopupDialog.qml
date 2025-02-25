import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

Dialog {
    id: popupDialog
    anchors.centerIn: parent
    modal: false
    opacity: 0.9
    padding: 20
    property alias text: textField.text

    Theme {
        id: theme
    }

    Text {
        id: textField
        horizontalAlignment: Text.AlignJustify
        color: theme.textColor
        Accessible.role: Accessible.HelpBalloon
        Accessible.name: text
        Accessible.description: qsTr("Reveals a shortlived help balloon")
    }
    background: Rectangle {
        anchors.fill: parent
        color: theme.backgroundDarkest
        border.width: 1
        border.color: theme.dialogBorder
        radius: 10
    }

    exit: Transition {
        NumberAnimation { duration: 500; property: "opacity"; from: 1.0; to: 0.0 }
    }

    onOpened: {
        timer.start()
    }

    Timer {
        id: timer
        interval: 500; running: false; repeat: false
        onTriggered: popupDialog.close()
    }
}