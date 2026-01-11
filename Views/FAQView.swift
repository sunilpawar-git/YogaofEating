import SwiftUI

// MARK: - FAQ Views

struct FAQView: View {
    var body: some View {
        List {
            Section("General") {
                FAQItem(
                    question: "What is 'Yoga of Eating'?",
                    answer: "It's a mindful approach to nutrition focusing on how food affects your energy and well-being, rather than just counting calories."
                )
                FAQItem(
                    question: "How does the Smiley work?",
                    answer: "The Smiley reflects the cumulative 'health' of your recent meals. Eat mindfully and healthily to keep it happy!"
                )
            }

            Section("AI & Analysis") {
                FAQItem(
                    question: "How is my food analyzed?",
                    answer: "We use advanced AI (powered by Google Gemini) to interpret your meal descriptions. It estimates nutritional value and 'sattvic' quality based on your input."
                )
                FAQItem(
                    question: "Is the AI advice medical advice?",
                    answer: "No. The AI provides general wellness insights based on common nutritional knowledge. Always consult a doctor for medical issues."
                )
            }

            Section("Data & Privacy") {
                FAQItem(
                    question: "Where is my data stored?",
                    answer: "By default, all your data is stored securely on your device. It never leaves your phone unless you choose to Sync."
                )
                FAQItem(
                    question: "How does Sync work?",
                    answer: "If you sign in, you can sync your data to the cloud. This allows you to restore your data if you lose your device. Passwords and sensitive data are encrypted."
                )
            }
        }
        .navigationTitle("FAQ & Help")
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring()) { self.isExpanded.toggle() }
            } label: {
                HStack {
                    Text(self.question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(self.isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if self.isExpanded {
                Text(self.answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
}
