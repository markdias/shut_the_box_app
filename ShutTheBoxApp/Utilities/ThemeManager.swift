import SwiftUI
import UIKit

@MainActor
final class ThemeManager: ObservableObject {
    @Published var theme: ThemeOption {
        didSet {
            guard oldValue != theme else { return }
            persist(theme)
            apply(theme)
        }
    }

    private let storage = StorageProvider()

    init() {
        if let raw: String = storage.restoreString(key: .theme), let option = ThemeOption(rawValue: raw) {
            self.theme = option
        } else {
            self.theme = .neon
        }

        persist(theme)
        apply(theme)
    }

    func applyCurrentTheme() {
        apply(theme)
    }

    private func apply(_ theme: ThemeOption) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }

        let accent = accentColor(for: theme)

        scene.windows.forEach { window in
            window.overrideUserInterfaceStyle = .dark
            window.tintColor = accent
            window.backgroundColor = UIColor.clear
        }

        if let keyWindow = scene.keyWindow {
            keyWindow.overrideUserInterfaceStyle = .dark
            keyWindow.tintColor = accent
        }
    }

    private func persist(_ theme: ThemeOption) {
        storage.persist(theme.rawValue, key: .theme)
    }

    private func accentColor(for theme: ThemeOption) -> UIColor {
        switch theme {
        case .neon:
            return UIColor(red: 0.58, green: 0.29, blue: 0.96, alpha: 1.0)
        case .matrix:
            return UIColor(red: 0.0, green: 0.78, blue: 0.39, alpha: 1.0)
        case .classic:
            return UIColor(red: 0.97, green: 0.68, blue: 0.15, alpha: 1.0)
        case .tabletop:
            return UIColor(red: 0.83, green: 0.43, blue: 0.22, alpha: 1.0)
        }
    }

    static func persistedTheme() -> ThemeOption {
        let storage = StorageProvider()
        if let raw: String = storage.restoreString(key: .theme), let option = ThemeOption(rawValue: raw) {
            return option
        }
        return .neon
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first { $0.isKeyWindow }
    }
}
