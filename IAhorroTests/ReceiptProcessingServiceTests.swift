import XCTest
import UIKit
@testable import IAhorro

final class ReceiptProcessingServiceTests: XCTestCase {
    func testProcessEnrichesKeywordsAndCategories() async throws {
        let analyzer = MockAnalyzer()
        let service = ReceiptProcessingService(analyzer: analyzer)
        let description = "Consulta médica por dolor estomacal en Viña del Mar"
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
        let image = renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 32, height: 32)))
        }
        let data = image.jpegData(compressionQuality: 0.8)!

        let processed = try await service.process(
            mediaData: data,
            mediaType: .image,
            originalFileName: "consulta.png",
            userDescription: description,
            location: Geolocation(latitude: -33.0, longitude: -71.5)
        )

        XCTAssertEqual(Set(processed.receipt.keywords).contains("dolor"), true)
        XCTAssertTrue(processed.receipt.categories.contains(.health))
        XCTAssertEqual(processed.receipt.mediaType, .image)
        XCTAssertNotNil(processed.thumbnail)
    }
}

private struct MockAnalyzer: ReceiptAnalyzing {
    func analyzeReceipt(mediaData: Data, mediaType: Receipt.MediaType, userDescription: String?, location: Geolocation?) async throws -> ReceiptAnalysisResult {
        ReceiptAnalysisResult(
            merchant: .init(name: "Clínica Mayo", contact: nil, address: "Viña del Mar"),
            payer: .init(name: "Juan Pérez", contact: nil, address: nil),
            purchaseDate: Date(timeIntervalSince1970: 0),
            taxBreakdown: .init(subtotal: 10000, tax: 1900, total: 11900),
            currencyCode: "CLP",
            keywords: ["salud", "consulta", "medico"],
            categories: ["health"],
            lineItems: [ReceiptAnalysisResult.LineItem(description: "Consulta gastroenterología", quantity: 1, unitPrice: 10000, total: 10000)],
            notes: "Consulta por dolor estomacal",
            aiSummary: "Atención médica general"
        )
    }
}
