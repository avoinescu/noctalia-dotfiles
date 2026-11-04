import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

// Second view alongside SteamBigPictureWindow: same ProtonDB/Deck/anti-cheat
///native-Linux playability signals, applied to your Steam wishlist instead
// of your owned library -- "which of these would actually run well before I
// buy them." Deliberately its own window rather than a tab bolted onto the
// big-picture one: wishlist games have no playtime/installed/achievements,
// so most of that file's per-game fields and category chips don't apply,
// and duplicating the (small) shared bits here keeps both files simple and
// independently readable, matching how every other panel in this repo is
// its own self-contained file.
PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property bool isOpen: false
    property bool autoClosePaused: false
    property bool grabActive: false
    visible: isOpen

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
        onActivated: {
            if (root.selectedGame !== null) root.selectedGame = null
            else if (root.isOpen) root.isOpen = false
        }
    }

    IpcHandler {
        target: "steam-library-wishlist"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
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
    property var summary: ({})
    property int checking: 0
    property string filterText: ""
    property string selectedCategory: "all"
    property var selectedGame: null

    readonly property var tierColor: ({
        platinum: "#b9d3e0", gold: "#d4af37", silver: "#adb5bd", bronze: "#b06a35",
        borked: Theme.error, pending: Theme.outline_variant, unknown: Theme.outline_variant
    })
    readonly property var tierLabel: ({
        platinum: "Platinum", gold: "Gold", silver: "Silver", bronze: "Bronze",
        borked: "Borked", pending: "No reports", unknown: "Checking…"
    })
    readonly property var categoryLabel: ({
        all: "All", great: "Great", playable: "Playable",
        anticheat_blocked: "Anti-cheat blocked", borked: "Borked", checking: "Checking"
    })
    readonly property var categoryColor: ({
        great: "#4caf7d", playable: "#5b9bd5", anticheat_blocked: "#e0a03c",
        borked: Theme.error, checking: Theme.outline_variant
    })
    readonly property var deckColor: ({ 3: "#4caf7d", 2: "#5b9bd5", 1: Theme.error, 0: Theme.outline_variant })

    property var filteredGames: {
        let list = root.allGames
        if (root.selectedCategory !== "all")
            list = list.filter(g => g.category === root.selectedCategory)
        if (root.filterText.length > 0) {
            const needle = root.filterText.toLowerCase()
            list = list.filter(g => g.name.toLowerCase().includes(needle))
        }
        // Wishlist priority is Steam's own manual ranking (lower = higher up
        // your list); games added without ever being manually ranked come
        // back as priority 0, which would otherwise sort first -- push those
        // to the end instead so the ranking reflects intent, not omission.
        return list.slice().sort((a, b) => {
            const pa = a.priority > 0 ? a.priority : 9999
            const pb = b.priority > 0 ? b.priority : 9999
            if (pa !== pb) return pa - pb
            return b.date_added - a.date_added
        })
    }

    function fmtDate(unixSeconds) {
        if (!unixSeconds) return "unknown"
        const d = new Date(unixSeconds * 1000)
        return d.toLocaleDateString(Qt.locale(), "d MMM yyyy")
    }

    function loadData(force) {
        collectProc.command = force
            ? ["bash", "-c", Quickshell.env("HOME") + "/.config/quickshell/SteamLibraryApp/scripts/wishlist-collect.sh --force"]
            : ["bash", "-c", Quickshell.env("HOME") + "/.config/quickshell/SteamLibraryApp/scripts/wishlist-collect.sh"]
        collectProc.running = false
        collectProc.running = true
    }

    onIsOpenChanged: {
        grabActive = isOpen
        if (isOpen) loadData(false)
    }

    Process {
        id: libraryProc
        command: ["qs", "ipc", "call", "steam-library-big", "open"]
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
                    root.summary = parsed.summary || {}
                    root.checking = parsed.checking || 0
                } catch (e) {
                    console.log("steam-library (wishlist): failed to parse wishlist-collect.sh output: " + e)
                }
            }
        }
    }

    component ActionIcon: Button {
        property string iconTxt: ""
        implicitWidth: 30
        implicitHeight: 30
        background: Rectangle { color: "transparent" }
        contentItem: Text {
            anchors.centerIn: parent
            text: iconTxt
            color: Theme.primary
            font.family: "monospace"
            font.pixelSize: 16
        }
    }

    component DonutChart: Item {
        id: donut
        property var segments: []
        property real lineWidth: 26

        Canvas {
            anchors.fill: parent
            onSegmentsChanged: requestPaint()
            property var segments: donut.segments
            property real lineWidth: donut.lineWidth

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const total = segments.reduce((s, seg) => s + seg.value, 0)
                const cx = width / 2, cy = height / 2
                const r = Math.min(width, height) / 2 - lineWidth / 2
                ctx.lineWidth = lineWidth
                ctx.lineCap = "butt"

                if (total <= 0) {
                    ctx.strokeStyle = Theme.outline_variant
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()
                    return
                }

                let start = -Math.PI / 2
                const gap = 0.02
                for (const seg of segments) {
                    if (seg.value <= 0) continue
                    const sweep = (seg.value / total) * Math.PI * 2
                    ctx.strokeStyle = seg.color
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, start + gap / 2, start + sweep - gap / 2)
                    ctx.stroke()
                    start += sweep
                }
            }
        }
    }

    component CategoryFilterButton: Rectangle {
        property string cat: "all"
        property bool active: root.selectedCategory === cat
        implicitWidth: catLabel.implicitWidth + 20
        implicitHeight: 28
        radius: 14
        color: active ? (root.categoryColor[cat] || Theme.primary) : Theme.surface_container_high
        border.width: active ? 0 : 1
        border.color: Theme.outline_variant

        Text {
            id: catLabel
            anchors.centerIn: parent
            text: root.categoryLabel[cat] + (cat !== "all" ? " (" + (root.summary[cat + "_count"] ?? 0) + ")" : "")
            color: active ? Theme.background : Theme.on_background
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.selectedCategory = cat
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        visible: root.isOpen
    }

    Item {
        id: panel
        anchors.centerIn: parent
        implicitWidth: 1320
        implicitHeight: 860
        focus: true

        Rectangle {
            anchors.fill: parent
            radius: 16
            opacity: 0.98
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
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text { text: "❤"; font.pixelSize: 22 }
                Text {
                    text: "Steam Wishlist"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                ActionIcon {
                    iconTxt: "🎮"
                    onClicked: {
                        root.isOpen = false
                        libraryProc.running = false
                        libraryProc.running = true
                    }
                }
                ActionIcon { iconTxt: "↻"; onClicked: root.loadData(true) }
                ActionIcon { iconTxt: "✕"; onClicked: root.isOpen = false }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3 }

            Text {
                visible: root.configured && root.reason === "fetch_failed"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: root.message
                color: Theme.on_background
                opacity: 0.75
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }
            Text {
                visible: !root.configured
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: root.message || "Set up your Steam API key/SteamID64 from the Steam Library panel first."
                color: Theme.on_background
                opacity: 0.75
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }

            RowLayout {
                visible: root.configured && root.reason !== "fetch_failed"
                Layout.fillWidth: true
                spacing: 24

                DonutChart {
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 150
                    segments: [
                        { value: root.summary.great_count ?? 0, color: root.categoryColor.great },
                        { value: root.summary.playable_count ?? 0, color: root.categoryColor.playable },
                        { value: root.summary.anticheat_blocked_count ?? 0, color: root.categoryColor.anticheat_blocked },
                        { value: root.summary.borked_count ?? 0, color: root.categoryColor.borked },
                        { value: root.summary.checking_count ?? 0, color: root.categoryColor.checking }
                    ]

                    Text {
                        anchors.centerIn: parent
                        text: (root.summary.total_games ?? 0) + "\nwishlisted"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.on_background
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                    }
                }

                GridLayout {
                    columns: 2
                    columnSpacing: 30
                    rowSpacing: 4
                    Layout.fillWidth: true

                    Text {
                        text: "Would run great"
                        color: Theme.on_background; opacity: 0.6
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                    Text {
                        text: (root.summary.great_count ?? 0) + " games"
                        color: Theme.on_background
                        font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                    }

                    Text {
                        text: "Native Linux"
                        color: Theme.on_background; opacity: 0.6
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                    Text {
                        text: (root.summary.native_linux_count ?? 0) + " games"
                        color: Theme.on_background
                        font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                    }

                    Text {
                        text: "Deck Verified"
                        color: Theme.on_background; opacity: 0.6
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                    Text {
                        text: (root.summary.deck_verified_count ?? 0) + " games"
                        color: Theme.on_background
                        font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                    }

                    Text {
                        text: "Still checking"
                        color: Theme.on_background; opacity: 0.6
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                    Text {
                        text: (root.summary.checking_count ?? 0) + " tier(s)"
                        color: Theme.on_background
                        font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                    }
                }
            }

            Rectangle { visible: root.configured && root.reason !== "fetch_failed"; Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.15 }

            RowLayout {
                visible: root.configured && root.reason !== "fetch_failed"
                Layout.fillWidth: true
                spacing: 8

                CategoryFilterButton { cat: "all" }
                CategoryFilterButton { cat: "great" }
                CategoryFilterButton { cat: "playable" }
                CategoryFilterButton { cat: "anticheat_blocked" }
                CategoryFilterButton { cat: "borked" }
                CategoryFilterButton { cat: "checking" }

                Item { Layout.fillWidth: true }

                TextField {
                    Layout.preferredWidth: 220
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
            }

            GridView {
                visible: root.configured && root.reason !== "fetch_failed"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 160
                cellHeight: 230
                model: root.filteredGames

                delegate: Item {
                    width: GridView.view.cellWidth
                    height: GridView.view.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: 10
                        color: root.selectedGame && root.selectedGame.appid === modelData.appid
                            ? Theme.primary : Theme.surface_container_high
                        border.width: root.selectedGame && root.selectedGame.appid === modelData.appid ? 0 : 1
                        border.color: Theme.outline_variant

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 130
                                radius: 6
                                color: Theme.background
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: modelData.cover_url || ""
                                    asynchronous: true
                                }

                                Rectangle {
                                    visible: modelData.native_linux === true
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 4
                                    width: 18; height: 18; radius: 9
                                    color: Qt.rgba(0, 0, 0, 0.6)
                                    Text { anchors.centerIn: parent; text: "🐧"; font.pixelSize: 10 }
                                }
                                Rectangle {
                                    visible: modelData.deck_category === 3
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    width: 18; height: 18; radius: 9
                                    color: Qt.rgba(0, 0, 0, 0.6)
                                    Text { anchors.centerIn: parent; text: "✓"; color: "#4caf7d"; font.pixelSize: 11; font.bold: true }
                                }
                                Rectangle {
                                    visible: modelData.anticheat_status === "Denied" || modelData.anticheat_status === "Broken"
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    width: 18; height: 18; radius: 9
                                    color: Qt.rgba(0, 0, 0, 0.6)
                                    Text { anchors.centerIn: parent; text: "⚠"; font.pixelSize: 10 }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: root.selectedGame && root.selectedGame.appid === modelData.appid
                                    ? Theme.background : Theme.on_background
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.fmtDate(modelData.date_added)
                                color: root.selectedGame && root.selectedGame.appid === modelData.appid
                                    ? Theme.background : Theme.on_background
                                opacity: 0.7
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedGame = modelData
                        }
                    }
                }
            }
        }

        // ==== SELECTED-GAME OVERLAY ====
        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(0, 0, 0, 0.7)
            visible: root.selectedGame !== null
            z: 10

            MouseArea {
                anchors.fill: parent
                onClicked: root.selectedGame = null
            }

            Rectangle {
                anchors.centerIn: parent
                width: 480
                height: 320
                radius: 14
                color: Theme.background
                border.width: 1
                border.color: Theme.outline_variant

                MouseArea { anchors.fill: parent; onClicked: {} }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: root.selectedGame ? root.selectedGame.name : ""
                            color: Theme.on_background
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        ActionIcon { iconTxt: "✕"; onClicked: root.selectedGame = null }
                    }

                    Text {
                        text: root.selectedGame ? "Wishlisted: " + root.fmtDate(root.selectedGame.date_added)
                            + (root.selectedGame.priority > 0 ? "  ·  Priority #" + root.selectedGame.priority : "") : ""
                        color: Theme.on_background; opacity: 0.7
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outline_variant; opacity: 0.4 }

                    Text {
                        text: root.selectedGame ? "ProtonDB: " + (root.tierLabel[root.selectedGame.tier] || "Unknown") : ""
                        color: root.selectedGame ? (root.tierColor[root.selectedGame.tier] || Theme.outline_variant) : Theme.on_background
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Text {
                        text: root.selectedGame ? "Steam Deck: " + root.selectedGame.deck_label : ""
                        color: root.selectedGame ? (root.deckColor[root.selectedGame.deck_category] || Theme.outline_variant) : Theme.on_background
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Text {
                        visible: root.selectedGame && root.selectedGame.native_linux === true
                        text: "🐧 Native Linux build"
                        color: "#4caf7d"
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Text {
                        visible: root.selectedGame && (root.selectedGame.anticheat_status === "Denied" || root.selectedGame.anticheat_status === "Broken")
                        text: "⚠ Anti-cheat: " + (root.selectedGame ? root.selectedGame.anticheat_status : "")
                        color: Theme.error
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Text {
                        visible: root.selectedGame && root.selectedGame.anticheat_status === "Supported"
                        text: "🛡 Anti-cheat: works on Linux"
                        color: "#4caf7d"
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
