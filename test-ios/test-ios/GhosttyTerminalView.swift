import SwiftUI
import UIKit
import GhosttyKit

/// A UIViewRepresentable that wraps a ghostty terminal surface.
///
/// Rendering is driven by CADisplayLink calling ghostty_app_tick()
/// and ghostty_surface_draw() each frame.
struct GhosttyTerminalView: UIViewRepresentable {
    let app: ghostty_app_t
    @Binding var uiView: GhosttyUIView?

    func makeUIView(context: Context) -> GhosttyUIView {
        let view = GhosttyUIView(app: app)
        DispatchQueue.main.async { self.uiView = view }
        return view
    }

    func updateUIView(_ uiView: GhosttyUIView, context: Context) {}
}

/// The underlying UIView that hosts the Metal-rendered terminal.
class GhosttyUIView: UIView {
    private let app: ghostty_app_t
    private var surface: ghostty_surface_t?
    private var displayLink: CADisplayLink?

    init(app: ghostty_app_t) {
        self.app = app
        super.init(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        displayLink?.invalidate()
        if let surface = surface {
            ghostty_surface_free(surface)
        }
    }

    // MARK: - Lifecycle

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else {
            displayLink?.invalidate()
            displayLink = nil
            return
        }

        if surface == nil {
            createSurface()
        }

        if displayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Keep the IOSurfaceLayer sublayer sized to match the view.
        layer.sublayers?.forEach { $0.frame = bounds }

        guard let surface = surface else { return }
        let scale = contentScaleFactor
        ghostty_surface_set_content_scale(surface, scale, scale)
        ghostty_surface_set_size(
            surface,
            UInt32(bounds.width * scale),
            UInt32(bounds.height * scale)
        )
    }

    // MARK: - Surface

    private func createSurface() {
        var config = ghostty_surface_config_new()
        config.userdata = Unmanaged.passUnretained(self).toOpaque()
        config.platform_tag = GHOSTTY_PLATFORM_IOS
        config.platform = ghostty_platform_u(
            ios: ghostty_platform_ios_s(
                uiview: Unmanaged.passUnretained(self).toOpaque()
            )
        )
        config.scale_factor = Double(contentScaleFactor)

        surface = ghostty_surface_new(app, &config)
        guard surface != nil else {
            print("[Ghostty] ghostty_surface_new failed")
            return
        }

        ghostty_surface_set_focus(surface!, true)
        print("[Ghostty] surface created, scale=\(contentScaleFactor)")
    }

    // MARK: - Render loop

    @objc private func tick() {
        ghostty_app_tick(app)
        if let surface = surface {
            ghostty_surface_draw(surface)
        }
    }

    // MARK: - Public API

    func feedData(_ data: Data) {
        guard let surface = surface else { return }
        data.withUnsafeBytes { buffer in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            ghostty_surface_feed_data(surface, ptr, buffer.count)
        }
    }

    func sendText(_ text: String) {
        guard let surface = surface else { return }
        text.withCString { ptr in
            ghostty_surface_text(surface, ptr, UInt(strlen(ptr)))
        }
    }
}
