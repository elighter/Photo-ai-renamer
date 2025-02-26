import Foundation
import Security

class KeychainManager {
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
    }
    
    static let serviceName = "com.photorenamer.apikey"
    static let account = "GeminiAPIKey"
    
    static func saveAPIKey(_ apiKey: String) throws {
        // Verileri hazırla
        guard let passwordData = apiKey.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        // Anahtar var mı kontrol et
        if try retrieveAPIKey() != nil {
            // Varsa güncelle
            var attributesToUpdate = [String: AnyObject]()
            attributesToUpdate[kSecValueData as String] = passwordData as AnyObject
            
            let query: [String: AnyObject] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName as AnyObject,
                kSecAttrAccount as String: account as AnyObject
            ]
            
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            guard status == errSecSuccess else {
                throw KeychainError.unexpectedStatus(status)
            }
        } else {
            // Yoksa yeni oluştur
            let keychainItem: [String: AnyObject] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName as AnyObject,
                kSecAttrAccount as String: account as AnyObject,
                kSecValueData as String: passwordData as AnyObject
            ]
            
            let status = SecItemAdd(keychainItem as CFDictionary, nil)
            
            guard status == errSecSuccess else {
                throw KeychainError.unexpectedStatus(status)
            }
        }
    }
    
    static func retrieveAPIKey() throws -> String? {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        return password
    }
    
    static func deleteAPIKey() throws {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName as AnyObject,
            kSecAttrAccount as String: account as AnyObject
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
} 