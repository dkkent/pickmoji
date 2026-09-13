import Foundation
import ServiceManagement

final class Settings: ObservableObject {
    static let skinToneKey = "defaultSkinTone"

    @Published var defaultSkinTone: SkinTone {
        didSet { defaults.set(defaultSkinTone.rawValue, forKey: Self.skinToneKey) }
    }

    @Published private(set) var launchAtLogin: Bool
    @Published var launchAtLoginError: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaultSkinTone = SkinTone(rawValue: defaults.integer(forKey: Self.skinToneKey)) ?? .none
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
