import Foundation

class KeyManager {
    
    private static let path = DataManager.docsDir.appendingPathComponent("key").path
    
    private init() {
    }
    
    static func setTracingKey(_ data: Data) {
        NSKeyedArchiver.archiveRootObject(data, toFile: path)
    }
    
    static func hasKey() -> Bool {
        return getTracingKey() != nil
    }
    
    static func getTracingKey() -> Data? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data
    }
    
    static func getDailyKey(for dayNumber: Int) -> Data {
        let tracingKey = getTracingKey()!
        
        return SecurityUtil.getDailyKey(tracingKey, dayNumber)
    }
    
    static func getSecretDailyKey(for dayNumber: Int) -> String {
        let tracingKey = getTracingKey()!
        
        return SecurityUtil.getSecretDailyKey(tracingKey, dayNumber)
    }
    
    static func getLatestDailyKeys() -> [Data] {
        let tracingKey = getTracingKey()!
        var result: [Data] = []
        
        let dayNumber = SecurityUtil.currentDayNumber()
        
        var offset = 0
        while offset < DataManager.maxDays {
            result.append(SecurityUtil.getDailyKey(tracingKey, dayNumber - offset))
            
            offset += 1
        }
        
        return result
    }
    
    static func getLatestSecretDailyKeys() -> [String] {
        let tracingKey = getTracingKey()!
        var result: [String] = []
        
        let dayNumber = SecurityUtil.currentDayNumber()
        
        var offset = 0
        while offset < DataManager.maxDays {
            result.append(SecurityUtil.getSecretDailyKey(tracingKey, dayNumber - offset))
            
            offset += 1
        }
        
        return result
    }
    
}
