import Foundation
import Alamofire
import CoreLocation

class KeysManager {
    
    private static let dailyKeysPath = DataManager.docsDir.appendingPathComponent("daily-keys").path
    private static let metaKeysPath = DataManager.docsDir.appendingPathComponent("meta-keys").path
    
    private static let kLastKeysUploadDay = "kLastKeysUploadDay"
    private static let kDiscloseMetaData = "kDiscloseMetaData"
    
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
    
    static var metaKeys: [Int: Data] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: metaKeysPath) as? Data else { return [:] }
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
                NSKeyedArchiver.archiveRootObject(data, toFile: metaKeysPath)
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
    
    static func uploadNewKeys(includeToday: Bool = false) {
        let oldLastUploadDay = lastUpdloadDay
        
        // Uploading after EOD to include widest borders
        let currentDayNumber = CryptoUtil.currentDayNumber()
        let previousDayNumber = currentDayNumber - 1
        
        if oldLastUploadDay == previousDayNumber {
            return
        }
        
        let borders = LocationBordersManager.locationBorders
        
        let keysData = KeysData()
        
        func addKey(for dayNumber: Int) {
            // We currently don't upload diagnostic keys without location data!
            if let border = borders[dayNumber],
                let dailyKey = dailyKeys[dayNumber],
                let metaKey = metaKeys[dayNumber] {
                border.secure()
                
                let meta = UserSettingsManager.discloseMetaData ? metaKey.base64EncodedString() : nil
                
                let key = Key(value: dailyKey.base64EncodedString(),
                              meta: meta,
                              day: dayNumber,
                              border: border)
                
                keysData.keys.append(key)
            }
        }
        
        if includeToday {
            // Include key for today when reporting exposure
            // This key will be uploaded again next day with updated borders
            addKey(for: currentDayNumber)
        }
        
        let diff = min(previousDayNumber - oldLastUploadDay, DataManager.maxDays)
        
        var offset = 0
        while offset < diff {
            let dayNumber = previousDayNumber - offset
            
            addKey(for: dayNumber)
            
            offset += 1
        }
        
        if keysData.keys.isEmpty {
            return
        }
        
        AF.request(NetworkUtil.storageEndpoint("keys"),
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
    let meta: String?
    let day: Int
    let border: LocationBorder
}
