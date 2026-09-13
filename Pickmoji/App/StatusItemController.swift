import AppKit
import KeyboardShortcuts
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let model: PopoverModel
    private var lastClose = Date.distantPast

    init(model: PopoverModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Pickmoji")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(statusItemClicked)
        }

        popover.contentSize = NSSize(width: PopoverView.size.width, height: PopoverView.size.height)
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: PopoverView(model: model))

        model.requestClose = { [weak self] in self?.close() }
        KeyboardShortcuts.onKeyUp(for: .togglePopover) { [weak self] in self?.toggle() }
    }

    // A click on the status item lands as mouse-down (which closes the transient
    // popover) then mouse-up (this action); without the guard it would reopen.
    @objc private func statusItemClicked() {
        if Date().timeIntervalSince(lastClose) < 0.3 { return }
        toggle()
    }

    func toggle() {
        if popover.isShown {
            close()
        } else {
            show()
        }
    }

    func show() {
        guard let button = statusItem.button else { return }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        model.didOpen()
    }

    func close() {
        popover.performClose(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        lastClose = Date()
        model.reset()
        NSApp.hide(nil)
    }
}
