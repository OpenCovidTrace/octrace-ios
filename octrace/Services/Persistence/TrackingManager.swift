import Foundation
import CoreLocation

class TrackingManager {
    
    static let trackingIntervalMs = 60000
    
    private static let path = DataManager.docsDir.appendingPathComponent("tracking").path
    
    private init() {
    }
    
    static var trackingData: [TrackingPoint] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [] }
            do {
                return try PropertyListDecoder().decode([TrackingPoint].self, from: data)
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
    
    static func addTrackingPoint(_ point: TrackingPoint) {
        var newTrackingData = trackingData
        
        newTrackingData.append(point)
        
        trackingData = newTrackingData
    }
    
    static func removeOldPoints() {
        let expirationTimestamp = DataManager.expirationTimestamp()
        
        let newTrackingData = trackingData.filter { $0.tst > expirationTimestamp }
        
        trackingData = newTrackingData
    }
    
}


struct TrackingPoint: Codable {
    let lat: Double
    let lng: Double
    let tst: Int64
    
    init(lat: Double, lng: Double, tst: Int64) {
        self.lat = lat
        self.lng = lng
        self.tst = tst
    }
    
    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(lat: coordinate.latitude, lng: coordinate.longitude, tst: Date.timestamp())
    }
    
    func coordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    func dayNumber() -> Int {
        return CryptoUtil.getDayNumber(from: tst)
    }
}
