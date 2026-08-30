//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import "PowerApp"
import "AIUsageApp"
import "ThemePickerApp"
import "CustomTheme"

// Everything ml4w-branded (Welcome, Sidebar, Calendar, Wallpaper picker,
// the alternate Statusbar/Dock engine) was retired once Noctalia became the
// sole daily-driver shell -- its own control-center/OSD/wallpaper-picker
// already covered all of it. Power and AI-usage have no Noctalia
// equivalent, so they're kept here as the last two panels this process
// hosts, still reachable via `qs ipc call power/ai-usage toggle` from
// either shell profile. ThemePickerApp is the grid picker for our own
// custom themes (rofi's noctalia-theme-picker.sh is kept as an unbound
// fallback), reachable via `qs ipc call theme-picker toggle`.
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
}