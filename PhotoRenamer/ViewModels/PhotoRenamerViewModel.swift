import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import UserNotifications

class PhotoRenamerViewModel: ObservableObject {
    @Published var selectedImages: [PhotoItem] = []
    @Published var currentSelectedImage: PhotoItem?
    @Published var isProcessing: Bool = false
    
    private let geminiService = GeminiAIService()
    
    // Sürükle-bırak işlemi için
    func handleDrop(providers: [NSItemProvider]) async {
        let supportedTypes = [UTType.image]
        
        for provider in providers {
            for type in supportedTypes {
                if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                    do {
                        let url = try await loadDroppedItem(provider: provider, typeIdentifier: type.identifier)
                        await addImageAndAnalyze(url: url)
                    } catch {
                        print("Dosya yüklenirken hata oluştu: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Dosya seçiciyi işleme
    func handleFileImport(result: Result<[URL], Error>) async {
        do {
            let urls = try result.get()
            for url in urls {
                if url.startAccessingSecurityScopedResource() {
                    await addImageAndAnalyze(url: url)
                    url.stopAccessingSecurityScopedResource()
                }
            }
        } catch {
            print("Dosya seçicisi hatası: \(error.localizedDescription)")
        }
    }
    
    // Yeni görüntü ekle ve analiz et
    @MainActor
    private func addImageAndAnalyze(url: URL) async {
        // Resmin daha önce eklenip eklenmediğini kontrol et
        guard !selectedImages.contains(where: { $0.url == url }) else { return }
        
        let photoItem = PhotoItem(url: url)
        var updatedItem = photoItem
        updatedItem.isProcessing = true
        selectedImages.append(updatedItem)
        
        if currentSelectedImage == nil {
            currentSelectedImage = updatedItem
        }
        
        // Resmi analiz et
        await analyzeImage(photoItem)
    }
    
    // Görüntüyü AI ile analiz et
    @MainActor
    private func analyzeImage(_ photoItem: PhotoItem) async {
        guard let index = selectedImages.firstIndex(where: { $0.id == photoItem.id }) else { return }
        
        selectedImages[index].isProcessing = true
        updateCurrentSelectedIfNeeded(photoItem)
        
        do {
            // Gemini AI servisi ile görüntü analizi yapılıyor
            let (description, suggestedName) = try await geminiService.analyzeImage(url: photoItem.url)
            
            // Sonuçları güncelle
            await MainActor.run {
                if let idx = self.selectedImages.firstIndex(where: { $0.id == photoItem.id }) {
                    self.selectedImages[idx].aiDescription = description
                    self.selectedImages[idx].suggestedName = suggestedName
                    self.selectedImages[idx].isProcessing = false
                    
                    // Mevcut seçili görüntüyü güncelle
                    self.updateCurrentSelectedIfNeeded(self.selectedImages[idx])
                }
            }
        } catch {
            await MainActor.run {
                if let idx = self.selectedImages.firstIndex(where: { $0.id == photoItem.id }) {
                    self.selectedImages[idx].error = error.localizedDescription
                    self.selectedImages[idx].isProcessing = false
                    self.updateCurrentSelectedIfNeeded(self.selectedImages[idx])
                }
            }
        }
    }
    
    // Tek bir görüntü için yeniden adlandır
    func renameSingleImage(_ photoItem: PhotoItem) {
        guard let index = selectedImages.firstIndex(where: { $0.id == photoItem.id }),
              let suggestedName = selectedImages[index].suggestedName,
              !selectedImages[index].isRenamed else { return }
        
        do {
            let newFileName = sanitizeFileName(suggestedName)
            _ = try renameFile(at: photoItem.url, to: newFileName) // _ kullanarak değeri yok sayıyoruz
            
            // UI güncelle
            selectedImages[index].isRenamed = true
            updateCurrentSelectedIfNeeded(selectedImages[index])
            
            // Kullanıcıya bildirim
            showNotification(title: "Yeniden Adlandırma Başarılı", message: "Dosya \(newFileName) olarak yeniden adlandırıldı")
        } catch {
            print("Yeniden adlandırma hatası: \(error.localizedDescription)")
            selectedImages[index].error = "Yeniden adlandırma hatası: \(error.localizedDescription)"
            updateCurrentSelectedIfNeeded(selectedImages[index])
        }
    }
    
    // Tüm seçili görüntüleri yeniden adlandır
    func renameAllImages() {
        isProcessing = true
        
        for photoItem in selectedImages where photoItem.suggestedName != nil && !photoItem.isRenamed {
            renameSingleImage(photoItem)
        }
        
        isProcessing = false
    }
    
    // Yeniden adlandırma önerisini yeniden oluştur
    @MainActor
    func regenerateSuggestion(for photoItem: PhotoItem) async {
        guard let index = selectedImages.firstIndex(where: { $0.id == photoItem.id }) else { return }
        
        selectedImages[index].isProcessing = true
        selectedImages[index].suggestedName = nil
        selectedImages[index].aiDescription = nil
        updateCurrentSelectedIfNeeded(selectedImages[index])
        
        await analyzeImage(photoItem)
    }
    
    // Seçili görüntüyü kaldır
    func removeImage(_ photoItem: PhotoItem) {
        selectedImages.removeAll(where: { $0.id == photoItem.id })
        
        // Eğer kaldırılan görüntü şu anda seçiliyse, başka bir görüntüyü seç
        if currentSelectedImage?.id == photoItem.id {
            currentSelectedImage = selectedImages.first
        }
    }
    
    // Mevcut seçili görüntüyü güncelle
    private func updateCurrentSelectedIfNeeded(_ photoItem: PhotoItem) {
        if currentSelectedImage?.id == photoItem.id,
           let updatedIndex = selectedImages.firstIndex(where: { $0.id == photoItem.id }) {
            currentSelectedImage = selectedImages[updatedIndex]
        }
    }
    
    // Sürükle-bırak edilen öğeyi yükle
    private func loadDroppedItem(provider: NSItemProvider, typeIdentifier: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let url = item as? URL else {
                    continuation.resume(throwing: NSError(domain: "PhotoRenamer", code: 1, userInfo: [NSLocalizedDescriptionKey: "URL yüklenemedi."]))
                    return
                }
                
                continuation.resume(returning: url)
            }
        }
    }
    
    // Dosya adını temizle
    private func sanitizeFileName(_ name: String) -> String {
        var sanitized = name
        let illegalCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        sanitized = sanitized.components(separatedBy: illegalCharacters).joined(separator: "_")
        
        // Uzunluğu sınırla
        if sanitized.count > 100 {
            sanitized = String(sanitized.prefix(100))
        }
        
        return sanitized
    }
    
    // Dosyayı yeniden adlandır
    private func renameFile(at url: URL, to newName: String) throws -> URL {
        let fileExtension = url.pathExtension
        let directory = url.deletingLastPathComponent()
        let newNameWithExtension = fileExtension.isEmpty ? newName : "\(newName).\(fileExtension)"
        let destinationURL = directory.appendingPathComponent(newNameWithExtension)
        
        // Eğer hedef dosya zaten varsa, benzersiz bir isim oluştur
        var finalDestinationURL = destinationURL
        var counter = 1
        
        while FileManager.default.fileExists(atPath: finalDestinationURL.path) {
            let uniqueName = "\(newName)_\(counter).\(fileExtension)"
            finalDestinationURL = directory.appendingPathComponent(uniqueName)
            counter += 1
        }
        
        try FileManager.default.moveItem(at: url, to: finalDestinationURL)
        return finalDestinationURL
    }
    
    // Kullanıcıya bildirim göster - UserNotifications framework kullanarak güncellendi
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, 
                                          content: content, 
                                          trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim hatası: \(error)")
            }
        }
    }
}