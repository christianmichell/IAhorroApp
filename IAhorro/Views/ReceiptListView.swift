import SwiftUI
import UIKit

struct ReceiptListView: View {
    @ObservedObject var viewModel: ReceiptListViewModel
    let receiptStore: ReceiptStore
    @State private var showingAddSheet = false
    @State private var showingDocumentPicker = false
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @StateObject private var addViewModel: AddReceiptViewModel
    @StateObject private var locationProvider = LocationProvider()
    init(viewModel: ReceiptListViewModel, processingService: ReceiptProcessingServiceProtocol, receiptStore: ReceiptStore) {
        self.viewModel = viewModel
        self.receiptStore = receiptStore
        _addViewModel = StateObject(wrappedValue: AddReceiptViewModel(receiptStore: receiptStore, processingService: processingService))
    }

    var body: some View {
        List {
            if viewModel.filteredReceipts.isEmpty {
                ContentUnavailableView("Sin boletas", systemImage: "doc") {
                    Text("Agrega tu primera boleta desde el botón +.")
                }
            } else {
                ForEach(viewModel.filteredReceipts) { receipt in
                    NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                        ReceiptRowView(receipt: receipt)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        let receiptsToDelete = indexSet.compactMap { index in
                            viewModel.filteredReceipts.indices.contains(index) ? viewModel.filteredReceipts[index] : nil
                        }
                        for receipt in receiptsToDelete {
                            try? await viewModel.delete(receipt)
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar por palabras clave o comercio")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Agregar boleta")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddReceiptSheet(addViewModel: addViewModel, showingDocumentPicker: $showingDocumentPicker, showingPhotoPicker: $showingPhotoPicker, showingCamera: $showingCamera)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                Task {
                    await handlePickedURL(url)
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker { image, name in
                Task {
                    await handlePickedImage(image, suggestedName: name)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { image in
                Task {
                    await handlePickedImage(image, suggestedName: "captura")
                }
            }
        }
        .onAppear {
            locationProvider.requestLocation()
        }
        .onReceive(locationProvider.$location) { location in
            addViewModel.location = location
        }
        .onChange(of: showingDocumentPicker) { newValue in
            if newValue { showingAddSheet = false }
        }
        .onChange(of: showingPhotoPicker) { newValue in
            if newValue { showingAddSheet = false }
        }
        .onChange(of: showingCamera) { newValue in
            if newValue { showingAddSheet = false }
        }
        .alert("Error", isPresented: Binding(get: { addViewModel.errorMessage != nil }, set: { _ in addViewModel.errorMessage = nil })) {
            Button("Entendido", role: .cancel) {}
        } message: {
            if let message = addViewModel.errorMessage {
                Text(message)
            }
        }
    }

    private func handlePickedURL(_ url: URL) async {
        showingAddSheet = false
        showingDocumentPicker = false
        do {
            let data = try Data(contentsOf: url)
            let mediaType: Receipt.MediaType = (url.pathExtension.lowercased() == "pdf") ? .pdf : .image
            await addViewModel.handlePickedMedia(data, mediaType: mediaType, originalFileName: url.lastPathComponent)
        } catch {
            addViewModel.errorMessage = error.localizedDescription
        }
    }

    private func handlePickedImage(_ image: UIImage, suggestedName: String) async {
        showingAddSheet = false
        showingPhotoPicker = false
        showingCamera = false
        guard let data = image.jpegData(compressionQuality: 0.95) else { return }
        await addViewModel.handlePickedMedia(data, mediaType: .image, originalFileName: "\(suggestedName).jpg")
    }
}
