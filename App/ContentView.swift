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
    
    // Temporary variables for Game Creation / Edit
    @State private var tempGameTitle = ""
    @State private var tempGameServer = "Asia"
    @State private var tempGameIcon = "gamecontroller.fill"
    @State private var tempSelectedImage: UIImage? = nil
    
    // Temporary variables for Account Creation
    @State private var tempAccUser = ""
    @State private var tempAccPass = ""
    @State private var tempAccServer = "Asia"
    @State private var tempAccRank = "Lv. 1"
    
    // Import / Export states
    @State private var importPasteText = ""
    @State private var exportModeSuccessOnly = true
    @State private var exportModeRemoveFailed = true
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var showingFileImporter = false
    
    // Toast notification
    @State private var toastMessage: String? = nil
    @State private var searchText: String = ""
    
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
            // Dark luxury background
            Color(red: 0.04, green: 0.05, blue: 0.08).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Header Bar
                topHeaderView
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                // Horizontal Game Carousel (Multi-Game Management)
                gameCarouselView
                    .padding(.bottom, 8)
                
                // Current Game Stats & Auto-Queue Bar
                if let game = currentGame {
                    currentGameDashboard(game: game)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Search & Action Toolbar
                searchAndActionToolbar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
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
        .sheet(isPresented: $showingImportSheet) { importSheetView }
        .sheet(isPresented: $showingExportSheet) { exportSheetView }
        .sheet(isPresented: $showingLogsSheet) { logsSheetView }
        .sheet(isPresented: $showingShareSheet) { ShareSheet(items: shareItems) }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.plainText]) { result in
            handleFileImport(result: result)
        }
    }
    
    // MARK: - Top Header View
    var topHeaderView: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    LinearGradient(colors: [Color.cyan, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text("🎮").font(.system(size: 16))
                }
                .frame(width: 32, height: 32)
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Game Manager")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Auto-Login Suite")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { openAddGameModal() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Game")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.18))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                }
                
                Button(action: { openAddAccountModal() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                        Text("Acc")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - Game Carousel View
    var gameCarouselView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TỰA GAME QUẢN LÝ")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                Spacer()
                if let game = currentGame {
                    Button(action: { openEditGameModal(game: game) }) {
                        Text("Sửa ảnh / Tên ✎")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.cyan)
                            .padding(.horizontal)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(games.indices, id: \.self) { idx in
                        let g = games[idx]
                        let isSelected = idx == selectedGameIndex
                        
                        Button(action: {
                            selectedGameIndex = idx
                            SharedDataManager.shared.saveActiveGameId(g.id)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                ZStack(alignment: .bottomTrailing) {
                                    if let data = g.customImageData, let uiImg = UIImage(data: data) {
                                        Image(uiImage: uiImg)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 60)
                                            .clipped()
                                    } else {
                                        LinearGradient(colors: [Color.indigo.opacity(0.8), Color.cyan.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            .frame(width: 120, height: 60)
                                            .overlay(Image(systemName: g.icon).font(.title2).foregroundColor(.white.opacity(0.8)))
                                    }
                                    
                                    Text("\(g.totalAccounts) Acc")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(4)
                                        .padding(4)
                                }
                                .cornerRadius(10)
                                
                                Text(g.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isSelected ? .cyan : .white)
                                    .lineLimit(1)
                                
                                Text("Server: \(g.server)")
                                    .font(.system(size: 9, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            .padding(8)
                            .background(Color(red: 0.07, green: 0.09, blue: 0.15))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                            )
                            .shadow(color: isSelected ? Color.cyan.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 2)
                        }
                    }
                    
                    // Add Game Tile
                    Button(action: { openAddGameModal() }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.cyan)
                            Text("Thêm Game")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 80, height: 95)
                        .background(Color(red: 0.06, green: 0.08, blue: 0.13))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(style: StrokeStyle(lineWidth: 1, dash: [4])).foregroundColor(Color.cyan.opacity(0.4)))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Current Game Dashboard & Auto-Runner Pill
    func currentGameDashboard(game: GameProfile) -> some View {
        VStack(spacing: 8) {
            // Stats summary row
            HStack(spacing: 8) {
                statBox(title: "Tổng số", value: "\(game.totalAccounts)", color: .cyan)
                statBox(title: "Đã xong", value: "\(game.successCount)", color: .green)
                statBox(title: "Sai MK", value: "\(game.wrongPassCount)", color: .orange)
                statBox(title: "Lỗi/Khóa", value: "\(game.failedCount)", color: .red)
            }
            
            // Auto Runner Banner
            autoRunnerPill(game: game)
        }
    }
    
    func statBox(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(red: 0.07, green: 0.09, blue: 0.15))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 1))
    }
    
    func autoRunnerPill(game: GameProfile) -> some View {
        let runningAccount = getActiveQueueAccount(game: game)
        
        return VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("AUTO RUNNER")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
                Spacer()
                Text("Acc #\(game.currentQueueIndex + 1)/\(max(game.totalAccounts, 1))")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            if let acc = runningAccount {
                HStack {
                    Text("Đang chạy: ")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(acc.username)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    Spacer()
                    Button("Copy MK") {
                        UIPasteboard.general.string = acc.password
                        showToast("Đã copy mật khẩu của @\(acc.username)")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.15))
                    .cornerRadius(6)
                }
            } else {
                Text("Đã hoàn tất toàn bộ hàng đợi của game này!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.yellow)
            }
            
            // 3 Quick Action Buttons
            HStack(spacing: 6) {
                Button(action: { advanceQueue(status: "Thành công") }) {
                    Label("Thành công", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.85))
                        .cornerRadius(8)
                }
                
                Button(action: { advanceQueue(status: "Sai mật khẩu") }) {
                    Label("Sai MK", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.85))
                        .cornerRadius(8)
                }
                
                Button(action: { advanceQueue(status: "Lỗi/Khóa") }) {
                    Label("Lỗi", systemImage: "xmark.octagon.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(8)
                }
            }
        }
        .padding(10)
        .background(
            LinearGradient(colors: [Color(red: 0.05, green: 0.12, blue: 0.2), Color(red: 0.07, green: 0.09, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
    }
    
    // MARK: - Search & Action Toolbar
    var searchAndActionToolbar: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray).font(.caption)
                TextField("Tìm username hoặc server...", text: $searchText)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(red: 0.08, green: 0.11, blue: 0.18))
            .cornerRadius(10)
            
            Button(action: { showingImportSheet = true }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(8)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.18))
                    .cornerRadius(10)
            }
            
            Button(action: { showingExportSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.18))
                    .cornerRadius(10)
            }
            
            Button(action: { showingLogsSheet = true }) {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.purple)
                    .padding(8)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.18))
                    .cornerRadius(10)
            }
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
                        Button("Thêm tài khoản hoặc Dán TXT") {
                            showingImportSheet = true
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                    }
                } else {
                    ForEach(filteredAccounts.indices, id: \.self) { accIdx in
                        let acc = filteredAccounts[accIdx]
                        let isCurrentQueue = isAccountCurrentInQueue(acc)
                        
                        accountCard(acc: acc, isCurrentInQueue: isCurrentQueue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80)
        }
    }
    
    func accountCard(acc: GameAccount, isCurrentInQueue: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(acc.username)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        statusBadge(status: acc.status, isQueue: isCurrentInQueue)
                    }
                    
                    Text("Pass: •••••••••••")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Button(action: {
                        UIPasteboard.general.string = "\(acc.username)\t\(acc.password)"
                        showToast("Đã copy acc & pass của @\(acc.username)")
                    }) {
                        Text("Login")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.cyan.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                    }
                    
                    Button(action: { deleteAccount(acc) }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(6)
                    }
                }
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            HStack {
                Text("Server: \(acc.server) • \(acc.levelOrRank)")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Spacer()
                if let last = acc.lastLogin {
                    Text(last, style: .relative)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                } else {
                    Text("Chưa đăng nhập")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.07, green: 0.09, blue: 0.15))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCurrentInQueue ? Color.cyan : Color.white.opacity(0.08), lineWidth: isCurrentInQueue ? 1.5 : 1)
        )
        .shadow(color: isCurrentInQueue ? Color.cyan.opacity(0.25) : Color.clear, radius: 8, x: 0, y: 2)
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
        tempSelectedImage = nil
        showingAddGame = true
    }
    
    func openEditGameModal(game: GameProfile) {
        tempGameTitle = game.title
        tempGameServer = game.server
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
    
    // MARK: - Add / Edit Game Sheets
    var addGameSheetView: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin Game")) {
                    TextField("Tên game (vd: Liên Quân Mobile)", text: $tempGameTitle)
                    TextField("Server mặc định (vd: Asia, VN)", text: $tempGameServer)
                }
                
                Section(header: Text("Ảnh đại diện nhận diện")) {
                    if let img = tempSelectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .cornerRadius(8)
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
                Section(header: Text("Sửa thông tin Game")) {
                    TextField("Tên game", text: $tempGameTitle)
                    TextField("Server mặc định", text: $tempGameServer)
                }
                
                Section(header: Text("Ảnh đại diện nhận diện")) {
                    if let img = tempSelectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .cornerRadius(8)
                    }
                    Button("Đổi ảnh từ thư viện máy") {
                        showingImagePicker = true
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
                Section(header: Text("Tài khoản cho: \(currentGame?.title ?? "")")) {
                    TextField("Username / Tài khoản", text: $tempAccUser)
                    SecureField("Mật khẩu", text: $tempAccPass)
                    TextField("Server", text: $tempAccServer)
                    TextField("Level / Rank / Ghi chú", text: $tempAccRank)
                }
            }
            .navigationTitle("Thêm Tài Khoản")
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
    
    // MARK: - Import Sheet (Paste Direct + File)
    var importSheetView: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Nhập vào game: \(currentGame?.title ?? "")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cyan)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dán danh sách tài khoản trực tiếp:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $importPasteText)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .frame(height: 160)
                    
                    Text("Hỗ trợ định dạng mỗi dòng: user,pass hoặc user|pass")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                Button(action: { parseAndImportPasteText() }) {
                    Text("Nhận Diện & Nạp Vào Game")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    Text("HOẶC").font(.caption).foregroundColor(.gray)
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal)
                
                Button(action: { showingFileImporter = true }) {
                    Label("Chọn Tệp TXT Từ Files", systemImage: "doc.text")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.cyan)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Nhập Tài Khoản")
            .navigationBarItems(trailing: Button("Đóng") { showingImportSheet = false })
        }
    }
    
    func parseAndImportPasteText() {
        let lines = importPasteText.components(separatedBy: .newlines)
        var count = 0
        guard selectedGameIndex < games.count else { return }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            var user = ""
            var pass = ""
            if trimmed.contains(",") {
                let parts = trimmed.components(separatedBy: ",")
                if parts.count >= 2 {
                    user = parts[0].trimmingCharacters(in: .whitespaces)
                    pass = parts[1].trimmingCharacters(in: .whitespaces)
                }
            } else if trimmed.contains("|") {
                let parts = trimmed.components(separatedBy: "|")
                if parts.count >= 2 {
                    user = parts[0].trimmingCharacters(in: .whitespaces)
                    pass = parts[1].trimmingCharacters(in: .whitespaces)
                }
            }
            
            if !user.isEmpty && !pass.isEmpty {
                games[selectedGameIndex].accounts.append(
                    GameAccount(username: user, password: pass, server: games[selectedGameIndex].server)
                )
                count += 1
            }
        }
        
        saveCurrentState()
        importPasteText = ""
        showingImportSheet = false
        showToast("Đã nạp thành công \(count) tài khoản!")
    }
    
    func handleFileImport(result: Result<URL, Error>) {
        do {
            let url = try result.get()
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                let text = try String(contentsOf: url, encoding: .utf8)
                importPasteText = text
                parseAndImportPasteText()
            }
        } catch {
            showToast("Lỗi đọc file: \(error.localizedDescription)")
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
                    Button("Xuất Thành File TXT Mới (Chia Sẻ)") {
                        exportToNewFile()
                    }
                    
                    Button("Lưu Đè Lên Danh Sách Game Này", role: .destructive) {
                        overwriteCurrentList()
                    }
                }
            }
            .navigationTitle("Lọc & Xuất TXT")
            .navigationBarItems(trailing: Button("Đóng") { showingExportSheet = false })
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
}
