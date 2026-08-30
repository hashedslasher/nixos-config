import QtQuick
import Quickshell.Io
import "../"

BarBlock {
  id: root
  content: BarText {
    symbolText: `${device}`
  }

  property string device
  property string type

  Process {
    id: netState
    command: ["sh", "-c", "nmcli mon | grep -E 'none|running|full'"]
    running: true

    stdout: SplitParser {
      onRead: netType.running = true
    }
  }
  
  Process {
    id: netType
    command: ["sh", "-c", "nmcli -g STATE,TYPE d"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split('\n');
        root.type = lines.find(line => line.startsWith('connected:'))?.split(':')[1] || null;
        if (root.type === "ethernet") root.device = "󰈁"
        else if (root.type === "wifi") netStrength.running = true
      }
    }
  }

  Process {
    id: netStrength
    command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\*/{if (NR!=1) {print $2}}'"]
    running: true
    
    stdout: SplitParser {
      onRead: function(data){
        if (data >= 75) root.device ="󰤨"
        else if (data >= 50) root.device ="󰤢"
        else if (data >= 25) root.device ="󰤟"
        else root.device ="󰤯"
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: netStrength.running = true
  }
}
