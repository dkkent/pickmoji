import AppKit
import SwiftUI

struct SearchField: NSViewRepresentable {
    @Binding var text: String
    var focusRequest: Int
    var onMove: (MoveDirection) -> Void
    var onCommit: () -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = "Search emoji"
        field.delegate = context.coordinator
        field.sendsSearchStringImmediately = true
        field.sendsWholeSearchString = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 15)
        return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text {
            field.stringValue = text
        }
        if context.coordinator.handledFocusRequest != focusRequest {
            context.coordinator.handledFocusRequest = focusRequest
            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
            }
        }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: SearchField
        var handledFocusRequest = 0

        init(parent: SearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.moveUp(_:)):
                parent.onMove(.up)
            case #selector(NSResponder.moveDown(_:)):
                parent.onMove(.down)
            case #selector(NSResponder.moveLeft(_:)):
                parent.onMove(.left)
            case #selector(NSResponder.moveRight(_:)):
                parent.onMove(.right)
            case #selector(NSResponder.insertNewline(_:)):
                parent.onCommit()
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
            default:
                return false
            }
            return true
        }
    }
}
