# GameAccountApp

Ứng dụng quản lý tài khoản game trên iOS hỗ trợ Auto-Login thông qua Credential Provider Extension (AutoFill) và chia sẻ dữ liệu qua App Group.

## 📁 Cấu trúc thư mục

```text
GameAccountApp/
├── .github/
│   └── workflows/
│       └── build.yml
├── App/
│   ├── ContentView.swift
│   ├── GameAccountApp.entitlements
│   ├── GameAccountApp.swift
│   └── SharedDataManager.swift
├── Extension/
│   ├── AutoFillExtension.entitlements
│   └── CredentialProviderViewController.swift
├── .gitignore
├── project.yml
└── README.md
```

## 🚀 Hướng dẫn đẩy lên GitHub và Build IPA

1. **Khởi tạo và đẩy lên GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit GameAccountApp"
   git branch -M main
   git remote add origin https://github.com/<tai-khoan-cua-ban>/GameAccountApp.git
   git push -u origin main
   ```

2. **Tự động biên dịch:**
   - Sau khi `push`, GitHub Actions (`.github/workflows/build.yml`) sẽ tự động chạy.
   - Khi hoàn tất, truy cập tab **Actions** -> Chọn build mới nhất -> Tải artifact **GameAccountApp-IPA**.

3. **Cài đặt lên iOS:**
   - Sử dụng **eSign**, **TrollStore**, **GBox**, **AltStore** hoặc **Sideloadly** để ký và cài đặt file `.ipa`.
   - Vào **Cài đặt (Settings) -> Mật khẩu (Passwords) -> Tùy chọn mật khẩu (Password Options)** -> Bật **GameAccountApp** để kích hoạt AutoFill.
