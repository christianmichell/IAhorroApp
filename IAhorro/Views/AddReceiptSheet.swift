import SwiftUI

struct AddReceiptSheet: View {
    @ObservedObject var addViewModel: AddReceiptViewModel
    @Binding var showingDocumentPicker: Bool
    @Binding var showingPhotoPicker: Bool
    @Binding var showingCamera: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Descripción opcional") {
                    TextField("Ej: almuerzo con clientes", text: $addViewModel.userDescription)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Selecciona el origen") {
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Label("Archivo existente", systemImage: "folder")
                    }

                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Foto de la librería", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        showingCamera = true
                    } label: {
                        Label("Tomar fotografía", systemImage: "camera")
                    }
                }

                if let receipt = addViewModel.processedReceipt {
                    Section("Última boleta agregada") {
                        ReceiptSummaryView(receipt: receipt)
                    }
                }
            }
            .navigationTitle("Nueva boleta")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        showingDocumentPicker = false
                        showingPhotoPicker = false
                        showingCamera = false
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReceiptSummaryView: View {
    let receipt: Receipt

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(receipt.merchant.name ?? "Comercio sin nombre")
                .font(.headline)
            if let date = receipt.purchaseDate {
                Text(date, style: .date)
                    .font(.subheadline)
            }
            if let total = receipt.effectiveTotal {
                Text("Total: \(NSDecimalNumber(decimal: total), formatter: NumberFormatter.currencyFormatter(code: receipt.currencyCode))")
                    .bold()
            }
            Text("Etiquetas: \(receipt.categories.map(\.displayName).joined(separator: ", "))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
