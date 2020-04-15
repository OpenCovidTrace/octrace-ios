import Foundation
import Alamofire
import CoreLocation

class KeysManager {
    
    private static let lastUpdatePath = DataManager.docsDir.appendingPathComponent("keys-last-update").path
    
    private static let lastUploadPath = DataManager.docsDir.appendingPathComponent("keys-last-updload").path
    
    private static let locationBordersPath = DataManager.docsDir.appendingPathComponent("location-borders").path
    
    private init() {
    }
    
    static func removeOldLocationBorders() {
        let lastDay = SecurityUtil.currentDayNumber() - DataManager.maxDays
        
        let oldBorders = getLocationBorders()
        
        var newBorders: [Int:LocationBorder] = [:]
                
        oldBorders.keys.forEach { dayNumber in
            if dayNumber > lastDay {
                newBorders[dayNumber] = oldBorders[dayNumber]
            }
        }
        
        saveLocationBorders(newBorders)
    }
    
    static func getLocationBorders() -> [Int:LocationBorder] {
        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: locationBordersPath) as? Data else { return [:] }
        do {
            return try PropertyListDecoder().decode([Int:LocationBorder].self, from: data)
        } catch {
            print("Retrieve Failed")
            
            return [:]
        }
    }
    
    static func updateLocationBorders(_ location: CLLocation) {
        var borders = getLocationBorders()
        
        let currentDayNumber = SecurityUtil.currentDayNumber()
        
        if let currentBorder = borders[currentDayNumber] {
            currentBorder.update(location)
        } else {
            borders[currentDayNumber] = LocationBorder(location)
        }
        
        saveLocationBorders(borders)
    }
    
    private static func saveLocationBorders(_ borders: [Int:LocationBorder]) {
        do {
            let data = try PropertyListEncoder().encode(borders)
            NSKeyedArchiver.archiveRootObject(data, toFile: locationBordersPath)
        } catch {
            print("Save Failed")
        }
    }
    
    static func setUpdated() {
        NSKeyedArchiver.archiveRootObject(Date.timestamp(), toFile: lastUpdatePath)
    }
    
    static func lastUpdateTimestamp() -> Int64 {
        return NSKeyedUnarchiver.unarchiveObject(withFile: lastUpdatePath) as? Int64 ?? 0
    }
    
    static func uploadNewKeys() {
        let lastUpload = lastUploadDayNumber()
        
        // Uploading after EOD to include widest borders
        let previousDayNumber = SecurityUtil.currentDayNumber() - 1
        
        if lastUpload == previousDayNumber {
            return
        }
        
        let borders = getLocationBorders()
        
        let keys = Keys()
        let diff = min(previousDayNumber - lastUpload, DataManager.maxDays)
        
        var offset = 0
        while offset < diff {
            let dayNumber = previousDayNumber - offset
            
            // We currently don't upload diagnostic keys without location data!
            if let border = borders[dayNumber] {
                let keyValue = KeyManager.getDailyKey(for: dayNumber).base64EncodedString()
                // TODO secure randomizer on upload if borders thinner than threshold
                let key = Key(value: keyValue, day: dayNumber, border: border)
                
                keys.keys.append(key)
            }
            
            offset += 1
        }
        
        AF.request(STORAGE_ENDPOINT + "keys",
                   method: .post,
                   parameters: keys,
                   encoder: JSONParameterEncoder.default).response { response in
                    let statusCode: Int = response.response?.statusCode ?? 0
                    if statusCode == 200 {
                        NSKeyedArchiver.archiveRootObject(lastUpload, toFile: lastUploadPath)
                    } else {
                        response.reportError("POST /keys")
                    }
        }
    }
    
    static func lastUploadDayNumber() -> Int {
        return NSKeyedUnarchiver.unarchiveObject(withFile: lastUploadPath) as? Int ?? 0
    }
    
}

class Keys: Codable {
    var keys: [Key] = []
}

struct Key: Codable {
    let value: String
    let day: Int
    let border: LocationBorder
}

class LocationBorder: Codable {
    
    var minLat: Double
    var minLng: Double
    var maxLat: Double
    var maxLng: Double
    
    init(minLat: Double, minLng: Double, maxLat: Double, maxLng: Double) {
        self.minLat = minLat
        self.minLng = minLng
        self.maxLat = maxLat
        self.maxLng = maxLng
    }

    convenience init(_ location: CLLocation) {
        self.init(
            minLat: location.coordinate.latitude,
            minLng: location.coordinate.longitude,
            maxLat: location.coordinate.latitude,
            maxLng: location.coordinate.longitude
        )
    }
    
    func update(_ location: CLLocation) {
        minLat = min(minLat, location.coordinate.latitude)
        minLng = min(minLng, location.coordinate.longitude)
        maxLat = max(maxLat, location.coordinate.latitude)
        maxLng = max(maxLng, location.coordinate.longitude)
    }
    
    func extend(_ other: LocationBorder) -> LocationBorder {
        return LocationBorder(
            minLat: min(minLat, other.minLat),
            minLng: min(minLng, other.minLng),
            maxLat: max(maxLat, other.maxLat),
            maxLng: max(maxLng, other.maxLng)
        )
    }
    
}
