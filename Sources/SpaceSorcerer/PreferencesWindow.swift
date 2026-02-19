import AppKit
import SwiftUI

final class PreferencesWindowController {
    private var window: NSWindow?
    private let spaceObserver: SpaceObserver
    private let renderer: SpaceRenderer
    var onSettingsChanged: (() -> Void)?

    init(spaceObserver: SpaceObserver, renderer: SpaceRenderer) {
        self.spaceObserver = spaceObserver
        self.renderer = renderer
    }

    func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = PreferencesView(
            spaceObserver: spaceObserver,
            renderer: renderer,
            onSettingsChanged: { [weak self] in self?.onSettingsChanged?() }
        )
        let hostingView = NSHostingView(rootView: view)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Space Sorcerer Preferences"
        win.contentView = hostingView
        win.center()
        win.isReleasedWhenClosed = false
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
    }
}

// MARK: - SwiftUI

struct PreferencesView: View {
    let spaceObserver: SpaceObserver
    let renderer: SpaceRenderer
    let onSettingsChanged: () -> Void

    @State private var spaces: [Space] = []
    @State private var selectedSpaceID: Int?
    @State private var editingName: String = ""
    @State private var displayStyle: DisplayStyle = .dots
    @State private var fontSize: CGFloat = 13

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Display Style
            GroupBox("Display Style") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Style", selection: $displayStyle) {
                        ForEach(DisplayStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: displayStyle) { newValue in
                        renderer.displayStyle = newValue
                        onSettingsChanged()
                    }

                    HStack {
                        Text("Font Size")
                        Slider(value: $fontSize, in: 8...24, step: 1)
                        Text("\(Int(fontSize))pt")
                            .monospacedDigit()
                            .frame(width: 36, alignment: .trailing)
                    }
                    .onChange(of: fontSize) { newValue in
                        renderer.fontSize = newValue
                        onSettingsChanged()
                    }
                }
                .padding(4)
            }

            // Rename Spaces
            GroupBox("Rename Spaces") {
                VStack(alignment: .leading, spacing: 8) {
                    if spaces.isEmpty {
                        Text("No spaces detected.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Space", selection: $selectedSpaceID) {
                            Text("Select a space…").tag(nil as Int?)
                            ForEach(spaces, id: \.spaceID) { space in
                                Text("\(space.spaceIndex): \(space.spaceName)\(space.isCurrentSpace ? " (current)" : "")")
                                    .tag(space.spaceID as Int?)
                            }
                        }

                        HStack {
                            TextField("Custom name", text: $editingName)
                                .textFieldStyle(.roundedBorder)
                            Button("Save") {
                                guard let id = selectedSpaceID else { return }
                                spaceObserver.renamespace(spaceID: id, name: editingName)
                                spaces = spaceObserver.querySpaces()
                                onSettingsChanged()
                            }
                            .disabled(selectedSpaceID == nil)
                            Button("Clear") {
                                guard let id = selectedSpaceID else { return }
                                editingName = ""
                                spaceObserver.renamespace(spaceID: id, name: "")
                                spaces = spaceObserver.querySpaces()
                                onSettingsChanged()
                            }
                            .disabled(selectedSpaceID == nil)
                        }
                    }
                }
                .padding(4)
            }

            Spacer()
        }
        .padding()
        .frame(width: 420, height: 340)
        .onAppear {
            spaces = spaceObserver.querySpaces()
            displayStyle = renderer.displayStyle
            fontSize = renderer.fontSize
            if let first = spaces.first {
                selectedSpaceID = first.spaceID
                editingName = first.spaceName
            }
        }
        .onChange(of: selectedSpaceID) { newValue in
            if let id = newValue, spaces.contains(where: { $0.spaceID == id }) {
                // Show saved name or empty if using default index
                let savedNames = UserDefaults.standard.dictionary(forKey: "SpaceNames") as? [String: String] ?? [:]
                editingName = savedNames[String(id)] ?? ""
            }
        }
    }
}
