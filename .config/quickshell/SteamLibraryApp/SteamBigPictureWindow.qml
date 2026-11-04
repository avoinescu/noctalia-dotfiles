import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

// Larger, richer view of the Steam library: category breakdown donut,
// cover-art grid grouped by playability, and per-game details (achievements
// fetched on demand). Same data source as the dropdown (SteamLibraryWindow's
// collect.sh) -- this is a separate fill-screen window rather than a mode
// toggle on the small dropdown, since the two layouts share almost nothing
// (anchored corner capsule vs. centered full layout), mirroring how
// ThemePickerWindow is its own window rather than a mode of the bar.
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
        // First Escape backs out of the achievements/detail overlay (same
        // job as its own close button); a second press closes the window.
        onActivated: {
            if (root.selectedGame !== null) root.selectedGame = null
            else if (root.isOpen) root.isOpen = false
        }
    }

    IpcHandler {
        target: "steam-library-big"
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
    property var allGames: []
    property var summary: ({})
    property int checking: 0
    property string filterText: ""
    property string selectedCategory: "all"
    property var selectedGame: null
    property var achievements: null   // {available, unlocked, total, achievements:[{name,icon,achieved}]} or null while loading

    readonly property var tierColor: ({
        platinum: "#b9d3e0", gold: "#d4af37", silver: "#adb5bd", bronze: "#b06a35",
        borked: Theme.error, pending: Theme.outline_variant, unknown: Theme.outline_variant
    })
    readonly property var tierLabel: ({
        platinum: "Platinum", gold: "Gold", silver: "Silver", bronze: "Bronze",
        borked: "Borked", pending: "No reports", unknown: "Checking…"
    })
    readonly property var categoryLabel: ({
        all: "All", most_played: "Most Played", recently_played: "Recently Played", installed: "Installed",
        great: "Great", playable: "Playable",
        anticheat_blocked: "Anti-cheat blocked", borked: "Borked", checking: "Checking"
    })
    readonly property var categoryColor: ({
        most_played: "#9b7bd6", recently_played: "#5bc0be", installed: "#e0a03c",
        great: "#4caf7d", playable: "#5b9bd5", anticheat_blocked: "#e0a03c",
        borked: Theme.error, checking: Theme.outline_variant
    })
    readonly property var deckColor: ({ 3: "#4caf7d", 2: "#5b9bd5", 1: Theme.error, 0: Theme.outline_variant })
    // Chips that pick a subset/sort of the whole library rather than
    // filtering by the tier-derived `category` field -- handled specially
    // in filteredGames below.
    readonly property var viewCategories: (["most_played", "recently_played", "installed"])

    property var filteredGames: {
        let list = root.allGames
        if (root.selectedCategory === "recently_played") {
            list = list.filter(g => (g.playtime_2weeks || 0) > 0)
        } else if (root.selectedCategory === "installed") {
            list = list.filter(g => g.installed === true)
        } else if (root.selectedCategory !== "all" && root.selectedCategory !== "most_played") {
            list = list.filter(g => g.category === root.selectedCategory)
        }
        if (root.filterText.length > 0) {
            const needle = root.filterText.toLowerCase()
            list = list.filter(g => g.name.toLowerCase().includes(needle))
        }
        list = list.slice()
        if (root.selectedCategory === "recently_played") {
            list.sort((a, b) => (b.playtime_2weeks || 0) - (a.playtime_2weeks || 0))
        } else {
            list.sort((a, b) => {
                if (b.playtime_forever !== a.playtime_forever) return b.playtime_forever - a.playtime_forever
                return a.name.localeCompare(b.name)
            })
        }
        return list
    }

    function fmtPlaytime(minutes) {
        if (!minutes || minutes <= 0) return "unplayed"
        const hours = minutes / 60
        return (hours >= 10 ? hours.toFixed(0) : hours.toFixed(1)) + "h"
    }

    function loadData() {
        collectProc.running = false
        collectProc.running = true
    }

    onIsOpenChanged: {
        grabActive = isOpen
        if (isOpen) loadData()
    }

    Process {
        id: wishlistProc
        command: ["qs", "ipc", "call", "steam-library-wishlist", "open"]
    }

    Process {
        id: collectProc
        command: ["bash", "-c", Quickshell.env("HOME") + "/.config/quickshell/SteamLibraryApp/scripts/collect.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(this.text.trim())
                    root.configured = parsed.configured !== false
                    root.allGames = parsed.games || []
                    root.summary = parsed.summary || {}
                    root.checking = parsed.checking || 0
                } catch (e) {
                    console.log("steam-library (big picture): failed to parse collect.sh output: " + e)
                }
            }
        }
    }

    function selectGame(game) {
        root.selectedGame = game
        root.achievements = null
        achievementsProc.command = ["bash", "-c",
            Quickshell.env("HOME") + "/.config/quickshell/SteamLibraryApp/scripts/achievements-fetch.sh " + game.appid]
        achievementsProc.running = false
        achievementsProc.running = true
    }

    Process {
        id: achievementsProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.achievements = JSON.parse(this.text.trim())
                } catch (e) {
                    root.achievements = { available: false, unlocked: 0, total: 0, achievements: [] }
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

    // Ring chart of category counts. Center label is drawn separately so it
    // stays crisp regardless of canvas DPR.
    component DonutChart: Item {
        id: donut
        property var segments: []   // [{value, color}]
        property real lineWidth: 26

        Canvas {
            id: canvas
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
            text: root.categoryLabel[cat] + (
                cat === "all" ? "" :
                cat === "most_played" ? "" :
                " (" + (root.summary[cat + "_count"] ?? 0) + ")"
            )
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

    // ==== DIM BACKDROP ====
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        visible: root.isOpen
    }

    // ==== MAIN PANEL ====
    Item {
        id: panel
        anchors.centerIn: parent
        implicitWidth: 1320
        implicitHeight: 860
        focus: true

        Rectangle {
            id: panelBg
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

            // --- HEADER ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text { text: "🎮"; font.pixelSize: 22 }
                Text {
                    text: "Steam Library — Big Picture"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                ActionIcon {
                    iconTxt: "❤"
                    onClicked: {
                        root.isOpen = false
                        wishlistProc.running = false
                        wishlistProc.running = true
                    }
                }
                ActionIcon { iconTxt: "↻"; onClicked: root.loadData() }
                ActionIcon { iconTxt: "✕"; onClicked: root.isOpen = false }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3 }

            // --- OVERVIEW: chart + stats ---
            RowLayout {
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
                        text: (root.summary.total_games ?? 0) + "\ngames"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.on_background
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                    }
                }

                GridLayout {
                    columns: 2
                    columnSpacing: 30
                    rowSpacing: 4
                    Layout.fillWidth: true

                    Text {
                        text: "Total playtime"
                        color: Theme.on_background; opacity: 0.6
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                    Text {
                        text: Math.round((root.summary.total_playtime_minutes ?? 0) / 60) + " hours"
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

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.15 }

            // --- FILTERS ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                CategoryFilterButton { cat: "all" }
                CategoryFilterButton { cat: "most_played" }
                CategoryFilterButton { cat: "recently_played" }
                CategoryFilterButton { cat: "installed" }
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

            // --- GAME GRID ---
            GridView {
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
                                    id: coverImg
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: modelData.cover_url || modelData.icon_url
                                    asynchronous: true
                                    onStatusChanged: {
                                        if (status === Image.Error && source !== modelData.icon_url)
                                            source = modelData.icon_url
                                    }
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
                                Rectangle {
                                    visible: modelData.installed === true
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.margins: 4
                                    width: 18; height: 18; radius: 9
                                    color: Qt.rgba(0, 0, 0, 0.6)
                                    Text { anchors.centerIn: parent; text: "💾"; font.pixelSize: 9 }
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
                                text: root.fmtPlaytime(modelData.playtime_forever)
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
                            onClicked: root.selectGame(modelData)
                        }
                    }
                }
            }
        }

        // ==== SELECTED-GAME OVERLAY ====
        // A true overlay (not a row sibling) so a long achievements list can
        // never squeeze the game grid out of existence -- it draws on top of
        // the panel instead of competing with it for layout space. Clicking
        // the dimmed backdrop, the close button, or Escape all back out.
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
                id: detailCard
                anchors.centerIn: parent
                width: 640
                height: 680
                radius: 14
                color: Theme.background
                border.width: 1
                border.color: Theme.outline_variant

                MouseArea {
                    // Swallow clicks so they don't fall through to the
                    // backdrop's close-on-click behind this card.
                    anchors.fill: parent
                    onClicked: {}
                }

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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        Text {
                            text: root.selectedGame ? "Played: " + root.fmtPlaytime(root.selectedGame.playtime_forever) : ""
                            color: Theme.on_background; opacity: 0.7
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                        Text {
                            visible: root.selectedGame && (root.selectedGame.playtime_2weeks || 0) > 0
                            text: root.selectedGame ? "Last 2wk: " + root.fmtPlaytime(root.selectedGame.playtime_2weeks) : ""
                            color: Theme.on_background; opacity: 0.7
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                        Text {
                            text: root.selectedGame ? "ProtonDB: " + (root.tierLabel[root.selectedGame.tier] || "Unknown") : ""
                            color: root.selectedGame ? (root.tierColor[root.selectedGame.tier] || Theme.outline_variant) : Theme.on_background
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                        Text {
                            text: root.selectedGame ? "Deck: " + root.selectedGame.deck_label : ""
                            color: root.selectedGame ? (root.deckColor[root.selectedGame.deck_category] || Theme.outline_variant) : Theme.on_background
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                        Text {
                            visible: root.selectedGame && root.selectedGame.installed === true
                            text: "💾 Installed"
                            color: Theme.on_background; opacity: 0.7
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        Text {
                            visible: root.selectedGame && root.selectedGame.native_linux === true
                            text: "🐧 Native Linux build"
                            color: "#4caf7d"
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                        Text {
                            visible: root.selectedGame && (root.selectedGame.anticheat_status === "Denied" || root.selectedGame.anticheat_status === "Broken")
                            text: "⚠ Anti-cheat: " + (root.selectedGame ? root.selectedGame.anticheat_status : "")
                            color: Theme.error
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outline_variant; opacity: 0.4 }

                    Text {
                        Layout.fillWidth: true
                        text: root.achievements === null ? "Achievements: loading…"
                            : !root.achievements.available ? "Achievements: unavailable for this game"
                            : "Achievements: " + root.achievements.unlocked + " / " + root.achievements.total + " owned"
                        color: Theme.on_background
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }

                    GridView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        visible: root.achievements !== null && root.achievements.available
                        cellWidth: 56
                        cellHeight: 56
                        model: root.achievements ? root.achievements.achievements : []

                        delegate: Item {
                            width: GridView.view.cellWidth
                            height: GridView.view.cellHeight

                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: modelData.icon || ""
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                opacity: modelData.achieved ? 1.0 : 0.35

                                HoverHandler { id: achHover }
                                ToolTip.visible: achHover.hovered
                                ToolTip.text: modelData.name + (modelData.achieved ? "" : " (locked)")
                            }
                        }
                    }
                }
            }
        }
    }
}
