import QtQuick
import Quickshell.Io
import "../"

BarBlock {
  id: root
  content: BarText {
    symbolText: ` ${Math.floor(usage)}%`
  }

  property string usage

  Process {
    id: cpuProc
    command: ["sh", "-c", "free | grep Mem | awk '{print $3/$2 * 100.0}'"]
    running: true

    stdout: SplitParser {
      onRead: data => usage = data
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: cpuProc.running = true
  }
}
