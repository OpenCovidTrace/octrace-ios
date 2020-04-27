import Foundation

class KeyManager {
    
    private static let kTracingKey = "kTracingKey"
    private static let dailyKeysPath = DataManager.docsDir.appendingPathComponent("daily-keys").path
    
    private init() {
    }
    
    /// Used in AG spec v1 and as onboarding indicator
    static var tracingKey: Data? {
        get {
            UserDefaults.standard.data(forKey: kTracingKey)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: kTracingKey)
        }
    }
    
    static func hasKey() -> Bool {
        return tracingKey != nil
    }
    
    
    /// Used in AG spec v1.1
    static var dailyKeys: [Int: Data] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: dailyKeysPath) as? Data else { return [:] }
            do {
                return try PropertyListDecoder().decode([Int: Data].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return [:]
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: dailyKeysPath)
            } catch {
                print("Save Failed")
            }
        }
    }
    
}
