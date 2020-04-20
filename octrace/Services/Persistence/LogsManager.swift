import Foundation

class LogsManager {
    
    private static let path = DataManager.docsDir.appendingPathComponent("logs").path
    
    private init() {
    }
    
    static var logs: [LogItem] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [] }
            do {
                return try PropertyListDecoder().decode([LogItem].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return []
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: path)
                
                if let logsViewController = LogsViewController.instance {
                    logsViewController.refresh()
                }
            } catch {
                print("Save Failed")
            }
        }
    }
    
    static func clear() {
        logs = []
    }
    
    // TODO call this method
    static func removeOldItems() {
        let expirationDate = DataManager.expirationDate()
        
        let newItems = logs.filter { $0.date > expirationDate }
        
        logs = newItems
    }

    static func append(_ text: String) {
        var newItems = logs
        
        newItems.append(LogItem(text))
        
        logs = newItems
    }
    
}

struct LogItem : Codable {
    let text: String
    let date: Date
    
    init(_ text: String) {
        self.text = text
        date = Date()
    }
}
