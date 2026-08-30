import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "modules" as Modules
import "root:/"

Scope {
  IpcHandler {
    target: "bar"

    function toggleVis(): void {
      // Toggle visibility of all bar instances
      for (let i = 0; i < Quickshell.screens.length; i++) {
        barInstances[i].visible = !barInstances[i].visible;
      }
    }
  }

  property var barInstances: []

  Variants {
    model: Quickshell.screens
  
    PanelWindow {
      id: bar
      property var modelData
      screen: modelData

      Component.onCompleted: {
        barInstances.push(bar);
      }

      color: "transparent"

      Rectangle {
        id: highlight
        anchors.fill: parent
        color: Theme.get.barBgColor
      }

      implicitHeight: 30

      visible: true

      anchors {
        top: Theme.get.onTop
        bottom: !Theme.get.onTop
        left: true
        right: true
      }
    
      Item {
        id: allModules
        //spacing: 5
        anchors.fill: parent
  
        // Left side
        Rectangle {
          color: "#494949"
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter

          RowLayout {
            id: icon
            spacing: 5
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 20
            Modules.Icon {}
          }

            width: icon.implicitWidth + 2 * icon.anchors.margins
            height: icon.implicitHeight + 2 * icon.anchors.margins
        } 

        RowLayout {
          spacing: 4
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          anchors.margins: 50
          Modules.ActiveWindow {}
        }
          
        Item {
          Layout.fillWidth: true
        }
        
        //Center 
        RowLayout {
          id: centerModules
          spacing: 5
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          
          Modules.MangoWorkspaces {}
        }
        
        Item {
          Layout.fillWidth: true
        }
  
        // Right side
        Rectangle {
            color: "#494949"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            radius: 1

            RowLayout {
                id: rightModules
                spacing: 5
                anchors.fill: parent
                anchors.margins: 6

                Modules.Memory {}
                Modules.Cpu {}
                Modules.Sound {}
                Modules.Network {}
                Modules.Battery {}
                Modules.Datetime {}
            }

            width: rightModules.implicitWidth + 2 * rightModules.anchors.margins
            height: rightModules.implicitHeight + 2 * rightModules.anchors.margins
        }
      }
    }
  }
}

