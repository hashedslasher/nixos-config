import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../"

BarBlock {
  id: root
  property string appId
  property string appName
  property string iconSource

  Connections {
    target: ToplevelManager
    onActiveToplevelChanged: {
      if (ToplevelManager.activeToplevel) {
        const id = ToplevelManager.activeToplevel.appId
        var entry = DesktopEntries.byId(id)
        if (!entry) {
          entry = DesktopEntries.heuristicLookup(id)
        }
        if (entry) {
          appId = id
          appName = entry.name
          iconSource = entry.icon
        }
      }
    }
  }
  
  RowLayout {
    id: leftModules
    spacing: 40
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: 10

    IconImage {
      source: Quickshell.iconPath(iconSource)
      mipmap: true
      implicitSize: 24
    }

    BarText {
      text: appName
      color: "white"
    }
  }
}
