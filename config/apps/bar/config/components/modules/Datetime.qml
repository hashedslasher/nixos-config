import Quickshell
import Quickshell.Io
import "../"

BarBlock {
  id: root
  content: BarText {
    symbolText: `${dateTime}`// 
  }
  
  readonly property string dateTime: {

    Qt.formatDateTime(clock.date, "ddd MMM d | hh:mm")
  }
  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
