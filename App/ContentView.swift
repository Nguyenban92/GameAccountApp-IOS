import SwiftUI
import UniformTypeIdentifiers

// Cấu trúc hỗ trợ xuất file TXT
struct TextFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String
    init(initialText: String = "") { text = initialText }
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else { text = "" }
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

// Cấu trúc tài khoản
struct GameAccount: Identifiable, Codable {
    var id = UUID()
    var gameName: String
    var username: String
    var password: String
    var status: String = "Chờ đăng nhập"
}

struct ContentView: View {
    @State private var savedAccounts: [GameAccount] = []
    @State private var currentQueueIndex: Int = 0
    
    @State private var showingFileImporter = false
    @State private var showingFileExporter = false
    @State private var documentToExport = TextFileDocument()
    
    var totalAccounts: Int { savedAccounts.count }
    var successCount: Int { savedAccounts.filter { $0.status == "Thành công" }.count }
    var failedCount: Int { savedAccounts.filter { $0.status == "Lỗi" || $0.status == "Sai mật khẩu" }.count }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Text("Quản Lý Auto-Login")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .padding(.top, 10).padding(.bottom, 20)
                
                // Dashboard
                HStack(spacing: 15) {
                    ModernStatBox(title: "Tổng số", count: totalAccounts, icon: "tray.full.fill", color: .blue)
                    ModernStatBox(title: "Thành công", count: successCount, icon: "checkmark.shield.fill", color: .green)
                    ModernStatBox(title: "Lỗi/Sai", count: failedCount, icon: "xmark.shield.fill", color: .red)
                }
                .padding(.horizontal).padding(.bottom, 20)
                
                // Danh sách
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(savedAccounts.indices, id: \.self) { index in
                            AccountCard(account: $savedAccounts[index], isNextInQueue: index == currentQueueIndex) { newStatus in
                                updateStatusAndMoveQueue(index: index, status: newStatus)
                            }
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 100)
                }
            }
            
            // Thanh công cụ đáy
            VStack {
                Spacer()
                HStack(spacing: 30) {
                    ActionButton(icon: "square.and.arrow.down", title: "Nhập TXT", color: .blue) { showingFileImporter = true }
                    ActionButton(icon: "square.and.arrow.up", title: "Lọc & Xuất", color: .green) { prepareExportDocument() }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.95))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            savedAccounts = SharedDataManager.shared.loadAccounts()
            findNextInQueue()
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.plainText]) { result in
            do {
                let url = try result.get()
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let fileContent = try String(contentsOf: url, encoding: .utf8)
                    let lines = fileContent.components(separatedBy: .newlines)
                    for line in lines {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty { continue }
                        let parts = trimmed.components(separatedBy: ",")
                        if parts.count >= 2 {
                            savedAccounts.append(GameAccount(
                                gameName: "Game",
                                username: parts[0].trimmingCharacters(in: .whitespaces),
                                password: parts[1].trimmingCharacters(in: .whitespaces)
                            ))
                        }
                    }
                    SharedDataManager.shared.saveAccounts(savedAccounts)
                    findNextInQueue()
                }
            } catch {
                print("Lỗi đọc file: \(error.localizedDescription)")
            }
        }
        .fileExporter(isPresented: $showingFileExporter, document: documentToExport, contentType: .plainText, defaultFilename: "TaiKhoan_DaLoc") { _ in }
    }
    
    // Logic Hàng đợi & Cập nhật
    func updateStatusAndMoveQueue(index: Int, status: String) {
        guard index >= 0 && index < savedAccounts.count else { return }
        savedAccounts[index].status = status
        SharedDataManager.shared.saveAccounts(savedAccounts)
        findNextInQueue()
    }
    
    func findNextInQueue() {
        if let nextIndex = savedAccounts.firstIndex(where: { $0.status == "Chờ đăng nhập" }) {
            currentQueueIndex = nextIndex
        }
    }
    
    // Logic Lọc và Xuất
    func prepareExportDocument() {
        let validAccounts = savedAccounts.filter { $0.status == "Thành công" || $0.status == "Chờ đăng nhập" }
        let exportString = validAccounts.map { "\($0.username),\($0.password)" }.joined(separator: "\n")
        documentToExport = TextFileDocument(initialText: exportString)
        showingFileExporter = true
    }
}

// UI Components
struct AccountCard: View {
    @Binding var account: GameAccount
    var isNextInQueue: Bool
    var statusChanged: (String) -> Void
    
    var statusColor: Color {
        switch account.status {
        case "Chờ đăng nhập": return .orange
        case "Thành công": return .green
        default: return .red
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(account.username).font(.system(size: 18, weight: .bold, design: .monospaced))
                Text("Trạng thái: \(account.status)").font(.caption).foregroundColor(statusColor)
            }
            Spacer()
            // Nút điều khiển
            Button("✅") { statusChanged("Thành công") }.buttonStyle(BorderlessButtonStyle()).font(.title2)
            Button("❌") { statusChanged("Lỗi") }.buttonStyle(BorderlessButtonStyle()).font(.title2)
        }
        .padding(16)
        .background(isNextInQueue ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(statusColor.opacity(0.5), lineWidth: 1.5))
    }
}

struct ModernStatBox: View {
    var title: String; var count: Int; var icon: String; var color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color).font(.title2)
            Text("\(count)").font(.title).bold()
            Text(title).font(.caption2).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActionButton: View {
    var icon: String; var title: String; var color: Color; var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20, weight: .bold))
                Text(title).font(.caption).bold()
            }
            .foregroundColor(color).frame(width: 80)
        }
    }
}
