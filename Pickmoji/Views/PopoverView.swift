import SwiftUI

struct PopoverView: View {
    static let size = CGSize(width: 360, height: 420)

    @ObservedObject var model: PopoverModel

    var body: some View {
        Group {
            if model.showingSettings {
                SettingsView(settings: model.settings, usage: model.usage) {
                    model.showingSettings = false
                    model.didOpen()
                }
            } else {
                picker
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    private var picker: some View {
        VStack(spacing: 0) {
            SearchField(
                text: $model.query,
                focusRequest: model.focusRequest,
                onMove: { model.move($0) },
                onCommit: { model.copySelected() },
                onCancel: { model.requestClose?() }
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            EmojiGridView(model: model)

            Divider()

            HStack {
                Text(model.selectedItem?.emoji.label ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                Button {
                    model.showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .overlay(alignment: .bottom) {
            if let copied = model.copiedEmoji {
                Text("Copied \(copied)")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 44)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.12), value: model.copiedEmoji)
    }
}
