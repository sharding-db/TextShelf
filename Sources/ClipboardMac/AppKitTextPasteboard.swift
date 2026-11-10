import AppKit
import ClipboardCore

public final class AppKitTextPasteboard: TextPasteboard {
    private let pasteboard: NSPasteboard

    public init(_ pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public var changeCount: Int { pasteboard.changeCount }

    public func readText() -> String? {
        let types = pasteboard.types ?? []
        // Files may also advertise their paths as text. They are outside this app's scope.
        guard !types.contains(.fileURL),
              !types.contains(NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        else { return nil }
        return pasteboard.string(forType: .string)
    }

    @discardableResult
    public func writeText(_ text: String) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}
