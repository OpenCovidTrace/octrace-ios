import Foundation

class EncryptionKeysManager {
    
    private static let path = DataManager.docsDir.appendingPathComponent("encryption-keys").path
    
    private init() {
    }
    
    static var encryptionKeys: [Int64: Data] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [:] }
            do {
                return try PropertyListDecoder().decode([Int64: Data].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return [:]
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: path)
            } catch {
                print("Save Failed")
            }
        }
    }
    
    static func removeOldKeys() {
        let expirationTimestamp = DataManager.expirationTimestamp()
        
        let remainingKeys = encryptionKeys.filter { (tst, _) in
            tst > expirationTimestamp
        }
        
        encryptionKeys = remainingKeys
    }
    
    static func generateKey(for tst: Int64) -> Data {
        let key = CryptoUtil.generateKey()
        
        var newKeys = encryptionKeys
        newKeys[tst] = key
        
        encryptionKeys = newKeys
        
        return key
    }
    
}
