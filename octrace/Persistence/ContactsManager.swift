import Foundation
import CoreLocation

class ContactsManager {
    
    private static let path = DataManager.docsDir.appendingPathComponent("contacts").path
    
    private init() {
    }
    
    static func removeOldContacts() {
        let expirationTimestamp = DataManager.expirationTimestamp()
        
        let newContacts = getContacts().filter { $0.contact.tst > expirationTimestamp }
        
        saveContacts(newContacts)
    }
    
    static func matchContacts(_ keys: Keys) -> Contact? {
        let contacts = getContacts()
        
        var lastInfectedContact: Contact? = nil
        
        contacts.forEach { contact in
            let contactDay = SecurityUtil.getDayNumber(from: contact.contact.tst)
            keys.keys.filter { key in
                key.day == contactDay
            }.forEach { key in
                let timeIntervalNumber = SecurityUtil.getTimeIntervalNumber(for: Int(contact.contact.tst/1000))
                
                let dailyKey = Data(base64Encoded: key.value)!
                
                // We check 3 nearest ids in case of timestamp rolling
                let idExact = SecurityUtil.getRollingId(dailyKey, timeIntervalNumber).base64EncodedString()
                let idBefore = SecurityUtil.getRollingId(dailyKey, timeIntervalNumber - 1).base64EncodedString()
                let idAfter = SecurityUtil.getRollingId(dailyKey, timeIntervalNumber + 1).base64EncodedString()
                
                if contact.contact.id == idExact || contact.contact.id == idBefore || contact.contact.id == idAfter {
                    contact.infected = true
                    lastInfectedContact = contact.contact
                }
            }
        }
        
        saveContacts(contacts)
        
        return lastInfectedContact
    }

    static func addContact(_ contact: Contact) {
        var contacts = getContacts()
        
        contacts.append(ContactHealth(contact))
        
        saveContacts(contacts)
    }
    
    private static func saveContacts(_ contacts: [ContactHealth]) {
        do {
            let data = try PropertyListEncoder().encode(contacts)
            NSKeyedArchiver.archiveRootObject(data, toFile: path)
        } catch {
            print("Save Failed")
        }
    }
    
    static func getContacts() -> [ContactHealth] {
        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [] }
        do {
            return try PropertyListDecoder().decode([ContactHealth].self, from: data)
        } catch {
            print("Retrieve Failed")
            
            return []
        }
    }
    
}

class ContactHealth : Codable {
    let contact: Contact
    var infected: Bool = false
    
    init(_ contact: Contact) {
        self.contact = contact
    }
}

struct Contact : Codable {
    let id: String
    let lat: Double
    let lng: Double
    let tst: Int64
    
    init(_ id: String, _ location: CLLocation, _ tst: Int64) {
        self.id = id
        self.lat = location.coordinate.latitude
        self.lng = location.coordinate.longitude
        self.tst = tst
    }
    
    func coordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    func date() -> Date {
        Date(tst: tst)
    }
    
}
