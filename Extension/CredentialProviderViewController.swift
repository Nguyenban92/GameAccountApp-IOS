import AuthenticationServices
import SwiftUI

// MARK: - Credential Provider View Controller
class CredentialProviderViewController: ASCredentialProviderViewController {
    
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let appGroupSuite = "group.com.ban.GameAccountApp"
        let userDefaults = UserDefaults(suiteName: appGroupSuite) ?? UserDefaults.standard
        
        let gamesData = userDefaults.data(forKey: "SavedGameProfiles")
        var profiles: [GameProfileItem] = []
        if let data = gamesData, let decoded = try? JSONDecoder().decode([GameProfileItem].self, from: data) {
            profiles = decoded
        }
        
        let activeGameId = userDefaults.string(forKey: "ActiveGameProfileId")
        
        // Present interactive SwiftUI Credential Picker Sheet
        let hostingController = UIHostingController(
            rootView: AutoFillPickerView(
                profiles: profiles,
                initialActiveGameId: activeGameId,
                onSelect: { [weak self] selectedAcc, profileIndex in
                    self?.handleCredentialSelected(account: selectedAcc, profileIndex: profileIndex, userDefaults: userDefaults, profiles: profiles)
                },
                onCancel: { [weak self] in
                    self?.extensionContext.cancelRequest(withError: NSError(domain: "com.ban.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]))
                }
            )
        )
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
    
    private func handleCredentialSelected(account: GameAccountItem, profileIndex: Int, userDefaults: UserDefaults, profiles: [GameProfileItem]) {
        // 1. Advance queue index and update last login in shared UserDefaults
        var updatedProfiles = profiles
        if profileIndex < updatedProfiles.count {
            if let accIdx = updatedProfiles[profileIndex].accounts.firstIndex(where: { $0.username == account.username }) {
                updatedProfiles[profileIndex].accounts[accIdx].status = "Đã điền"
                updatedProfiles[profileIndex].currentQueueIndex = (accIdx + 1) % max(updatedProfiles[profileIndex].accounts.count, 1)
                
                if let encoded = try? JSONEncoder().encode(updatedProfiles) {
                    userDefaults.set(encoded, forKey: "SavedGameProfiles")
                }
            }
        }
        
        // 2. Complete request: iOS natively pastes username & password into the game!
        let credential = ASPasswordCredential(
            user: account.username,
            password: account.password
        )
        self.extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
    }
}

// MARK: - Decodable Items for Extension
struct GameAccountItem: Identifiable, Codable {
    var id: UUID? = UUID()
    var username: String
    var password: String
    var server: String?
    var levelOrRank: String?
    var status: String
}

struct GameProfileItem: Identifiable, Codable {
    var id: UUID? = UUID()
    var title: String
    var server: String?
    var accounts: [GameAccountItem]
    var currentQueueIndex: Int?
}

// MARK: - SwiftUI AutoFill Picker View (Hiển thị ngay trên bàn phím iOS)
struct AutoFillPickerView: View {
    let profiles: [GameProfileItem]
    @State private var selectedProfileIdx: Int = 0
    let onSelect: (GameAccountItem, Int) -> Void
    let onCancel: () -> Void
    
    init(profiles: [GameProfileItem], initialActiveGameId: String?, onSelect: @escaping (GameAccountItem, Int) -> Void, onCancel: @escaping () -> Void) {
        self.profiles = profiles
        self.onSelect = onSelect
        self.onCancel = onCancel
        
        if let activeId = initialActiveGameId,
           let foundIdx = profiles.firstIndex(where: { $0.id?.uuidString == activeId }) {
            _selectedProfileIdx = State(initialValue: foundIdx)
        } else {
            _selectedProfileIdx = State(initialValue: 0)
        }
    }
    
    var currentProfile: GameProfileItem? {
        guard !profiles.isEmpty && selectedProfileIdx >= 0 && selectedProfileIdx < profiles.count else { return nil }
        return profiles[selectedProfileIdx]
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.12).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Sheet Header
                HStack {
                    HStack(spacing: 6) {
                        Text("🎮").font(.title3)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("AutoFill Tự Động")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text("Chọn tài khoản để điền vào Game")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Đóng") {
                        onCancel()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.15))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
                
                // Game Selector Tabs (Nếu chơi nhiều game)
                if profiles.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(profiles.indices, id: \.self) { pIdx in
                                let prof = profiles[pIdx]
                                let isSelected = pIdx == selectedProfileIdx
                                
                                Button(action: { selectedProfileIdx = pIdx }) {
                                    Text(prof.title)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isSelected ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.cyan : Color(red: 0.1, green: 0.14, blue: 0.22))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 10)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Accounts List for Selected Game
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if let prof = currentProfile, !prof.accounts.isEmpty {
                            ForEach(prof.accounts.indices, id: \.self) { aIdx in
                                let acc = prof.accounts[aIdx]
                                let isNextInQueue = aIdx == (prof.currentQueueIndex ?? 0)
                                
                                Button(action: {
                                    onSelect(acc, selectedProfileIdx)
                                }) {
                                    HStack(spacing: 12) {
                                        // Status Icon
                                        ZStack {
                                            Circle()
                                                .fill(isNextInQueue ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: isNextInQueue ? "arrow.right.circle.fill" : "person.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(isNextInQueue ? .green : .cyan)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(acc.username)
                                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.white)
                                                
                                                if isNextInQueue {
                                                    Text("Kế tiếp")
                                                        .font(.system(size: 8, weight: .bold))
                                                        .foregroundColor(.green)
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 1)
                                                        .background(Color.green.opacity(0.15))
                                                        .cornerRadius(4)
                                                }
                                            }
                                            
                                            Text("Pass: •••••••• • \(acc.server ?? prof.server ?? "Server")")
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("Điền ➔")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.cyan)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.cyan.opacity(0.15))
                                            .cornerRadius(8)
                                    }
                                    .padding(10)
                                    .background(Color(red: 0.08, green: 0.11, blue: 0.18))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isNextInQueue ? Color.green.opacity(0.6) : Color.white.opacity(0.06), lineWidth: isNextInQueue ? 1.5 : 1)
                                    )
                                }
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                    .padding(.top, 30)
                                Text("Chưa có tài khoản cho game này")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}
