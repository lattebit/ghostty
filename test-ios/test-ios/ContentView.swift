import SwiftUI
import GhosttyKit

struct ContentView: View {
    @EnvironmentObject private var ghostty: GhosttyAppState
    @State private var inputText = ""
    @State private var terminalView: GhosttyUIView?

    var body: some View {
        VStack(spacing: 0) {
            if let app = ghostty.app {
                GhosttyTerminalView(app: app)
                    .ignoresSafeArea(.keyboard)
                    .overlay(alignment: .topLeading) {
                        // Capture the UIView reference for demo injection
                        GhosttyViewFinder(view: $terminalView)
                    }
            } else {
                Text("Ghostty failed to initialize")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Input bar
            HStack {
                TextField("Type here and press Send", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { sendInput() }

                Button("Send") { sendInput() }
                    .buttonStyle(.borderedProminent)

                Button("Demo") { runDemo() }
                    .buttonStyle(.bordered)
            }
            .padding(8)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            // Auto-run demo after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                runDemo()
            }
        }
    }

    private func sendInput() {
        guard !inputText.isEmpty else { return }
        terminalView?.sendText(inputText + "\r")
        inputText = ""
    }

    private func runDemo() {
        guard let view = terminalView else { return }

        for (i, seq) in DemoSequences.all.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                view.feedData(Data(seq.utf8))
            }
        }
    }
}

/// A helper view to find the GhosttyUIView reference from the SwiftUI hierarchy.
struct GhosttyViewFinder: UIViewRepresentable {
    @Binding var view: GhosttyUIView?

    func makeUIView(context: Context) -> UIView {
        let probe = UIView(frame: .zero)
        probe.isHidden = true
        DispatchQueue.main.async {
            // Walk up from the probe to find GhosttyUIView
            var current = probe.superview
            while let v = current {
                if let ghosttyView = v as? GhosttyUIView {
                    self.view = ghosttyView
                    return
                }
                current = v.superview
            }
        }
        return probe
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
