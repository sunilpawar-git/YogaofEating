import SwiftUI

/// A reusable sheet view for selecting a time using a wheel picker.
/// Extracted from JournalBlockView to reduce file size and improve reusability.
struct TimePickerSheetView: View {
    /// Binding to the selected time
    @Binding var selectedTime: Date

    /// Callback when the user saves the time
    let onSave: () -> Void

    /// Callback when the user cancels
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Meal Time",
                    selection: self.$selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Edit Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        self.onSave()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    TimePickerSheetView(
        selectedTime: .constant(Date()),
        onSave: {},
        onCancel: {}
    )
}
