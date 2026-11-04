--!nonstrict
-- Bar capsule for the steam-library poller. Deliberately thin: the dropdown
-- is the Quickshell SteamLibraryWindow, so a click just toggles it over
-- `qs ipc` instead of redrawing the game list here in Luau.

local COLOR_BY_CLASS = {
    low = "on_surface",
    critical = "error",
}

local text = noctalia.state.get("text") or "steam: --"
local tooltip = noctalia.state.get("tooltip") or ""
local class = noctalia.state.get("class") or "low"

local function render()
    barWidget.setGlyph("device-gamepad-2")
    barWidget.setText(text)
    barWidget.setTooltip(tooltip)
    local role = COLOR_BY_CLASS[class] or "on_surface"
    barWidget.setColor(role)
    barWidget.setGlyphColor(role)
end

noctalia.state.watch("text", function(value) text = value; render() end)
noctalia.state.watch("tooltip", function(value) tooltip = value; render() end)
noctalia.state.watch("class", function(value) class = value; render() end)

function update()
    -- The poller service drives the real refresh interval; this only needs
    -- to redraw, so keep this widget's own tick slow.
    noctalia.setUpdateInterval(60000)
    render()
end

function onClick()
    noctalia.runAsync("qs ipc call steam-library toggle")
end
