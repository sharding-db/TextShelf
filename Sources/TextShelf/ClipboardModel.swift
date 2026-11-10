import AppKit
import ClipboardCore
import ClipboardMac
import SwiftUI

@MainActor
final class ClipboardModel: ObservableObject {
    @Published private(set) var items: [String] = []
    @Published private(set) var errorMessage: String?
    private let recorder: ClipboardRecorder
    private var timer: Timer?

    init(pasteboard: NSPasteboard = .general) {
        recorder = ClipboardRecorder(pasteboard: AppKitTextPasteboard(pasteboard))
        items = recorder.history.items
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func refresh() {
        recorder.poll()
        if items != recorder.history.items { items = recorder.history.items }
    }

    func copy(_ text: String) -> Bool {
        let succeeded = recorder.restore(text)
        refresh()
        errorMessage = succeeded ? nil : "复制失败，请再试一次"
        return succeeded
    }
}
