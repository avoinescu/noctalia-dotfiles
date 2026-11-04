--!nonstrict
-- Headless poller: runs this repo's own bar-format.sh (same data source the
-- Quickshell SteamLibraryWindow panel uses) and publishes the result for the
-- bar widget to draw. No credentials pass through this plugin at all --
-- collect.sh reads them from the OS keyring (see save-credentials.sh).

local SCRIPT = noctalia.getenv("HOME") .. "/.config/quickshell/SteamLibraryApp/scripts/bar-format.sh"
local RETRY_MS = 30000

local function intervalMs()
    local minutes = tonumber(noctalia.getConfig("refresh_minutes")) or 30
    if minutes < 5 then minutes = 5 end
    return math.floor(minutes * 60 * 1000)
end

local inFlight = false
-- Starts "critical" so the very first poll after enabling the plugin (before
-- credentials exist yet) doesn't wait a full refresh_minutes to notice once
-- they're set up via the panel's setup form -- it keeps retrying every
-- RETRY_MS until a real result comes back, then settles into the slow,
-- configured cadence.
local lastClass = "critical"

local function refresh()
    if inFlight then return end
    inFlight = true
    noctalia.setUpdateInterval(lastClass == "critical" and RETRY_MS or intervalMs())

    -- Steam + ProtonDB round trips can be slower than the local-only
    -- ai-usage source, so this gets a longer timeout than that plugin's 15s.
    local started = noctalia.runAsync(SCRIPT, function(result)
        inFlight = false
        local decoded = result ~= nil and noctalia.json.decode(result.stdout or "") or nil
        if type(decoded) == "table" and decoded.text ~= nil then
            lastClass = decoded.class or "low"
            noctalia.state.set("text", decoded.text)
            noctalia.state.set("tooltip", decoded.tooltip or "")
            noctalia.state.set("class", lastClass)
            noctalia.state.set("error", false)
        else
            lastClass = "critical"
            noctalia.state.set("error", true)
        end
    end, 30000)

    if not started then
        inFlight = false
        lastClass = "critical"
        noctalia.state.set("error", true)
    end
end

function update()
    refresh()
end
