import SwiftUI

struct TonePickerView: View {
    let emoji: Emoji
    let onPick: (String) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(SkinTone.allCases) { tone in
                Button {
                    onPick(emoji.variant(for: tone))
                } label: {
                    Text(emoji.variant(for: tone))
                        .font(.system(size: 26))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ToneButtonStyle())
                .help(tone.name)
            }
        }
        .padding(6)
    }
}

private struct ToneButtonStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.15)
                          : hovering ? Color.primary.opacity(0.08) : .clear)
            )
            .onHover { hovering = $0 }
    }
}
