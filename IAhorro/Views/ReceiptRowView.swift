import SwiftUI
import UIKit

struct ReceiptRowView: View {
    let receipt: Receipt

    var body: some View {
        HStack(spacing: 16) {
            if let thumbnailURL = receipt.thumbnailURL, let image = UIImage(contentsOfFile: thumbnailURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: receipt.mediaType == .pdf ? "doc.richtext" : "photo")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    )
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(receipt.merchant.name ?? "Comercio sin nombre")
                    .font(.headline)
                if let purchaseDate = receipt.purchaseDate {
                    Text(purchaseDate, format: .dateTime.day().month().year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(receipt.categories.map(\.displayName).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let total = receipt.effectiveTotal {
                Text(NSDecimalNumber(decimal: total), formatter: NumberFormatter.currencyFormatter(code: receipt.currencyCode))
                    .font(.headline)
            }
        }
        .padding(.vertical, 8)
    }
}
