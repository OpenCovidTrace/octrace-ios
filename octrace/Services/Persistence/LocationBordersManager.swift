import Foundation
import CoreLocation

class LocationBordersManager {
    
    private static let locationBordersPath = DataManager.docsDir.appendingPathComponent("location-borders").path
    
    private init() {
    }
    
    static var locationBorders: [Int: LocationBorder] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: locationBordersPath) as? Data else {
                return [:]
            }
            
            do {
                return try PropertyListDecoder().decode([Int: LocationBorder].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return [:]
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: locationBordersPath)
            } catch {
                print("Save Failed")
            }
        }
    }
    
    static func removeOldLocationBorders() {
        let lastDay = CryptoUtil.currentDayNumber() - DataManager.maxDays
        
        let oldBorders = locationBorders
        
        var newBorders: [Int: LocationBorder] = [:]
                
        oldBorders.keys.forEach { dayNumber in
            if dayNumber > lastDay {
                newBorders[dayNumber] = oldBorders[dayNumber]
            }
        }
        
        locationBorders = newBorders
    }
    
    static func updateLocationBorders(_ location: CLLocation) {
        var newBorders = locationBorders
        
        let currentDayNumber = CryptoUtil.currentDayNumber()
        
        if let currentBorder = newBorders[currentDayNumber] {
            currentBorder.update(location)
        } else {
            newBorders[currentDayNumber] = LocationBorder(location)
        }
        
        locationBorders = newBorders
    }
    
}

class LocationBorder: Codable {
    
    static let maxLatValue = 90.0
    static let maxLngValue = 180.0
    private static let minDiff = 0.1 // ~ 10km
    
    var minLat: Double
    var minLng: Double
    var maxLat: Double
    var maxLng: Double
    
    init(minLat: Double, minLng: Double, maxLat: Double, maxLng: Double) {
        self.minLat = minLat
        self.minLng = minLng
        self.maxLat = maxLat
        self.maxLng = maxLng
    }

    convenience init(_ location: CLLocation) {
        self.init(
            minLat: location.coordinate.latitude,
            minLng: location.coordinate.longitude,
            maxLat: location.coordinate.latitude,
            maxLng: location.coordinate.longitude
        )
    }
    
    convenience init(_ locationIndex: LocationIndex) {
        let centerLat = Double(locationIndex.latIdx) / LocationIndex.precision
        let centerLng = Double(locationIndex.lngIdx) / LocationIndex.precision
        
        self.init(
            minLat: centerLat - LocationIndex.diff,
            minLng: centerLng - LocationIndex.diff,
            maxLat: centerLat + LocationIndex.diff,
            maxLng: centerLng + LocationIndex.diff
        )
        
        adjustLatLimits()
        adjustLngLimits()
    }
    
    func update(_ location: CLLocation) {
        minLat = min(minLat, location.coordinate.latitude)
        minLng = min(minLng, location.coordinate.longitude)
        maxLat = max(maxLat, location.coordinate.latitude)
        maxLng = max(maxLng, location.coordinate.longitude)
    }
    
    func extend(_ other: LocationBorder) -> LocationBorder {
        return LocationBorder(
            minLat: min(minLat, other.minLat),
            minLng: min(minLng, other.minLng),
            maxLat: max(maxLat, other.maxLat),
            maxLng: max(maxLng, other.maxLng)
        )
    }
    
    func secure() {
        if minLat - maxLat < LocationBorder.minDiff {
            minLat -= Double.random(in: LocationBorder.minDiff/2 ..< LocationBorder.minDiff)
            maxLat += Double.random(in: LocationBorder.minDiff/2 ..< LocationBorder.minDiff)
            
            adjustLatLimits()
            
            print("Extended latitude to \(minLat) - \(maxLat)")
        }
        
        if minLng - maxLng < LocationBorder.minDiff {
            minLng -= Double.random(in: LocationBorder.minDiff/2 ..< LocationBorder.minDiff)
            maxLng += Double.random(in: LocationBorder.minDiff/2 ..< LocationBorder.minDiff)
            
            adjustLngLimits()
            
            print("Extended longitude to \(minLng) - \(maxLng)")
        }
    }
    
    private func adjustLatLimits() {
        if minLat < -LocationBorder.maxLatValue {
            minLat += LocationBorder.maxLatValue * 2
        }
        
        if maxLat > LocationBorder.maxLatValue {
            maxLat -= LocationBorder.maxLatValue * 2
        }
    }
    
    private func adjustLngLimits() {
        if minLng < -LocationBorder.maxLngValue {
            minLng += LocationBorder.maxLngValue * 2
        }
        
        if maxLng > LocationBorder.maxLngValue {
            maxLng -= LocationBorder.maxLngValue * 2
        }
    }
    
}

extension LocationBorder: CustomStringConvertible {
    var description: String {
        return "LocationBorder(lat: \(minLat)-\(maxLat), lng: \(minLng)-\(maxLng))"
    }
}
