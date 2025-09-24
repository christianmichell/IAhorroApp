import Foundation
import UIKit

@MainActor
final class ReceiptStore: ObservableObject {
    @Published private(set) var receipts: [Receipt] = []

    private let storage: ReceiptStorageService

    init(storage: ReceiptStorageService) {
        self.storage = storage
        Task {
            await loadReceipts()
        }
    }

    func loadReceipts() async {
        let loaded = await storage.loadReceipts()
        receipts = loaded
    }

    func receipt(withId id: Receipt.ID) async -> Receipt? {
        await storage.receipt(withId: id)
    }

    func add(_ receipt: Receipt, data: Data, thumbnail: UIImage?) async throws {
        try await storage.persist(receipt, data: data, thumbnail: thumbnail)
        await loadReceipts()
    }

    func delete(_ receipt: Receipt) async throws {
        try await storage.delete(receipt.id)
        await loadReceipts()
    }
}
