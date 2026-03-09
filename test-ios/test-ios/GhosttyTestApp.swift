import SwiftUI
import GhosttyKit

@main
struct GhosttyTestApp: App {
    @StateObject private var ghostty = GhosttyAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ghostty)
        }
    }
}

/// Minimal wrapper around the ghostty C API lifecycle.
class GhosttyAppState: ObservableObject {
    @Published var app: ghostty_app_t?

    init() {
        // Global init
        var argv: [UnsafeMutablePointer<CChar>?] = [strdup("ghostty"), nil]
        defer { argv.compactMap { $0 }.forEach { free($0) } }

        guard ghostty_init(1, &argv) == GHOSTTY_SUCCESS else {
            print("[Ghostty] ghostty_init failed")
            return
        }

        // Config
        let config = ghostty_config_new()!
        ghostty_config_finalize(config)

        // Runtime callbacks
        var rt = ghostty_runtime_config_s()
        rt.userdata = Unmanaged.passUnretained(self).toOpaque()
        rt.supports_selection_clipboard = false
        rt.wakeup_cb = { _ in
            DispatchQueue.main.async { /* wakeup — no-op for test app */ }
        }
        rt.action_cb = { _, _, _ in false }
        rt.read_clipboard_cb = { _, _, _ in }
        rt.confirm_read_clipboard_cb = { _, _, _, _ in }
        rt.write_clipboard_cb = { _, _, _, _, _ in }
        rt.close_surface_cb = { _, _ in
            print("[Ghostty] close_surface requested")
        }

        app = ghostty_app_new(&rt, config)
        if app == nil {
            print("[Ghostty] ghostty_app_new failed")
        }
    }

    deinit {
        if let app = app {
            ghostty_app_free(app)
        }
    }
}
