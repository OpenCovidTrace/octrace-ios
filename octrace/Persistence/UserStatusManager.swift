import Foundation

class UserStatusManager {
    
    static let healthy = "healthy"
    static let symptoms = "symptoms"
    
    private static let path = DataManager.docsDir.appendingPathComponent("user-status").path
    
    private init() {
    }
    
    static func setStatus(status: String) {
        NSKeyedArchiver.archiveRootObject(status, toFile: path)
    }
    
    static func sick() -> Bool {
        return getStatus() == symptoms
    }
    
    static func getStatus() -> String {
        return NSKeyedUnarchiver.unarchiveObject(withFile: path) as? String ?? healthy
    }
    
}
