import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitHeight: 30

    property var tags: Array.from({ length: 9 }, () => ({
        active: false,
        filled: false
    }))

    property string buffer: ""

    implicitWidth: tagBar.implicitWidth

    Process {
        id: tagPoll
        command: ["sh", "-c", "mmsg -w -t"]
        running: true

        stdout: SplitParser {
            onRead: {
                tagInfo.running = true;
            }
        }
    }

    Process {
        id: tagInfo
        command: ["sh", "-c", "mmsg -g -t"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.buffer += text;
                const lines = root.buffer.split("\n");
                root.buffer = lines.pop();

                let lastTagsLine = null;

                for (let line of lines) {
                    line = line.trim();
                    if (!line)
                        continue;

                    const parts = line.split(/\s+/);

                    if (parts.length >= 5 && parts[1] === "tags") {
                        lastTagsLine = parts;
                    }
                }

                if (!lastTagsLine)
                    return;

                const filledMask = lastTagsLine[2];
                const activeMask = lastTagsLine[3];

                let newTags = [];
                for (let i = 0; i < 9; i++) {
                    const rev = filledMask.length - 1 - i;
                
                    newTags.push({
                        filled: filledMask[rev] === "1",
                        active: activeMask[rev] === "1"
                    });
                }
                root.tags = newTags;
            }
        }
    }

    Rectangle {
        id: tagBar
        anchors.verticalCenter: parent.verticalCenter
        height: 24
        radius: 4

        color: "#000000"
        border.color: "#ffffff"
        border.width: 1

        implicitWidth: textItem.implicitWidth + 12

        Text {
            id: textItem
            anchors.centerIn: parent
            font.pixelSize: 18
            font.family: "Blex Mono Nerd Font"
            //textFormat: Text.RichText

            text: {
                let result = "";

                for (let i = 0; i < root.tags.length; i++) {
                    const t = root.tags[i];

                    if (t.active) {
                        result += `<font color="#ffffff">${i+1}</font>`;
                    } else if (t.filled) {
                        result += `<font color="#aaaaaa">${i+1}</font>`;
                    } else {
                        result += `<font color="#444b6a">${i+1}</font>`;
                    }

                    if (i !== root.tags.length - 1)
                        result += " ";
                }

                return result;
            }
        }

        MouseArea {
            anchors.fill: parent

            onClicked: (mouse) => {
                const charWidth = textItem.width / root.tags.length;
                const idx = Math.floor(mouse.x / charWidth);

                if (idx >= 0 && idx < 9) {
                    Process.startDetached([
                        "mmsg",
                        "-t",
                        (idx + 1).toString()
                    ]);
                }
            }
        }
    }
}
