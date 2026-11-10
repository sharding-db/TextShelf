import ClipboardCore

final class ClipboardCoreTests {
    func testCapacityKeepsOnlyTheFifteenMostRecentTexts() {
        var history = ClipboardHistory()
        for index in 1...20 { history.record("text-\(index)") }
        expectEqual(history.items, (6...20).reversed().map { "text-\($0)" })
        expectEqual(history.capacity, 15)
    }

    func testExternalDuplicateMovesToFrontWithoutUsingAnotherSlot() {
        var history = ClipboardHistory(capacity: 3)
        ["a", "b", "c"].forEach { history.record($0) }
        expectTrue(history.record("a"))
        expectEqual(history.items, ["a", "c", "b"])
        expectFalse(history.record("a"))
    }

    func testTextIsStoredVerbatimAndOnlyEmptyValuesAreIgnored() {
        var history = ClipboardHistory()
        expectFalse(history.record(nil))
        expectFalse(history.record(""))
        let original = "  中文 🧑🏽‍💻\n\tline two\r\n" + String(repeating: "x", count: 10_000)
        expectTrue(history.record(original))
        expectEqual(history.items.first, original)
        expectTrue(history.record(" \t\n"))
        expectEqual(history.items.first, " \t\n")
    }

    func testCapacityOne() {
        var history = ClipboardHistory(capacity: 1)
        history.record("a")
        history.record("b")
        expectEqual(history.items, ["b"])
    }

    func testInitialClipboardIsCapturedAndUnchangedClipboardIsNotReread() {
        let board = FakePasteboard("initial")
        let recorder = ClipboardRecorder(pasteboard: board)
        expectEqual(recorder.history.items, ["initial"])
        expectFalse(recorder.poll())
        expectEqual(board.readCount, 1)
        board.externalCopy("next")
        expectTrue(recorder.poll())
        expectEqual(recorder.history.items, ["next", "initial"])
        board.externalCopy("next")
        expectFalse(recorder.poll())
    }

    func testNonTextChangesAreConsumedWithoutRemovingHistory() {
        let board = FakePasteboard("text")
        let recorder = ClipboardRecorder(pasteboard: board)
        board.externalCopy(nil)
        expectFalse(recorder.poll())
        expectFalse(recorder.poll())
        expectEqual(board.readCount, 2)
        expectEqual(recorder.history.items, ["text"])
    }

    func testRestoreDoesNotDuplicateOrReorderHistory() {
        let board = FakePasteboard("first")
        let recorder = ClipboardRecorder(pasteboard: board)
        board.externalCopy("second")
        recorder.poll()
        expectTrue(recorder.restore("first"))
        expectEqual(board.text, "first")
        expectFalse(recorder.poll())
        expectEqual(recorder.history.items, ["second", "first"])
        board.externalCopy("first")
        expectTrue(recorder.poll())
        expectEqual(recorder.history.items, ["first", "second"])
    }

    func testRestoreRetainsAnExternalCopyThatArrivedBeforeTheNextPoll() {
        let board = FakePasteboard("first")
        let recorder = ClipboardRecorder(pasteboard: board)
        board.externalCopy("just copied")
        expectTrue(recorder.restore("first"))
        expectEqual(board.text, "first")
        expectEqual(recorder.history.items, ["just copied", "first"])
        expectFalse(recorder.poll())
    }

    func testFailedAndEmptyRestoresDoNotPretendToSucceed() {
        let board = FakePasteboard("first")
        let recorder = ClipboardRecorder(pasteboard: board)
        expectFalse(recorder.restore(""))
        expectEqual(board.writeCount, 0)
        board.allowWrites = false
        expectFalse(recorder.restore("first"))
        expectEqual(board.text, "first")
        board.externalCopy("later")
        expectTrue(recorder.poll())
        expectEqual(recorder.history.items, ["later", "first"])
    }
}

private final class FakePasteboard: TextPasteboard {
    private(set) var changeCount = 0
    private(set) var text: String?
    private(set) var readCount = 0
    private(set) var writeCount = 0
    var allowWrites = true

    init(_ text: String?) { self.text = text }

    func readText() -> String? {
        readCount += 1
        return text
    }

    func externalCopy(_ text: String?) {
        self.text = text
        changeCount += 1
    }

    func writeText(_ text: String) -> Bool {
        writeCount += 1
        guard allowWrites else { return false }
        externalCopy(text)
        return true
    }
}
