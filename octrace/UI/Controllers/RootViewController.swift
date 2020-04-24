import Alamofire
import UIKit

class RootViewController: UITabBarController {
    
    static var instance: RootViewController?
    
    var infoViewController: InfoViewController!
    var mapViewController: MapViewController!
    var statusViewController: StatusViewController!
    
    var indicator: UIActivityIndicatorView!
    
    private var firstAppearance = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        indicator = addActivityIndicator()
        
        infoViewController = viewControllers?[0] as? InfoViewController
        
        mapViewController = viewControllers?[1] as? MapViewController
        mapViewController.rootViewController = self
        
        statusViewController = viewControllers?[2] as? StatusViewController
        
        // preload all tabs
        viewControllers?.forEach { _ = $0.view }
        
        if KeyManager.hasKey() {
            LocationManager.requestLocationUpdates()
            BtAdvertisingManager.shared.setup()
            BtScanningManager.shared.setup()
        } else {
            navigationController?.pushViewController(
                OnboardingViewController.instanciate(),
                animated: false
            )
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // HACK: if we do it in viewDidLoad, map layout is invalid until tabbed :(
        if firstAppearance {
            selectedIndex = 1
            
            firstAppearance = false
        }
        
        if KeyManager.hasKey() {
            print("Cleaning old data...")
            
            // Otherwise lastUpdateTimestamp won't be 0 for the initial load
            if TracksManager.lastUpdateTimestamp > 0 {
                ContactsManager.removeOldContacts()
                TracksManager.removeOldTracks()
                TrackingManager.removeOldPoints()
                LocationBordersManager.removeOldLocationBorders()
                EncryptionKeysManager.removeOldKeys()
                LogsManager.removeOldItems()
            }
            
            print("Cleaning old data complete!.")
            
            loadTracks()
            loadDiagnosticKeys()
            
            if UserStatusManager.sick() {
                KeysManager.uploadNewKeys()
            }
            
            if BtScanningManager.shared.state == .poweredOff {
                showBluetoothOffWarning()
            }
        }
        
        RootViewController.instance = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        RootViewController.instance = nil
    }
    
    func showBluetoothOffWarning() {
        showInfo("Please turn on Bluetooth to enable automatic contact tracing!")
    }
    
    func addContact(_ contact: Contact) {
        mapViewController.updateContacts()
        mapViewController.goToContact(contact)
    }
    
    func makeContact(rId: String, key: String, token: String, platform: String, tst: Int64) {
        if abs(Int(Date.timestamp() - tst)) > 60000 {
            // QR contact should be valid for 1 minute only
            showError("Contact code has expired, please try again.")
            
            return
        }
        
        guard let location = LocationManager.lastLocation else {
            showError("No location info")
            
            return
        }
        
        let rollingId = SecurityUtil.getRollingId().base64EncodedString()
        let secret = SecurityUtil.encodeAES(rollingId, with: Data(base64Encoded: key)!)
        let contactRequest = ContactRequest(token: token,
                                            platform: platform,
                                            secret: secret.base64EncodedString(),
                                            tst: tst)
        
        indicator.show()
        
        AF.request(CONTACT_ENDPOINT + "makeContact",
                   method: .post,
                   parameters: contactRequest,
                   encoder: JSONParameterEncoder.default).response { response in
                    self.indicator.hide()
                    
                    let statusCode: Int = response.response?.statusCode ?? 0
                    if statusCode == 200 {
                        let contact = Contact(rId, location, tst)
                        
                        ContactsManager.addContact(contact)
                        
                        self.addContact(contact)
                        
                        self.showInfo("The contact has been recorded!")
                    } else {
                        self.showError("Status code: \(statusCode)")
                    }
        }
    }
    
    private func loadTracks() {
        indicator.show()
        
        let lastUpdateTimestamp = TracksManager.lastUpdateTimestamp
        if let border = self.getQueryBorder(for: lastUpdateTimestamp) {
            AF.request(
                STORAGE_ENDPOINT + "tracks",
                parameters: [
                    "lastUpdateTimestamp": lastUpdateTimestamp,
                    "minLat": border.minLat,
                    "maxLat": border.maxLat,
                    "minLng": border.minLng,
                    "maxLng": border.maxLng
                ]
            ).responseDecodable(of: TracksData.self) { response in
                self.indicator.hide()
                
                if let data = response.value {
                    TracksManager.setUpdated()
                    
                    if data.tracks.isEmpty {
                        return
                    }
                    
                    let latestDailyKeys = KeyManager.getLatestDailyKeys()
                    
                    let tracksFiltered = data.tracks.filter { track in
                        !latestDailyKeys.contains(Data(base64Encoded: track.key)!)
                    }
                    
                    print("Got \(tracksFiltered.count) new tracks since \(lastUpdateTimestamp).")
                    
                    if tracksFiltered.isEmpty {
                        return
                    }
                    
                    TracksManager.addTracks(tracksFiltered)
                    self.mapViewController.updateExtTracks()
                } else {
                    response.reportError("GET /tracks")
                }
            }
        }
    }
    
    private func loadDiagnosticKeys() {
        indicator.show()
        
        let lastUpdateTimestamp = KeysManager.lastUpdateTimestamp
        if let border = self.getQueryBorder(for: lastUpdateTimestamp) {
            AF.request(
                STORAGE_ENDPOINT + "keys",
                parameters: [
                    "lastUpdateTimestamp": lastUpdateTimestamp,
                    "minLat": border.minLat,
                    "maxLat": border.maxLat,
                    "minLng": border.minLng,
                    "maxLng": border.maxLng
                ]
            ).responseDecodable(of: KeysData.self) { response in
                if let data = response.value {
                    print("Got \(data.keys.count) new keys since \(lastUpdateTimestamp).")
                    
                    KeysManager.setUpdated()
                    
                    if data.keys.isEmpty {
                        return
                    }
                    
                    let lastInfectedContact = ContactsManager.matchContacts(data)
                    
                    if let contact = lastInfectedContact {
                        self.showExposedNotification()
                        
                        self.mapViewController.goToContact(contact)
                        self.mapViewController.updateContacts()
                    }
                    
                    if BtContactsManager.matchContacts(data) != nil && lastInfectedContact == nil {
                        self.showExposedNotification()
                    }
                } else {
                    response.reportError("GET /keys")
                }
            }
        }
    }
    
    private func showExposedNotification() {
        let content = UNMutableNotificationContent()
        
        content.categoryIdentifier = EXPOSED_CONTACT_CATEGORY
        content.title = "Exposed contact"
        content.body = "A contact you have recorded has reported symptoms."
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func getQueryBorder(for lastUpdateTimestamp: Int64) -> LocationBorder? {
        var borders = LocationBordersManager.locationBorders
        
        if lastUpdateTimestamp > 0 {
            let dayNumber = SecurityUtil.getDayNumber(from: lastUpdateTimestamp)
            
            borders = borders.filter { (day, _) in
                day >= dayNumber
            }
        }
        
        if borders.isEmpty {
            return nil
        }
        
        let border = borders.values.reduce(borders.values.first!) { first, second in
            first.extend(second)
        }
        
        border.secure()
        
        return border
    }
}


struct ContactRequest: Codable {
    let token: String
    let platform: String
    let secret: String
    let tst: Int64
}
