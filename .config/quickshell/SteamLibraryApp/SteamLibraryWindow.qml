import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

// Steam library dropdown: owned games with ProtonDB compatibility tiers.
// collect.sh owns all the Steam/ProtonDB API + caching logic; this panel
// just renders whatever it reports and lets you filter/sort the list.
PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: 380
    implicitHeight: 560
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
    property bool autoClosePaused: false
    // See AIUsageWindow.qml for why this exists separately from isOpen --
    // HyprlandFocusGrab needs to be pulsed false->true to re-request the
    // compositor grab after being paused (e.g. during a screenshot).
    property bool grabActive: false
    visible: isOpen || slideAnim.running
    property real currentTopMargin: isOpen ? 40 : -700

    Behavior on currentTopMargin {
        NumberAnimation {
            id: slideAnim
            duration: 250
            easing.type: Easing.OutQuint
        }
    }

    Timer {
        id: reArmGrabTimer
        interval: 0
        onTriggered: if (root.isOpen) root.grabActive = true
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.grabActive
        onCleared: if (root.isOpen && !root.autoClosePaused) root.isOpen = false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: if (root.isOpen) root.isOpen = false
    }

    IpcHandler {
        target: "steam-library"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
        function isOpen(): bool { return root.isOpen }
        function pauseAutoClose(): void { root.autoClosePaused = true }
        function resumeAutoClose(): void {
            root.autoClosePaused = false
            if (root.isOpen) {
                root.grabActive = false
                reArmGrabTimer.restart()
            }
        }
    }

    property bool configured: true
    property string reason: ""
    property string message: ""
    property var allGames: []
    property int checking: 0
    property string filterText: ""
    property bool showSetupForm: false
    property string setupError: ""

    readonly property var tierRank: ({
        platinum: 0, gold: 1, silver: 2, bronze: 3,
        borked: 4, pending: 5, unknown: 6
    })
    readonly property var tierColor: ({
        platinum: "#b9d3e0", gold: "#d4af37", silver: "#adb5bd", bronze: "#b06a35",
        borked: Theme.error, pending: Theme.outline_variant, unknown: Theme.outline_variant
    })
    readonly property var tierLabel: ({
        platinum: "Platinum", gold: "Gold", silver: "Silver", bronze: "Bronze",
        borked: "Borked", pending: "No reports", unknown: "Checking…"
    })

    property var filteredGames: {
        let list = root.allGames
        if (root.filterText.length > 0) {
            const needle = root.filterText.toLowerCase()
            list = list.filter(g => g.name.toLowerCase().includes(needle))
        }
        return list.slice().sort((a, b) => {
            const ra = root.tierRank[a.tier] ?? 6
            const rb = root.tierRank[b.tier] ?? 6
            if (ra !== rb) return ra - rb
            return a.name.localeCompare(b.name)
        })
    }

    function fmtPlaytime(minutes) {
        if (!minutes || minutes <= 0) return "unplayed"
        const hours = minutes / 60
        return (hours >= 10 ? hours.toFixed(0) : hours.toFixed(1)) + "h"
    }

    function loadData(force) {
        collectProc.command = force
            ? ["bash", "-c", Quickshell.env("HOME") + "/.config/quickshell/SteamLibraryApp/scripts/collect.sh --force"]
            : ["bash", "-c", Quickshell.env("HOME") + "/.config/quickshell/SteamLibraryApp/scripts/collect.sh"]
        collectProc.running = false
        collectProc.running = true
    }

    onIsOpenChanged: {
        grabActive = isOpen
        if (isOpen) loadData(false)
    }

    Process {
        id: collectProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(this.text.trim())
                    root.configured = parsed.configured !== false
                    root.reason = parsed.reason || ""
                    root.message = parsed.message || ""
                    root.allGames = parsed.games || []
                    root.checking = parsed.checking || 0
                    if (!root.configured) root.showSetupForm = true
                } catch (e) {
                    console.log("steam-library: failed to parse collect.sh output: " + e)
                }
            }
        }
    }

    Process {
        id: bigPictureProc
        command: ["qs", "ipc", "call", "steam-library-big", "open"]
    }

    Process {
        id: wishlistProc
        command: ["qs", "ipc", "call", "steam-library-wishlist", "open"]
    }

    function saveCredentials(apiKey, steamId64) {
        saveProc.command = ["bash", "-c", Quickshell.env("HOME") + "/.config/quickshell/SteamLibraryApp/scripts/save-credentials.sh"]
        saveProc.running = false
        saveProc.running = true
        saveProc.write(JSON.stringify({ api_key: apiKey, steam_id64: steamId64 }) + "\n")
    }

    Process {
        id: saveProc
        stdinEnabled: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(this.text.trim())
                    if (parsed.success) {
                        root.setupError = ""
                        root.showSetupForm = false
                        apiKeyField.text = ""
                        steamIdField.text = ""
                        root.loadData(true)
                    } else {
                        root.setupError = parsed.message || "Failed to save"
                    }
                } catch (e) {
                    root.setupError = "Failed to save (unexpected response)"
                }
            }
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

    component TierBadge: Rectangle {
        property string tier: "unknown"
        implicitWidth: badgeText.implicitWidth + 14
        implicitHeight: 20
        radius: 10
        color: Qt.rgba(0, 0, 0, 0)
        border.width: 1
        border.color: root.tierColor[tier] || Theme.outline_variant
        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.tierLabel[tier] || "Unknown"
            color: root.tierColor[tier] || Theme.outline_variant
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }
    }

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

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "🎮"
                    font.pixelSize: 18
                }
                Text {
                    text: "Steam Library"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    visible: root.configured
                    text: root.allGames.length + " games"
                    color: Theme.on_background
                    opacity: 0.6
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                ActionIcon {
                    visible: root.configured && !root.showSetupForm
                    iconTxt: "❤"
                    onClicked: {
                        root.isOpen = false
                        wishlistProc.running = false
                        wishlistProc.running = true
                    }
                }
                ActionIcon {
                    visible: root.configured && !root.showSetupForm
                    iconTxt: "⛶"
                    onClicked: {
                        root.isOpen = false
                        bigPictureProc.running = false
                        bigPictureProc.running = true
                    }
                }
                ActionIcon {
                    visible: root.configured
                    iconTxt: "⚙"
                    onClicked: root.showSetupForm = !root.showSetupForm
                }
                ActionIcon {
                    iconTxt: "↻"
                    onClicked: root.loadData(true)
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3 }

            Text {
                visible: root.configured && root.reason === "fetch_failed" && !root.showSetupForm
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: root.message
                color: Theme.on_background
                opacity: 0.75
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }

            // --- SETUP FORM: shown on first run (no credentials yet) or
            // whenever the gear icon is clicked to rotate the key later.
            // Values go straight to save-credentials.sh over stdin, which
            // stores them in the OS keyring -- never written to disk here.
            ColumnLayout {
                visible: root.showSetupForm
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Get a key (instant, no approval needed): steamcommunity.com/dev/apikey\nGet your SteamID64: steamid.io"
                    color: Theme.on_background
                    opacity: 0.6
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                TextField {
                    id: apiKeyField
                    Layout.fillWidth: true
                    placeholderText: "Steam Web API key"
                    echoMode: TextInput.Password
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.on_background
                    background: Rectangle {
                        radius: 8
                        color: Theme.surface_container_high
                        border.color: Theme.outline_variant
                        border.width: 1
                    }
                }

                TextField {
                    id: steamIdField
                    Layout.fillWidth: true
                    placeholderText: "SteamID64"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.on_background
                    background: Rectangle {
                        radius: 8
                        color: Theme.surface_container_high
                        border.color: Theme.outline_variant
                        border.width: 1
                    }
                }

                Text {
                    visible: root.setupError.length > 0
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: root.setupError
                    color: Theme.error
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        text: "Save"
                        enabled: apiKeyField.text.length > 0 && steamIdField.text.length > 0
                        onClicked: root.saveCredentials(apiKeyField.text, steamIdField.text)
                    }
                    Button {
                        visible: root.configured
                        text: "Cancel"
                        onClicked: {
                            root.showSetupForm = false
                            root.setupError = ""
                            apiKeyField.text = ""
                            steamIdField.text = ""
                        }
                    }
                }
            }

            TextField {
                visible: root.configured && !root.showSetupForm
                Layout.fillWidth: true
                placeholderText: "Filter games…"
                text: root.filterText
                onTextChanged: root.filterText = text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.on_background
                background: Rectangle {
                    radius: 8
                    color: Theme.surface_container_high
                    border.color: Theme.outline_variant
                    border.width: 1
                }
            }

            Text {
                visible: root.configured && root.checking > 0 && !root.showSetupForm
                text: root.checking + " tier(s) still checking against ProtonDB…"
                color: Theme.on_background
                opacity: 0.5
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            ListView {
                visible: root.configured && !root.showSetupForm && root.reason !== "fetch_failed"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: root.filteredGames

                delegate: Rectangle {
                    width: ListView.view.width
                    implicitHeight: 40
                    radius: 8
                    color: Theme.surface_container_high

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: Theme.on_background
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Text {
                            text: root.fmtPlaytime(modelData.playtime_forever)
                            color: Theme.on_background
                            opacity: 0.5
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        TierBadge { tier: modelData.tier }
                    }
                }
            }
        }
    }
}
