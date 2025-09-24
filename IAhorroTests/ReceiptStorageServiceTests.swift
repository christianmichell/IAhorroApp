import XCTest
@testable import IAhorro

final class ReceiptStorageServiceTests: XCTestCase {
    func testPersistAndLoadReceipts() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let storage = try await ReceiptStorageService(containerURL: tempURL)
        let receipt = Receipt(
            purchaseDate: Date(timeIntervalSince1970: 0),
            merchant: .init(name: "Supermercado Central", contact: nil, address: nil),
            taxBreakdown: .init(subtotal: 1000, tax: 190, total: 1190),
            currencyCode: "CLP",
            mediaType: .image,
            fileName: "super.jpg",
            fileURL: tempURL,
            keywords: ["supermercado", "comida"],
            categories: [.groceries]
        )

        try await storage.persist(receipt, data: Data([0x0]), thumbnail: nil)
        let receipts = await storage.loadReceipts()
        XCTAssertEqual(receipts.count, 1)
        XCTAssertEqual(receipts.first?.keywords.sorted(), ["comida", "supermercado"])
        XCTAssertEqual(receipts.first?.categories, [.groceries])
    }
}
