import Foundation

struct StorageProvider {
    enum Key: String {
        case snapshot
        case theme
    }

    private let defaults = UserDefaults.standard

    func persist<T: Encodable>(_ value: T, key: Key) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
    }

    func persist(_ value: String, key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    func restore<T: Decodable>(key: Key) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func restoreString(key: Key) -> String? {
        defaults.string(forKey: key.rawValue)
    }
}
