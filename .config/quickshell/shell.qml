//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import "PowerApp"
import "AIUsageApp"
import "ThemePickerApp"
import "SteamLibraryApp"
import "BookAlertsApp"
import "CustomTheme"

// Everything ml4w-branded (Welcome, Sidebar, Calendar, Wallpaper picker,
// the alternate Statusbar/Dock engine) was retired once Noctalia became the
// sole daily-driver shell -- its own control-center/OSD/wallpaper-picker
// already covered all of it. Power, AI-usage and Steam-library have no
// Noctalia equivalent, so they're kept here, reachable via
// `qs ipc call power/ai-usage/steam-library toggle`. ThemePickerApp is the
// grid picker for our own custom themes (rofi's noctalia-theme-picker.sh is
// kept as an unbound fallback), reachable via `qs ipc call theme-picker
// toggle`. SteamBigPictureWindow is the larger, richer view of the same
// steam-library data (categories/donut chart/covers/achievements),
// reachable via `qs ipc call steam-library-big toggle` -- opened from a
// button in the small SteamLibraryWindow dropdown. SteamWishlistWindow is
// the same playability signals applied to your wishlist instead of your
// owned library, reachable via `qs ipc call steam-library-wishlist toggle`
// -- opened from buttons in both of the above. BookAlertsApp reads a JSON
// snapshot an external n8n automation writes (new/restocked/price-changed
// listings from a handful of book retailers) over an SSHFS mount, reachable
// via `qs ipc call book-alerts toggle` -- it does no scraping/diffing of its
// own, n8n owns that.
ShellRoot {
    // Test IPC tools: qs ipc show

    IpcHandler {
        target: "theme-manager"
        function reload(): void {
            Theme.reloadTheme()
        }
    }

    PowerWindow {}
    AIUsageWindow {}
    ThemePickerWindow {}
    SteamLibraryWindow {}
    SteamBigPictureWindow {}
    SteamWishlistWindow {}
    BookAlertsWindow {}
}