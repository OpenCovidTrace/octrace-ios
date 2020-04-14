import Foundation

class EncryptionKeysManager {
        
    private static let path = DataManager.docsDir.appendingPathComponent("encryption-keys").path
    
    private init() {
    }
    
    static func removeOldKeys() {
        let expirationTimestamp = DataManager.expirationTimestamp()
        
        let remainingKeys = getEncryptionKeys().filter { (tst, _) in
            tst > expirationTimestamp
        }
        
        saveEncryptionKeys(remainingKeys)
    }
    
    static func generateKey(for tst: Int64) -> Data {
        let key = SecurityUtil.generateKey()
        
        var keys = getEncryptionKeys()
        keys[tst] = key
        
        saveEncryptionKeys(keys)
        
        return key
    }
    
    static func getKey(for tst: Int64) -> Data? {
        return getEncryptionKeys()[tst]
    }
    
    private static func getEncryptionKeys() -> [Int64:Data] {
        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [:] }
        do {
            return try PropertyListDecoder().decode([Int64:Data].self, from: data)
        } catch {
            print("Retrieve Failed")
            
            return [:]
        }
    }
    
    private static func saveEncryptionKeys(_ encryptionKeys: [Int64:Data]) {
        do {
            let data = try PropertyListEncoder().encode(encryptionKeys)
            NSKeyedArchiver.archiveRootObject(data, toFile: path)
        } catch {
            print("Save Failed")
        }
    }
    
}
