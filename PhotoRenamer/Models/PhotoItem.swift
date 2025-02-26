import Foundation
import AppKit

struct PhotoItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let originalName: String
    let fullImage: NSImage?
    let thumbnail: NSImage?
    var suggestedName: String?
    var aiDescription: String?
    var isProcessing: Bool = false
    var isRenamed: Bool = false
    var error: String?
    
    init(url: URL) {
        self.url = url
        self.originalName = url.lastPathComponent
        
        // Görüntüyü yükle
        if let image = NSImage(contentsOf: url) {
            self.fullImage = image
            
            // Küçük resim (thumbnail) oluştur
            let thumbnailSize = NSSize(width: 120, height: 120)
            self.thumbnail = image.resized(to: thumbnailSize)
        } else {
            self.fullImage = nil
            self.thumbnail = nil
        }
    }
    
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// NSImage boyutlandırma uzantısı
extension NSImage {
    func resized(to newSize: NSSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        
        newImage.unlockFocus()
        return newImage
    }
} 