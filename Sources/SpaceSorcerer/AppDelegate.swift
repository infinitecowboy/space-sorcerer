import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, SpaceObserverDelegate {
    private let spaceObserver = SpaceObserver()
    private let statusBar = StatusBarController()
    private let renderer = SpaceRenderer()
    private lazy var prefsController = PreferencesWindowController(
        spaceObserver: spaceObserver,
        renderer: renderer
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hideFromDock = UserDefaults.standard.object(forKey: "HideFromDock") as? Bool ?? true
        NSApp.setActivationPolicy(hideFromDock ? .accessory : .regular)

        spaceObserver.delegate = self

        statusBar.onPreferences = { [weak self] in
            self?.prefsController.show()
        }
        statusBar.onQuit = {
            NSApp.terminate(nil)
        }

        prefsController.onSettingsChanged = { [weak self] in
            self?.spaceObserver.refresh()
        }

        // Defer initial refresh to the next run loop pass so the status bar
        // has fully materialised — setting the image during didFinishLaunching
        // can silently fail to render on some macOS versions.
        DispatchQueue.main.async { [weak self] in
            self?.spaceObserver.refresh()
        }
    }

    // MARK: - SpaceObserverDelegate

    func didUpdateSpaces(_ spaces: [Space]) {
        let image = renderer.render(spaces: spaces)
        statusBar.updateIcon(image)
        statusBar.updateSpaces(spaces)
    }
}
