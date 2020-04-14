import Foundation

class DataManager {
    
    private init() {}
    
    static let maxDays = 14
    
    static let docsDir = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static func expirationTimestamp() -> Int64 {
        return Calendar.current.date(byAdding: .day, value: -maxDays, to: Date())!.timestamp()
    }
    
}
