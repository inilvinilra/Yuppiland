import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#000000"

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000d8"
    }

    // ── VOID PALETTE ──
    readonly property color colBg:       "#000000"
    readonly property color colSurface:  "#080808"
    readonly property color colOverlay:  "#1a1a1a"
    readonly property color colMuted:    "#2a2a2a"
    readonly property color colSubtle:   "#555555"
    readonly property color colSubtext:  "#888888"
    readonly property color colText:     "#cccccc"
    readonly property color colBright:   "#e8e8e8"
    readonly property color colWhite:    "#ffffff"
    readonly property color colRed:      "#cc4444"

    readonly property string fontFamily: config.Font || "JetBrains Mono Nerd Font"
    readonly property int    fontSize:   config.FontSize || 12

    // ── CONNECTION ──
    Connections {
        target: sddm
        function onLoginSucceeded() {
            errorLabel.text = ""
        }
        function onLoginFailed() {
            errorLabel.text = "authentication failed"
            passwordField.text = ""
            passwordField.focus = true
        }
    }

    // ── CLOCK ──
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.22
        spacing: 8

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 64
            font.weight: Font.Normal
            color: root.colBright
            renderType: Text.NativeRendering

            function updateTime() {
                text = Qt.formatTime(new Date(), "HH:mm")
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeLabel.updateTime()
            }

            Component.onCompleted: updateTime()
        }

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 16
            font.weight: Font.Normal
            color: root.colSubtext
            renderType: Text.NativeRendering

            function updateDate() {
                text = Qt.formatDate(new Date(), "dddd, MMMM d")
            }

            Timer {
                interval: 60000
                running: true
                repeat: true
                onTriggered: dateLabel.updateDate()
            }

            Component.onCompleted: updateDate()
        }
    }

    // ── LOGIN FORM ──
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 40
        spacing: 14
        width: 280

        // username
        Text {
            id: usernameLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: userModel.lastUser || ""
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: root.colSubtle
            renderType: Text.NativeRendering
        }

        // password field
        TextField {
            id: passwordField
            width: parent.width
            height: 42
            placeholderText: "enter password..."
            echoMode: TextInput.Password
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            horizontalAlignment: TextInput.AlignHCenter

            color: root.colText
            selectionColor: root.colOverlay
            selectedTextColor: root.colBright
            placeholderTextColor: root.colSubtle

            background: Rectangle {
                color: root.colSurface
                border.color: passwordField.activeFocus ? root.colSubtle : root.colOverlay
                border.width: 1
                radius: 5
            }

            Keys.onReturnPressed: {
                sddm.login(userModel.lastUser, passwordField.text, sessionModel.lastIndex)
            }

            Component.onCompleted: {
                forceActiveFocus()
            }
        }

        // error message
        Text {
            id: errorLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            font.family: root.fontFamily
            font.pixelSize: 11
            color: root.colRed
            renderType: Text.NativeRendering
        }
    }

    // ── SESSION SELECTOR (bottom-left) ──
    ComboBox {
        id: sessionBox
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 20
        width: 180
        height: 32
        model: sessionModel
        currentIndex: sessionModel.lastIndex
        textRole: "name"
        font.family: root.fontFamily
        font.pixelSize: 11

        contentItem: Text {
            text: sessionBox.displayText
            font: sessionBox.font
            color: root.colSubtext
            verticalAlignment: Text.AlignVCenter
            leftPadding: 10
            renderType: Text.NativeRendering
        }

        background: Rectangle {
            color: root.colSurface
            border.color: root.colOverlay
            border.width: 1
            radius: 5
        }

        popup: Popup {
            y: -contentItem.implicitHeight - 4
            width: sessionBox.width
            implicitHeight: contentItem.implicitHeight + 2
            padding: 1

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: sessionBox.popup.visible ? sessionBox.delegateModel : null

                delegate: ItemDelegate {
                    width: sessionBox.width
                    height: 30

                    contentItem: Text {
                        text: model.name
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        color: highlighted ? root.colBright : root.colSubtext
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                        renderType: Text.NativeRendering
                    }

                    background: Rectangle {
                        color: highlighted ? root.colOverlay : root.colSurface
                    }

                    highlighted: sessionBox.highlightedIndex === index
                }
            }

            background: Rectangle {
                color: root.colSurface
                border.color: root.colOverlay
                border.width: 1
                radius: 5
            }
        }

        onCurrentIndexChanged: {
            sessionModel.lastIndex = currentIndex
        }
    }

    // ── POWER BUTTONS (bottom-right) ──
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        spacing: 16

        Text {
            text: "⏻"
            font.family: root.fontFamily
            font.pixelSize: 16
            color: ma_shutdown.containsMouse ? root.colRed : root.colSubtle
            renderType: Text.NativeRendering

            MouseArea {
                id: ma_shutdown
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.powerOff()
            }
        }

        Text {
            text: "⟳"
            font.family: root.fontFamily
            font.pixelSize: 16
            color: ma_reboot.containsMouse ? root.colText : root.colSubtle
            renderType: Text.NativeRendering

            MouseArea {
                id: ma_reboot
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.reboot()
            }
        }
    }

    // ── HOSTNAME (bottom-center) ──
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 22
        text: sddm.hostName || ""
        font.family: root.fontFamily
        font.pixelSize: 10
        color: root.colMuted
        renderType: Text.NativeRendering
    }
}
