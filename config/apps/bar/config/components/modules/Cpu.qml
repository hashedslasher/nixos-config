import QtQuick
import Quickshell.Io
import "../"

BarBlock {
  id: root
  content: BarText {
    symbolText: ` ${Math.floor(usage)}%`
  }

  property string usage

  Process {
    id: cpuProc
    //command: ["sh", "-c", "sensors | grep -i 'tccd1' | awk {'print $2'} | tr -d '+'"]
    command: ["sh", "-c", "mpstat 1 1 | grep 'Average' | awk '{print 100 - $12}'"]
    //command: [ "sh", "-c", "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}'"]
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
