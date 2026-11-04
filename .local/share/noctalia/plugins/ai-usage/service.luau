--!nonstrict
-- Headless poller: runs this repo's own waybar-format.sh (the exact same data
-- source the Waybar module and the Quickshell AIUsageWindow panel use) and
-- publishes the result for the bar widget to draw. No credentials pass through
-- this plugin at all -- waybar-format.sh/collect.sh own the OAuth/token
-- accounting, same as they do for Waybar.

local SCRIPT = noctalia.getenv("HOME") .. "/.config/quickshell/AIUsageApp/scripts/waybar-format.sh"

local function intervalMs()
    local minutes = tonumber(noctalia.getConfig("refresh_minutes")) or 5
    if minutes < 1 then minutes = 1 end
    return math.floor(minutes * 60 * 1000)
end

local inFlight = false

local function refresh()
    if inFlight then return end
    inFlight = true
    noctalia.setUpdateInterval(intervalMs())

    local started = noctalia.runAsync(SCRIPT, function(result)
        inFlight = false
        local decoded = result ~= nil and noctalia.json.decode(result.stdout or "") or nil
        if type(decoded) == "table" and decoded.text ~= nil then
            noctalia.state.set("text", decoded.text)
            noctalia.state.set("tooltip", decoded.tooltip or "")
            noctalia.state.set("class", decoded.class or "low")
            noctalia.state.set("error", false)
        else
            noctalia.state.set("error", true)
        end
    end, 15000)

    if not started then
        inFlight = false
        noctalia.state.set("error", true)
    end
end

function update()
    refresh()
end
