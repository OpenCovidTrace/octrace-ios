import Foundation
import Alamofire
import CoreLocation

class KeysManager {
    
    private static let dailyKeysPath = DataManager.docsDir.appendingPathComponent("daily-keys").path
    
    private static let kLastKeysUploadDay = "kLastKeysUploadDay"
    
    private init() {
    }
    
    static var dailyKeys: [Int: Data] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: dailyKeysPath) as? Data else { return [:] }
            do {
                return try PropertyListDecoder().decode([Int: Data].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return [:]
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: dailyKeysPath)
            } catch {
                print("Save Failed")
            }
        }
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
        let previousDayNumber = CryptoUtil.currentDayNumber() - 1
        
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
                let keyValue = CryptoUtil.getDailyKey(for: dayNumber).base64EncodedString()
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
