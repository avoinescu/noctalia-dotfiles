--!nonstrict
-- Bar capsule for the ai-usage poller. Deliberately thin: the dropdown is the
-- Quickshell AIUsageWindow we already built and verified, so a click just
-- toggles it over `qs ipc` instead of redrawing it here in Luau.

-- Always pass an explicit theme role -- Noctalia widgets don't inherit a
-- themed color for free, so leaving this unset was why the capsule looked the
-- same regardless of the active palette. "on_surface" is the normal themed
-- body-text token; secondary/error only kick in at higher usage.
local COLOR_BY_CLASS = {
    low = "on_surface",
    mid = "secondary",
    high = "secondary",
    critical = "error",
}

local text = noctalia.state.get("text") or "ai: --"
local tooltip = noctalia.state.get("tooltip") or ""
local class = noctalia.state.get("class") or "low"

local function render()
    barWidget.setGlyph("brain")
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
    -- The poller service drives the real refresh interval; this only needs to
    -- redraw, so keep this widget's own tick slow.
    noctalia.setUpdateInterval(60000)
    render()
end

function onClick()
    noctalia.runAsync("qs ipc call ai-usage toggle")
end
