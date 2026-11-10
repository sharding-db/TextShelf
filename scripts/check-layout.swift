import AppKit
import SwiftUI

@main
struct LayoutCheck {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let board = NSPasteboard.withUniqueName()
        let model = ClipboardModel(pasteboard: board)
        func measure(_ label: String) {
            let controller = NSHostingController(rootView: HistoryView(model: model, onCopy: { _ in }, onQuit: {}))
            controller.view.layoutSubtreeIfNeeded()
            let size = controller.view.fittingSize
            print("\(label): \(Int(size.width)) × \(Int(size.height))")
            guard abs(size.width - 400) < 1, size.height >= 250, size.height <= 650 else {
                print("FAIL unexpected popover content size")
                exit(1)
            }
        }
        measure("empty")
        for index in 1...18 {
            board.clearContents()
            board.setString("测试记录 \(index)\n第二行 · 中文 👋", forType: .string)
            model.refresh()
        }
        guard model.items.count == 15 else { exit(1) }
        measure("15 records with preview")
        print("PASS native SwiftUI layout")
    }
}
