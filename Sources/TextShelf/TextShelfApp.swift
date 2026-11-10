import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var model: ClipboardModel!
    private var previousApp: NSRunningApplication?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let bundleID = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.accessory)
        // UI acceptance can run on an isolated board without touching the user's clipboard.
        let board = ProcessInfo.processInfo.environment["TEXTSHELF_TEST_PASTEBOARD"]
            .map { NSPasteboard(name: NSPasteboard.Name($0)) } ?? .general
        model = ClipboardModel(pasteboard: board)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "TextShelf")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "TextShelf · 最近 15 条文本"
            button.target = self
            button.action = #selector(togglePopover)
            button.setAccessibilityLabel("TextShelf 剪贴板历史")
        }
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: HistoryView(
            model: model,
            onCopy: { [weak self] text in self?.copyAndClose(text) },
            onQuit: { NSApp.terminate(nil) }
        ))
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53, self?.popover.isShown == true {
                self?.popover.performClose(nil)
                return nil
            }
            return event
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        guard let button = statusItem.button else { return }
        previousApp = NSWorkspace.shared.frontmostApplication
        model.refresh()
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func copyAndClose(_ text: String) {
        guard model.copy(text) else { return }
        popover.performClose(nil)
        previousApp?.activate(options: [.activateIgnoringOtherApps])
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
    }
}

@main
struct TextShelfApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
