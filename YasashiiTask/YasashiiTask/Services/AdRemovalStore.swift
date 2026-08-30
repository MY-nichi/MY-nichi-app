import Combine
import Foundation
import StoreKit

@MainActor
final class AdRemovalStore: ObservableObject {
    static let productID = "remove_ads"
    static let adsRemovedDefaultsKey = "adsRemoved"

    @Published private(set) var isAdsRemoved: Bool
    @Published private(set) var product: Product?
    @Published private(set) var isWorking = false
    @Published var message: String?

    init() {
        isAdsRemoved = UserDefaults.standard.bool(forKey: Self.adsRemovedDefaultsKey)
    }

    var purchaseTitle: String {
        if let product {
            return "広告を非表示にする（\(product.displayPrice)）"
        }
        return "広告を非表示にする"
    }

    func load() async {
        await refreshPurchasedStatus()
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            message = "購入情報を読み込めませんでした。"
        }
    }

    func purchase() async {
        isWorking = true
        defer { isWorking = false }

        if product == nil {
            await load()
        }

        guard let product else {
            message = "広告非表示の商品がまだ準備できていません。"
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                setAdsRemoved(true)
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                message = "購入は保留中です。"
            @unknown default:
                break
            }
        } catch {
            message = "購入を完了できませんでした。"
        }
    }

    func restorePurchases() async {
        isWorking = true
        defer { isWorking = false }

        do {
            try await AppStore.sync()
            await refreshPurchasedStatus()
            if !isAdsRemoved {
                message = "復元できる購入が見つかりませんでした。"
            }
        } catch {
            message = "購入を復元できませんでした。"
        }
    }

    private func refreshPurchasedStatus() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  transaction.productID == Self.productID,
                  transaction.revocationDate == nil else {
                continue
            }
            setAdsRemoved(true)
            return
        }
    }

    private func setAdsRemoved(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Self.adsRemovedDefaultsKey)
        isAdsRemoved = value
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private enum StoreError: Error {
        case failedVerification
    }
}
