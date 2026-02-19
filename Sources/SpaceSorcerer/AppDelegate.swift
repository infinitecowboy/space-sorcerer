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
        NSApp.setActivationPolicy(.accessory)

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

        spaceObserver.refresh()
    }

    // MARK: - SpaceObserverDelegate

    func didUpdateSpaces(_ spaces: [Space]) {
        let image = renderer.render(spaces: spaces)
        statusBar.updateIcon(image)
        statusBar.updateSpaces(spaces)
    }
}
