import Combine
import Foundation
import StoreKit

@MainActor
final class PremiumManager: ObservableObject {
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var products: [Product] = []

    /// Loaded once from Info.plist — never hardcoded.
    private let productIDs: Set<String>

    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        let ids = (Bundle.main.object(forInfoDictionaryKey: "StoreKitProductIDs") as? [String]) ?? []
        self.productIDs = Set(ids)
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    // MARK: - Startup

    /// Call once from the app entry point to sync entitlement state and listen for changes.
    func startListeningForTransactions() {
        self.transactionUpdatesTask = Task(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                await self?.handleVerificationResult(update)
            }
        }
    }

    func restorePurchases() async {
        var entitledToOurProduct = false
        // swiftlint:disable opening_brace
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement,
               self.productIDs.contains(transaction.productID)
            {
                entitledToOurProduct = true
                break
            }
        }
        // swiftlint:enable opening_brace
        self.isPremium = entitledToOurProduct
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            self.products = try await Product.products(for: self.productIDs)
        } catch {
            self.products = []
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> PurchaseResult {
        do {
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                await self.handleVerificationResult(verification)
                return self.isPremium ? .success : .failed(nil)
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed(nil)
            }
        } catch {
            return .failed(error)
        }
    }

    // MARK: - Testing

    func setPremiumForTesting(_ value: Bool) {
        self.isPremium = value
    }
}

// MARK: - Purchase result

enum PurchaseResult {
    case success
    case pending
    case cancelled
    case failed(Error?)
}

// MARK: - Private

private extension PremiumManager {
    func handleVerificationResult(_ result: VerificationResult<Transaction>) async {
        switch result {
        case let .verified(transaction):
            if self.productIDs.contains(transaction.productID) {
                switch transaction.revocationDate {
                case .none:
                    self.isPremium = true
                default:
                    await self.restorePurchases()
                }
            }
            await transaction.finish()
        case .unverified:
            break
        }
    }
}
