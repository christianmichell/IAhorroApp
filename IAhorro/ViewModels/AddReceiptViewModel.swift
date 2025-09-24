import Foundation
import SwiftUI
import Combine

@MainActor
final class AddReceiptViewModel: ObservableObject {
    enum AddState: Equatable {
        case idle
        case picking
        case processing
        case completed
    }

    @Published var state: AddState = .idle
    @Published var userDescription: String = ""
    @Published var location: Geolocation?
    @Published private(set) var errorMessage: String?
    @Published private(set) var processedReceipt: Receipt?

    private let receiptStore: ReceiptStore
    private let processingService: ReceiptProcessingServiceProtocol

    init(receiptStore: ReceiptStore, processingService: ReceiptProcessingServiceProtocol) {
        self.receiptStore = receiptStore
        self.processingService = processingService
    }

    func handlePickedMedia(_ mediaData: Data, mediaType: Receipt.MediaType, originalFileName: String) async {
        state = .processing
        do {
            let processed = try await processingService.process(
                mediaData: mediaData,
                mediaType: mediaType,
                originalFileName: originalFileName,
                userDescription: userDescription,
                location: location
            )
            try await receiptStore.add(processed.receipt, data: processed.fileData, thumbnail: processed.thumbnail)
            processedReceipt = processed.receipt
            state = .completed
        } catch {
            errorMessage = error.localizedDescription
            state = .idle
        }
    }

    func reset() {
        state = .idle
        userDescription = ""
        location = nil
        processedReceipt = nil
        errorMessage = nil
    }
}
