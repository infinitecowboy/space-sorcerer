import AppKit
import CGSBridge

protocol SpaceObserverDelegate: AnyObject {
    func didUpdateSpaces(_ spaces: [Space])
}

final class SpaceObserver {
    weak var delegate: SpaceObserverDelegate?

    private var spaceNames: [Int: String] {
        get {
            UserDefaults.standard.dictionary(forKey: "SpaceNames") as? [Int: String]
                ?? (UserDefaults.standard.dictionary(forKey: "SpaceNames") as? [String: String])
                    .map { dict in
                        var result: [Int: String] = [:]
                        for (k, v) in dict {
                            if let intKey = Int(k) { result[intKey] = v }
                        }
                        return result
                    } ?? [:]
        }
        set {
            let stringKeyed = Dictionary(uniqueKeysWithValues: newValue.map { (String($0.key), $0.value) })
            UserDefaults.standard.set(stringKeyed, forKey: "SpaceNames")
        }
    }

    init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func spaceDidChange(_ notification: Notification) {
        refresh()
    }

    func refresh() {
        let spaces = querySpaces()
        delegate?.didUpdateSpaces(spaces)
    }

    func renamespace(spaceID: Int, name: String) {
        var names = spaceNames
        if name.isEmpty {
            names.removeValue(forKey: spaceID)
        } else {
            names[spaceID] = name
        }
        spaceNames = names
        refresh()
    }

    func querySpaces() -> [Space] {
        let conn = CGSMainConnectionID()
        guard let cfArray = CGSCopyManagedDisplaySpaces(conn) else { return [] }
        guard let displaysInfo = cfArray as NSArray as? [[String: Any]] else { return [] }

        let activeSpaceID = CGSGetActiveSpace(conn)

        var spaces: [Space] = []
        var globalIndex = 1

        for display in displaysInfo {
            let displayID = display["Display Identifier"] as? String ?? "Unknown"
            guard let spaceEntries = display["Spaces"] as? [[String: Any]] else { continue }

            // Current space info for this display
            let currentSpaceOnDisplay = (display["Current Space"] as? [String: Any])?["ManagedSpaceID"] as? Int

            for entry in spaceEntries {
                guard let managedSpaceID = entry["ManagedSpaceID"] as? Int else { continue }
                let type = entry["type"] as? Int ?? 0

                // type 0 = normal desktop, type 4 = fullscreen
                let isFullScreen = type == 4

                let isCurrent = managedSpaceID == activeSpaceID
                    || managedSpaceID == currentSpaceOnDisplay

                let savedName = spaceNames[managedSpaceID]
                let defaultName = "\(globalIndex)"
                let name = savedName ?? defaultName

                spaces.append(Space(
                    displayID: displayID,
                    spaceID: managedSpaceID,
                    spaceName: name,
                    spaceIndex: globalIndex,
                    isCurrentSpace: isCurrent,
                    isFullScreen: isFullScreen
                ))

                globalIndex += 1
            }
        }

        return spaces
    }
}
