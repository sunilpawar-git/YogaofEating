import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss)
    private var dismiss
    @EnvironmentObject var premiumManager: PremiumManager

    @State private var purchaseError: Error?
    @State private var showPurchaseError = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.Premium.heading)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(Strings.Premium.subtitle)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label(Strings.Premium.trendFeature, systemImage: "chart.line.uptrend.xyaxis")
                    Label(Strings.Premium.archetypeFeature, systemImage: "figure.walk.motion")
                    Label(Strings.Premium.pdfFeature, systemImage: "doc.richtext")
                }
                .font(.subheadline)

                if self.premiumManager.products.isEmpty {
                    Text(Strings.Premium.productsUnavailable)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(self.premiumManager.products, id: \.id) { product in
                        Button("\(product.displayName) • \(product.displayPrice)") {
                            Task { await self.attemptPurchase(product) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Button(Strings.Premium.restorePurchases) {
                    Task {
                        await self.premiumManager.restorePurchases()
                        if self.premiumManager.isPremium { self.dismiss() }
                    }
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .navigationTitle(Strings.Premium.navTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Premium.close) { self.dismiss() }
                }
            }
            .alert(Strings.Premium.purchaseFailed, isPresented: self.$showPurchaseError) {
                Button(Strings.Common.done, role: .cancel) {}
            } message: {
                Text(self.purchaseError?.localizedDescription ?? Strings.Premium.purchaseFailedMessage)
            }
        }
        .task {
            await self.premiumManager.loadProducts()
        }
    }

    private func attemptPurchase(_ product: Product) async {
        let result = await self.premiumManager.purchase(product)
        switch result {
        case .success:
            self.dismiss()
        case .cancelled, .pending:
            break
        case let .failed(error):
            self.purchaseError = error
            self.showPurchaseError = true
        }
    }
}
