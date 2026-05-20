import SwiftUI
import UIKit

// MARK: - DeleteDetectingTextField

final class DeleteDetectingTextField: UITextField {
    var onDeleteWhenEmpty: (() -> Void)?

    override func deleteBackward() {
        if (text ?? "").isEmpty {
            self.onDeleteWhenEmpty?()
        }
        super.deleteBackward()
    }
}

// MARK: - BulletTextField

/// UIViewRepresentable wrapping DeleteDetectingTextField.
/// Handles: text binding, focus management, Return key (keep keyboard up), backspace-on-empty.
struct BulletTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isFocused: Bool
    let onFocusChange: (Bool) -> Void
    let onReturn: () -> Void
    let onDeleteEmpty: () -> Void

    func makeUIView(context: Context) -> DeleteDetectingTextField {
        let tf = DeleteDetectingTextField()
        tf.text = self.text // pre-populate so view never flashes empty on first render
        tf.delegate = context.coordinator
        tf.font = .roundedSystem(size: 17, weight: .regular)
        tf.textColor = .label
        tf.tintColor = .systemBlue
        tf.borderStyle = .none
        tf.returnKeyType = .next
        tf.autocorrectionType = .default
        tf.autocapitalizationType = .sentences
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: DeleteDetectingTextField, context _: Context) {
        if uiView.text != self.text {
            uiView.text = self.text
        }
        uiView.attributedPlaceholder = NSAttributedString(
            string: self.placeholder,
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        uiView.onDeleteWhenEmpty = self.onDeleteEmpty

        DispatchQueue.main.async {
            if self.isFocused, !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !self.isFocused, uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BulletTextField

        init(_ parent: BulletTextField) { self.parent = parent }

        @objc func textDidChange(_ textField: UITextField) {
            self.parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_: UITextField) {
            self.parent.onFocusChange(true)
        }

        func textFieldDidEndEditing(_: UITextField) {
            self.parent.onFocusChange(false)
        }

        func textFieldShouldReturn(_: UITextField) -> Bool {
            self.parent.onReturn()
            return false // keep keyboard up
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let current = textField.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }
            let updated = current.replacingCharacters(in: swiftRange, with: string)
            return updated.count <= ValidationLimits.mealDescription
        }
    }
}

// MARK: - UIFont rounded helper

private extension UIFont {
    static func roundedSystem(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
