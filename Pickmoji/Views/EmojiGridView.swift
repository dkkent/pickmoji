import AppKit
import SwiftUI

struct EmojiGridView: View {
    @ObservedObject var model: PopoverModel

    private let cellSize: CGFloat = 40
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: PopoverModel.columns)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if !model.store.isLoaded {
                    Text("Loading emoji…")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else if model.sections.allSatisfy({ $0.items.isEmpty }) {
                    Text("No emoji found")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(model.sections) { section in
                            Section {
                                ForEach(section.items) { item in
                                    cell(for: item)
                                        .id(item.id)
                                }
                            } header: {
                                SectionHeader(title: section.title)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .onChange(of: model.selectedID) { id in
                if let id {
                    proxy.scrollTo(id)
                }
            }
        }
    }

    private func cell(for item: GridSection.Item) -> some View {
        EmojiCell(
            text: model.display(item.emoji),
            label: item.emoji.label,
            isSelected: model.selectedID == item.id,
            size: cellSize,
            onPrimary: { model.copy(model.display(item.emoji), base: item.emoji) },
            onAlternate: {
                model.selectedID = item.id
                if item.emoji.supportsSkinTones {
                    model.tonePickerID = item.id
                }
            }
        )
        .popover(
            isPresented: Binding(
                get: { model.tonePickerID == item.id },
                set: { if !$0 { model.tonePickerID = nil } }
            ),
            arrowEdge: .bottom
        ) {
            TonePickerView(emoji: item.emoji) { variant in
                model.copy(variant, base: item.emoji)
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .padding(.horizontal, 20)
            .background(.regularMaterial)
    }
}

struct EmojiCell: View {
    let text: String
    let label: String
    let isSelected: Bool
    let size: CGFloat
    let onPrimary: () -> Void
    let onAlternate: () -> Void

    @State private var hovering = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)
            Text(text)
                .font(.system(size: 26))
            MouseCatcher(onHover: { hovering = $0 }, onPrimary: onPrimary, onAlternate: onAlternate)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(label)
        .help(label)
    }

    private var backgroundColor: Color {
        if isSelected { return Color.accentColor.opacity(0.35) }
        if hovering { return Color.primary.opacity(0.08) }
        return .clear
    }
}

struct MouseCatcher: NSViewRepresentable {
    var onHover: (Bool) -> Void
    var onPrimary: () -> Void
    var onAlternate: () -> Void

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        update(view)
        return view
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        update(view)
    }

    private func update(_ view: CatcherView) {
        view.onHover = onHover
        view.onPrimary = onPrimary
        view.onAlternate = onAlternate
    }

    final class CatcherView: NSView {
        var onHover: ((Bool) -> Void)?
        var onPrimary: (() -> Void)?
        var onAlternate: (() -> Void)?
        private var trackingArea: NSTrackingArea?
        private var pressedInside = false

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let trackingArea {
                removeTrackingArea(trackingArea)
            }
            let area = NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(area)
            trackingArea = area
        }

        override func mouseEntered(with event: NSEvent) { onHover?(true) }
        override func mouseExited(with event: NSEvent) { onHover?(false) }

        override func mouseDown(with event: NSEvent) {
            if event.modifierFlags.contains(.control) {
                onAlternate?()
                pressedInside = false
            } else {
                pressedInside = true
            }
        }

        override func mouseUp(with event: NSEvent) {
            defer { pressedInside = false }
            guard pressedInside, bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
            if event.modifierFlags.contains(.option) {
                onAlternate?()
            } else {
                onPrimary?()
            }
        }

        override func rightMouseDown(with event: NSEvent) {
            onAlternate?()
        }
    }
}
