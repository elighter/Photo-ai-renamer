import Foundation
import SwiftUI

class PreferencesViewModel: ObservableObject {
    @Published var apiKey: String = ""
    
    private let apiKeyKey = "GeminiAPIKey"
    private let keychainService = "com.photorenamer.apikey"
    
    init() {
        // Başlatıldığında API anahtarını yükle
        loadSettings()
        
        // API anahtarı boşsa, varsayılan anahtarı ayarla
        if apiKey.isEmpty {
            apiKey = "AIzaSyAMUy5aYcYc0kr4w_h73E1eAKau-g0l9nY"
            saveSettings()
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
            // API anahtarını servis için güncelle
            NotificationCenter.default.post(name: Notification.Name("APIKeyChanged"), object: nil)
        } catch {
            print("API anahtarı kaydedilirken hata oluştu: \(error)")
        }
    }
}