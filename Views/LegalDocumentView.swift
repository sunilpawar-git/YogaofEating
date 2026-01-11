import SwiftUI

struct LegalDocumentView: View {
    let title: String
    let textContent: String

    var body: some View {
        ScrollView {
            Text(self.textContent)
                .padding()
                .textSelection(.enabled)
        }
        .navigationTitle(self.title)
        #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
