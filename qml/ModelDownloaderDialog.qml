import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts
import download
import llm

Dialog {
    id: modelDownloaderDialog
    width: 1024
    height: 435
    modal: true
    opacity: 0.9
    closePolicy: LLM.modelList.length === 0 ? Popup.NoAutoClose : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)
    background: Rectangle {
        anchors.fill: parent
        anchors.margins: -20
        color: theme.backgroundDarkest
        border.width: 1
        border.color: theme.dialogBorder
        radius: 10
    }

    Component.onCompleted: {
        if (LLM.modelList.length === 0)
            open();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 30

        Label {
            id: listLabel
            text: "Available Models:"
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            color: theme.textColor
        }

        ScrollView {
            id: scrollView
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: modelList
                model: Download.modelList
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: delegateItem
                    width: modelList.width
                    height: 70
                    objectName: "delegateItem"
                    property bool downloading: false
                    Rectangle {
                        anchors.fill: parent
                        color: index % 2 === 0 ? theme.backgroundLight : theme.backgroundLighter
                    }

                    Text {
                        id: modelName
                        objectName: "modelName"
                        property string filename: modelData.filename
                        text: filename.slice(5, filename.length - 4)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        color: theme.textColor
                        Accessible.role: Accessible.Paragraph
                        Accessible.name: qsTr("Model file")
                        Accessible.description: qsTr("Model file to be downloaded")
                    }

                    Text {
                        id: isDefault
                        text: qsTr("(default)")
                        visible: modelData.isDefault
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: modelName.right
                        anchors.leftMargin: 10
                        color: theme.textColor
                        Accessible.role: Accessible.Paragraph
                        Accessible.name: qsTr("Default file")
                        Accessible.description: qsTr("Whether the file is the default model")
                    }

                    Text {
                        text: modelData.filesize
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: isDefault.visible ? isDefault.right : modelName.right
                        anchors.leftMargin: 10
                        color: theme.textColor
                        Accessible.role: Accessible.Paragraph
                        Accessible.name: qsTr("File size")
                        Accessible.description: qsTr("The size of the file")
                    }

                    Label {
                        id: speedLabel
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: itemProgressBar.left
                        anchors.rightMargin: 10
                        objectName: "speedLabel"
                        color: theme.textColor
                        text: ""
                        visible: downloading
                        Accessible.role: Accessible.Paragraph
                        Accessible.name: qsTr("Download speed")
                        Accessible.description: qsTr("Download speed in bytes/kilobytes/megabytes per second")
                    }

                    ProgressBar {
                        id: itemProgressBar
                        objectName: "itemProgressBar"
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: downloadButton.left
                        anchors.rightMargin: 10
                        width: 100
                        visible: downloading
                        background: Rectangle {
                            implicitWidth: 200
                            implicitHeight: 30
                            color: theme.backgroundDarkest
                            radius: 3
                        }

                        contentItem: Item {
                            implicitWidth: 200
                            implicitHeight: 25

                            Rectangle {
                                width: itemProgressBar.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: theme.backgroundLightest
                            }
                        }
                        Accessible.role: Accessible.ProgressBar
                        Accessible.name: qsTr("Download progressBar")
                        Accessible.description: qsTr("Shows the progress made in the download")
                    }

                    Item {
                        visible: modelData.calcHash
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 10

                        Label {
                            id: calcHashLabel
                            anchors.right: busyCalcHash.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            objectName: "calcHashLabel"
                            color: theme.textColor
                            text: qsTr("Calculating MD5...")
                            Accessible.role: Accessible.Paragraph
                            Accessible.name: text
                            Accessible.description: qsTr("Whether the file hash is being calculated")
                        }

                        BusyIndicator {
                            id: busyCalcHash
                            anchors.right: parent.right
                            anchors.verticalCenter: calcHashLabel.verticalCenter
                            running: modelData.calcHash
                            Accessible.role: Accessible.Animation
                            Accessible.name: qsTr("Busy indicator")
                            Accessible.description: qsTr("Displayed when the file hash is being calculated")
                        }
                    }

                    Label {
                        id: installedLabel
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 15
                        objectName: "installedLabel"
                        color: theme.textColor
                        text: qsTr("Already installed")
                        visible: modelData.installed
                        Accessible.role: Accessible.Paragraph
                        Accessible.name: text
                        Accessible.description: qsTr("Whether the file is already installed on your system")
                    }

                    Button {
                        id: downloadButton
                        contentItem: Text {
                            color: theme.textColor
                            text: downloading ? "Cancel" : "Download"
                        }
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        visible: !modelData.installed && !modelData.calcHash
                        padding: 10
                        onClicked: {
                            if (!downloading) {
                                downloading = true;
                                Download.downloadModel(modelData.filename);
                            } else {
                                downloading = false;
                                Download.cancelDownload(modelData.filename);
                            }
                        }
                        background: Rectangle {
                            opacity: .5
                            border.color: theme.backgroundLightest
                            border.width: 1
                            radius: 10
                            color: theme.backgroundLight
                        }
                        Accessible.role: Accessible.Button
                        Accessible.name: text
                        Accessible.description: qsTr("Cancel/Download button to stop/start the download")

                    }
                }

                Component.onCompleted: {
                    Download.downloadProgress.connect(updateProgress);
                    Download.downloadFinished.connect(resetProgress);
                }

                property var lastUpdate: ({})

                function updateProgress(bytesReceived, bytesTotal, modelName) {
                    let currentTime = new Date().getTime();

                    for (let i = 0; i < modelList.contentItem.children.length; i++) {
                        let delegateItem = modelList.contentItem.children[i];
                        if (delegateItem.objectName === "delegateItem") {
                            let modelNameText = delegateItem.children.find(child => child.objectName === "modelName").filename;
                            if (modelNameText === modelName) {
                                let progressBar = delegateItem.children.find(child => child.objectName === "itemProgressBar");
                                progressBar.value = bytesReceived / bytesTotal;

                                // Calculate the download speed
                                if (lastUpdate[modelName] && lastUpdate[modelName].timestamp) {
                                    let timeDifference = currentTime - lastUpdate[modelName].timestamp;
                                    let bytesDifference = bytesReceived - lastUpdate[modelName].bytesReceived;
                                    let speed = (bytesDifference / timeDifference) * 1000; // bytes per second

                                    // Update the speed label
                                    let speedLabel = delegateItem.children.find(child => child.objectName === "speedLabel");
                                    if (speed < 1024) {
                                        speedLabel.text = speed.toFixed(2) + " B/s";
                                    } else if (speed < 1024 * 1024) {
                                        speedLabel.text = (speed / 1024).toFixed(2) + " KB/s";
                                    } else {
                                        speedLabel.text = (speed / (1024 * 1024)).toFixed(2) + " MB/s";
                                    }
                                }

                                // Update the lastUpdate object for the current model
                                lastUpdate[modelName] = {"timestamp": currentTime, "bytesReceived": bytesReceived};
                                break;
                            }
                        }
                    }
                }

                function resetProgress(modelName) {
                    for (let i = 0; i < modelList.contentItem.children.length; i++) {
                        let delegateItem = modelList.contentItem.children[i];
                        if (delegateItem.objectName === "delegateItem") {
                            let modelNameText = delegateItem.children.find(child => child.objectName === "modelName").filename;
                            if (modelNameText === modelName) {
                                let progressBar = delegateItem.children.find(child => child.objectName === "itemProgressBar");
                                progressBar.value = 0;
                                delegateItem.downloading = false;

                                // Remove speed label text
                                let speedLabel = delegateItem.children.find(child => child.objectName === "speedLabel");
                                speedLabel.text = "";

                                // Remove the lastUpdate object for the canceled model
                                delete lastUpdate[modelName];
                                break;
                            }
                        }
                    }
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            text: qsTr("NOTE: models will be downloaded to\n") + Download.downloadLocalModelsPath()
            wrapMode: Text.WrapAnywhere
            horizontalAlignment: Text.AlignHCenter
            color: theme.textColor
            Accessible.role: Accessible.Paragraph
            Accessible.name: qsTr("Model download path")
            Accessible.description: qsTr("The path where downloaded models will be saved.")
        }
    }
}
