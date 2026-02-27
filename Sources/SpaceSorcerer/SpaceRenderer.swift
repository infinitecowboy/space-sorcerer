import AppKit

enum DisplayMode: String {
    case auto = "auto"
    case manual = "manual"
}

final class SpaceRenderer {
    var displayStyle: DisplayStyle {
        get {
            DisplayStyle(rawValue: UserDefaults.standard.string(forKey: "DisplayStyle") ?? "dots") ?? .dots
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "DisplayStyle")
        }
    }

    var displayMode: DisplayMode {
        get {
            DisplayMode(rawValue: UserDefaults.standard.string(forKey: "DisplayMode") ?? "manual") ?? .manual
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "DisplayMode")
        }
    }

    var fontSize: CGFloat {
        get { CGFloat(UserDefaults.standard.float(forKey: "FontSize").clamped(to: 8...24, default: 13)) }
        set { UserDefaults.standard.set(Float(newValue), forKey: "FontSize") }
    }

    var effectiveDisplayStyle: DisplayStyle {
        guard displayMode == .auto else { return displayStyle }
        switch DisplayDetector.classifyMenuBarDisplay() {
        case .compact: return .dots
        case .medium: return .abbreviated
        case .large: return .named
        }
    }

    func render(spaces: [Space]) -> NSImage {
        switch effectiveDisplayStyle {
        case .dots:
            return renderDots(spaces: spaces)
        case .abbreviated:
            return renderAbbreviated(spaces: spaces)
        case .named:
            return renderNamed(spaces: spaces)
        }
    }

    // MARK: - Dots

    private func renderDots(spaces: [Space]) -> NSImage {
        guard !spaces.isEmpty else { return placeholderImage() }
        let dotSize: CGFloat = 6
        let spacing: CGFloat = 5
        let totalWidth = CGFloat(spaces.count) * dotSize + CGFloat(max(0, spaces.count - 1)) * spacing
        let height: CGFloat = 18

        let image = NSImage(size: NSSize(width: totalWidth, height: height), flipped: false) { rect in
            let color = NSColor.black
            color.set()

            for (i, space) in spaces.enumerated() {
                let x = CGFloat(i) * (dotSize + spacing)
                let y = (height - dotSize) / 2
                let dotRect = NSRect(x: x, y: y, width: dotSize, height: dotSize)
                let path = NSBezierPath(ovalIn: dotRect)

                if space.isCurrentSpace {
                    path.fill()
                } else {
                    path.lineWidth = 1.2
                    path.stroke()
                }
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    // MARK: - Abbreviated

    private func renderAbbreviated(spaces: [Space]) -> NSImage {
        guard !spaces.isEmpty else { return placeholderImage() }
        let font = berkeleyMono(size: fontSize)
        let spacing: CGFloat = 6
        let pillPadH: CGFloat = 4
        let pillPadV: CGFloat = 2
        let cornerRadius: CGFloat = 4

        struct LabelInfo {
            let text: String
            let size: NSSize
            let isCurrent: Bool
        }

        let labels: [LabelInfo] = spaces.map { space in
            let text = String(space.spaceName.prefix(1))
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let size = (text as NSString).size(withAttributes: attrs)
            return LabelInfo(text: text, size: size, isCurrent: space.isCurrentSpace)
        }

        let height: CGFloat = max(18, labels.map { $0.size.height }.max().map { $0 + pillPadV * 2 } ?? 18)
        var totalWidth: CGFloat = 0
        for (i, label) in labels.enumerated() {
            totalWidth += label.size.width + pillPadH * 2
            if i < labels.count - 1 { totalWidth += spacing }
        }

        let image = NSImage(size: NSSize(width: ceil(totalWidth), height: height), flipped: false) { rect in
            var x: CGFloat = 0

            for label in labels {
                let labelWidth = label.size.width + pillPadH * 2
                let textY = (rect.height - label.size.height) / 2

                if label.isCurrent {
                    let pillRect = NSRect(x: x, y: (rect.height - label.size.height - pillPadV * 2) / 2,
                                          width: labelWidth, height: label.size.height + pillPadV * 2)
                    let pill = NSBezierPath(roundedRect: pillRect, xRadius: cornerRadius, yRadius: cornerRadius)
                    NSColor.white.withAlphaComponent(0.9).setFill()
                    pill.fill()

                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: NSColor.black.withAlphaComponent(0.85),
                    ]
                    (label.text as NSString).draw(at: NSPoint(x: x + pillPadH, y: textY), withAttributes: attrs)
                } else {
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: NSColor.white.withAlphaComponent(0.5),
                    ]
                    (label.text as NSString).draw(at: NSPoint(x: x + pillPadH, y: textY), withAttributes: attrs)
                }

                x += labelWidth + spacing
            }
            return true
        }
        image.isTemplate = false
        return image
    }

    // MARK: - Named

    private func renderNamed(spaces: [Space]) -> NSImage {
        guard !spaces.isEmpty else { return placeholderImage() }
        let font = berkeleyMono(size: fontSize)
        let spacing: CGFloat = 6
        let pillPadH: CGFloat = 6
        let pillPadV: CGFloat = 2
        let cornerRadius: CGFloat = 4

        // Measure each space label
        struct LabelInfo {
            let text: String
            let size: NSSize
            let isCurrent: Bool
        }

        let labels: [LabelInfo] = spaces.map { space in
            let text = space.spaceName
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let size = (text as NSString).size(withAttributes: attrs)
            return LabelInfo(text: text, size: size, isCurrent: space.isCurrentSpace)
        }

        // Calculate total width
        let height: CGFloat = max(18, labels.map { $0.size.height }.max().map { $0 + pillPadV * 2 } ?? 18)
        var totalWidth: CGFloat = 0
        for (i, label) in labels.enumerated() {
            totalWidth += label.size.width + pillPadH * 2
            if i < labels.count - 1 { totalWidth += spacing }
        }

        let image = NSImage(size: NSSize(width: ceil(totalWidth), height: height), flipped: false) { rect in
            var x: CGFloat = 0

            for label in labels {
                let labelWidth = label.size.width + pillPadH * 2
                let textY = (rect.height - label.size.height) / 2

                if label.isCurrent {
                    // Draw pill background
                    let pillRect = NSRect(x: x, y: (rect.height - label.size.height - pillPadV * 2) / 2,
                                          width: labelWidth, height: label.size.height + pillPadV * 2)
                    let pill = NSBezierPath(roundedRect: pillRect, xRadius: cornerRadius, yRadius: cornerRadius)
                    NSColor.white.withAlphaComponent(0.9).setFill()
                    pill.fill()

                    // Dark text on light pill
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: NSColor.black.withAlphaComponent(0.85),
                    ]
                    (label.text as NSString).draw(at: NSPoint(x: x + pillPadH, y: textY), withAttributes: attrs)
                } else {
                    // Dimmed text
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: NSColor.white.withAlphaComponent(0.5),
                    ]
                    (label.text as NSString).draw(at: NSPoint(x: x + pillPadH, y: textY), withAttributes: attrs)
                }

                x += labelWidth + spacing
            }
            return true
        }
        // Not a template — we draw explicit colors for pill + text
        image.isTemplate = false
        return image
    }

    private func placeholderImage() -> NSImage {
        let size = NSSize(width: 8, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.set()
            let dot = NSRect(x: 1, y: 6, width: 6, height: 6)
            NSBezierPath(ovalIn: dot).fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    // MARK: - Font

    private func berkeleyMono(size: CGFloat) -> NSFont {
        NSFont(name: "Berkeley Mono", size: size)
            ?? NSFont(name: "BerkeleyMono-Regular", size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>, default defaultValue: Float) -> Float {
        if self == 0 { return defaultValue }
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
