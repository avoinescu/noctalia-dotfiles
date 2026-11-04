import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

// Book alerts dropdown: reads a JSON snapshot written externally by an n8n
// automation (new listings / restocks / price changes across a handful of
// specialty book retailers), shown as a list with per-item change badges.
// This panel never scrapes or diffs anything itself -- n8n stamps
// changeType/changedAt authoritatively, the widget's only local-state job is
// remembering which changes it has already turned into a desktop
// notification, so comparison logic doesn't live in two places.
PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: 380
    implicitHeight: Math.min(mainContentColumn.implicitHeight + 160, 620)
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
        target: "book-alerts"
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

    onIsOpenChanged: {
        grabActive = isOpen
        if (isOpen) markViewed()
    }

    // Records "now" so the bar badge (bar-format.sh) can show an
    // unread-since-last-viewed count instead of the raw 14-day window
    // total, which never clears on its own. Fire-and-forget, same
    // re-trigger pattern as the other Process nodes here.
    function markViewed() {
        markViewedProc.command = ["bash", Quickshell.env("HOME") + "/.config/quickshell/BookAlertsApp/scripts/mark-viewed.sh"]
        markViewedProc.running = false
        markViewedProc.running = true
    }

    Process { id: markViewedProc }

    property var snapshot: ({ items: [], sources: [], generatedAt: null })
    property var notifiedState: ({})

    readonly property var changeColor: ({
        new: Theme.primary,
        restock: "#22C55E",
        price_change: "#F59E0B",
        restock_and_price_change: "#22C55E"
    })
    readonly property var changeLabel: ({
        new: "New",
        restock: "Restock",
        price_change: "Price change",
        restock_and_price_change: "Restock + Price"
    })

    // Shared snapshot n8n writes on icecrown every run (roughly every 20
    // min), relayed here via Proton Drive: a host-level systemd timer on
    // icecrown uploads it, a systemd --user timer on this desktop downloads
    // it to this local path (see book-alerts.tf / download-book-alerts-
    // snapshot.sh) -- watched live so this panel can notify even while
    // closed, not just refresh when opened. This is a genuinely local file
    // (not a network mount), so watchChanges/fileChanged is real inotify,
    // no reliability caveat here.
    FileView {
        id: sharedSnapshotFile
        path: "/home/lufftwafedracula/.cache/book-alerts/shared-snapshot.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.handleSnapshotText(text())
        onLoadFailed: (error) => console.log("book-alerts: failed to load shared snapshot: " + error)
    }

    function handleSnapshotText(txt) {
        try {
            const parsed = JSON.parse(txt)
            root.snapshot = parsed
            root.checkForNewAlerts(parsed.items || [])
        } catch (e) {
            console.log("book-alerts: failed to parse shared snapshot: " + e)
        }
    }

    function checkForNewAlerts(items) {
        const toNotify = items.filter(i => root.notifiedState[i.id] !== i.changedAt)
        if (toNotify.length === 0) return
        root.fireNotification(toNotify)
        const next = Object.assign({}, root.notifiedState)
        for (const i of toNotify) next[i.id] = i.changedAt
        root.notifiedState = next
        saveNotifiedProc.command = ["bash", "-c", Quickshell.env("HOME") + "/.config/quickshell/BookAlertsApp/scripts/save-notified-state.sh"]
        saveNotifiedProc.running = false
        saveNotifiedProc.running = true
        saveNotifiedProc.write(JSON.stringify(next) + "\n")
    }

    function fireNotification(toNotify) {
        const counts = {}
        for (const i of toNotify) counts[i.changeType] = (counts[i.changeType] || 0) + 1
        const summary = Object.entries(counts)
            .map(([t, c]) => `${c} ${(root.changeLabel[t] || t).toLowerCase()}`)
            .join(", ")
        const body = toNotify.slice(0, 5).map(i => `${i.shop}: ${i.title}`).join("\n")
            + (toNotify.length > 5 ? `\n+${toNotify.length - 5} more` : "")
        notifyProc.command = ["notify-send", "-a", "Book Alerts", `📚 Book Alerts — ${summary}`, body]
        notifyProc.running = false
        notifyProc.running = true
    }

    function loadNotifiedState() {
        loadNotifiedProc.running = false
        loadNotifiedProc.running = true
    }

    Component.onCompleted: loadNotifiedState()

    Process { id: notifyProc }

    Process {
        id: loadNotifiedProc
        command: ["bash", "-c", Quickshell.env("HOME") + "/.config/quickshell/BookAlertsApp/scripts/load-notified-state.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.notifiedState = JSON.parse(this.text.trim())
                } catch (e) {
                    root.notifiedState = {}
                }
            }
        }
    }

    Process {
        id: saveNotifiedProc
        stdinEnabled: true
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

    component ChangeBadge: Rectangle {
        property string changeType: "new"
        implicitWidth: badgeText.implicitWidth + 14
        implicitHeight: 20
        radius: 10
        color: Qt.rgba(0, 0, 0, 0)
        border.width: 1
        border.color: root.changeColor[changeType] || Theme.outline_variant
        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.changeLabel[changeType] || changeType
            color: root.changeColor[changeType] || Theme.outline_variant
            font.family: Theme.fontFamily
            font.pixelSize: 10
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
                    text: "📚"
                    font.pixelSize: 18
                }
                Text {
                    text: "Book Alerts"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: root.snapshot.items ? "(" + root.snapshot.items.length + ")" : ""
                    color: Theme.on_background
                    opacity: 0.6
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Rectangle {
                    visible: (root.snapshot.sources || []).some(s => !s.ok)
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: Theme.error
                }
                Item { Layout.fillWidth: true }
                ActionIcon {
                    iconTxt: "↻"
                    onClicked: sharedSnapshotFile.reload()
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3 }

            Text {
                visible: !root.snapshot.items || root.snapshot.items.length === 0
                text: "No recent changes"
                color: Theme.on_background
                opacity: 0.6
                font.family: Theme.fontFamily
            }

            // --- SCROLLABLE LIST ---
            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: mainContentColumn.implicitHeight
                clip: true
                visible: root.snapshot.items && root.snapshot.items.length > 0

                ColumnLayout {
                    id: mainContentColumn
                    width: scrollView.width
                    spacing: 8

                    Repeater {
                        model: root.snapshot.items || []
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: rowLayout.implicitHeight + 16
                            radius: 8
                            color: Theme.surface_container_high
                            opacity: 0.9

                            RowLayout {
                                id: rowLayout
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    id: coverThumb
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    radius: 6
                                    color: Theme.background
                                    clip: true

                                    Image {
                                        id: coverImg
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        source: modelData.image || ""
                                        asynchronous: true
                                        visible: !!modelData.image && status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !coverImg.visible
                                        text: modelData.shopEmoji
                                        font.pixelSize: 16
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        elide: Text.ElideRight
                                        color: Theme.on_background
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        readonly property string currencySymbol: ({ GBP: "£", USD: "$", EUR: "€", RON: " RON " })[modelData.currency] || (modelData.currency ? modelData.currency + " " : "£")
                                        text: modelData.shop
                                            + (modelData.priceUnknown
                                                ? " · price unknown"
                                                : (modelData.price != null ? " · " + currencySymbol + modelData.price : "")
                                                + (modelData.available === false ? " · out of stock" : ""))
                                        color: Theme.on_background
                                        opacity: 0.6
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                ChangeBadge { changeType: modelData.changeType }

                                ActionIcon {
                                    iconTxt: "↗"
                                    onClicked: Qt.openUrlExternally(modelData.url)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
