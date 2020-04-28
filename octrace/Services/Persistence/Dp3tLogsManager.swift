import Foundation

class Dp3tLogsManager {
    
    private static let path = DataManager.docsDir.appendingPathComponent("dp3t-logs").path
    
    private init() {
    }
    
    static var logs: [Dp3tLogItem] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [] }
            do {
                return try PropertyListDecoder().decode([Dp3tLogItem].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return []
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: path)
                
                if let logsViewController = Dp3tLogsViewController.instance {
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

    static func append(_ text: String) {
        var newItems = logs
        
        newItems.append(Dp3tLogItem(text))
        
        logs = newItems
    }
    
}

struct Dp3tLogItem: Codable {
    let text: String
    let date: Date
    
    init(_ text: String) {
        self.text = text
        date = Date()
    }
}
