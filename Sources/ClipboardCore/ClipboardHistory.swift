/// The original strings are kept intact; only their display previews are shortened.
public struct ClipboardHistory {
    public private(set) var items: [String] = []
    public let capacity: Int

    public init(capacity: Int = 15) {
        precondition(capacity > 0)
        self.capacity = capacity
    }

    @discardableResult
    public mutating func record(_ text: String?) -> Bool {
        guard let text, !text.isEmpty, items.first != text else { return false }
        items.removeAll { $0 == text }
        items.insert(text, at: 0)
        if items.count > capacity {
            items.removeLast(items.count - capacity)
        }
        return true
    }
}

public protocol TextPasteboard: AnyObject {
    var changeCount: Int { get }
    func readText() -> String?
    @discardableResult func writeText(_ text: String) -> Bool
}

/// Used on the main thread by the app; the protocol also permits isolated pasteboard tests.
public final class ClipboardRecorder {
    public private(set) var history: ClipboardHistory
    private let pasteboard: any TextPasteboard
    private var lastChangeCount: Int

    public init(pasteboard: any TextPasteboard, capacity: Int = 15) {
        self.pasteboard = pasteboard
        self.history = ClipboardHistory(capacity: capacity)
        self.lastChangeCount = pasteboard.changeCount
        history.record(pasteboard.readText())
    }

    @discardableResult
    public func poll() -> Bool {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return false }
        lastChangeCount = currentChangeCount
        return history.record(pasteboard.readText())
    }

    @discardableResult
    public func restore(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        // Retain an external copy that arrived between the timer tick and the click.
        poll()
        guard pasteboard.writeText(text) else { return false }
        // Our own write must not create another history item or reorder the list.
        lastChangeCount = pasteboard.changeCount
        return true
    }
}
