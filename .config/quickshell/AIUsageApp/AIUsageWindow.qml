import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

// AI usage dropdown: session/weekly rate-limit %, tokens by day, tokens by
// model — one tab per provider script under
// ~/.config/waybar/scripts/ai-usage/providers/. Adding a new AI tool means
// dropping a script there; this panel just renders whatever collect.sh
// reports, it has no per-tool logic of its own.
PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: 360
    implicitHeight: Math.min(mainContentColumn.implicitHeight + 220, 620)
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    margins {
        top: root.currentTopMargin
        right: 12
    }

    property bool isOpen: false
    visible: isOpen || slideAnim.running
    property real currentTopMargin: isOpen ? 40 : -700

    Behavior on currentTopMargin {
        NumberAnimation {
            id: slideAnim
            duration: 250
            easing.type: Easing.OutQuint
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: if (root.isOpen) root.isOpen = false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: if (root.isOpen) root.isOpen = false
    }

    IpcHandler {
        target: "ai-usage"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
        function isOpen(): bool { return root.isOpen }
    }

    property var providersData: []
    property int activeTab: 0
    property var currentProvider: providersData.length > activeTab ? providersData[activeTab] : null

    function fmtNum(n) {
        if (n >= 1000000) return (n / 1000000).toFixed(1) + "M"
        if (n >= 1000) return (n / 1000).toFixed(1) + "K"
        return String(n)
    }

    function maxValue(arr) {
        if (!arr || arr.length === 0) return 1
        let m = 1
        for (let i = 0; i < arr.length; i++) if (arr[i].value > m) m = arr[i].value
        return m
    }

    function barColor(percent) {
        if (percent >= 90) return Theme.error
        if (percent >= 75) return "#e6621c"
        if (percent >= 50) return Theme.tertiary
        return Theme.primary
    }

    function loadData(force) {
        collectProc.command = force
            ? ["bash", "-c", Quickshell.env("HOME") + "/.config/waybar/scripts/ai-usage/collect.sh --force"]
            : ["bash", "-c", Quickshell.env("HOME") + "/.config/waybar/scripts/ai-usage/collect.sh"]
        collectProc.running = false
        collectProc.running = true
    }

    onIsOpenChanged: if (isOpen) loadData(false)

    Process {
        id: collectProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(this.text.trim())
                    root.providersData = parsed.providers || []
                    if (root.activeTab >= root.providersData.length) root.activeTab = 0
                } catch (e) {
                    console.log("ai-usage: failed to parse collect.sh output: " + e)
                }
            }
        }
    }

    component TabButton: Button {
        property bool active: false
        implicitHeight: 30
        background: Rectangle {
            radius: 8
            color: active ? Theme.primary : "transparent"
            border.color: Theme.primary
            border.width: 1
        }
        contentItem: Text {
            text: parent.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: active ? Theme.on_primary : Theme.primary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    component ActionIcon: Button {
        property string iconTxt: ""
        implicitWidth: 26
        implicitHeight: 26
        background: Rectangle { color: "transparent" }
        contentItem: Text {
            anchors.centerIn: parent
            text: iconTxt
            color: Theme.primary
            font.family: "monospace"
            font.pixelSize: 15
        }
    }

    component SectionLabel: Text {
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.bold: true
        color: Theme.on_background
        opacity: 0.6
    }

    component PercentBar: Rectangle {
        property real percent: 0
        implicitHeight: 8
        radius: 4
        color: Theme.surface_container_high
        border.color: Theme.outline_variant
        border.width: 1
        Rectangle {
            width: Math.max(4, parent.width * Math.min(percent, 100) / 100)
            height: parent.height
            radius: parent.radius
            color: root.barColor(percent)
        }
    }

    component ValueBar: Rectangle {
        property real fraction: 0
        implicitHeight: 8
        radius: 4
        color: Theme.surface_container_high
        Rectangle {
            width: Math.max(3, parent.width * Math.min(fraction, 1))
            height: parent.height
            radius: parent.radius
            color: Theme.primary
        }
    }

    // --- MAIN CARD ---
    Item {
        anchors.fill: parent
        anchors.margins: 10

        Rectangle {
            id: mainBgRect
            anchors.fill: parent
            radius: 12
            opacity: 0.97

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.primary }
                GradientStop { position: 1.0; color: Theme.on_primary }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: parent.radius - anchors.margins
                color: Theme.background
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // --- HEADER ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "✳"
                    color: Theme.primary
                    font.pixelSize: 18
                }
                Text {
                    text: root.currentProvider ? root.currentProvider.name : "AI Usage"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    visible: root.currentProvider && root.currentProvider.plan
                    text: root.currentProvider ? root.currentProvider.plan : ""
                    color: Theme.on_background
                    opacity: 0.6
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                ActionIcon {
                    iconTxt: "↻"
                    onClicked: root.loadData(true)
                }
            }

            // --- TABS ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.providersData.length > 0

                Repeater {
                    model: root.providersData
                    delegate: TabButton {
                        text: modelData.name
                        active: index === root.activeTab
                        onClicked: root.activeTab = index
                    }
                }
                Item { Layout.fillWidth: true }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3 }

            Text {
                visible: root.providersData.length === 0
                text: "Loading…"
                color: Theme.on_background
                opacity: 0.6
                font.family: Theme.fontFamily
            }

            Text {
                visible: root.currentProvider && !root.currentProvider.available
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: root.currentProvider ? root.currentProvider.message : ""
                color: Theme.on_background
                opacity: 0.7
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }

            // --- SCROLLABLE BODY ---
            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: mainContentColumn.implicitHeight
                clip: true
                visible: root.currentProvider && root.currentProvider.available

                ColumnLayout {
                    id: mainContentColumn
                    width: scrollView.width
                    spacing: 16

                    // LIMITS
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: root.currentProvider && root.currentProvider.limits.length > 0

                        SectionLabel { text: "LIMITS" }

                        Repeater {
                            model: root.currentProvider ? root.currentProvider.limits : []
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: modelData.label
                                        color: Theme.on_background
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: modelData.percent + "%"
                                        color: Theme.on_background
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                    }
                                }
                                PercentBar { Layout.fillWidth: true; percent: modelData.percent }
                                Text {
                                    text: "Resets in " + modelData.resets_in
                                    color: Theme.on_background
                                    opacity: 0.5
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.2
                        visible: root.currentProvider && root.currentProvider.tokens_by_day.length > 0
                    }

                    // TOKENS BY DAY
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: root.currentProvider && root.currentProvider.tokens_by_day.length > 0

                        SectionLabel { text: "TOKENS BY DAY" }

                        Repeater {
                            model: root.currentProvider ? root.currentProvider.tokens_by_day : []
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: modelData.label
                                    color: Theme.on_background
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 44
                                }
                                ValueBar {
                                    Layout.fillWidth: true
                                    fraction: modelData.value / root.maxValue(root.currentProvider.tokens_by_day)
                                }
                                Text {
                                    text: root.fmtNum(modelData.value)
                                    color: Theme.on_background
                                    opacity: 0.7
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 44
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.2
                        visible: root.currentProvider && root.currentProvider.tokens_by_model.length > 0
                    }

                    // TOKENS BY MODEL
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: root.currentProvider && root.currentProvider.tokens_by_model.length > 0

                        SectionLabel { text: "TOKENS BY MODEL" }

                        Repeater {
                            model: root.currentProvider ? root.currentProvider.tokens_by_model : []
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: modelData.label
                                    color: Theme.on_background
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 90
                                    elide: Text.ElideRight
                                }
                                ValueBar {
                                    Layout.fillWidth: true
                                    fraction: modelData.value / root.maxValue(root.currentProvider.tokens_by_model)
                                }
                                Text {
                                    text: root.fmtNum(modelData.value)
                                    color: Theme.on_background
                                    opacity: 0.7
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 44
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
