import Foundation
import Combine

@MainActor
final class AskAIViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var answer: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let receiptStore: ReceiptStore
    private let answerService: ReceiptAnswering

    init(receiptStore: ReceiptStore, answerService: ReceiptAnswering) {
        self.receiptStore = receiptStore
        self.answerService = answerService
    }

    func submitQuery() async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Escribe una consulta para comenzar."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let relevantReceipts = filterReceipts(for: query)
            answer = try await answerService.answerQuestion(query: query, receipts: relevantReceipts)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func filterReceipts(for query: String) -> [Receipt] {
        let tokens = query.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return receiptStore.receipts.filter { receipt in
            let haystack = receipt.keywords + [receipt.merchant.name ?? "", receipt.notes ?? ""]
            let combined = haystack.joined(separator: " ").lowercased()
            return tokens.allSatisfy { combined.contains($0) }
        }
    }
}
