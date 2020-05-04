import Foundation

class DataManager {
    
    private init() {}
    
    static let maxDays = 14
    
    static let docsDir = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static func expirationDate() -> Date {
        return Calendar.current.date(byAdding: .day, value: -maxDays, to: Date())!
    }
    
    static func expirationTimestamp() -> Int64 {
        expirationDate().timestamp()
    }
    
    static func expirationDay() -> Int {
        CryptoUtil.getDayNumber(for: expirationDate())
    }
    
}
