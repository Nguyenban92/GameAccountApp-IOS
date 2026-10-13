import SwiftUI
import UIKit

public struct ImagePicker: UIViewControllerRepresentable {
    @Binding public var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    public init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Resize / compress to reasonable size for performance
                let resized = image.resized(toMaxDimension: 300)
                parent.selectedImage = resized
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

extension UIImage {
    func resized(toMaxDimension maxDim: CGFloat) -> UIImage {
        let currentMax = max(size.width, size.height)
        if currentMax <= maxDim { return self }
        let ratio = maxDim / currentMax
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
