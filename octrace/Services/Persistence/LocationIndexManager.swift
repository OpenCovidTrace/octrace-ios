import Foundation
import CoreLocation

class LocationIndexManager {
    
    private static let keysIndexPath = DataManager.docsDir.appendingPathComponent("keys-index").path
    private static let tracksIndexPath = DataManager.docsDir.appendingPathComponent("tracks-index").path
    
    private init() {
    }
    
    static var keysIndex: [LocationIndex: Int64] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: keysIndexPath) as? Data else {
                return [:]
            }
            
            do {
                return try PropertyListDecoder().decode([LocationIndex: Int64].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return [:]
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: keysIndexPath)
            } catch {
                print("Save Failed")
            }
        }
    }
    
    static func updateKeysIndex(_ index: LocationIndex) {
        var newIndex = keysIndex
        
        newIndex[index] = Date.timestamp()
        
        keysIndex = newIndex
    }
    
    static var tracksIndex: [LocationIndex: Int64] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: tracksIndexPath) as? Data else {
                return [:]
            }
            
            do {
                return try PropertyListDecoder().decode([LocationIndex: Int64].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return [:]
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: tracksIndexPath)
            } catch {
                print("Save Failed")
            }
        }
    }
    
    static func updateTracksIndex(_ index: LocationIndex) {
        var newIndex = tracksIndex
        
        newIndex[index] = Date.timestamp()
        
        tracksIndex = newIndex
    }
    
}

struct LocationIndex: Codable, Hashable {
    
    static let diff = 0.25 // ~ 25km
    static let precision = 10.0 // ~ 10km square side per index
    
    let latIdx: Int
    let lngIdx: Int
    
    init(_ location: CLLocation) {
        latIdx = Int(round(location.coordinate.latitude * LocationIndex.precision))
        lngIdx = Int(round(location.coordinate.longitude * LocationIndex.precision))
    }
    
}
