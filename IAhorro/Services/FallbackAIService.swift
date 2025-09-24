import Foundation

struct FallbackAIService: ReceiptAnalyzing, ReceiptAnswering {
    func analyzeReceipt(mediaData: Data, mediaType: Receipt.MediaType, userDescription: String?, location: Geolocation?) async throws -> ReceiptAnalysisResult {
        let keywords = (userDescription ?? "")
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let categories = inferCategories(from: keywords)
        return ReceiptAnalysisResult(
            merchant: .init(name: "Comercio desconocido", contact: nil, address: nil),
            payer: .init(name: nil, contact: nil, address: nil),
            purchaseDate: Date(),
            taxBreakdown: .init(subtotal: nil, tax: nil, total: nil),
            currencyCode: Locale.current.currency?.identifier,
            keywords: keywords,
            categories: categories,
            lineItems: [],
            notes: userDescription,
            aiSummary: "Boleta capturada sin análisis IA en modo sin conexión"
        )
    }

    func answerQuestion(query: String, receipts: [Receipt]) async throws -> String {
        let total = receipts.compactMap(\.effectiveTotal).reduce(Decimal(0), +)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = receipts.first?.currencyCode ?? Locale.current.currency?.identifier
        let totalText = formatter.string(from: NSDecimalNumber(decimal: total)) ?? "-"
        let titles = receipts.map { receipt in
            "• \(receipt.merchant.name ?? "Comercio") - \(receipt.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "fecha desconocida")"
        }
        return [
            "Resumen sin conexión",
            "Total estimado: \(totalText)",
            "Coincidencias: \n\(titles.joined(separator: "\n"))"
        ].joined(separator: "\n\n")
    }

    private func inferCategories(from keywords: [String]) -> [String] {
        let mapping: [String: String] = [
            "medic": "health",
            "salud": "health",
            "doctor": "health",
            "super": "groceries",
            "comida": "dining",
            "arriendo": "rent",
            "ocio": "entertainment"
        ]
        var matched: Set<String> = []
        for keyword in keywords {
            for (pattern, category) in mapping where keyword.contains(pattern) {
                matched.insert(category)
            }
        }
        if matched.isEmpty {
            matched.insert(ReceiptCategory.other.rawValue)
        }
        return Array(matched)
    }
}
