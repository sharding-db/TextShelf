import Foundation

// Command Line Tools ships AppKit but not XCTest. Keep these checks dependency-free.
private var failureCount = 0

func expectTrue(_ value: @autoclosure () -> Bool, file: StaticString = #filePath, line: UInt = #line) {
    if !value() { fail("Expected true", file: file, line: line) }
}

func expectFalse(_ value: @autoclosure () -> Bool, file: StaticString = #filePath, line: UInt = #line) {
    if value() { fail("Expected false", file: file, line: line) }
}

func expectEqual<T: Equatable>(_ actual: @autoclosure () -> T, _ expected: @autoclosure () -> T,
                               file: StaticString = #filePath, line: UInt = #line) {
    if actual() != expected() { fail("Values differ", file: file, line: line) }
}

func expectNil<T>(_ value: @autoclosure () -> T?, file: StaticString = #filePath, line: UInt = #line) {
    if value() != nil { fail("Expected nil", file: file, line: line) }
}

private func fail(_ message: String, file: StaticString, line: UInt) {
    failureCount += 1
    print("FAIL \(file):\(line): \(message)")
}

let core = ClipboardCoreTests()
let native = NativePasteboardTests()
let cases: [(String, () -> Void)] = [
    ("15-item capacity", core.testCapacityKeepsOnlyTheFifteenMostRecentTexts),
    ("External duplicate", core.testExternalDuplicateMovesToFrontWithoutUsingAnotherSlot),
    ("Original text and empty values", core.testTextIsStoredVerbatimAndOnlyEmptyValuesAreIgnored),
    ("Capacity of one", core.testCapacityOne),
    ("Initial clipboard and change detection", core.testInitialClipboardIsCapturedAndUnchangedClipboardIsNotReread),
    ("Non-text changes", core.testNonTextChangesAreConsumedWithoutRemovingHistory),
    ("Restore preserves history", core.testRestoreDoesNotDuplicateOrReorderHistory),
    ("Copy before next timer tick", core.testRestoreRetainsAnExternalCopyThatArrivedBeforeTheNextPoll),
    ("Failed and empty restores", core.testFailedAndEmptyRestoresDoNotPretendToSucceed),
    ("Native pasteboard round trip", native.testRealPasteboardRoundTripPreservesFullTextAndHistoryOrder),
    ("Image and file exclusion", native.testImageAndFileClipboardChangesAreNotRecordedAsText),
    ("Concealed and rich text", native.testConcealedTextIsSkippedAndOrdinaryRichTextCanBeRead),
]

for (name, run) in cases {
    let before = failureCount
    run()
    print("\(failureCount == before ? "PASS" : "FAIL") \(name)")
}
print("\(cases.count) checks, \(failureCount) failures")
exit(failureCount == 0 ? 0 : 1)
