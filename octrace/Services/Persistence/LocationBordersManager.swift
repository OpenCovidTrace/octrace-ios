import Foundation
import CoreLocation

class LocationBordersManager {
    
    private static let locationBordersPath = DataManager.docsDir.appendingPathComponent("location-borders").path
    
    private init() {
    }
    
    static var locationBorders: [Int:LocationBorder] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: locationBordersPath) as? Data else { return [:] }
            do {
                return try PropertyListDecoder().decode([Int:LocationBorder].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return [:]
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: locationBordersPath)
            } catch {
                print("Save Failed")
            }
        }
    }
    
    static func removeOldLocationBorders() {
        let lastDay = SecurityUtil.currentDayNumber() - DataManager.maxDays
        
        let oldBorders = locationBorders
        
        var newBorders: [Int:LocationBorder] = [:]
                
        oldBorders.keys.forEach { dayNumber in
            if dayNumber > lastDay {
                newBorders[dayNumber] = oldBorders[dayNumber]
            }
        }
        
        locationBorders = newBorders
    }
    
    static func updateLocationBorders(_ location: CLLocation) {
        var newBorders = locationBorders
        
        let currentDayNumber = SecurityUtil.currentDayNumber()
        
        if let currentBorder = newBorders[currentDayNumber] {
            currentBorder.update(location)
        } else {
            newBorders[currentDayNumber] = LocationBorder(location)
        }
        
        locationBorders = newBorders
    }
    
}
