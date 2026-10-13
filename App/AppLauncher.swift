import UIKit

public class AppLauncher {
    public static let shared = AppLauncher()
    
    /// Tự động mở Game qua Bundle ID hoặc URL Scheme hoặc Apple Shortcuts
    public func launchGame(scheme: String?, bundleID: String?, gameName: String, completion: @escaping (Bool, String) -> Void) {
        
        // 1. Thử mở bằng Bundle ID qua LSApplicationWorkspace (Objective-C Runtime)
        if let bid = bundleID?.trimmingCharacters(in: .whitespacesAndNewlines), !bid.isEmpty {
            if openViaBundleID(bid) {
                completion(true, "Đang mở \(gameName) qua Bundle ID...")
                return
            }
        }
        
        // 2. Thử mở bằng URL Scheme trực tiếp
        if let s = scheme?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            let cleanScheme = s.hasSuffix("://") ? s : (s.contains("://") ? s : "\(s)://")
            if let url = URL(string: cleanScheme) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        completion(true, "Đang mở \(gameName)...")
                    } else {
                        // Thử giải pháp 3: Mở qua Apple Shortcuts nếu có
                        self.tryShortcutsFallback(gameName: gameName, completion: completion)
                    }
                }
                return
            }
        }
        
        // 3. Fallback: Mở qua Apple Shortcuts
        tryShortcutsFallback(gameName: gameName, completion: completion)
    }
    
    private func openViaBundleID(_ bundleID: String) -> Bool {
        guard let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type else {
            return false
        }
        let defaultSelector = Selector(("defaultWorkspace"))
        guard workspaceClass.responds(to: defaultSelector),
              let workspace = workspaceClass.perform(defaultSelector)?.takeUnretainedValue() else {
            return false
        }
        let openSelector = Selector(("openApplicationWithBundleID:"))
        if workspace.responds(to: openSelector) {
            let result = workspace.perform(openSelector, with: bundleID)
            return result != nil
        }
        return false
    }
    
    private func tryShortcutsFallback(gameName: String, completion: @escaping (Bool, String) -> Void) {
        // Thử mở phím tắt trùng tên game nếu người dùng đã tạo trong Shortcuts
        let encodedName = gameName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let shortcutUrl = URL(string: "shortcuts://run-shortcut?name=\(encodedName)") {
            UIApplication.shared.open(shortcutUrl, options: [:]) { opened in
                if opened {
                    completion(true, "Đang mở \(gameName) qua Phím tắt iOS...")
                } else {
                    completion(false, "Không mở được trực tiếp. Đã nạp tài khoản, hãy vuốt sang \(gameName) để AutoFill!")
                }
            }
        } else {
            completion(false, "Đã nạp tài khoản vào hàng đợi. Hãy mở \(gameName) để AutoFill!")
        }
    }
}
