import UIKit
import SwiftUI

// MARK: - Keyboard Root View Controller
class KeyboardViewController: UIInputViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostingController = UIHostingController(
            rootView: GameKeyboardView(
                onInsertText: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                },
                onDelete: { [weak self] in
                    self?.textDocumentProxy.deleteBackward()
                },
                onNextKeyboard: { [weak self] in
                    self?.advanceToNextInputMode()
                },
                onDismiss: { [weak self] in
                    self?.dismissKeyboard()
                }
            )
        )
        
        hostingController.view.backgroundColor = UIColor(red: 16/255, green: 20/255, blue: 28/255, alpha: 1.0)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let heightConstraint = hostingController.view.heightAnchor.constraint(equalToConstant: 240)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true
        
        hostingController.didMove(toParent: self)
    }
}

// MARK: - Data Models
struct KeyboardAccount: Identifiable, Codable {
    var id: String = UUID().uuidString
    var username: String
    var password: String
    var server: String = "Asia"
    var status: String = "Chờ đăng nhập"
}

struct KeyboardPayload: Codable {
    var gameTitle: String
    var currentUsername: String
    var currentPassword: String
    var accounts: [KeyboardAccount]
}

// MARK: - SwiftUI Game Keyboard View
struct GameKeyboardView: View {
    var onInsertText: (String) -> Void
    var onDelete: () -> Void
    var onNextKeyboard: () -> Void
    var onDismiss: () -> Void
    
    @State private var gameTitle: String = "Liên quân"
    @State private var accounts: [KeyboardAccount] = []
    @State private var currentIndex: Int = 0
    @State private var toastMessage: String? = nil
    
    var currentAccount: KeyboardAccount? {
        guard !accounts.isEmpty, currentIndex < accounts.count else { return nil }
        return accounts[currentIndex]
    }
    
    var body: some View {
        VStack(spacing: 8) {
            
            // Top Bar
            HStack {
                Button(action: onNextKeyboard) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 14))
                        Text("Đổi phím")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("🎮 \(gameTitle.uppercased())")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.cyan.opacity(0.15))
                .cornerRadius(12)
                
                Spacer()
                
                // Backspace Key
                Button(action: onDelete) {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 38, height: 30)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                }
                
                // Dismiss Key
                Button(action: onDismiss) {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 32, height: 30)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            
            // Active Account Card
            if let acc = currentAccount {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("👤 Nick #\(currentIndex + 1):")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                            Text(acc.username)
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        HStack(spacing: 6) {
                            Text("🔑 Pass:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                            Text(String(repeating: "•", count: max(acc.password.count, 6)))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Spacer()
                    
                    if accounts.count > 1 {
                        Button(action: nextAccount) {
                            HStack(spacing: 3) {
                                Text("Acc kế")
                                    .font(.system(size: 11, weight: .bold))
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 25/255, green: 32/255, blue: 44/255))
                .cornerRadius(10)
                .padding(.horizontal, 10)
            } else {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.cyan)
                    Text("Mở GameAccountApp bấm Login để nạp danh sách nick!")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal, 10)
            }
            
            // Primary Action Buttons (Big & Touch-Friendly)
            HStack(spacing: 8) {
                // Button Điền Tên Đăng Nhập
                Button(action: {
                    if let acc = currentAccount {
                        onInsertText(acc.username)
                        showToast("Đã điền tài khoản!")
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Điền Tài Khoản")
                            .font(.system(size: 13, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(colors: [Color.green.opacity(0.85), Color(red: 20/255, green: 140/255, blue: 70/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color.green.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                
                // Button Điền Mật Khẩu
                Button(action: {
                    if let acc = currentAccount {
                        onInsertText(acc.password)
                        showToast("Đã điền mật khẩu!")
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Điền Mật Khẩu")
                            .font(.system(size: 13, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(colors: [Color.cyan.opacity(0.85), Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 10)
            
            // Bottom Utility Row (Quick Navigation)
            HStack(spacing: 6) {
                // Enter / Return Key
                Button(action: { onInsertText("\n") }) {
                    HStack(spacing: 4) {
                        Image(systemName: "return")
                        Text("Enter")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(8)
                }
                
                // Tab Key (switch to next field)
                Button(action: { onInsertText("\t") }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.to.line")
                        Text("Tab")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(8)
                }
                
                // Space Key
                Button(action: { onInsertText(" ") }) {
                    Text("Dấu cách")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                }
                
                // Refresh Data Button
                Button(action: loadData) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                        .frame(width: 38, height: 32)
                        .background(Color.cyan.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 10)
            
            // Toast Notification
            if let toast = toastMessage {
                Text(toast)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.vertical, 2)
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    private func nextAccount() {
        guard !accounts.isEmpty else { return }
        currentIndex = (currentIndex + 1) % accounts.count
        showToast("Đã chọn Nick #\(currentIndex + 1)")
    }
    
    private func showToast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if toastMessage == msg {
                toastMessage = nil
            }
        }
    }
    
    private func loadData() {
        // 1. Check Shared App Group UserDefaults
        let appGroupSuite = "group.com.ban.GameAccountApp"
        let userDefaults = UserDefaults(suiteName: appGroupSuite) ?? UserDefaults.standard
        
        if let data = userDefaults.data(forKey: "SavedGameProfiles") {
            // Parse profiles
            if let rawJson = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                let activeId = userDefaults.string(forKey: "ActiveGameProfileId")
                for dict in rawJson {
                    let id = dict["id"] as? String ?? ""
                    let title = dict["title"] as? String ?? "Liên quân"
                    if activeId == nil || activeId == id || activeId == "" {
                        self.gameTitle = title
                        if let accsRaw = dict["accounts"] as? [[String: Any]] {
                            var parsed: [KeyboardAccount] = []
                            for a in accsRaw {
                                let u = a["username"] as? String ?? ""
                                let p = a["password"] as? String ?? ""
                                let s = a["server"] as? String ?? "Asia"
                                if !u.isEmpty {
                                    parsed.append(KeyboardAccount(username: u, password: p, server: s))
                                }
                            }
                            if !parsed.isEmpty {
                                self.accounts = parsed
                                self.currentIndex = dict["currentQueueIndex"] as? Int ?? 0
                                if self.currentIndex >= self.accounts.count { self.currentIndex = 0 }
                                return
                            }
                        }
                    }
                }
            }
        }
        
        // 2. Check Clipboard Fallback (UIPasteboard)
        if let clip = UIPasteboard.general.string, !clip.isEmpty {
            if clip.hasPrefix("GAMEACC::") {
                let jsonStr = String(clip.dropFirst("GAMEACC::".count))
                if let jsonData = jsonStr.data(using: .utf8),
                   let payload = try? JSONDecoder().decode(KeyboardPayload.self, from: jsonData) {
                    self.gameTitle = payload.gameTitle
                    self.accounts = payload.accounts
                    if let foundIdx = payload.accounts.firstIndex(where: { $0.username == payload.currentUsername }) {
                        self.currentIndex = foundIdx
                    }
                    return
                }
            } else if clip.contains("\t") {
                let parts = clip.components(separatedBy: "\t")
                if parts.count >= 2 {
                    let u = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let p = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    self.accounts = [KeyboardAccount(username: u, password: p)]
                    self.currentIndex = 0
                    return
                }
            }
        }
        
        // 3. Fallback sample accounts if empty
        if self.accounts.isEmpty {
            self.accounts = [
                KeyboardAccount(username: "lienquan_pro", password: "Password123")
            ]
        }
    }
}
