import AppKit
import KeyboardShortcuts
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let model: PopoverModel

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

    @objc private func statusItemClicked() {
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
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        model.didOpen()
    }

    func close() {
        popover.performClose(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        model.reset()
        NSApp.hide(nil)
    }
}
