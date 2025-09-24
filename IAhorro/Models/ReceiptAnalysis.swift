import Foundation

/// Result returned by the OpenAI analysis endpoint once a receipt image or PDF has been processed.
struct ReceiptAnalysisResult: Codable {
    struct Party: Codable {
        var name: String?
        var contact: String?
        var address: String?
    }

    struct TaxBreakdown: Codable {
        var subtotal: Decimal?
        var tax: Decimal?
        var total: Decimal?
    }

    struct LineItem: Codable {
        var description: String
        var quantity: Double?
        var unitPrice: Decimal?
        var total: Decimal?
    }

    var merchant: Party
    var payer: Party
    var purchaseDate: Date?
    var taxBreakdown: TaxBreakdown
    var currencyCode: String?
    var keywords: [String]
    var categories: [String]
    var lineItems: [LineItem]
    var notes: String?
    var aiSummary: String?

    init(
        merchant: Party = .init(),
        payer: Party = .init(),
        purchaseDate: Date? = nil,
        taxBreakdown: TaxBreakdown = .init(),
        currencyCode: String? = nil,
        keywords: [String] = [],
        categories: [String] = [],
        lineItems: [LineItem] = [],
        notes: String? = nil,
        aiSummary: String? = nil
    ) {
        self.merchant = merchant
        self.payer = payer
        self.purchaseDate = purchaseDate
        self.taxBreakdown = taxBreakdown
        self.currencyCode = currencyCode
        self.keywords = keywords
        self.categories = categories
        self.lineItems = lineItems
        self.notes = notes
        self.aiSummary = aiSummary
    }
}

struct ReceiptInsight: Codable {
    var totalSpent: Decimal
    var categories: [String: Decimal]
    var keywords: [String]
    var summary: String
}
