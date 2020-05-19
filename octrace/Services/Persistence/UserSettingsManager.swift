import Foundation

class UserSettingsManager {
    
    private static let kUserStatus = "kUserStatus"
    private static let kDiscloseMetaData = "kDiscloseMetaData"
    private static let kRecordTrack = "kRecordTrack"
    private static let kUploadTrack = "kUploadTrack"
    
    static let normal = "normal"
    static let exposed = "exposed"
    
    private init() {
    }

    static var status: String {
        get {
            UserDefaults.standard.string(forKey: kUserStatus) ?? normal
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: kUserStatus)
        }
    }
    
    static func sick() -> Bool {
        return status == exposed
    }
    
    static var discloseMetaData: Bool {
        get {
            UserDefaults.standard.bool(forKey: kDiscloseMetaData)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: kDiscloseMetaData)
        }
    }
    
    static var recordTrack: Bool {
        get {
            UserDefaults.standard.bool(forKey: kRecordTrack)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: kRecordTrack)
            
            LocationManager.updateBackgroundState()
        }
    }
    
    static var uploadTrack: Bool {
        get {
            UserDefaults.standard.bool(forKey: kUploadTrack)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: kUploadTrack)
        }
    }
    
}
