import AuthenticationServices

class CredentialProviderViewController: ASCredentialProviderViewController {
    
    struct GameAccount: Codable {
        var username: String
        var password: String
        var status: String
    }
    
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let userDefaults = UserDefaults(suiteName: "group.com.ban.GameAccountApp")
        var accounts: [GameAccount] = []
        
        if let savedData = userDefaults?.data(forKey: "SavedAccounts"),
           let decoded = try? JSONDecoder().decode([GameAccount].self, from: savedData) {
            accounts = decoded
        }
        
        // Lấy tài khoản "Chờ đăng nhập" đầu tiên theo logic Hàng đợi
        if let nextAccount = accounts.first(where: { $0.status == "Chờ đăng nhập" }) {
            let passwordCredential = ASPasswordCredential(
                user: nextAccount.username,
                password: nextAccount.password
            )
            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        } else {
            self.extensionContext.cancelRequest(withError: NSError(domain: "com.ban.error", code: 0, userInfo: nil))
        }
    }
}
