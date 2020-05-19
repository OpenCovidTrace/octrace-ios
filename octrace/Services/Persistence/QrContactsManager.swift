import Foundation
import CoreLocation

class QrContactsManager {
    
    private static let path = DataManager.docsDir.appendingPathComponent("qr-contacts").path
    
    private init() {
    }
    
    static var contacts: [QrContact] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [] }
            do {
                return try PropertyListDecoder().decode([QrContact].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return []
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: path)
            } catch {
                print("Save Failed")
            }
        }
    }
    
    static func removeOldContacts() {
        let expirationDay = DataManager.expirationDay()
        
        let newContacts = contacts.filter { $0.day > expirationDay }
        
        contacts = newContacts
    }
    
    static func matchContacts(_ keysData: KeysData) -> (Bool, ContactCoord?) {
        let newContacts = contacts
        
        var hasExposure = false
        var lastExposedContactCoord: ContactCoord?
        
        newContacts.forEach { contact in
            keysData.keys
                .filter { $0.day == contact.day }
                .forEach { key in
                    if CryptoUtil.match(contact.rollingId, contact.day, Data(base64Encoded: key.value)!) {
                        contact.exposed = true
                        
                        if let metaKey = key.meta {
                            contact.metaData = CryptoUtil.decodeMetaData(
                                contact.meta,
                                with: Data(base64Encoded: metaKey)!
                            )
                            
                            if let coord = contact.metaData?.coord {
                                lastExposedContactCoord = coord
                            }
                        }
                        
                        hasExposure = true
                    }
            }
        }
        
        contacts = newContacts
        
        return (hasExposure, lastExposedContactCoord)
    }
    
    static func addContact(_ contact: QrContact) {
        var newContacts = contacts
        
        newContacts.append(contact)
        
        contacts = newContacts
    }
    
}

class QrContact: Codable {
    
    let rollingId: String
    let meta: Data
    let day: Int
    
    var exposed: Bool = false
    var metaData: ContactMetaData?
    
    init(_ rollingId: String, _ meta: Data) {
        self.rollingId = rollingId
        self.meta = meta
        
        day = CryptoUtil.currentDayNumber()
    }
    
    convenience init(_ rpi: String) {
        let rpiData = Data(base64Encoded: rpi)!
        
        self.init(rpiData.prefix(CryptoUtil.keyLength).base64EncodedString(), rpiData.suffix(CryptoUtil.keyLength))
    }
}

struct ContactMetaData: Codable {
    let coord: ContactCoord?
    let date: Date
}

struct ContactCoord: Codable {
    let lat: Double
    let lng: Double
    let accuracy: Int
    
    func coordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
