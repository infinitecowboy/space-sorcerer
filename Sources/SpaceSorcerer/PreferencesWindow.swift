import AppKit
import ServiceManagement
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
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 420),
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
    @State private var displayMode: DisplayMode = .manual
    @State private var displayStyle: DisplayStyle = .dots
    @State private var fontSize: CGFloat = 13
    @State private var sizeClassOverride: DisplaySizeClass?
    @State private var hideFromDock: Bool = UserDefaults.standard.object(forKey: "HideFromDock") as? Bool ?? true
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // General
            GroupBox("General") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Hide from Dock", isOn: $hideFromDock)
                        .onChange(of: hideFromDock) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "HideFromDock")
                            NSApp.setActivationPolicy(newValue ? .accessory : .regular)
                        }
                    Toggle("Start at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                launchAtLogin = !newValue
                            }
                        }
                }
                .padding(4)
            }

            // Display Style
            GroupBox("Display Style") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Mode", selection: $displayMode) {
                        Text("Auto").tag(DisplayMode.auto)
                        Text("Manual").tag(DisplayMode.manual)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: displayMode) { newValue in
                        renderer.displayMode = newValue
                        onSettingsChanged()
                    }

                    if displayMode == .auto {
                        Text("Automatically switches based on display size")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Simulate")
                                .font(.caption)
                            Picker("", selection: Binding(
                                get: { sizeClassOverride ?? .compact },
                                set: { sizeClassOverride = $0 }
                            )) {
                                ForEach(DisplaySizeClass.allCases) { sc in
                                    Text(sc.label).tag(sc)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: 200)

                            Toggle("", isOn: Binding(
                                get: { sizeClassOverride != nil },
                                set: { enabled in
                                    if enabled {
                                        sizeClassOverride = .compact
                                        DisplayDetector.override = .compact
                                    } else {
                                        sizeClassOverride = nil
                                        DisplayDetector.override = nil
                                    }
                                    onSettingsChanged()
                                }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                        }
                        .onChange(of: sizeClassOverride) { newValue in
                            DisplayDetector.override = newValue
                            onSettingsChanged()
                        }
                    }

                    Picker("Style", selection: $displayStyle) {
                        ForEach(DisplayStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(displayMode == .auto)
                    .opacity(displayMode == .auto ? 0.5 : 1)
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
        .frame(width: 420, height: 420)
        .onAppear {
            spaces = spaceObserver.querySpaces()
            displayMode = renderer.displayMode
            displayStyle = renderer.displayStyle
            fontSize = renderer.fontSize
            sizeClassOverride = DisplayDetector.override
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
