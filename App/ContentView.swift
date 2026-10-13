import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var games: [GameProfile] = []
    @State private var selectedGameIndex: Int = 0
    
    // Sheets & Dialogs
    @State private var showingAddGame = false
    @State private var showingEditGame = false
    @State private var showingAddAccount = false
    @State private var showingImportSheet = false
    @State private var showingExportSheet = false
    @State private var showingLogsSheet = false
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var showingAutoFillGuide = false
    
    // Temporary variables for Game Creation / Edit
    @State private var tempGameTitle = ""
    @State private var tempGameServer = "Asia"
    @State private var tempGameScheme = ""
    @State private var tempGameBundleID = ""
    @State private var tempSelectedImage: UIImage? = nil
    
    // Temporary variables for Account Creation
    @State private var tempAccUser = ""
    @State private var tempAccPass = ""
    @State private var tempAccServer = "Asia"
    @State private var tempAccRank = "Lv. 1"
    // Edit Account states
    @State private var showingEditAccount = false
    @State private var editingAccountID: UUID? = nil
    @State private var editAccUser = ""
    @State private var editAccPass = ""
    @State private var editAccServer = ""
    @State private var editAccRank = ""
    @State private var editAccStatus = "Chờ đăng nhập"
    
    // Import / Export states
    @State private var importPasteText = ""
    @State private var exportModeSuccessOnly = true
    @State private var exportModeRemoveFailed = true
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false
    
    // Toast notification
    @State private var toastMessage: String? = nil
    @State private var searchText: String = ""
    
    // Copy Separator preference: "space" (1 khoảng trắng) hoặc "pipe" (dấu |)
    @AppStorage("copyFormat") private var copyFormat: String = "space"
    
    func getFormattedCredentials(acc: GameAccount) -> String {
        if copyFormat == "pipe" {
            return "\(acc.username)|\(acc.password)"
        } else {
            return "\(acc.username) \(acc.password)"
        }
    }
    
    // Active Game helper
    var currentGame: GameProfile? {
        guard !games.isEmpty && selectedGameIndex >= 0 && selectedGameIndex < games.count else { return nil }
        return games[selectedGameIndex]
    }
    
    // Filtered accounts based on search
    var filteredAccounts: [GameAccount] {
        guard let game = currentGame else { return [] }
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return game.accounts
        }
        return game.accounts.filter {
            $0.username.localizedCaseInsensitiveContains(searchText) ||
            $0.server.localizedCaseInsensitiveContains(searchText) ||
            $0.levelOrRank.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            // Dark Tactical Carbon background
            Color(red: 0.04, green: 0.06, blue: 0.05).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                // Top Header Bar
                topHeaderView
                    .padding(.horizontal)
                    .padding(.top, 6)
                
                // Horizontal Game Tabs (Chips)
                gameCarouselView
                
                // Search & Action Toolbar
                searchAndActionToolbar
                    .padding(.horizontal)
                
                // Copy Separator Preference Bar
                copyFormatSelectorBar
                    .padding(.horizontal)
                
                // Account Cards List
                accountListView
            }
            
            // Toast banner
            if let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.6), lineWidth: 1))
                        .cornerRadius(20)
                        .shadow(color: Color.cyan.opacity(0.3), radius: 10, x: 0, y: 4)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(), value: toastMessage)
            }
        }
        .onAppear {
            loadInitialData()
        }
        .sheet(isPresented: $showingAddGame) { addGameSheetView }
        .sheet(isPresented: $showingEditGame) { editGameSheetView }
        .sheet(isPresented: $showingAddAccount) { addAccountSheetView }
        .sheet(isPresented: $showingEditAccount) { editAccountSheetView }
        .sheet(isPresented: $showingImportSheet) { importSheetView }
        .sheet(isPresented: $showingExportSheet) { exportSheetView }
        .sheet(isPresented: $showingLogsSheet) { logsSheetView }
        .sheet(isPresented: $showingShareSheet) { ShareSheet(items: shareItems) }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(
                onPick: { content in
                    importPasteText = content
                    parseAndImportPasteText()
                },
                onError: { errMsg in
                    showToast(errMsg)
                }
            )
        }
        .sheet(isPresented: $showingAutoFillGuide) { autoFillGuideSheetView }
    }
    
    // MARK: - Top Header View (Clean & Professional)
    var topHeaderView: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                ZStack {
                    LinearGradient(colors: [Color(red: 0.0, green: 0.85, blue: 0.55), Color(red: 0.0, green: 0.5, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text("🎮").font(.system(size: 15))
                }
                .frame(width: 32, height: 32)
                .cornerRadius(9)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("QUẢN LÝ TÀI KHOẢN")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("Game Account Suite")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.55))
                }
            }
            
            Spacer()
            
            // Nút Liên Hệ Zalo - CHỈ 1 NÚT DUY NHẤT, KHÔNG WRAP CHỮ
            Button(action: {
                if let url = URL(string: "https://zalo.me/0779977792") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "message.fill")
                    Text("Liên Hệ Zalo")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 0.65))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 0.0, green: 0.8, blue: 0.5).opacity(0.18))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.0, green: 0.85, blue: 0.55).opacity(0.4), lineWidth: 1))
                .fixedSize()
            }
        }
    }
    
    // MARK: - Game Tabs (Clean Horizontal Chips)
    var gameCarouselView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(games.indices, id: \.self) { idx in
                    let g = games[idx]
                    let isSelected = idx == selectedGameIndex
                    
                    Button(action: {
                        selectedGameIndex = idx
                        SharedDataManager.shared.saveActiveGameId(g.id)
                    }) {
                        HStack(spacing: 5) {
                            Text(g.title.lowercased().contains("liên quân") ? "⚔️" : (g.title.lowercased().contains("free fire") ? "🔥" : "🎮"))
                                .font(.system(size: 12))
                            Text(g.title)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                .lineLimit(1)
                            Text("(\(g.accounts.count))")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .opacity(0.85)
                        }
                        .foregroundColor(isSelected ? .white : .gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color(red: 0.0, green: 0.75, blue: 0.45) : Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color(red: 0.0, green: 0.9, blue: 0.6) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .fixedSize()
                    }
                    .contextMenu {
                        Button(action: { openEditGameModal(game: g) }) {
                            Label("Sửa thông tin / Đổi tên", systemImage: "pencil")
                        }
                        Button(action: {
                            AppLauncher.shared.launchGame(scheme: g.urlScheme, bundleID: g.bundleID, gameName: g.title) { _, msg in
                                showToast(msg)
                            }
                        }) {
                            Label("Mở Game Trực Tiếp", systemImage: "arrow.up.forward.app")
                        }
                    }
                }
                
                // Nút Thêm Game Mới
                Button(action: { openAddGameModal() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Game Mới")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .fixedSize()
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Search & Action Toolbar (Clean Unified Row)
    var searchAndActionToolbar: some View {
        HStack(spacing: 8) {
            // Search Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.caption)
                TextField("Tìm tài khoản...", text: $searchText)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
            
            // Nhập TXT Button
            Button(action: { showingImportSheet = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Nhập TXT")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(red: 0.0, green: 0.85, blue: 0.55))
                .cornerRadius(10)
                .fixedSize()
            }
            
            // + Thêm Nick Button
            Button(action: { openAddAccountModal() }) {
                HStack(spacing: 3) {
                    Image(systemName: "plus")
                    Text("Nick")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1))
                .fixedSize()
            }
            
            // Menu ... (Mở game, Xuất File, Nhật ký, AutoFill)
            Menu {
                if let g = currentGame {
                    Button(action: {
                        AppLauncher.shared.launchGame(scheme: g.urlScheme, bundleID: g.bundleID, gameName: g.title) { _, msg in
                            showToast(msg)
                        }
                    }) {
                        Label("Mở Game: \(g.title)", systemImage: "arrow.up.forward.app")
                    }
                    
                    Button(action: { openEditGameModal(game: g) }) {
                        Label("Sửa Cấu Hình Game", systemImage: "pencil")
                    }
                }
                
                Button(action: { showingExportSheet = true }) {
                    Label("Xuất File / Apple Passwords", systemImage: "square.and.arrow.up")
                }
                
                Button(action: { showingLogsSheet = true }) {
                    Label("Nhật Ký Đăng Nhập", systemImage: "clock")
                }
                
                Button(action: { showingAutoFillGuide = true }) {
                    Label("Hướng Dẫn Bàn Phím", systemImage: "key.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Copy Format Selector Bar (Tactical E-Sports)
    var copyFormatSelectorBar: some View {
        HStack(spacing: 8) {
            Text("Định dạng dán:")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            
            Button(action: {
                copyFormat = "space"
                showToast("Đã chọn: ID Pass (1 khoảng trắng)")
            }) {
                HStack(spacing: 3) {
                    Image(systemName: copyFormat == "space" ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 9))
                    Text("1 Khoảng trắng")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(copyFormat == "space" ? Color(red: 0.0, green: 0.9, blue: 0.6) : .gray)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(copyFormat == "space" ? Color(red: 0.0, green: 0.8, blue: 0.5).opacity(0.18) : Color.white.opacity(0.04))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(copyFormat == "space" ? Color(red: 0.0, green: 0.85, blue: 0.55).opacity(0.4) : Color.clear, lineWidth: 1))
            }
            
            Button(action: {
                copyFormat = "pipe"
                showToast("Đã chọn: ID|Pass (Dấu gạch đứng)")
            }) {
                HStack(spacing: 3) {
                    Image(systemName: copyFormat == "pipe" ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 9))
                    Text("Dấu gạch |")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(copyFormat == "pipe" ? .cyan : .gray)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(copyFormat == "pipe" ? Color.cyan.opacity(0.18) : Color.white.opacity(0.04))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(copyFormat == "pipe" ? Color.cyan.opacity(0.4) : Color.clear, lineWidth: 1))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Account Cards List
    var accountListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filteredAccounts.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 40)
                        Text("Chưa có tài khoản nào trong game này")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                        Button("Nhấn vào đây để thêm tài khoản") {
                            openAddAccountModal()
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                    }
                } else {
                    ForEach(filteredAccounts.indices, id: \.self) { accIdx in
                        let acc = filteredAccounts[accIdx]
                        let isCurrentQueue = isAccountCurrentInQueue(acc)
                        
                        accountCard(acc: acc, index: accIdx + 1, isCurrentInQueue: isCurrentQueue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80)
        }
    }
    
    func accountCard(acc: GameAccount, index: Int, isCurrentInQueue: Bool) -> some View {
        VStack(spacing: 9) {
            // Hàng 1: Thứ tự, Tên tài khoản, Trạng thái, Nút Sửa & Xóa
            HStack(spacing: 6) {
                Text("#\(index)")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.0, green: 0.8, blue: 0.5).opacity(0.18))
                    .cornerRadius(6)
                    .fixedSize()
                
                Text(acc.username)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                statusBadge(status: acc.status, isQueue: isCurrentInQueue)
                    .fixedSize()
                
                Spacer()
                
                Button(action: { openEditAccountModal(acc: acc) }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(6)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(Circle())
                }
                .fixedSize()
                
                Button(action: { deleteAccount(acc) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(6)
                        .background(Color.white.opacity(0.04))
                        .clipShape(Circle())
                }
                .fixedSize()
            }
            
            // Hàng 2: Mật khẩu (chạm để chép), Server & Rank
            HStack {
                HStack(spacing: 4) {
                    Text("MK:")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text("•••••••••••")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .tracking(1)
                    Text("(chép pass)")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.55).opacity(0.8))
                }
                .onTapGesture {
                    UIPasteboard.general.string = acc.password
                    showToast("Đã chép pass: \(acc.password)")
                }
                
                Spacer()
                
                if !acc.levelOrRank.isEmpty && acc.levelOrRank != "Lv. 1" {
                    Text(acc.levelOrRank)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.3))
                        .lineLimit(1)
                }
                
                Text(acc.server)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Divider().background(Color.white.opacity(0.06))
            
            // Hàng 3: 2 Nút bấm to bản rộng rãi, không bao giờ bị rớt dòng
            HStack(spacing: 8) {
                // Nút Copy ID Pass (định dạng theo cài đặt: 1 space hoặc |)
                Button(action: {
                    let formatted = getFormattedCredentials(acc: acc)
                    UIPasteboard.general.string = formatted
                    showToast("Đã copy: \(formatted)")
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy ID Pass")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.9, blue: 0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.0, green: 0.8, blue: 0.5).opacity(0.15))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.0, green: 0.85, blue: 0.55).opacity(0.35), lineWidth: 1))
                }
                
                // Nút Đăng Nhập trực tiếp
                Button(action: {
                    if let g = currentGame { triggerLogin(acc: acc, game: g) }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("Đăng Nhập")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.0, green: 0.88, blue: 0.55))
                    .cornerRadius(8)
                    .shadow(color: Color(red: 0.0, green: 0.88, blue: 0.55).opacity(0.3), radius: 4, x: 0, y: 1)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.06, green: 0.09, blue: 0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCurrentInQueue ? Color(red: 0.0, green: 0.9, blue: 0.55) : Color.white.opacity(0.06), lineWidth: isCurrentInQueue ? 1.5 : 1)
        )
        .shadow(color: isCurrentInQueue ? Color(red: 0.0, green: 0.9, blue: 0.55).opacity(0.25) : Color.clear, radius: 8, x: 0, y: 2)
        .onTapGesture(count: 2) { openEditAccountModal(acc: acc) }
    }
    
    func statusBadge(status: String, isQueue: Bool) -> some View {
        let text: String
        let color: Color
        if isQueue {
            text = "Đang chọn"
            color = .cyan
        } else {
            text = status
            switch status {
            case "Thành công": color = .green
            case "Sai mật khẩu": color = .orange
            case "Lỗi/Khóa": color = .red
            default: color = .gray
            }
        }
        
        return Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.3), lineWidth: 0.8))
            .fixedSize()
    }
    
    // MARK: - Logic Methods
    func loadInitialData() {
        games = SharedDataManager.shared.loadGames()
        if let savedId = SharedDataManager.shared.loadActiveGameId(),
           let idx = games.firstIndex(where: { $0.id == savedId }) {
            selectedGameIndex = idx
        } else {
            selectedGameIndex = 0
        }
    }
    
    func saveCurrentState() {
        SharedDataManager.shared.saveGames(games)
    }
    
    func getActiveQueueAccount(game: GameProfile) -> GameAccount? {
        if game.accounts.isEmpty { return nil }
        if game.currentQueueIndex >= 0 && game.currentQueueIndex < game.accounts.count {
            return game.accounts[game.currentQueueIndex]
        }
        return game.accounts.first(where: { $0.status == "Chờ đăng nhập" })
    }
    
    func isAccountCurrentInQueue(_ acc: GameAccount) -> Bool {
        guard let game = currentGame, let active = getActiveQueueAccount(game: game) else { return false }
        return active.id == acc.id
    }
    
    // Auto-launch into game when tapping login!
    func triggerLogin(acc: GameAccount, game: GameProfile) {
        // Set queue index to this account
        if let idx = game.accounts.firstIndex(where: { $0.id == acc.id }) {
            games[selectedGameIndex].currentQueueIndex = idx
            saveCurrentState()
        }
        
        // Copy credentials according to selected format (1 space or |)
        let formatted = getFormattedCredentials(acc: acc)
        UIPasteboard.general.string = formatted
        
        // Open Game directly via AppLauncher (LSApplicationWorkspace, URL Scheme, Shortcuts)
        AppLauncher.shared.launchGame(scheme: game.urlScheme, bundleID: game.bundleID, gameName: game.title) { success, msg in
            showToast("Đã copy: \(formatted)")
        }
    }
    
    func advanceQueue(status: String) {
        guard !games.isEmpty && selectedGameIndex < games.count else { return }
        var game = games[selectedGameIndex]
        
        if let currentAcc = getActiveQueueAccount(game: game),
           let accIdx = game.accounts.firstIndex(where: { $0.id == currentAcc.id }) {
            
            game.accounts[accIdx].status = status
            game.accounts[accIdx].lastLogin = Date()
            
            // Add audit log
            let log = LoginLog(
                username: currentAcc.username,
                status: status,
                detail: "Game: \(game.title) • Server: \(currentAcc.server)"
            )
            game.logs.insert(log, at: 0)
            
            // Find next pending account
            if let nextPending = game.accounts.indices.first(where: { $0 > accIdx && game.accounts[$0].status == "Chờ đăng nhập" }) {
                game.currentQueueIndex = nextPending
            } else if let firstPending = game.accounts.indices.first(where: { game.accounts[$0].status == "Chờ đăng nhập" }) {
                game.currentQueueIndex = firstPending
            } else {
                game.currentQueueIndex = game.accounts.count // All done
            }
            
            games[selectedGameIndex] = game
            saveCurrentState()
            
            // Auto copy next account password if exists
            if let nextAcc = getActiveQueueAccount(game: game) {
                UIPasteboard.general.string = nextAcc.password
                showToast("Đã xong! Tiếp theo: @\(nextAcc.username)")
            } else {
                showToast("Đã duyệt hết hàng đợi của \(game.title)!")
            }
        }
    }
    
    func deleteAccount(_ acc: GameAccount) {
        guard !games.isEmpty && selectedGameIndex < games.count else { return }
        games[selectedGameIndex].accounts.removeAll(where: { $0.id == acc.id })
        saveCurrentState()
        showToast("Đã xóa @\(acc.username)")
    }
    
    func showToast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastMessage == msg { toastMessage = nil }
        }
    }
    
    // MARK: - Modals & Sheets
    func openAddGameModal() {
        tempGameTitle = ""
        tempGameServer = "Asia"
        tempGameScheme = ""
        tempGameBundleID = ""
        tempSelectedImage = nil
        showingAddGame = true
    }
    
    func openEditGameModal(game: GameProfile) {
        tempGameTitle = game.title
        tempGameServer = game.server
        tempGameScheme = game.urlScheme ?? ""
        tempGameBundleID = game.bundleID ?? ""
        if let data = game.customImageData {
            tempSelectedImage = UIImage(data: data)
        } else {
            tempSelectedImage = nil
        }
        showingEditGame = true
    }
    
    func openAddAccountModal() {
        tempAccUser = ""
        tempAccPass = ""
        tempAccServer = currentGame?.server ?? "Asia"
        tempAccRank = "Lv. 1"
        showingAddAccount = true
    }
    
    func openEditAccountModal(acc: GameAccount) {
        editingAccountID = acc.id
        editAccUser = acc.username
        editAccPass = acc.password
        editAccServer = acc.server
        editAccRank = acc.levelOrRank
        editAccStatus = acc.status
        showingEditAccount = true
    }
    
    func saveEditedAccount() {
        guard let id = editingAccountID, selectedGameIndex < games.count else {
            showingEditAccount = false
            return
        }
        if let idx = games[selectedGameIndex].accounts.firstIndex(where: { $0.id == id }) {
            let u = editAccUser.trimmingCharacters(in: .whitespaces)
            let p = editAccPass.trimmingCharacters(in: .whitespaces)
            if !u.isEmpty && !p.isEmpty {
                games[selectedGameIndex].accounts[idx].username = u
                games[selectedGameIndex].accounts[idx].password = p
                games[selectedGameIndex].accounts[idx].server = editAccServer
                games[selectedGameIndex].accounts[idx].levelOrRank = editAccRank
                games[selectedGameIndex].accounts[idx].status = editAccStatus
                saveCurrentState()
                showToast("Đã cập nhật @\(u)")
            }
        }
        showingEditAccount = false
    }
    
    // MARK: - Add / Edit Game Sheets
    var addGameSheetView: some View {
        NavigationView {
            Form {
                Section(header: Text("Chọn Game Phổ Biến (Tự Động Điền Nhận Diện)")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PRESET_GAMES) { pg in
                                Button(action: {
                                    tempGameTitle = pg.name
                                    tempGameScheme = pg.scheme
                                    tempGameBundleID = pg.bundleID
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: pg.icon)
                                        Text(pg.name)
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.cyan.opacity(0.12))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Thông tin Game")) {
                    TextField("Tên game (vd: Liên Quân Mobile)", text: $tempGameTitle)
                    TextField("Server mặc định (vd: Asia, VN)", text: $tempGameServer)
                }
                
                Section(header: Text("Định danh mở game (Bundle ID / URL Scheme)")) {
                    TextField("Bundle ID (vd: com.garena.game.kgvn)", text: $tempGameBundleID)
                    TextField("URL Scheme (vd: garena-kgvn://)", text: $tempGameScheme)
                    
                    Button("Thử mở Game ngay ➔") {
                        AppLauncher.shared.launchGame(scheme: tempGameScheme, bundleID: tempGameBundleID, gameName: tempGameTitle) { success, msg in
                            showToast(msg)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
                
                Section(header: Text("Ảnh đại diện vuông (1:1)")) {
                    if let img = tempSelectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .cornerRadius(16)
                            .clipped()
                    }
                    Button("Chọn ảnh từ thư viện máy") {
                        showingImagePicker = true
                    }
                }
            }
            .navigationTitle("Thêm Tựa Game")
            .navigationBarItems(
                leading: Button("Hủy") { showingAddGame = false },
                trailing: Button("Lưu") {
                    let title = tempGameTitle.trimmingCharacters(in: .whitespaces)
                    if !title.isEmpty {
                        let newGame = GameProfile(
                            title: title,
                            server: tempGameServer,
                            urlScheme: tempGameScheme.isEmpty ? nil : tempGameScheme,
                            bundleID: tempGameBundleID.isEmpty ? nil : tempGameBundleID,
                            customImageData: tempSelectedImage?.jpegData(compressionQuality: 0.7)
                        )
                        games.append(newGame)
                        selectedGameIndex = games.count - 1
                        saveCurrentState()
                        showToast("Đã thêm game: \(title)")
                    }
                    showingAddGame = false
                }
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $tempSelectedImage)
            }
        }
    }
    
    var editGameSheetView: some View {
        NavigationView {
            Form {
                Section(header: Text("Chọn Game Phổ Biến (Tự Động Điền Nhận Diện)")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PRESET_GAMES) { pg in
                                Button(action: {
                                    tempGameTitle = pg.name
                                    tempGameScheme = pg.scheme
                                    tempGameBundleID = pg.bundleID
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: pg.icon)
                                        Text(pg.name)
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.cyan.opacity(0.12))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Sửa thông tin Game")) {
                    TextField("Tên game", text: $tempGameTitle)
                    TextField("Server mặc định", text: $tempGameServer)
                }
                
                Section(header: Text("Định danh mở game (Bundle ID / URL Scheme)")) {
                    TextField("Bundle ID (vd: com.garena.game.kgvn)", text: $tempGameBundleID)
                    TextField("URL Scheme (vd: garena-kgvn://)", text: $tempGameScheme)
                    
                    Button("Thử mở Game ngay ➔") {
                        AppLauncher.shared.launchGame(scheme: tempGameScheme, bundleID: tempGameBundleID, gameName: tempGameTitle) { success, msg in
                            showToast(msg)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
                
                Section(header: Text("Ảnh đại diện vuông (1:1)")) {
                    if let img = tempSelectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .cornerRadius(16)
                            .clipped()
                    }
                    Button("Đổi ảnh từ thư viện máy") {
                        showingImagePicker = true
                    }
                }
                
                Section {
                    Button("Thêm Tài Khoản Vào Game Này") {
                        showingEditGame = false
                        openAddAccountModal()
                    }
                }
                
                Section {
                    Button("Xóa Game này", role: .destructive) {
                        if games.count > 1 {
                            games.remove(at: selectedGameIndex)
                            selectedGameIndex = max(0, selectedGameIndex - 1)
                            saveCurrentState()
                            showingEditGame = false
                            showToast("Đã xóa game")
                        } else {
                            showToast("Phải giữ lại ít nhất 1 game")
                        }
                    }
                }
            }
            .navigationTitle("Sửa Tựa Game")
            .navigationBarItems(
                leading: Button("Hủy") { showingEditGame = false },
                trailing: Button("Lưu") {
                    let title = tempGameTitle.trimmingCharacters(in: .whitespaces)
                    if !title.isEmpty && selectedGameIndex < games.count {
                        games[selectedGameIndex].title = title
                        games[selectedGameIndex].server = tempGameServer
                        games[selectedGameIndex].urlScheme = tempGameScheme.isEmpty ? nil : tempGameScheme
                        games[selectedGameIndex].bundleID = tempGameBundleID.isEmpty ? nil : tempGameBundleID
                        if let img = tempSelectedImage {
                            games[selectedGameIndex].customImageData = img.jpegData(compressionQuality: 0.7)
                        }
                        saveCurrentState()
                        showToast("Đã cập nhật game")
                    }
                    showingEditGame = false
                }
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $tempSelectedImage)
            }
        }
    }
    
    // MARK: - Add Account Sheet
    var addAccountSheetView: some View {
        NavigationView {
            Form {
                Section(header: Text("Tạo tài khoản cho: \(currentGame?.title ?? "")")) {
                    TextField("Username / Tài khoản", text: $tempAccUser)
                    SecureField("Mật khẩu", text: $tempAccPass)
                    TextField("Server", text: $tempAccServer)
                    TextField("Level / Rank / Ghi chú", text: $tempAccRank)
                }
            }
            .navigationTitle("Tạo Tài Khoản")
            .navigationBarItems(
                leading: Button("Hủy") { showingAddAccount = false },
                trailing: Button("Lưu") {
                    let user = tempAccUser.trimmingCharacters(in: .whitespaces)
                    let pass = tempAccPass.trimmingCharacters(in: .whitespaces)
                    if !user.isEmpty && !pass.isEmpty && selectedGameIndex < games.count {
                        let acc = GameAccount(
                            username: user,
                            password: pass,
                            server: tempAccServer,
                            levelOrRank: tempAccRank
                        )
                        games[selectedGameIndex].accounts.append(acc)
                        saveCurrentState()
                        showToast("Đã thêm @\(user)")
                    }
                    showingAddAccount = false
                }
            )
        }
    }
    
    // MARK: - Edit Account Sheet
    var editAccountSheetView: some View {
        NavigationView {
            Form {
                Section(header: Text("Chỉnh sửa tài khoản")) {
                    TextField("Username / Tài khoản", text: $editAccUser)
                    TextField("Mật khẩu", text: $editAccPass)
                    TextField("Server", text: $editAccServer)
                    TextField("Level / Rank / Ghi chú", text: $editAccRank)
                }
                
                Section(header: Text("Trạng thái tài khoản")) {
                    Picker("Trạng thái", selection: $editAccStatus) {
                        Text("Chờ đăng nhập").tag("Chờ đăng nhập")
                        Text("Thành công").tag("Thành công")
                        Text("Sai mật khẩu").tag("Sai mật khẩu")
                        Text("Lỗi/Khóa").tag("Lỗi/Khóa")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(role: .destructive, action: {
                        if let id = editingAccountID, selectedGameIndex < games.count {
                            games[selectedGameIndex].accounts.removeAll(where: { $0.id == id })
                            saveCurrentState()
                            showToast("Đã xóa tài khoản")
                        }
                        showingEditAccount = false
                    }) {
                        HStack {
                            Spacer()
                            Text("Xóa tài khoản này")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Sửa Tài Khoản")
            .navigationBarItems(
                leading: Button("Hủy") { showingEditAccount = false },
                trailing: Button("Lưu") { saveEditedAccount() }
            )
        }
    }
    
    // MARK: - Import Sheet
    var importSheetView: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Nhập vào game: \(currentGame?.title ?? "")")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.55))
                    .padding(.top)
                
                // Button 1: UIDocumentPickerViewController
                Button(action: {
                    showingImportSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingDocumentPicker = true
                    }
                }) {
                    HStack {
                        Image(systemName: "folder.badge.gearshape.fill")
                        Text("Chọn Tệp TXT Từ Files")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [Color(red: 0.0, green: 0.85, blue: 0.55), Color.cyan], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                    .shadow(color: Color(red: 0.0, green: 0.85, blue: 0.55).opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal)
                
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    Text("HOẶC DÁN NỘI DUNG VĂN BẢN").font(.caption).foregroundColor(.gray)
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 6) {
                    TextEditor(text: $importPasteText)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .frame(height: 140)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("⚡ Tự động nhận diện thông minh mọi định dạng TXT:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.55))
                        Text("• Dòng dài chứa UID, NAME, LEVEL, SKIN... (tự lọc lấy ID|Pass)\n• Dạng: user|pass|email (tự bỏ email đuôi)\n• Dạng: user:pass hoặc user,pass hoặc user pass")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                Button(action: { parseAndImportPasteText() }) {
                    Text("Nhận Diện & Nạp Vào Game")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(Color(red: 0.0, green: 0.7, blue: 0.45))
                        .cornerRadius(10)
                        .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 2)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Nhập Tài Khoản")
            .navigationBarItems(trailing: Button("Đóng") { showingImportSheet = false })
        }
    }
    
    // MARK: - Smart Account Parser from TXT
    func parseSmartAccountLine(_ rawLine: String) -> (username: String, password: String, rank: String)? {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.isEmpty { return nil }
        
        // Skip header lines
        if line.lowercased().starts(with: "title,") || line.lowercased().starts(with: "username,") { return nil }
        
        // Trích xuất RANK nếu có trong dòng thông tin (vd: RANK : Đại Cao Thủ IV [10 Sao])
        var extractedRank = "Lv. 1"
        if let rankRange = line.range(of: "(?i)RANK\\s*:\\s*([^|\r\n]+)", options: .regularExpression) {
            let rankSub = String(line[rankRange])
            let rankParts = rankSub.components(separatedBy: ":")
            if rankParts.count >= 2 {
                extractedRank = rankParts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        
        // TRƯỜNG HỢP 1: Phân cách bằng dấu gạch đứng '|'
        if line.contains("|") {
            let segments = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            
            // TH 1A: user|pass| UID : ... hoặc user|pass|email
            if segments.count >= 2 {
                let first = segments[0]
                let second = segments[1]
                let isFirstLabel = first.contains(":") || first.lowercased().starts(with: "uid") || first.lowercased().starts(with: "name")
                let isSecondLabel = second.contains(":") || second.lowercased().starts(with: "uid") || second.lowercased().starts(with: "name")
                
                if !isFirstLabel && !isSecondLabel && !first.isEmpty && !second.isEmpty {
                    return (first, second, extractedRank)
                }
            }
            
            // TH 1B: Nếu có chữ "UID" và user|pass nằm sau hoặc trước UID
            if let uidIndex = segments.firstIndex(where: { $0.lowercased().contains("uid") }) {
                // Nằm sau UID
                if uidIndex + 1 < segments.count {
                    let nextSeg = segments[uidIndex + 1]
                    if nextSeg.contains(":") {
                        let sub = nextSeg.components(separatedBy: ":")
                        if sub.count == 2 {
                            return (sub[0].trimmingCharacters(in: .whitespaces), sub[1].trimmingCharacters(in: .whitespaces), extractedRank)
                        }
                    }
                    if uidIndex + 2 < segments.count {
                        let u = segments[uidIndex + 1]
                        let p = segments[uidIndex + 2]
                        if !u.contains(":") && !p.contains(":") {
                            return (u, p, extractedRank)
                        }
                    }
                }
                // Nằm trước UID
                if uidIndex >= 2 {
                    let u = segments[uidIndex - 2]
                    let p = segments[uidIndex - 1]
                    if !u.contains(":") && !p.contains(":") {
                        return (u, p, extractedRank)
                    }
                }
            }
            
            // TH 1C: Lọc tất cả các segment không chứa nhãn ':'
            let candidateSegs = segments.filter { seg in
                !seg.contains(":") && !seg.contains("@") && !seg.lowercased().contains("cccd") && !seg.lowercased().contains("region")
            }
            if candidateSegs.count >= 2 {
                return (candidateSegs[0], candidateSegs[1], extractedRank)
            }
        }
        
        // TRƯỜNG HỢP 2: Phân cách bằng dấu hai chấm ':' (vd: tvnk.17328:uhuBCTu62@)
        if line.contains(":") && !line.lowercased().starts(with: "http") {
            let parts = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 && !parts[0].isEmpty && !parts[1].isEmpty {
                return (parts[0], parts[1], extractedRank)
            }
        }
        
        // TRƯỜNG HỢP 3: Phân cách bằng dấu phẩy ',' (vd: tvnk.173228,uhuBCTu62@)
        if line.contains(",") {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 && !parts[0].isEmpty && !parts[1].isEmpty {
                return (parts[0], parts[1], extractedRank)
            }
        }
        
        // TRƯỜNG HỢP 4: Phân cách bằng khoảng trắng hoặc Tab (vd: tvnk.17328 uhuBCTu62@)
        let whiteParts = line.components(separatedBy: .whitespaces).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if whiteParts.count == 2 {
            return (whiteParts[0], whiteParts[1], extractedRank)
        }
        
        return nil
    }
    
    func parseAndImportPasteText() {
        let lines = importPasteText.components(separatedBy: .newlines)
        var count = 0
        guard selectedGameIndex < games.count else { return }
        
        for line in lines {
            if let result = parseSmartAccountLine(line) {
                let acc = GameAccount(
                    username: result.username,
                    password: result.password,
                    server: games[selectedGameIndex].server,
                    levelOrRank: result.rank.isEmpty ? "Lv. 1" : result.rank
                )
                games[selectedGameIndex].accounts.append(acc)
                count += 1
            }
        }
        
        saveCurrentState()
        importPasteText = ""
        showingImportSheet = false
        if count > 0 {
            showToast("Đã nạp thành công \(count) tài khoản!")
        } else {
            showToast("Không tìm thấy tài khoản hợp lệ trong nội dung")
        }
    }
    
    // MARK: - Export Sheet
    var exportSheetView: some View {
        NavigationView {
            Form {
                Section(header: Text("Tùy chọn lọc xuất file")) {
                    Toggle("Chỉ xuất tài khoản Thành công", isOn: $exportModeSuccessOnly)
                    Toggle("Loại bỏ tài khoản Sai MK / Lỗi", isOn: $exportModeRemoveFailed)
                }
                
                Section {
                    Button(action: { exportToApplePasswordsCSV() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "key.fill")
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Xuất Sang Mật Khẩu iPhone (AutoFill 1 Chạm)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.yellow)
                                Text("Nạp toàn bộ nick vào nút '🔑 Mật khẩu' của iPhone")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Button("Xuất Thành File TXT Mới (Chia Sẻ)") {
                        exportToNewFile()
                    }
                    
                    Button("Lưu Đè Lên Danh Sách Game Này", role: .destructive) {
                        overwriteCurrentList()
                    }
                }
            }
            .navigationTitle("Lọc & Xuất Tài Khoản")
            .navigationBarItems(trailing: Button("Đóng") { showingExportSheet = false })
        }
    }
    
    func exportToApplePasswordsCSV() {
        guard let game = currentGame else { return }
        var list = game.accounts
        if exportModeRemoveFailed {
            list = list.filter { $0.status != "Sai mật khẩu" && $0.status != "Lỗi/Khóa" }
        }
        
        let header = "Title,URL,Username,Password,Notes\n"
        let domain = game.title.lowercased().contains("liên quân") ? "https://auth.garena.com" : "https://game.login"
        let rows = list.map {
            "\"\(game.title)\",\"\(domain)\",\"\($0.username)\",\"\($0.password)\",\"Server: \($0.server)\""
        }.joined(separator: "\n")
        
        let csvContent = header + rows
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(game.title)_ApplePasswords.csv")
        try? csvContent.write(to: tempUrl, atomically: true, encoding: .utf8)
        
        shareItems = [tempUrl]
        showingExportSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingShareSheet = true
        }
    }
    
    func exportToNewFile() {
        guard let game = currentGame else { return }
        var list = game.accounts
        if exportModeSuccessOnly {
            list = list.filter { $0.status == "Thành công" }
        }
        if exportModeRemoveFailed {
            list = list.filter { $0.status != "Sai mật khẩu" && $0.status != "Lỗi/Khóa" }
        }
        
        let content = list.map { "\($0.username),\($0.password)" }.joined(separator: "\n")
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(game.title)_TaiKhoan.txt")
        try? content.write(to: tempUrl, atomically: true, encoding: .utf8)
        
        shareItems = [tempUrl]
        showingExportSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingShareSheet = true
        }
    }
    
    func overwriteCurrentList() {
        guard selectedGameIndex < games.count else { return }
        var list = games[selectedGameIndex].accounts
        if exportModeSuccessOnly {
            list = list.filter { $0.status == "Thành công" }
        }
        if exportModeRemoveFailed {
            list = list.filter { $0.status != "Sai mật khẩu" && $0.status != "Lỗi/Khóa" }
        }
        games[selectedGameIndex].accounts = list
        saveCurrentState()
        showingExportSheet = false
        showToast("Đã lưu đè: Giữ lại \(list.count) tài khoản sạch!")
    }
    
    // MARK: - Logs Sheet View
    var logsSheetView: some View {
        NavigationView {
            List {
                if let game = currentGame, !game.logs.isEmpty {
                    ForEach(game.logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.username)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                Spacer()
                                Text(log.status)
                                    .font(.caption)
                                    .foregroundColor(log.status == "Thành công" ? .green : (log.status == "Sai mật khẩu" ? .orange : .red))
                            }
                            Text(log.detail)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(log.timestamp, style: .time)
                                .font(.system(size: 9))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .padding(.vertical, 2)
                    }
                } else {
                    Text("Chưa có nhật ký đăng nhập nào cho game này.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Nhật Ký Đăng Nhập")
            .navigationBarItems(
                leading: Button("Xóa tất cả") {
                    if selectedGameIndex < games.count {
                        games[selectedGameIndex].logs.removeAll()
                        saveCurrentState()
                        showToast("Đã xóa nhật ký")
                    }
                },
                trailing: Button("Đóng") { showingLogsSheet = false }
            )
        }
    }
    
    // MARK: - Game Keyboard Guide Sheet
    var autoFillGuideSheetView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Bàn Phím Game Trợ Thủ (Điền 1 Chạm)")
                        .font(.title2).bold()
                        .padding(.top)
                    
                    Text("Giải pháp tự động điền tối ưu nhất cho Liên Quân và mọi tựa game iOS! Chỉ cần bấm Quả địa cầu 🌐 trên bàn phím là hiện sẵn 2 nút Điền ID và Điền Pass.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        stepItem(num: "1", title: "Thêm Bàn phím vào iOS", desc: "Vào Cài đặt (Settings) ➔ Cài đặt chung (General) ➔ Bàn phím (Keyboards) ➔ Bàn phím ➔ Thêm bàn phím mới ➔ Chọn 'Game Keyboard'.")
                        stepItem(num: "2", title: "Bật Cho phép Truy cập Đầy đủ", desc: "Chạm vào dòng 'Game Keyboard' vừa thêm ➔ Bật công tắc 'Cho phép truy cập đầy đủ' (Allow Full Access) để bàn phím đọc danh sách nick.")
                        stepItem(num: "3", title: "Điền 1 chạm trong Game", desc: "Mở Liên Quân hoặc bất kỳ game nào, chạm vào ô Tài khoản ➔ Bấm phím Quả địa cầu 🌐 ➔ Chạm [Điền Tài Khoản] và [Điền Mật Khẩu] là xong!")
                    }
                    .padding(.vertical)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Bàn Phím Game")
            .navigationBarItems(trailing: Button("Đóng") { showingAutoFillGuide = false })
        }
    }
    
    func stepItem(num: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
                .background(Color.cyan)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold))
                Text(desc).font(.caption).foregroundColor(.gray)
            }
        }
    }
}
