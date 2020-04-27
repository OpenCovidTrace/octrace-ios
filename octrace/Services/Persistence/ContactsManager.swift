import Foundation
import CoreLocation

class ContactsManager {
    
    private static let path = DataManager.docsDir.appendingPathComponent("contacts").path
    
    private init() {
    }
    
    static var contacts: [ContactHealth] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [] }
            do {
                return try PropertyListDecoder().decode([ContactHealth].self, from: data)
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
        let expirationTimestamp = DataManager.expirationTimestamp()
        
        let newContacts = contacts.filter { $0.contact.tst > expirationTimestamp }
        
        contacts = newContacts
    }
    
    static func matchContacts(_ keysData: KeysData) -> Contact? {
        let newContacts = contacts
        
        var lastInfectedContact: Contact?
        
        newContacts.forEach { contact in
            let contactDate = Date(tst: contact.contact.tst)
            let contactDay = CryptoUtil.getDayNumber(for: contactDate)
            if keysData.keys.contains(where: { $0.day == contactDay &&
                CryptoUtil.spec.match(contact.contact.id, contactDate, Data(base64Encoded: $0.value)!) }) {
                contact.infected = true
                lastInfectedContact = contact.contact
            }
        }
        
        contacts = newContacts
        
        return lastInfectedContact
    }
    
    static func addContact(_ contact: Contact) {
        var newContacts = contacts
        
        newContacts.append(ContactHealth(contact))
        
        contacts = newContacts
    }
    
}

class ContactHealth: Codable {
    let contact: Contact
    var infected: Bool = false
    
    init(_ contact: Contact) {
        self.contact = contact
    }
}

struct Contact: Codable {
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
