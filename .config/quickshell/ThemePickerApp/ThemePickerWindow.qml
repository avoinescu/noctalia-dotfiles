import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import qs.CustomTheme

// Grid picker for our ~41 hand-built custom themes -- shows a wallpaper
// thumbnail per theme (sourced fresh from ~/Pictures/wallpaper/<id>/ every
// time the picker opens) plus its name, click-to-apply. Data comes from
// theme-list-json.sh, which itself sources theme-list.sh -- the same file
// noctalia-theme-picker.sh (the rofi fallback, still bound nowhere but kept
// as a dormant escape hatch) reads, so the two pickers can't drift apart.
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
    visible: isOpen
    property var allThemes: []

    onIsOpenChanged: {
        if (isOpen) {
            searchInput.text = ""
            themeListProcess.running = true
            panel.forceActiveFocus()
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: {
            if (root.isOpen)
                root.isOpen = false
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.isOpen)
                root.isOpen = false
        }
    }

    IpcHandler {
        target: "theme-picker"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
    }

    // ==========================================
    // DATA: theme-list-json.sh -> allThemes -> filtered into themeModel
    // ==========================================
    Process {
        id: themeListProcess
        command: ["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/theme-list-json.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allThemes = JSON.parse(this.text.trim())
                } catch (e) {
                    console.log("theme-picker: failed to parse theme-list-json.sh output: " + e)
                    root.allThemes = []
                }
                root.applyFilter()
            }
        }
    }

    ListModel { id: themeModel }

    function applyFilter() {
        const query = searchInput.text.trim().toLowerCase()
        themeModel.clear()
        for (const entry of root.allThemes) {
            if (query === "" || entry.label.toLowerCase().includes(query))
                themeModel.append(entry)
        }
    }

    // ==========================================
    // DIM BACKDROP
    // ==========================================
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        visible: root.isOpen
    }

    // ==========================================
    // MAIN PANEL
    // ==========================================
    Item {
        id: panel
        anchors.centerIn: parent
        implicitWidth: 1120
        implicitHeight: 780
        focus: true

        RectangularShadow {
            anchors.fill: panelBg
            radius: panelBg.radius
            blur: 20
            color: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.5)
        }

        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: 24
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.primary }
                GradientStop { position: 1.0; color: Theme.on_primary }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: parent.radius - 2
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

                Text {
                    text: "Custom Themes"
                    color: Theme.on_background
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                TextField {
                    id: searchInput
                    placeholderText: "Search themes"
                    color: Theme.primary
                    font.pixelSize: 14
                    padding: 8
                    Layout.preferredWidth: 260
                    horizontalAlignment: TextInput.AlignHCenter

                    background: Rectangle {
                        anchors.fill: parent
                        color: Theme.surface
                        radius: 10
                        border.color: Theme.primary
                        border.width: 1
                    }

                    onTextChanged: root.applyFilter()
                    Keys.onEscapePressed: root.isOpen = false
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cacheBuffer: 2000
                reuseItems: true

                cellWidth: width / 6
                cellHeight: cellWidth * 0.85

                ScrollBar.vertical: ScrollBar { interactive: true }

                model: themeModel

                delegate: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight

                    // Card layout: image on top, a solid label footer below
                    // (filled with the accent color when this theme is the
                    // active one) -- modeled after a preset-picker reference
                    // the user liked, adapted to our click-anywhere-to-apply
                    // behavior (no separate Apply button).
                    Rectangle {
                        id: card
                        anchors.fill: parent
                        anchors.margins: 8
                        color: Theme.surface
                        radius: 14
                        clip: true

                        border.color: !model.active && cardMouse.containsMouse ? Theme.primary : "transparent"
                        border.width: 2

                        Rectangle {
                            id: cardMask
                            anchors.fill: parent
                            radius: parent.radius
                            visible: false
                        }

                        Column {
                            anchors.fill: parent
                            spacing: 0
                            layer.enabled: true
                            layer.effect: OpacityMask { maskSource: cardMask }

                            // Thumbnail, or a placeholder glyph when the
                            // theme's wallpaper folder is empty/missing
                            // (wallpapers aren't tracked in git).
                            Item {
                                id: thumbArea
                                width: parent.width
                                height: parent.height * 0.68

                                Image {
                                    id: thumbnail
                                    anchors.fill: parent
                                    visible: model.thumbnail !== ""
                                    source: model.thumbnail !== "" ? "file://" + model.thumbnail : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 220
                                    sourceSize.height: 220

                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                    }
                                }

                                BusyIndicator {
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
                                    running: model.thumbnail !== "" && thumbnail.status === Image.Loading
                                    opacity: running ? 0.5 : 0.0
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.surface
                                    visible: model.thumbnail === ""

                                    Image {
                                        anchors.centerIn: parent
                                        source: "../shared/icons/wallpaper.svg"
                                        width: 28
                                        height: 28
                                        sourceSize.width: 28
                                        sourceSize.height: 28
                                        fillMode: Image.PreserveAspectFit
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            colorization: 1.0
                                            colorizationColor: Theme.on_surface_variant
                                        }
                                    }
                                }
                            }

                            // Label footer -- filled with the accent color
                            // when this card is the active theme.
                            Rectangle {
                                width: parent.width
                                height: parent.height - thumbArea.height
                                color: model.active ? Theme.primary : Theme.surface

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - 12
                                    text: model.label
                                    color: model.active ? Theme.on_primary : Theme.on_background
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["bash", "-c", model.applyCmd])
                                root.isOpen = false
                            }
                        }
                    }
                }
            }
        }
    }
}
