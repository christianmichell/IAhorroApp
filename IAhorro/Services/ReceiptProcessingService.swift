import Foundation
import UIKit
import CoreGraphics

struct ProcessedReceipt {
    let receipt: Receipt
    let fileData: Data
    let thumbnail: UIImage?
}

protocol ReceiptProcessingServiceProtocol {
    func process(mediaData: Data, mediaType: Receipt.MediaType, originalFileName: String, userDescription: String?, location: Geolocation?) async throws -> ProcessedReceipt
}

final class ReceiptProcessingService: ReceiptProcessingServiceProtocol {
    private let analyzer: ReceiptAnalyzing
    private let thumbnailGenerator: ThumbnailGenerating

    init(analyzer: ReceiptAnalyzing, thumbnailGenerator: ThumbnailGenerating = DefaultThumbnailGenerator()) {
        self.analyzer = analyzer
        self.thumbnailGenerator = thumbnailGenerator
    }

    func process(mediaData: Data, mediaType: Receipt.MediaType, originalFileName: String, userDescription: String?, location: Geolocation?) async throws -> ProcessedReceipt {
        let analysis = try await analyzer.analyzeReceipt(mediaData: mediaData, mediaType: mediaType, userDescription: userDescription, location: location)
        let categories = mapCategories(analysis.categories)
        let keywords = enrichKeywords(analysis.keywords, userDescription: userDescription)
        let taxBreakdown = Receipt.TaxBreakdown(
            subtotal: analysis.taxBreakdown.subtotal,
            tax: analysis.taxBreakdown.tax,
            total: analysis.taxBreakdown.total
        )

        let fileName = uniqueFileName(from: originalFileName, mediaType: mediaType)
        var receipt = Receipt(
            purchaseDate: analysis.purchaseDate,
            merchant: .init(name: analysis.merchant.name, contact: analysis.merchant.contact, address: analysis.merchant.address),
            payer: .init(name: analysis.payer.name, contact: analysis.payer.contact, address: analysis.payer.address),
            taxBreakdown: taxBreakdown,
            currencyCode: analysis.currencyCode ?? Locale.current.currency?.identifier ?? "USD",
            mediaType: mediaType,
            fileName: fileName,
            fileURL: URL(fileURLWithPath: ""),
            userDescription: userDescription,
            location: location,
            keywords: keywords,
            categories: categories,
            lineItems: analysis.lineItems.map { item in
                Receipt.LineItem(description: item.description, quantity: item.quantity, unitPrice: item.unitPrice, total: item.total)
            },
            notes: analysis.notes ?? analysis.aiSummary
        )

        let thumbnail = try await thumbnailGenerator.makeThumbnail(from: mediaData, mediaType: mediaType)
        let normalizedData = try normalize(mediaData: mediaData, mediaType: mediaType)
        return ProcessedReceipt(receipt: receipt, fileData: normalizedData, thumbnail: thumbnail)
    }

    private func normalize(mediaData: Data, mediaType: Receipt.MediaType) throws -> Data {
        switch mediaType {
        case .image:
            guard let image = UIImage(data: mediaData) else { return mediaData }
            guard let jpegData = image.jpegData(compressionQuality: 0.92) else { return mediaData }
            return jpegData
        case .pdf:
            return mediaData
        }
    }

    private func uniqueFileName(from original: String, mediaType: Receipt.MediaType) -> String {
        let sanitized = original.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
        let ext = (mediaType == .pdf) ? "pdf" : "jpg"
        if sanitized.isEmpty {
            return "receipt-\(UUID().uuidString).\(ext)"
        }
        if sanitized.lowercased().hasSuffix(".\(ext)") {
            return sanitized
        }
        return "\(sanitized).\(ext)"
    }

    private func mapCategories(_ categories: [String]) -> [ReceiptCategory] {
        let normalized = categories.map { $0.lowercased() }
        let mapping = Dictionary(uniqueKeysWithValues: ReceiptCategory.predefined.map { ($0.rawValue, $0) })
        var result: [ReceiptCategory] = []
        for category in normalized {
            if let mapped = mapping[category] {
                result.append(mapped)
            } else if let fuzzy = mapping.values.first(where: { category.contains($0.rawValue) || $0.rawValue.contains(category) }) {
                result.append(fuzzy)
            }
        }
        if result.isEmpty {
            result.append(.other)
        }
        return Array(Set(result)).sorted(by: { $0.displayName < $1.displayName })
    }

    private func enrichKeywords(_ keywords: [String], userDescription: String?) -> [String] {
        var combined = Set(keywords.map { $0.lowercased() })
        if let userDescription {
            let descriptionKeywords = userDescription
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty && $0.count > 2 }
            combined.formUnion(descriptionKeywords)
        }
        return combined.sorted()
    }
}

// MARK: - Thumbnail Generation

protocol ThumbnailGenerating {
    func makeThumbnail(from data: Data, mediaType: Receipt.MediaType) async throws -> UIImage?
}

struct DefaultThumbnailGenerator: ThumbnailGenerating {
    func makeThumbnail(from data: Data, mediaType: Receipt.MediaType) async throws -> UIImage? {
        switch mediaType {
        case .image:
            return UIImage(data: data)
        case .pdf:
            guard let provider = CGDataProvider(data: data as CFData), let document = CGPDFDocument(provider) else { return nil }
            guard let page = document.page(at: 1) else { return nil }

            let pageRect = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { context in
                UIColor.white.set()
                context.fill(pageRect)
                context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                context.cgContext.scaleBy(x: 1, y: -1)
                context.cgContext.drawPDFPage(page)
            }
            return image
        }
    }
}
