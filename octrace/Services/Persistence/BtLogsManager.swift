import Foundation

class BtLogsManager {
    
    private static let path = DataManager.docsDir.appendingPathComponent("bt-logs").path
    
    private init() {
    }
    
    static var logs: [BtLogItem] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [] }
            do {
                return try PropertyListDecoder().decode([BtLogItem].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return []
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: path)
                
                if let logsViewController = BtLogsViewController.instance {
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
    
    static func removeOldItems() {
        let expirationDate = DataManager.expirationDate()
        
        let newItems = logs.filter { $0.date > expirationDate }
        
        logs = newItems
    }

    static func append(tag: String, text: String) {
        var newItems = logs
        
        newItems.append(BtLogItem(tag: tag, text: text))
        
        logs = newItems
    }
    
}

struct BtLogItem: Codable {
    let tag: String
    let text: String
    let date: Date
    
    init(tag: String, text: String) {
        self.tag = tag
        self.text = text
        date = Date()
    }
}
