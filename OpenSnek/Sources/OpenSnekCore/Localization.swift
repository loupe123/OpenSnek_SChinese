import Foundation

/// Resolves a localized string for a dynamically constructed key.
///
/// SwiftUI resolves `Text("literal")` and other `LocalizedStringKey` values on its own,
/// but values that reach the UI as a plain `String` (label providers, computed model
/// properties, surfaced error messages) bypass that lookup and must ask the bundle
/// directly. Returns the key itself when no translation exists for the active language,
/// so untranslated entries stay readable instead of rendering blank.
public func localized(_ key: String) -> String { Bundle.main.localizedString(forKey: key, value: nil, table: nil) }

/// Resolves a localized format template and applies the provided arguments.
///
/// Use this for text that mixes a translated sentence with runtime values, for example
/// `localizedFormat("Stage %lld DPI", stage)`. The key lives in `Localizable.strings`
/// with its `%` placeholders intact, which keeps argument order translatable.
public func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String { String(format: localized(key), arguments: arguments) }
