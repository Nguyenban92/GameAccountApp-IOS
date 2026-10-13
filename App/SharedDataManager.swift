import Foundation

class SharedDataManager {
    static let shared = SharedDataManager()
    private let userDefaults = UserDefaults(suiteName: "group.com.ban.GameAccountApp")
    private let key = "SavedAccounts"

    func saveAccounts(_ accounts: [GameAccount]) {
        if let encoded = try? JSONEncoder().encode(accounts) {
            userDefaults?.set(encoded, forKey: key)
        }
    }

    func loadAccounts() -> [GameAccount] {
        if let savedData = userDefaults?.data(forKey: key),
           let decoded = try? JSONDecoder().decode([GameAccount].self, from: savedData) {
            return decoded
        }
        return []
    }
}
