import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private var spaces: [Space] = []
    var onPreferences: (() -> Void)?
    var onQuit: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageOnly
        buildMenu()
    }

    func updateIcon(_ image: NSImage) {
        statusItem.button?.image = image
    }

    func updateSpaces(_ spaces: [Space]) {
        self.spaces = spaces
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        if !spaces.isEmpty {
            let header = NSMenuItem(title: "Spaces", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for space in spaces {
                let prefix = space.isCurrentSpace ? "► " : "   "
                let title = "\(prefix)\(space.spaceIndex): \(space.spaceName)"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                if space.isFullScreen {
                    item.title += " (FS)"
                }
                menu.addItem(item)
            }

            menu.addItem(NSMenuItem.separator())
        }

        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(preferencesClicked), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Space Sorcerer", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func preferencesClicked() {
        onPreferences?()
    }

    @objc private func quitClicked() {
        onQuit?()
    }
}
