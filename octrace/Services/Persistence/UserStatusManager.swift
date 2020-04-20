import Foundation

class UserStatusManager {
    
    private static let kUserStatus = "kUserStatus"
    
    static let healthy = "healthy"
    static let symptoms = "symptoms"
    
    private init() {
    }

    static var status: String {
        get {
            UserDefaults.standard.string(forKey: kUserStatus) ?? healthy
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: kUserStatus)
        }
    }
    
    static func sick() -> Bool {
        return status == symptoms
    }
    
}
