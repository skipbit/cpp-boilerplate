import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import myapp

// The interface, and nothing else. There is no rule in this file: what matches
// is decided in catalogue, how a row reads in presentation, and both reach here
// through FilteredEntries. A binding is the whole wiring - nothing here is told
// when to update, it says what it shows and follows.

ApplicationWindow {
    id: window

    width: 420
    height: 320
    visible: true
    title: qsTr("myapp")

    FilteredEntries {
        id: entries
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        TextField {
            id: query

            objectName: "query"
            Layout.fillWidth: true
            placeholderText: qsTr("filter")
            onTextChanged: entries.query = query.text
        }

        Label {
            objectName: "summary"
            text: entries.summary
        }

        ListView {
            objectName: "matches"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: entries
            delegate: Label {
                required property string label

                text: label
            }
        }
    }
}
