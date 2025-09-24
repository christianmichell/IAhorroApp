import Foundation
/// Represents a single receipt captured or imported by the user.
struct Receipt: Identifiable, Codable, Hashable {
    enum MediaType: String, Codable {
        case image
        case pdf
    }

    struct TaxBreakdown: Codable, Hashable {
        var subtotal: Decimal?
        var tax: Decimal?
        var total: Decimal?

        init(subtotal: Decimal? = nil, tax: Decimal? = nil, total: Decimal? = nil) {
            self.subtotal = subtotal
            self.tax = tax
            self.total = total
        }
    }

    struct Party: Codable, Hashable {
        var name: String?
        var contact: String?
        var address: String?
    }

    struct LineItem: Codable, Hashable, Identifiable {
        var id: UUID
        var description: String
        var quantity: Double?
        var unitPrice: Decimal?
        var total: Decimal?

        init(id: UUID = UUID(), description: String, quantity: Double? = nil, unitPrice: Decimal? = nil, total: Decimal? = nil) {
            self.id = id
            self.description = description
            self.quantity = quantity
            self.unitPrice = unitPrice
            self.total = total
        }
    }

    var id: UUID
    var createdAt: Date
    var purchaseDate: Date?
    var merchant: Party
    var payer: Party
    var taxBreakdown: TaxBreakdown
    var currencyCode: String
    var mediaType: MediaType
    var fileName: String
    var fileURL: URL
    var thumbnailURL: URL?
    var userDescription: String?
    var location: Geolocation?
    var keywords: [String]
    var categories: [ReceiptCategory]
    var lineItems: [LineItem]
    var notes: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = .init(),
        purchaseDate: Date? = nil,
        merchant: Party = .init(),
        payer: Party = .init(),
        taxBreakdown: TaxBreakdown = .init(),
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        mediaType: MediaType,
        fileName: String,
        fileURL: URL,
        thumbnailURL: URL? = nil,
        userDescription: String? = nil,
        location: Geolocation? = nil,
        keywords: [String] = [],
        categories: [ReceiptCategory] = [],
        lineItems: [LineItem] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.purchaseDate = purchaseDate
        self.merchant = merchant
        self.payer = payer
        self.taxBreakdown = taxBreakdown
        self.currencyCode = currencyCode
        self.mediaType = mediaType
        self.fileName = fileName
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.userDescription = userDescription
        self.location = location
        self.keywords = keywords
        self.categories = categories
        self.lineItems = lineItems
        self.notes = notes
    }
}

extension Receipt {
    /// Returns the effective total for the receipt prioritising explicit total, subtotal+tax, then the sum of line items.
    var effectiveTotal: Decimal? {
        if let total = taxBreakdown.total {
            return total
        }
        if let subtotal = taxBreakdown.subtotal, let tax = taxBreakdown.tax {
            return subtotal + tax
        }
        let lineTotals = lineItems.compactMap(\.total)
        if lineTotals.isEmpty {
            return nil
        }
        return lineTotals.reduce(Decimal(0), +)
    }
}

struct ReceiptCategory: Codable, Identifiable, Hashable {
    var id: String { rawValue }
    let rawValue: String
    let displayName: String
    let iconSystemName: String

    static let basics = ReceiptCategory(rawValue: "basics", displayName: "Gastos básicos", iconSystemName: "house.fill")
    static let rent = ReceiptCategory(rawValue: "rent", displayName: "Arriendo", iconSystemName: "building.2.fill")
    static let groceries = ReceiptCategory(rawValue: "groceries", displayName: "Supermercado", iconSystemName: "cart.fill")
    static let dining = ReceiptCategory(rawValue: "dining", displayName: "Comidas", iconSystemName: "fork.knife")
    static let fastFood = ReceiptCategory(rawValue: "fast-food", displayName: "Comida chatarra", iconSystemName: "takeoutbag.and.cup.and.straw.fill")
    static let entertainment = ReceiptCategory(rawValue: "entertainment", displayName: "Ocio", iconSystemName: "gamecontroller.fill")
    static let health = ReceiptCategory(rawValue: "health", displayName: "Salud", iconSystemName: "cross.case.fill")
    static let transport = ReceiptCategory(rawValue: "transport", displayName: "Transporte", iconSystemName: "car.fill")
    static let education = ReceiptCategory(rawValue: "education", displayName: "Educación", iconSystemName: "book.fill")
    static let other = ReceiptCategory(rawValue: "other", displayName: "Otros", iconSystemName: "tray.full.fill")

    static let predefined: [ReceiptCategory] = [
        .basics, .rent, .groceries, .dining, .fastFood, .entertainment, .health, .transport, .education, .other
    ]
}

struct Geolocation: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}

extension Array where Element == ReceiptCategory {
    static var defaultForAI: [ReceiptCategory] { ReceiptCategory.predefined }
}
