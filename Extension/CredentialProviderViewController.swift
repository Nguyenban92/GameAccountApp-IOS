import AuthenticationServices

class CredentialProviderViewController: ASCredentialProviderViewController {
    
    struct GameAccountItem: Codable {
        var username: String
        var password: String
        var status: String
    }
    
    struct GameProfileItem: Codable {
        var id: String?
        var title: String?
        var accounts: [GameAccountItem]
        var currentQueueIndex: Int?
    }
    
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let appGroupSuite = "group.com.ban.GameAccountApp"
        let userDefaults = UserDefaults(suiteName: appGroupSuite) ?? UserDefaults.standard
        
        var nextAccount: GameAccountItem? = nil
        
        // 1. Try modern multi-game profiles
        if let gamesData = userDefaults.data(forKey: "SavedGameProfiles"),
           let profiles = try? JSONDecoder().decode([GameProfileItem].self, from: gamesData) {
            
            let activeGameId = userDefaults.string(forKey: "ActiveGameProfileId")
            let targetProfile = profiles.first(where: { $0.id == activeGameId }) ?? profiles.first
            
            if let profile = targetProfile {
                nextAccount = profile.accounts.first(where: { $0.status == "Chờ đăng nhập" })
            }
        }
        
        // 2. Fallback to legacy flat list if needed
        if nextAccount == nil,
           let savedData = userDefaults.data(forKey: "SavedAccounts"),
           let flatAccounts = try? JSONDecoder().decode([GameAccountItem].self, from: savedData) {
            nextAccount = flatAccounts.first(where: { $0.status == "Chờ đăng nhập" })
        }
        
        // Complete or cancel request
        if let account = nextAccount {
            let passwordCredential = ASPasswordCredential(
                user: account.username,
                password: account.password
            )
            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        } else {
            self.extensionContext.cancelRequest(withError: NSError(domain: "com.ban.error", code: 0, userInfo: nil))
        }
    }
}
