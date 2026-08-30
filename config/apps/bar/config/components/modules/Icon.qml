import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Effects
import "../"
import "root:/"

BarBlock {
  IconImage {
    id: svgImage
    source: Quickshell.iconPath("/etc/xdg/bar/components/assets/NixOS_logo.svg")
    implicitSize: 25
    anchors.centerIn: parent
  }
  MultiEffect {
    anchors.fill: svgImage
    source: svgImage
    colorization: 1.0
    colorizationColor: "transparent"
  }
}
