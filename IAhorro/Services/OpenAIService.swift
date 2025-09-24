import Foundation
import UIKit

struct OpenAIConfiguration {
    var apiKey: String
    var organization: String?
    var baseURL: URL

    init(apiKey: String, organization: String? = nil, baseURL: URL = URL(string: "https://api.openai.com/v1")!) {
        self.apiKey = apiKey
        self.organization = organization
        self.baseURL = baseURL
    }

    static func loadFromInfoPlist() -> OpenAIConfiguration? {
        guard let dict = Bundle.main.infoDictionary,
              let key = dict["OPENAI_API_KEY"] as? String,
              !key.isEmpty else { return nil }
        let organization = dict["OPENAI_ORG_ID"] as? String
        return .init(apiKey: key, organization: organization)
    }
}

protocol ReceiptAnalyzing {
    func analyzeReceipt(mediaData: Data, mediaType: Receipt.MediaType, userDescription: String?, location: Geolocation?) async throws -> ReceiptAnalysisResult
}

protocol ReceiptAnswering {
    func answerQuestion(query: String, receipts: [Receipt]) async throws -> String
}

final class OpenAIService {
    enum ServiceError: LocalizedError {
        case missingConfiguration
        case unexpectedResponse
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "No se encontró la configuración de OpenAI."
            case .unexpectedResponse:
                return "La respuesta del servicio de IA no es válida."
            case .decodingFailed:
                return "No se pudo decodificar la respuesta del servicio de IA."
            }
        }
    }

    private let configuration: OpenAIConfiguration
    private let session: URLSession

    init(configuration: OpenAIConfiguration? = OpenAIConfiguration.loadFromInfoPlist(), session: URLSession = .shared) throws {
        guard let configuration else {
            throw ServiceError.missingConfiguration
        }
        self.configuration = configuration
        self.session = session
    }

    // MARK: - Public API

    func analyzeReceipt(mediaData: Data, mediaType: Receipt.MediaType, userDescription: String?, location: Geolocation?) async throws -> ReceiptAnalysisResult {
        let boundary = UUID().uuidString
        var request = URLRequest(url: configuration.baseURL.appendingPathComponent("/assistants/receipts:analyze"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        if let organization = configuration.organization {
            request.setValue(organization, forHTTPHeaderField: "OpenAI-Organization")
        }

        let body = try buildMultipartBody(
            boundary: boundary,
            mediaData: mediaData,
            mediaType: mediaType,
            userDescription: userDescription,
            location: location
        )
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw ServiceError.unexpectedResponse
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(ReceiptAnalysisResult.self, from: data)
        } catch {
            throw ServiceError.decodingFailed
        }
    }

    func answerQuestion(query: String, receipts: [Receipt]) async throws -> String {
        var request = URLRequest(url: configuration.baseURL.appendingPathComponent("/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        if let organization = configuration.organization {
            request.setValue(organization, forHTTPHeaderField: "OpenAI-Organization")
        }

        let prompt = buildQueryPrompt(query: query, receipts: receipts)
        let payload = ChatCompletionPayload(model: "gpt-4o-mini", messages: prompt)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw ServiceError.unexpectedResponse
        }
        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let message = completion.choices.first?.message.content else {
            throw ServiceError.unexpectedResponse
        }
        return message
    }

    // MARK: - Multipart helpers

    private func buildMultipartBody(boundary: String, mediaData: Data, mediaType: Receipt.MediaType, userDescription: String?, location: Geolocation?) throws -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        var metadata: [String: Any] = [
            "media_type": mediaType.rawValue
        ]
        if let userDescription, !userDescription.isEmpty {
            metadata["user_description"] = userDescription
        }
        if let location {
            metadata["location"] = ["latitude": location.latitude, "longitude": location.longitude]
        }

        let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"metadata\"\r\n")
        body.appendString("Content-Type: application/json\r\n\r\n")
        body.append(metadataData)
        body.appendString(lineBreak)

        let filename = "receipt.\(mediaType == .pdf ? "pdf" : "jpg")"
        let mimeType = mediaType == .pdf ? "application/pdf" : "image/jpeg"

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(mediaData)
        body.appendString(lineBreak)
        body.appendString("--\(boundary)--\r\n")
        return body
    }

    private func buildQueryPrompt(query: String, receipts: [Receipt]) -> [ChatMessage] {
        let systemMessage = ChatMessage(role: "system", content: "Eres un asistente financiero que responde en español con resúmenes claros y cálidos. Usa las boletas proporcionadas para responder.")
        let contextBlocks = receipts.map { receipt -> String in
            let formatter = ISO8601DateFormatter()
            let purchaseDate = receipt.purchaseDate.flatMap { formatter.string(from: $0) } ?? "desconocida"
            let total = receipt.effectiveTotal?.description ?? "-"
            let categories = receipt.categories.map(\.displayName).joined(separator: ", ")
            return "Boleta #\(receipt.id.uuidString) | Comercio: \(receipt.merchant.name ?? "-") | Fecha: \(purchaseDate) | Total: \(total) \(receipt.currencyCode) | Categorías: \(categories) | Palabras clave: \(receipt.keywords.joined(separator: ", ")) | Notas: \(receipt.notes ?? "-" )"
        }

        let userContent = (["Consulta: \(query)"] + contextBlocks).joined(separator: "\n")
        let userMessage = ChatMessage(role: "user", content: userContent)
        return [systemMessage, userMessage]
    }
}

extension OpenAIService: ReceiptAnalyzing, ReceiptAnswering {}

// MARK: - Chat Completion Payload

private struct ChatCompletionPayload: Encodable {
    struct Message: Encodable {
        var role: String
        var content: String
    }

    var model: String
    var messages: [ChatMessage]
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        var message: ChatMessage
    }

    var choices: [Choice]
}

struct ChatMessage: Codable {
    var role: String
    var content: String
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
