import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var usage: UsageStore
    var onBack: () -> Void

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "Pickmoji \(short) (\(build))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Text("Settings").font(.headline)
                HStack {
                    Button(action: onBack) {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                row("Hotkey") {
                    KeyboardShortcuts.Recorder(for: .togglePopover)
                }
                row("Skin tone") {
                    Picker("", selection: $settings.defaultSkinTone) {
                        ForEach(SkinTone.allCases) { tone in
                            Text("\(tone.sample)  \(tone.name)").tag(tone)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 200)
                }
                row("Startup") {
                    Toggle("Launch at login", isOn: Binding(
                        get: { settings.launchAtLogin },
                        set: { settings.setLaunchAtLogin($0) }
                    ))
                    .toggleStyle(.checkbox)
                }
                if let error = settings.launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                row("Recents") {
                    Button("Clear recents") { usage.clear() }
                        .disabled(usage.records.isEmpty)
                }
            }
            .padding(12)

            Divider()

            AboutView()

            Divider()

            HStack {
                Text(version)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Quit Pickmoji") { NSApp.terminate(nil) }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func row<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
            content()
            Spacer(minLength: 0)
        }
    }
}

private struct AboutView: View {
    private struct Credit: Identifiable {
        let id: String
        let title: String
        let detail: String
        let licenseFile: String
    }

    private let credits = [
        Credit(id: "emojibase", title: "emojibase-data 17.0.0 (MIT)",
               detail: "Emoji names and keywords, derived from Unicode CLDR.",
               licenseFile: "emojibase-MIT"),
        Credit(id: "unicode", title: "Unicode CLDR (Unicode License v3)",
               detail: "Source of the emoji annotations in emojibase.",
               licenseFile: "Unicode-License-v3"),
        Credit(id: "keyboardshortcuts", title: "KeyboardShortcuts 3.1.0 (MIT)",
               detail: "Global hotkey recording, by Sindre Sorhus.",
               licenseFile: "KeyboardShortcuts-MIT"),
    ]

    @State private var expanded: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pickmoji is open source under the MIT License. Emoji are drawn by macOS with the Apple Color Emoji font; no emoji artwork is bundled.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(credits) { credit in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expanded == credit.id },
                            set: { expanded = $0 ? credit.id : nil }
                        )
                    ) {
                        Text(licenseText(credit.licenseFile))
                            .font(.system(size: 10, design: .monospaced))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(credit.title).font(.caption.weight(.semibold))
                            Text(credit.detail).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    private func licenseText(_ name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt", subdirectory: "LICENSES"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return "License text not bundled." }
        return text
    }
}
