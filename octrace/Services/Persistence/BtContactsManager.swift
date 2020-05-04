import Foundation
import CoreLocation

class BtContactsManager {
    
    private static let path = DataManager.docsDir.appendingPathComponent("bt-contacts").path
    
    private init() {
    }
    
    static var contacts: [String: BtContact] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [:] }
            do {
                return try PropertyListDecoder().decode([String: BtContact].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return [:]
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
        
        let newContacts = contacts.filter { (_, contact) in
            contact.day > expirationDay
        }
        
        contacts = newContacts
    }
    
    static func matchContacts(_ keysData: KeysData) -> (Bool, ContactCoord?) {
        let newContacts = contacts
        
        var hasExposure = false
        var lastExposedContactCoord: ContactCoord?
        
        newContacts.forEach { (id, contact) in
            keysData.keys
                .filter { $0.day == contact.day }
                .forEach { key in
                    if CryptoUtil.match(contact.id, contact.day, Data(base64Encoded: key.value)!) {
                        contact.exposed = true
                        
                        if let metaKey = key.meta {
                            for encounter in contact.encounters {
                                encounter.metaData = CryptoUtil.decodeMetaData(
                                    encounter.meta,
                                    with: Data(base64Encoded: metaKey)!
                                )
                                
                                if let coord = encounter.metaData?.coord {
                                    lastExposedContactCoord = coord
                                }
                            }
                        }
                        
                        hasExposure = true
                    }
            }
        }
        
        contacts = newContacts
        
        return (hasExposure, lastExposedContactCoord)
    }
    
    static func addContact(_ id: String, _ day: Int, _ encounter: BtEncounter) {
        var newContacts = contacts
        
        if let contact = newContacts[id] {
            contact.encounters.append(encounter)
        } else {
            newContacts[id] = BtContact(id, day, encounter)
        }
        
        contacts = newContacts
    }
    
}

class BtContact: Codable {
    
    let id: String
    let day: Int
    
    var encounters: [BtEncounter]
    
    var exposed: Bool = false
    
    init(_ id: String, _ day: Int, _ encounter: BtEncounter) {
        self.id = id
        self.day = day
        
        encounters = [encounter]
    }
    
}

class BtEncounter: Codable {
    let rssi: Int
    let meta: Data
    
    var metaData: ContactMetaData?
    
    init(rssi: Int, meta: Data) {
        self.rssi = rssi
        self.meta = meta
    }
}
