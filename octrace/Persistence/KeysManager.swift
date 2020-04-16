import Foundation
import Alamofire
import CoreLocation

class KeysManager {
    
    private static let kLastKeysUploadDay = "kLastKeysUploadDay"
    
    private static let lastUpdatePath = DataManager.docsDir.appendingPathComponent("keys-last-update").path
    
    private init() {
    }
    
    static var lastUpdateTimestamp: Int64 {
        get {
            NSKeyedUnarchiver.unarchiveObject(withFile: lastUpdatePath) as? Int64 ?? 0
        }
        
        set {
            NSKeyedArchiver.archiveRootObject(newValue, toFile: lastUpdatePath)
        }
    }
    
    static func setUpdated() {
        lastUpdateTimestamp = Date.timestamp()
    }
    
    static var lastUpdloadDay: Int {
        get {
            UserDefaults.standard.integer(forKey: kLastKeysUploadDay)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: kLastKeysUploadDay)
        }
    }
    
    static func uploadNewKeys() {
        let oldLastUploadDay = lastUpdloadDay
        
        // Uploading after EOD to include widest borders
        let previousDayNumber = SecurityUtil.currentDayNumber() - 1
        
        if oldLastUploadDay == previousDayNumber {
            return
        }
        
        let borders = LocationBordersManager.locationBorders
        
        let keysData = KeysData()
        let diff = min(previousDayNumber - oldLastUploadDay, DataManager.maxDays)
        
        var offset = 0
        while offset < diff {
            let dayNumber = previousDayNumber - offset
            
            // We currently don't upload diagnostic keys without location data!
            if let border = borders[dayNumber] {
                let keyValue = KeyManager.getDailyKey(for: dayNumber).base64EncodedString()
                border.secure()
                let key = Key(value: keyValue, day: dayNumber, border: border)
                
                keysData.keys.append(key)
            }
            
            offset += 1
        }
        
        AF.request(STORAGE_ENDPOINT + "keys",
                   method: .post,
                   parameters: keysData,
                   encoder: JSONParameterEncoder.default).response { response in
                    let statusCode: Int = response.response?.statusCode ?? 0
                    if statusCode == 200 {
                        lastUpdloadDay = previousDayNumber
                    } else {
                        response.reportError("POST /keys")
                    }
        }
    }
    
}

class KeysData: Codable {
    var keys: [Key] = []
}

struct Key: Codable {
    let value: String
    let day: Int
    let border: LocationBorder
}

class LocationBorder: Codable {
    
    private static let minDiff = 0.1 // ~ 10km
    private static let maxLatValue = 90.0
    private static let maxLngValue = 180.0
    
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
    
    func secure() {
        if minLat - maxLat < LocationBorder.minDiff {
            minLat -= Double.random(in: LocationBorder.minDiff/2 ..< LocationBorder.minDiff)
            maxLat += Double.random(in: LocationBorder.minDiff/2 ..< LocationBorder.minDiff)
            
            if minLat < -LocationBorder.maxLatValue {
                minLat += LocationBorder.maxLatValue * 2
            }
            
            if maxLat > LocationBorder.maxLatValue {
                maxLat -= LocationBorder.maxLatValue * 2
            }
            
            print("Extended latitude to \(minLat) - \(maxLat)")
        }
        
        if minLng - maxLng < LocationBorder.minDiff {
            minLng -= Double.random(in: LocationBorder.minDiff/2 ..< LocationBorder.minDiff)
            maxLng += Double.random(in: LocationBorder.minDiff/2 ..< LocationBorder.minDiff)
            
            if minLng < -LocationBorder.maxLngValue {
                minLng += LocationBorder.maxLngValue * 2
            }
            
            if maxLng > LocationBorder.maxLngValue {
                maxLng -= LocationBorder.maxLngValue * 2
            }
            
            print("Extended longitude to \(minLng) - \(maxLng)")
        }
    }
    
}
