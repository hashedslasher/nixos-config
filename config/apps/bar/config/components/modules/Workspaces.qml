import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../utils" as Utils
import "root:/"

RowLayout {
    property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    Rectangle {
        id: workspaceBar
        Layout.preferredWidth: Math.max(50, Utils.HyprlandUtils.maxWorkspace * 25)
        Layout.preferredHeight: 23
        radius: 3
        color: Theme.get.barBgColor

        Row {
            anchors.centerIn: parent
            spacing: 15

            Repeater {
                model: Utils.HyprlandUtils.maxWorkspace || 1

                Item {
                    required property int index
                    property bool focused: Hyprland.focusedMonitor?.activeWorkspace?.id === (index + 1)
                    
                    width: workspaceText.width
                    height: workspaceText.height

                    Text {
                        id: workspaceText
                        text: (index + 1).toString()
                        color: "white"
                        font.pixelSize: 15
                        font.bold: focused
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Utils.HyprlandUtils.switchWorkspace(index + 1)
                    }
                }
            }
        }
    }
}
