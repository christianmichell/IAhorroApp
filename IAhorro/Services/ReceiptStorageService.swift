import Foundation
import UIKit
import UniformTypeIdentifiers

actor ReceiptStorageService {
    enum StorageError: LocalizedError {
        case failedToCreateDirectory
        case failedToPersistMetadata
        case receiptNotFound
        case failedToDelete

        var errorDescription: String? {
            switch self {
            case .failedToCreateDirectory:
                return "No se pudo crear el directorio de almacenamiento."
            case .failedToPersistMetadata:
                return "No se pudo guardar la información de la boleta."
            case .receiptNotFound:
                return "Boleta no encontrada."
            case .failedToDelete:
                return "No se pudo eliminar el archivo asociado."
            }
        }
    }

    private struct MetadataEnvelope: Codable {
        var receipts: [Receipt]
    }

    private let fileManager: FileManager
    private let metadataURL: URL
    private let receiptsDirectoryURL: URL
    private let thumbnailsDirectoryURL: URL
    private var cachedReceipts: [Receipt] = []

    init(fileManager: FileManager = .default, containerURL: URL? = nil) async throws {
        self.fileManager = fileManager
        let container: URL
        if let containerURL {
            container = containerURL
            try fileManager.createDirectory(at: container, withIntermediateDirectories: true, attributes: nil)
        } else {
            container = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
        receiptsDirectoryURL = container.appendingPathComponent("Receipts", isDirectory: true)
        thumbnailsDirectoryURL = container.appendingPathComponent("Thumbnails", isDirectory: true)
        metadataURL = container.appendingPathComponent("receipts.json", conformingTo: .json)

        try createDirectoriesIfNeeded()
        try await loadMetadataIfNeeded()
    }

    // MARK: - Public API

    func loadReceipts() -> [Receipt] {
        cachedReceipts.sorted(by: { ($0.purchaseDate ?? $0.createdAt) > ($1.purchaseDate ?? $1.createdAt) })
    }

    func receipt(withId id: Receipt.ID) -> Receipt? {
        cachedReceipts.first(where: { $0.id == id })
    }

    func persist(_ receipt: Receipt, data: Data, thumbnail: UIImage?) async throws {
        let receiptURL = receiptsDirectoryURL.appendingPathComponent(receipt.fileName)
        try data.write(to: receiptURL, options: .atomic)

        var updatedReceipt = receipt
        updatedReceipt.fileURL = receiptURL

        if let thumbnail {
            let thumbnailURL = thumbnailsDirectoryURL.appendingPathComponent("\(receipt.id.uuidString).jpg")
            guard let jpeg = thumbnail.jpegData(compressionQuality: 0.8) else {
                throw StorageError.failedToPersistMetadata
            }
            try jpeg.write(to: thumbnailURL, options: .atomic)
            updatedReceipt.thumbnailURL = thumbnailURL
        }

        if let index = cachedReceipts.firstIndex(where: { $0.id == updatedReceipt.id }) {
            cachedReceipts[index] = updatedReceipt
        } else {
            cachedReceipts.append(updatedReceipt)
        }

        try persistMetadata()
    }

    func delete(_ receiptID: Receipt.ID) async throws {
        guard let index = cachedReceipts.firstIndex(where: { $0.id == receiptID }) else {
            throw StorageError.receiptNotFound
        }
        let receipt = cachedReceipts.remove(at: index)

        do {
            try fileManager.removeItem(at: receipt.fileURL)
            if let thumbnailURL = receipt.thumbnailURL {
                try? fileManager.removeItem(at: thumbnailURL)
            }
        } catch {
            throw StorageError.failedToDelete
        }

        try persistMetadata()
    }

    // MARK: - Helpers

    private func createDirectoriesIfNeeded() throws {
        try fileManager.createDirectory(at: receiptsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: thumbnailsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    private func loadMetadataIfNeeded() async throws {
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            cachedReceipts = []
            return
        }
        let data = try Data(contentsOf: metadataURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(MetadataEnvelope.self, from: data)
        cachedReceipts = envelope.receipts
    }

    private func persistMetadata() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(MetadataEnvelope(receipts: cachedReceipts))
        do {
            try data.write(to: metadataURL, options: .atomic)
        } catch {
            throw StorageError.failedToPersistMetadata
        }
    }
}
