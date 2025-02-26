import Foundation
import SwiftUI

class PreferencesViewModel: ObservableObject {
    @Published var apiKey: String = ""
    
    private let apiKeyKey = "GeminiAPIKey"
    private let keychainService = "com.photorenamer.apikey"
    
    init() {
        loadSettings()
        
        if apiKey.isEmpty {
            loadAPIKeyFromEnv()
        }
    }
    
    private func loadAPIKeyFromEnv() {
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil),
           let contents = try? String(contentsOfFile: envPath, encoding: .utf8) {
            let lines = contents.components(separatedBy: .newlines)
            for line in lines {
                let components = line.components(separatedBy: "=")
                if components.count == 2 && components[0] == "GEMINI_API_KEY" {
                    apiKey = components[1].trimmingCharacters(in: .whitespaces)
                    saveSettings()
                    break
                }
            }
        }
    }
    
    func loadSettings() {
        do {
            if let savedKey = try KeychainManager.retrieveAPIKey() {
                apiKey = savedKey
            }
        } catch {
            print("API anahtarı yüklenirken hata oluştu: \(error)")
        }
    }
    
    func saveSettings() {
        do {
            try KeychainManager.saveAPIKey(apiKey)
            NotificationCenter.default.post(name: Notification.Name("APIKeyChanged"), object: nil)
        } catch {
            print("API anahtarı kaydedilirken hata oluştu: \(error)")
        }
    }
}