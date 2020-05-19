import Foundation
import Alamofire

class TracksManager {
    
    private static let lastUploadPath = DataManager.docsDir.appendingPathComponent("tracks-last-updload").path
    
    private static let tracksPath = DataManager.docsDir.appendingPathComponent("tracks").path
    
    private init() {
    }
    
    static var tracks: [Track] {
        get {
            guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: tracksPath) as? Data else { return [] }
            do {
                return try PropertyListDecoder().decode([Track].self, from: data)
            } catch {
                print("Retrieve Failed")
                
                return []
            }
        }
        
        set {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                NSKeyedArchiver.archiveRootObject(data, toFile: tracksPath)
            } catch {
                print("Save Failed")
            }
        }
    }
    
    static func removeOldTracks() {
        let lastDay = CryptoUtil.currentDayNumber() - 14
        
        let newTracks = tracks.filter { track in
            track.day > lastDay
        }
        
        tracks = newTracks
    }
    
    static func addTracks(_ items: [Track]) {
        var newTracks = tracks
        
        newTracks.append(contentsOf: items)
        
        tracks = newTracks
    }
    
    static var lastUploadTimestamp: Int64 {
        get {
            NSKeyedUnarchiver.unarchiveObject(withFile: lastUploadPath) as? Int64 ?? 0
        }
        
        set {
            NSKeyedArchiver.archiveRootObject(newValue, toFile: lastUploadPath)
        }
    }
    
    static func uploadNewTracks() {
        let oldLastUploadTimestamp = lastUploadTimestamp
        let now = Date.timestamp()
        
        let points = TrackingManager.trackingData.filter { point in
            point.tst > oldLastUploadTimestamp
        }
        
        var tracksByDay: [Int: Track] = [:]
        
        points.forEach { point in
            let dayNumber = point.dayNumber()
            
            if let track = tracksByDay[dayNumber] {
                track.points.append(point)
            } else {
                let (dailyKey, _) = CryptoUtil.getDailyKeys(for: dayNumber)
                let secretKey = CryptoUtil.toSecretKey(dailyKey)
                
                tracksByDay[dayNumber] = Track([point], dayNumber, secretKey)
            }
        }
        
        if tracksByDay.isEmpty {
            return
        }
        
        let tracksData = TracksData(tracks: [Track](tracksByDay.values))
        
        AF.request(NetworkUtil.storageEndpoint("tracks"),
                   method: .post,
                   parameters: tracksData,
                   encoder: JSONParameterEncoder.default).response { response in
                    let statusCode: Int = response.response?.statusCode ?? 0
                    
                    if statusCode == 200 {
                        lastUploadTimestamp = now
                    } else {
                        response.reportError("POST /tracks")
                    }
        }
    }
    
}

class TracksData: Codable {
    let tracks: [Track]
    
    init(tracks: [Track]) {
        self.tracks = tracks
    }
}

class Track: Codable {
    var points: [TrackingPoint]
    let day: Int
    let key: String
    
    init(_ points: [TrackingPoint], _ day: Int, _ key: String) {
        self.points = points
        self.day = day
        self.key = key
    }
}
