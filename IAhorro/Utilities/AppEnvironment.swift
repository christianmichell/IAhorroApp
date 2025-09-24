import Foundation

@MainActor
struct AppEnvironment {
    let receiptStore: ReceiptStore
    let answerService: any ReceiptAnswering
    let processingService: ReceiptProcessingService

    static func make() async throws -> AppEnvironment {
        let storage = try await ReceiptStorageService()
        let store = ReceiptStore(storage: storage)
        let aiClient: any ReceiptAnswering & ReceiptAnalyzing
        if let liveService = try? OpenAIService() {
            aiClient = liveService
        } else {
            aiClient = FallbackAIService()
        }
        let processing = ReceiptProcessingService(analyzer: aiClient)
        return AppEnvironment(receiptStore: store, answerService: aiClient, processingService: processing)
    }
}
