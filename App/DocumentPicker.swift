import SwiftUI
import UIKit
import UniformTypeIdentifiers

public struct DocumentPicker: UIViewControllerRepresentable {
    public var onPick: (String) -> Void
    public var onError: (String) -> Void
    @Environment(\.presentationMode) private var presentationMode

    public init(onPick: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        self.onPick = onPick
        self.onError = onError
    }

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Broad types including custom .txt extension to prevent greyed-out files
        var types: [UTType] = [.plainText, .text, .utf8PlainText]
        if let customTxt = UTType(filenameExtension: "txt") {
            types.append(customTxt)
        }
        types.append(.data)

        // asCopy: true ensures iOS automatically copies file into app sandbox!
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.presentationMode.wrappedValue.dismiss()
                return
            }

            do {
                // Since asCopy: true was used, url is directly readable in local sandbox
                let content = try String(contentsOf: url, encoding: .utf8)
                parent.onPick(content)
            } catch {
                // Fallback attempt with ISO Latin or Windows-1258 encodings
                if let data = try? Data(contentsOf: url),
                   let fallbackString = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .isoLatin1) {
                    parent.onPick(fallbackString)
                } else {
                    parent.onError("Không thể đọc tệp TXT: \(error.localizedDescription)")
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
