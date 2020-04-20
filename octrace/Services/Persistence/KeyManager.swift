import Foundation

class KeyManager {
    
    private static let kTracingKey = "kTracingKey"
    
    private init() {
    }
    
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
    
    static func getDailyKey(for dayNumber: Int) -> Data {
        return SecurityUtil.getDailyKey(tracingKey!, dayNumber)
    }
    
    static func getSecretDailyKey(for dayNumber: Int) -> String {
        return SecurityUtil.getSecretDailyKey(tracingKey!, dayNumber)
    }
    
    static func getLatestDailyKeys() -> [Data] {
        var result: [Data] = []
        
        let dayNumber = SecurityUtil.currentDayNumber()
        
        var offset = 0
        while offset < DataManager.maxDays {
            result.append(SecurityUtil.getDailyKey(tracingKey!, dayNumber - offset))
            
            offset += 1
        }
        
        return result
    }
    
    static func getLatestSecretDailyKeys() -> [String] {
        var result: [String] = []
        
        let dayNumber = SecurityUtil.currentDayNumber()
        
        var offset = 0
        while offset < DataManager.maxDays {
            result.append(SecurityUtil.getSecretDailyKey(tracingKey!, dayNumber - offset))
            
            offset += 1
        }
        
        return result
    }
    
}
