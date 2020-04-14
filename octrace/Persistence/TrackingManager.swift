import Foundation
import CoreLocation

class TrackingManager {
    
    static let trackingIntervalMs = 60000
    
    private static let path = DataManager.docsDir.appendingPathComponent("tracking").path
    
    private init() {
    }
    
    static func addTrackingPoint(_ point: TrackingPoint) {
        var trackingData = getTrackingData()
        
        trackingData.append(point)
        
        saveTrackingData(trackingData)
    }
    
    static func removeOldPoints() {
        let expirationTimestamp = DataManager.expirationTimestamp()
        
        let newData = getTrackingData().filter { $0.tst > expirationTimestamp }
        
        saveTrackingData(newData)
    }
    
    private static func saveTrackingData(_ trackingData: [TrackingPoint]) {
        do {
            let data = try PropertyListEncoder().encode(trackingData)
            NSKeyedArchiver.archiveRootObject(data, toFile: path)
        } catch {
            print("Save Failed")
        }
    }
    
    static func getTrackingData() -> [TrackingPoint] {
        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data else { return [] }
        do {
            return try PropertyListDecoder().decode([TrackingPoint].self, from: data)
        } catch {
            print("Retrieve Failed")
            
            return []
        }
    }
    
}


struct TrackingPoint : Codable {
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
        return SecurityUtil.getDayNumber(from: tst)
    }
}
