import Foundation
import Combine

@MainActor
final class ReceiptListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var receipts: [Receipt] = []
    @Published private(set) var filteredReceipts: [Receipt] = []

    private let receiptStore: ReceiptStore
    private var cancellables: Set<AnyCancellable> = []

    init(receiptStore: ReceiptStore) {
        self.receiptStore = receiptStore

        receiptStore.$receipts
            .combineLatest($searchText)
            .map { receipts, searchText in
                Self.filter(receipts: receipts, query: searchText)
            }
            .assign(to: &$filteredReceipts)

        receiptStore.$receipts
            .assign(to: &$receipts)
    }

    func refresh() async {
        await receiptStore.loadReceipts()
    }

    func delete(_ receipt: Receipt) async throws {
        try await receiptStore.delete(receipt)
    }

    private static func filter(receipts: [Receipt], query: String) -> [Receipt] {
        guard !query.isEmpty else { return receipts }
        let lowercased = query.lowercased()
        return receipts.filter { receipt in
            if receipt.merchant.name?.lowercased().contains(lowercased) == true { return true }
            if receipt.keywords.contains(where: { $0.lowercased().contains(lowercased) }) { return true }
            if receipt.categories.contains(where: { $0.displayName.lowercased().contains(lowercased) }) { return true }
            if receipt.notes?.lowercased().contains(lowercased) == true { return true }
            return false
        }
    }
}
