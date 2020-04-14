import Foundation

class OnboardingManager {
    
    private static let OnboardingArchiveURL = DataManager.docsDir.appendingPathComponent("onboarding")
    
    private init() {
    }
    
    static func doComplete() {
        NSKeyedArchiver.archiveRootObject(true, toFile: OnboardingManager.OnboardingArchiveURL.path)
    }
    
    static func isComplete() -> Bool {
        return NSKeyedUnarchiver.unarchiveObject(withFile: OnboardingManager.OnboardingArchiveURL.path) as? Bool ?? false
    }
    
}
