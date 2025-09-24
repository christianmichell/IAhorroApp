import SwiftUI
import QuickLook

struct ReceiptDetailView: View {
    let receipt: Receipt
    @State private var quickLookURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                totalsSection
                lineItemsSection
                keywordsSection
                notesSection
                metadataSection
            }
            .padding()
        }
        .navigationTitle(receipt.merchant.name ?? "Detalle")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    quickLookURL = receipt.fileURL
                } label: {
                    Label("Ver archivo", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
        .quickLookPreview($quickLookURL)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(receipt.merchant.name ?? "Comercio sin nombre")
                .font(.largeTitle).bold()
            if let purchaseDate = receipt.purchaseDate {
                Text(purchaseDate.formatted(date: .long, time: .shortened))
                    .font(.headline)
            }
            HStack(spacing: 8) {
                ForEach(receipt.categories) { category in
                    Label(category.displayName, systemImage: category.iconSystemName)
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .padding(6)
                        .background(Capsule().fill(Color.blue.opacity(0.1)))
                }
            }
        }
    }

    private var totalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let subtotal = receipt.taxBreakdown.subtotal {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(NSDecimalNumber(decimal: subtotal), formatter: NumberFormatter.currencyFormatter(code: receipt.currencyCode))
                }
            }
            if let tax = receipt.taxBreakdown.tax {
                HStack {
                    Text("IVA")
                    Spacer()
                    Text(NSDecimalNumber(decimal: tax), formatter: NumberFormatter.currencyFormatter(code: receipt.currencyCode))
                }
            }
            if let total = receipt.effectiveTotal {
                HStack {
                    Text("Total")
                        .bold()
                    Spacer()
                    Text(NSDecimalNumber(decimal: total), formatter: NumberFormatter.currencyFormatter(code: receipt.currencyCode))
                        .bold()
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGroupedBackground)))
    }

    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if receipt.lineItems.isEmpty {
                EmptyView()
            } else {
                Text("Detalle de productos")
                    .font(.headline)
                ForEach(receipt.lineItems) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.description)
                            .font(.subheadline)
                        HStack {
                            if let quantity = item.quantity {
                                Text("Cantidad: \(quantity, specifier: "%.2f")")
                            }
                            Spacer()
                            if let total = item.total {
                                Text(NSDecimalNumber(decimal: total), formatter: NumberFormatter.currencyFormatter(code: receipt.currencyCode))
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    Divider()
                }
            }
        }
    }

    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if receipt.keywords.isEmpty {
                EmptyView()
            } else {
                Text("Palabras clave")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(receipt.keywords.sorted(), id: \.self) { keyword in
                        Text(keyword)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.orange.opacity(0.15)))
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let notes = receipt.notes {
                Text("Notas de IA")
                    .font(.headline)
                Text(notes)
                    .font(.body)
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metadatos")
                .font(.headline)
            if let location = receipt.location {
                Text("Ubicación aproximada: lat \(location.latitude), lon \(location.longitude)")
            }
            Text("Creado: \(receipt.createdAt.formatted())")
            Text("Archivo: \(receipt.fileName)")
        }
    }
}
