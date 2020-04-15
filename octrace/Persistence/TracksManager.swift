import Foundation
import Alamofire

class TracksManager {
    
    private static let lastUpdatePath = DataManager.docsDir.appendingPathComponent("tracks-last-update").path
    
    private static let lastUploadPath = DataManager.docsDir.appendingPathComponent("tracks-last-updload").path
    
    private static let tracksPath = DataManager.docsDir.appendingPathComponent("tracks").path
    
    private init() {
    }
    
    static func removeOldTracks() {
        let lastDay = SecurityUtil.currentDayNumber() - 14
        
        let newTracks = getTracks().filter { track in
            track.day > lastDay
        }
        
        saveTracks(newTracks)
    }
    
    static func getTracks() -> [Track] {
        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: tracksPath) as? Data else { return [] }
        do {
            return try PropertyListDecoder().decode([Track].self, from: data)
        } catch {
            print("Retrieve Failed")
            
            return []
        }
    }
    
    static func addTracks(_ newTracks: [Track]) {
        var tracks = getTracks()
        
        tracks.append(contentsOf: newTracks)
        
        saveTracks(tracks)
    }
    
    private static func saveTracks(_ tracks: [Track]) {
        do {
            let data = try PropertyListEncoder().encode(tracks)
            NSKeyedArchiver.archiveRootObject(data, toFile: tracksPath)
        } catch {
            print("Save Failed")
        }
    }
    
    static func setUpdated() {
        NSKeyedArchiver.archiveRootObject(Date.timestamp(), toFile: lastUpdatePath)
    }
    
    static func lastUpdateTimestamp() -> Int64 {
        return NSKeyedUnarchiver.unarchiveObject(withFile: lastUpdatePath) as? Int64 ?? 0
    }
    
    static func uploadNewTracks() {
        let lastUploadTst = lastUploadTimestamp()
        let now = Date.timestamp()
        
        let points = TrackingManager.getTrackingData().filter { point in
            point.tst > lastUploadTst
        }
        
        var tracksByDay: [Int:Track] = [:]
        
        points.forEach { point in
            let dayNumber = point.dayNumber()
            
            if let track = tracksByDay[dayNumber] {
                track.points.append(point)
            } else {
                tracksByDay[dayNumber] = Track([point], dayNumber, KeyManager.getSecretDailyKey(for: dayNumber))
            }
        }
        
        let tracks = [Track](tracksByDay.values)
        
        AF.request(STORAGE_ENDPOINT + "tracks",
                   method: .post,
                   parameters: tracks,
                   encoder: JSONParameterEncoder.default).response { response in
                    let statusCode: Int = response.response?.statusCode ?? 0
                    
                    if statusCode == 200 {
                        NSKeyedArchiver.archiveRootObject(now, toFile: lastUploadPath)
                    } else {
                        print("Error while sending tracks: \(statusCode).")
                    }
        }
    }
    
    static func lastUploadTimestamp() -> Int64 {
        return NSKeyedUnarchiver.unarchiveObject(withFile: lastUploadPath) as? Int64 ?? 0
    }
}

class Tracks : Codable {
    let tracks: [Track]
}

class Track : Codable {
    var points: [TrackingPoint]
    let day: Int
    let key: String
    
    init(_ points: [TrackingPoint], _ day: Int, _ key: String) {
        self.points = points
        self.day = day
        self.key = key
    }
}
