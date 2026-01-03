import SwiftUI

// MARK: - FAQ Views

struct FAQView: View {
    var body: some View {
        List {
            Section("Mindful Eating FAQs") {
                FAQItem(
                    question: "What is 'Yoga of Eating'?",
                    answer: "It's a mindful approach to nutrition focusing on how food affects your energy."
                )
                FAQItem(
                    question: "How does the Smiley work?",
                    answer: "The Smiley reflects the cumulative health of your meals. Eat mindfully to keep it happy."
                )
                FAQItem(
                    question: "What is 'Smart Smiley'?",
                    answer: "AI heuristics that interpret your meal descriptions to adjust the Smiley state."
                )
                FAQItem(
                    question: "How do I track my progress?",
                    answer: "Your daily timeline shows every meal logged, focusing on consistency over perfection."
                )
            }
            Section("Privacy & Data") {
                FAQItem(
                    question: "Are my details private?",
                    answer: "Yes. Your details are stored locally. Cloud sync is optional and encrypted."
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
                    Text(self.question).font(.headline).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(self.isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                }
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
