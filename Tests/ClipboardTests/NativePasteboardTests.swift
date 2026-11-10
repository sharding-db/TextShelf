import AppKit
import ClipboardCore
import ClipboardMac

final class NativePasteboardTests {
    func testRealPasteboardRoundTripPreservesFullTextAndHistoryOrder() {
        let board = NSPasteboard.withUniqueName()
        let adapter = AppKitTextPasteboard(board)
        let recorder = ClipboardRecorder(pasteboard: adapter)
        let original = "  hello 中文 👋\n\tsecond line\n" + String(repeating: "long text ", count: 1_000)
        expectTrue(adapter.writeText(original))
        expectTrue(recorder.poll())
        for index in 1...15 {
            expectTrue(adapter.writeText("copy-\(index)"))
            expectTrue(recorder.poll())
        }
        expectEqual(recorder.history.items.count, 15)
        expectEqual(recorder.history.items.first, "copy-15")
        expectFalse(recorder.history.items.contains(original))
        let before = recorder.history.items
        expectTrue(recorder.restore("copy-1"))
        expectEqual(board.string(forType: .string), "copy-1")
        expectFalse(recorder.poll())
        expectEqual(recorder.history.items, before)
        expectTrue(adapter.writeText(original))
        expectTrue(recorder.poll())
        expectTrue(recorder.restore(original))
        expectEqual(board.string(forType: .string), original)
    }

    func testImageAndFileClipboardChangesAreNotRecordedAsText() {
        let board = NSPasteboard.withUniqueName()
        let adapter = AppKitTextPasteboard(board)
        board.clearContents()
        expectTrue(board.setData(Data([0, 1, 2]), forType: .png))
        expectNil(adapter.readText())
        board.clearContents()
        expectTrue(board.setString("file:///tmp/example.txt", forType: .fileURL))
        expectTrue(board.setString("/tmp/example.txt", forType: .string))
        expectNil(adapter.readText())
    }

    func testConcealedTextIsSkippedAndOrdinaryRichTextCanBeRead() {
        let board = NSPasteboard.withUniqueName()
        let adapter = AppKitTextPasteboard(board)
        expectTrue(adapter.writeText("sensitive test text"))
        board.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        expectNil(adapter.readText())
        expectTrue(adapter.writeText("visible text"))
        board.setData(Data("{\\rtf1 visible text}".utf8), forType: .rtf)
        expectEqual(adapter.readText(), "visible text")
    }
}
