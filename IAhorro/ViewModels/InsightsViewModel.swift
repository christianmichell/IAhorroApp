import Foundation
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {
    struct CategorySummary: Identifiable {
        let id: String
        let category: ReceiptCategory
        let total: Decimal
    }

    @Published private(set) var totalSpent: Decimal = 0
    @Published private(set) var categorySummaries: [CategorySummary] = []
    @Published private(set) var keywords: [String] = []

    private var cancellables: Set<AnyCancellable> = []

    init(receiptPublisher: Published<[Receipt]>.Publisher) {
        receiptPublisher
            .sink { [weak self] receipts in
                self?.computeInsights(from: receipts)
            }
            .store(in: &cancellables)
    }

    private func computeInsights(from receipts: [Receipt]) {
        totalSpent = receipts.compactMap(\.effectiveTotal).reduce(Decimal(0), +)
        let grouped = Dictionary(grouping: receipts) { receipt -> ReceiptCategory in
            receipt.categories.first ?? .other
        }
        categorySummaries = grouped.map { category, receipts in
            let total = receipts.compactMap(\.effectiveTotal).reduce(Decimal(0), +)
            return CategorySummary(id: category.id, category: category, total: total)
        }
        .sorted(by: { $0.total > $1.total })

        let keywordsSet = receipts.flatMap(\.keywords)
        let counts = keywordsSet.reduce(into: [String: Int]()) { partialResult, keyword in
            partialResult[keyword, default: 0] += 1
        }
        keywords = counts.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key < rhs.key
            }
            return lhs.value > rhs.value
        }
        .map(\.key)
        .prefix(25)
        .map(String.init)
    }
}
