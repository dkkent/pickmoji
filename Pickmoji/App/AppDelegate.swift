import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard NSClassFromString("XCTestCase") == nil else { return }

        installMainMenu()

        let store = EmojiStore()
        let usage = UsageStore()
        let settings = Settings()
        let model = PopoverModel(store: store, usage: usage, settings: settings)
        controller = StatusItemController(model: model)
        store.loadInBackground()
    }

    // Menu bar apps have no visible menu, but text fields still route ⌘C/⌘V/⌘A through one.
    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Pickmoji", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)

        NSApp.mainMenu = mainMenu
    }
}
