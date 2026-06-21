import Foundation

/// Lightweight inline localization. The app ships English by default and uses
/// Korean when the user's preferred language is Korean. Kept dependency-free
/// (no .strings bundle) so it works from a plain SwiftPM executable.
enum L {
    static let isKorean: Bool =
        (Locale.preferredLanguages.first ?? "en").lowercased().hasPrefix("ko")

    static func t(_ en: String, _ ko: String) -> String {
        isKorean ? ko : en
    }
}
