import UIKit

public class AppLauncher {
    public static let shared = AppLauncher()
    
    /// Tự động mở Game qua Bundle ID, danh sách URL Scheme hoặc Apple Shortcuts
    public func launchGame(scheme: String?, bundleID: String?, gameName: String, completion: @escaping (Bool, String) -> Void) {
        
        // 1. Thử mở bằng Bundle ID qua LSApplicationWorkspace (Objective-C Runtime)
        if let bid = bundleID?.trimmingCharacters(in: .whitespacesAndNewlines), !bid.isEmpty {
            if openViaBundleID(bid) {
                completion(true, "Đang mở \(gameName)...")
                return
            }
        }
        
        // 2. Thu thập danh sách URL Schemes tiềm năng
        var schemesToTry: [String] = []
        if let s = scheme?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            schemesToTry.append(s)
        }
        
        let lower = gameName.lowercased()
        if lower.contains("liên quân") || lower.contains("lien quan") {
            schemesToTry.append(contentsOf: ["kgvn://", "garena-kgvn://", "com.garena.game.kgvn://", "garena://"])
        } else if lower.contains("võ lâm") || lower.contains("vo lam") {
            schemesToTry.append(contentsOf: ["vng-vltk://", "vltk://"])
        } else if lower.contains("free fire") {
            schemesToTry.append(contentsOf: ["freefireth://", "freefire://"])
        }
        
        trySchemes(schemesToTry, index: 0, gameName: gameName) { success, msg in
            if success {
                completion(true, msg)
            } else {
                // 3. Fallback: Mở qua Apple Shortcuts với các biến thể tên
                self.tryShortcutsFallback(gameName: gameName, completion: completion)
            }
        }
    }
    
    private func trySchemes(_ schemes: [String], index: Int, gameName: String, completion: @escaping (Bool, String) -> Void) {
        guard index < schemes.count else {
            completion(false, "Không mở được bằng URL Scheme.")
            return
        }
        
        let raw = schemes[index].trimmingCharacters(in: .whitespacesAndNewlines)
        let clean = raw.hasSuffix("://") ? raw : (raw.contains("://") ? raw : "\(raw)://")
        
        guard let url = URL(string: clean) else {
            trySchemes(schemes, index: index + 1, gameName: gameName, completion: completion)
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                completion(true, "Đang mở \(gameName)...")
            } else {
                self.trySchemes(schemes, index: index + 1, gameName: gameName, completion: completion)
            }
        }
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
        var names: [String] = [gameName]
        let lower = gameName.lowercased()
        if lower.contains("liên quân") || lower.contains("lien quan") {
            names.append(contentsOf: ["Liên quân", "Liên Quân", "Liên Quân Mobile", "Lien Quan", "lienquan"])
        } else if lower.contains("võ lâm") || lower.contains("vo lam") {
            names.append(contentsOf: ["Võ Lâm", "Võ Lâm Truyền Kỳ", "Vo Lam"])
        }
        
        tryShortcutNames(names, index: 0, gameName: gameName, completion: completion)
    }
    
    private func tryShortcutNames(_ names: [String], index: Int, gameName: String, completion: @escaping (Bool, String) -> Void) {
        guard index < names.count else {
            completion(false, "Đã nạp tài khoản! Hãy mở game và bấm Quả địa cầu 🌐 trên bàn phím để điền.")
            return
        }
        
        let targetName = names[index]
        let encoded = targetName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let shortcutUrl = URL(string: "shortcuts://run-shortcut?name=\(encoded)") {
            UIApplication.shared.open(shortcutUrl, options: [:]) { success in
                if success {
                    completion(true, "Đang mở \(gameName) qua Phím tắt '\(targetName)'...")
                } else {
                    self.tryShortcutNames(names, index: index + 1, gameName: gameName, completion: completion)
                }
            }
        } else {
            tryShortcutNames(names, index: index + 1, gameName: gameName, completion: completion)
        }
    }
}
