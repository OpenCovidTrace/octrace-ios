import Foundation

class OnboardingManager {
    
    private static let kOnboadringStatus = "kOnboadringStatus"
    
    private init() {
    }

    static var status: String {
        get {
            UserDefaults.standard.string(forKey: kOnboadringStatus) ?? OnboardingStage.welcome
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: kOnboadringStatus)
        }
    }
    
    static func isComplete() -> Bool {
        return status == OnboardingStage.complete
    }
    
}

struct OnboardingStage {
    
    private init() {}
    
    static let welcome = "welcome"
    static let bluetooth = "bluetooth"
    static let location = "location"
    static let notifications = "notifications"
    static let complete = "complete"
    
}
