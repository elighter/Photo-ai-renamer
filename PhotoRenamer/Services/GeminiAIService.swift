import Foundation
import AppKit

class GeminiAIService {
    // API anahtarı için keychain bilgileri
    private let apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent"
    
    enum GeminiError: Error {
        case invalidImageData
        case networkError(String)
        case apiError(String)
        case parsingError
        case missingApiKey
    }
    
    init() {
        // API anahtarı değiştiğinde bildirim dinleyicisi
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAPIKeyChanged),
            name: Notification.Name("APIKeyChanged"),
            object: nil
        )
    }
    
    @objc private func handleAPIKeyChanged() {
        // API anahtarı değiştiğinde yapılacak işlemler
        print("API anahtarı güncellendi")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Keychain'den API anahtarını al
    private func getAPIKey() -> String? {
        do {
            return try KeychainManager.retrieveAPIKey()
        } catch {
            print("API anahtarı alınırken hata: \(error)")
            return nil
        }
    }
    
    // Resmi analiz et ve önerilen dosya adını döndür
    func analyzeImage(url: URL) async throws -> (description: String, suggestedName: String) {
        // API anahtarının var olduğundan emin ol
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            throw GeminiError.missingApiKey
        }
        
        // Resmi yükle ve base64'e dönüştür
        guard let imageData = try? Data(contentsOf: url),
              let image = NSImage(data: imageData),
              let base64Image = convertImageToBase64(image) else {
            throw GeminiError.invalidImageData
        }
        
        // API isteği için JSON oluştur
        let requestBody = createRequestBody(base64Image: base64Image)
        
        // API isteği yap
        let (data, response) = try await makeApiRequest(with: requestBody, apiKey: apiKey)
        
        // Yanıtı işle
        return try parseApiResponse(data: data, response: response)
    }
    
    // NSImage'ı base64'e dönüştür
    private func convertImageToBase64(_ image: NSImage) -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            return nil
        }
        
        return jpegData.base64EncodedString()
    }
    
    // API isteği gövdesini oluştur
    private func createRequestBody(base64Image: String) -> [String: Any] {
        return [
            "contents": [
                [
                    "parts": [
                        [
                            "text": "Bu fotoğrafı detaylı bir şekilde analiz et ve açıkla. Ardından, fotoğrafın içeriğini yansıtan uygun bir dosya adı öner. Dosya adı için noktalama işaretleri veya özel karakterler kullanma. Yanıtını şu formatta ver: AÇIKLAMA: [fotoğrafın detaylı açıklaması] ÖNERİLEN_DOSYA_ADI: [önerilen dosya adı]"
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generation_config": [
                "temperature": 0.4,
                "max_output_tokens": 800
            ]
        ]
    }
    
    // API isteği yap
    private func makeApiRequest(with requestBody: [String: Any], apiKey: String) async throws -> (Data, URLResponse) {
        let urlString = "\(apiUrl)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.networkError("Geçersiz URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw GeminiError.networkError("İstek JSON serileştirme hatası: \(error.localizedDescription)")
        }
        
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiError.networkError("Ağ hatası: \(error.localizedDescription)")
        }
    }
    
    // API yanıtını ayrıştır
    private func parseApiResponse(data: Data, response: URLResponse) throws -> (description: String, suggestedName: String) {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError("Geçersiz HTTP yanıtı")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Bilinmeyen hata"
            throw GeminiError.apiError("API Hatası (\(httpResponse.statusCode)): \(errorMessage)")
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                throw GeminiError.parsingError
            }
            
            // AI yanıtını ayrıştır
            return extractDescriptionAndSuggestedName(from: text)
        } catch {
            throw GeminiError.parsingError
        }
    }
    
    // AI yanıtını işle ve açıklama ve önerilen dosya adını çıkar
    private func extractDescriptionAndSuggestedName(from text: String) -> (description: String, suggestedName: String) {
        // Varsayılan değerler
        var description = text
        var suggestedName = "yeni_fotograf"
        
        // AI yanıtını ayrıştır
        if let descriptionRange = text.range(of: "AÇIKLAMA:", options: .caseInsensitive) {
            let afterDescription = text[descriptionRange.upperBound...]
            
            if let nameRange = afterDescription.range(of: "ÖNERİLEN_DOSYA_ADI:", options: .caseInsensitive) {
                // Açıklamayı ve önerilen dosya adını çıkar
                description = String(afterDescription[..<nameRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                suggestedName = String(afterDescription[nameRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Dosya adını temizle
        suggestedName = suggestedName.replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
        suggestedName = suggestedName.replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "", options: .regularExpression)
        
        return (description, suggestedName)
    }
}