import Foundation

// MARK: - Models

public struct PresetGame: Identifiable {
    public var id = UUID()
    public var name: String
    public var scheme: String
    public var bundleID: String
    public var icon: String
    
    public init(name: String, scheme: String, bundleID: String, icon: String) {
        self.name = name
        self.scheme = scheme
        self.bundleID = bundleID
        self.icon = icon
    }
}

public let PRESET_GAMES: [PresetGame] = [
    PresetGame(name: "Liên Quân Mobile", scheme: "garena-kgvn://", bundleID: "com.garena.game.kgvn", icon: "shield.lefthalf.filled"),
    PresetGame(name: "Võ Lâm Truyền Kỳ", scheme: "vng-vltk://", bundleID: "com.vng.vltk", icon: "flame.fill"),
    PresetGame(name: "Tốc Chiến (Wild Rift)", scheme: "riotgames://", bundleID: "com.riotgames.league.wildriftvn", icon: "bolt.fill"),
    PresetGame(name: "Free Fire", scheme: "freefireth://", bundleID: "com.dts.freefireth", icon: "cross.fill"),
    PresetGame(name: "PUBG Mobile", scheme: "igmobile://", bundleID: "com.vng.pubgmobile", icon: "scope"),
    PresetGame(name: "Roblox", scheme: "roblox://", bundleID: "com.roblox.robloxmobile", icon: "cube.fill"),
    PresetGame(name: "Genshin Impact", scheme: "genshinimpact://", bundleID: "com.miHoYo.GenshinImpact", icon: "sparkles")
]

public struct LoginLog: Identifiable, Codable {
    public var id = UUID()
    public var timestamp = Date()
    public var username: String
    public var status: String // "Thành công", "Sai mật khẩu", "Lỗi/Khóa"
    public var detail: String
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), username: String, status: String, detail: String) {
        self.id = id
        self.timestamp = timestamp
        self.username = username
        self.status = status
        self.detail = detail
    }
}

public struct GameAccount: Identifiable, Codable {
    public var id = UUID()
    public var username: String
    public var password: String
    public var server: String
    public var levelOrRank: String
    public var status: String // "Chờ đăng nhập", "Thành công", "Sai mật khẩu", "Lỗi/Khóa"
    public var lastLogin: Date?
    
    public init(id: UUID = UUID(), username: String, password: String, server: String = "Asia", levelOrRank: String = "Lv. 1", status: String = "Chờ đăng nhập", lastLogin: Date? = nil) {
        self.id = id
        self.username = username
        self.password = password
        self.server = server
        self.levelOrRank = levelOrRank
        self.status = status
        self.lastLogin = lastLogin
    }
}

public struct GameProfile: Identifiable, Codable {
    public var id = UUID()
    public var title: String
    public var server: String
    public var icon: String
    public var urlScheme: String? // URL Scheme (vd: garena-kgvn://)
    public var bundleID: String?  // Bundle ID (vd: com.garena.game.kgvn)
    public var customImageData: Data?
    public var accounts: [GameAccount]
    public var currentQueueIndex: Int
    public var logs: [LoginLog]
    
    public init(id: UUID = UUID(), title: String, server: String = "Asia", icon: String = "gamecontroller.fill", urlScheme: String? = nil, bundleID: String? = nil, customImageData: Data? = nil, accounts: [GameAccount] = [], currentQueueIndex: Int = 0, logs: [LoginLog] = []) {
        self.id = id
        self.title = title
        self.server = server
        self.icon = icon
        self.urlScheme = urlScheme
        self.bundleID = bundleID
        self.customImageData = customImageData
        self.accounts = accounts
        self.currentQueueIndex = currentQueueIndex
        self.logs = logs
    }
    
    // Quick Statistics
    public var totalAccounts: Int { accounts.count }
    public var successCount: Int { accounts.filter { $0.status == "Thành công" }.count }
    public var wrongPassCount: Int { accounts.filter { $0.status == "Sai mật khẩu" }.count }
    public var failedCount: Int { accounts.filter { $0.status == "Lỗi/Khóa" || $0.status == "Lỗi" }.count }
    public var pendingCount: Int { accounts.filter { $0.status == "Chờ đăng nhập" }.count }
}

// MARK: - Shared Data Manager
public class SharedDataManager {
    public static let shared = SharedDataManager()
    
    private let appGroupSuite = "group.com.ban.GameAccountApp"
    private let gamesKey = "SavedGameProfiles"
    private let activeGameIdKey = "ActiveGameProfileId"
    
    public var storage: UserDefaults {
        if let groupDefaults = UserDefaults(suiteName: appGroupSuite) {
            return groupDefaults
        }
        return UserDefaults.standard
    }
    
    public func saveGames(_ games: [GameProfile]) {
        if let encoded = try? JSONEncoder().encode(games) {
            storage.set(encoded, forKey: gamesKey)
        }
    }
    
    public func loadGames() -> [GameProfile] {
        if let data = storage.data(forKey: gamesKey),
           let decoded = try? JSONDecoder().decode([GameProfile].self, from: data),
           !decoded.isEmpty {
            return decoded
        }
        // Initial sample games with real bundleIDs and schemes
        let initialGames = [
            GameProfile(
                title: "Liên Quân Mobile",
                server: "Việt Nam",
                icon: "shield.lefthalf.filled",
                urlScheme: "garena-kgvn://",
                bundleID: "com.garena.game.kgvn",
                accounts: [
                    GameAccount(username: "AthanorPro", password: "LienQuan#2026", server: "VN", levelOrRank: "Cao Thủ", status: "Chờ đăng nhập"),
                    GameAccount(username: "Valhein69", password: "XaThuGank#1", server: "VN", levelOrRank: "Tinh Anh", status: "Chờ đăng nhập")
                ]
            ),
            GameProfile(
                title: "Võ Lâm Truyền Kỳ",
                server: "Biện Kinh",
                icon: "flame.fill",
                urlScheme: "vng-vltk://",
                bundleID: "com.vng.vltk",
                accounts: [
                    GameAccount(username: "VoLamBangChu", password: "ThienHaVoSong#1", server: "S1", levelOrRank: "Lv. 89", status: "Chờ đăng nhập")
                ]
            ),
            GameProfile(
                title: "Cyber Warriors",
                server: "Asia",
                icon: "bolt.shield.fill",
                urlScheme: nil,
                bundleID: nil,
                accounts: [
                    GameAccount(username: "ShadowBlade", password: "Pass12345@", server: "Asia", levelOrRank: "Lv. 82", status: "Chờ đăng nhập"),
                    GameAccount(username: "CyberNinja99", password: "NinjaSecure#9", server: "Asia", levelOrRank: "Lv. 75", status: "Chờ đăng nhập")
                ]
            )
        ]
        saveGames(initialGames)
        return initialGames
    }
    
    public func saveActiveGameId(_ id: UUID) {
        storage.set(id.uuidString, forKey: activeGameIdKey)
    }
    
    public func loadActiveGameId() -> UUID? {
        if let str = storage.string(forKey: activeGameIdKey), let uuid = UUID(uuidString: str) {
            return uuid
        }
        return nil
    }
}
