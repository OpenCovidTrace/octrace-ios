import Foundation
import CryptoSwift

class CryptoUtil {
    
    static let keyLength = 16
    
    private static let coordPrecision = 1e7
    
    private init() {}
    
    
    // MARK: - AES 128bit
    
    static func encodeAES(_ value: Data, with key: Data) -> Data {
        let aes = getAes(from: key)
        
        return Data(try! aes.encrypt(value.bytes))
    }
    
    static func decodeAES(_ value: Data, with key: Data) -> Data {
        let aes = getAes(from: key)
        
        return Data(try! aes.decrypt(value.bytes))
    }
    
    private static func getAes(from key: Data) -> AES {
        return try! AES(key: key.bytes, blockMode: ECB(), padding: .noPadding)
    }
    
    
    // MARK: - Apple/Google crypto spec:
    // https://www.blog.google/documents/56/Contact_Tracing_-_Cryptography_Specification.pdf
    
    private static let daySeconds = 60 * 60 * 24
    private static let enIntervalSeconds = 60 * 10
    private static let info = "EN-RPIK".bytes
    private static let rpiPrefix = "EN-RPI".bytes
    
    static func generateKey() -> Data {
        var bytes = [UInt8](repeating: 0, count: keyLength)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        if status != errSecSuccess { // Always test the status.
            fatalError("Failed to generate random bytes")
        }
        
        print("Generated key: \(bytes)")
        
        return Data(bytes)
    }
    
    static func toSecretKey(_ key: Data) -> String {
        return key.sha256().base64EncodedString()
    }
 
    static func getLatestSecretDailyKeys() -> [String] {
        return getLatestDailyKeys().map(toSecretKey)
    }
    
    static func getCurrentRpi() -> Data {
        let (rollingId, meta) = getCurrentRollingIdAndMeta()
        
        var data = rollingId
        data.append(meta)
        
        return data
    }
    
    static func getCurrentRollingIdAndMeta() -> (Data, Data) {
        let date = Date()
        let dayNumber = getDayNumber(for: date)
        let (dailyKey, metaKey) = getDailyKeys(for: dayNumber)
        
        return (getRollingId(dailyKey, date: date), getMetaData(for: date, with: metaKey))
    }
    
    static func getDayNumber(from tst: Int64) -> Int {
        return Int(tst/1000) / daySeconds
    }
    
    static func getDayNumber(for date: Date) -> Int {
        return Int(date.timeIntervalSince1970) / daySeconds
    }
    
    static func currentDayNumber() -> Int {
        return getDayNumber(for: Date())
    }
    
    private static func getRollingId(_ rpiKey: Data, _ enIntervalNumber: UInt32) -> Data {
        var paddedData = rpiPrefix
        for _ in 6...11 {
            paddedData.append(0)
        }
        
        paddedData.append(contentsOf: withUnsafeBytes(of: enIntervalNumber, Array.init))
        
        return encodeAES(Data(paddedData), with: rpiKey)
    }

    private static func getEnIntervalNumber(for date: Date) -> UInt32 {
        getEnIntervalNumber(Int(date.timeIntervalSince1970))
    }
    
    private static func getEnIntervalNumber(_ timeIntervalSince1970: Int) -> UInt32 {
        UInt32(timeIntervalSince1970 / enIntervalSeconds)
    }
    
    static func getDailyKeys(for dayNumber: Int) -> (Data, Data) {
        var dailyKeys = KeysManager.dailyKeys
        var metaKeys = KeysManager.metaKeys
        
        if let dailyKey = dailyKeys[dayNumber],
            let metaKey = metaKeys[dayNumber] {
            return (dailyKey, metaKey)
        }
                
        let dailyKey = CryptoUtil.generateKey()
        let metaKey = CryptoUtil.generateKey()
        
        dailyKeys[dayNumber] = dailyKey
        metaKeys[dayNumber] = metaKey
        
        KeysManager.dailyKeys = dailyKeys
        KeysManager.metaKeys = metaKeys
        
        return (dailyKey, metaKey)
    }
    
    private static func getMetaData(for date: Date, with metaKey: Data) -> Data {
        let timeInterval = Int32(date.timeIntervalSince1970)
        
        var data = Data(withUnsafeBytes(of: timeInterval, Array.init))
        
        var latInt32 = Int32.max
        var lngInt32 = Int32.min
        var accuracy = Int32(0)
        if let location = LocationManager.lastLocation {
            latInt32 = coordToInt(location.coordinate.latitude)
            lngInt32 = coordToInt(location.coordinate.longitude)
            accuracy = Int32(location.horizontalAccuracy)
        }
        
        data.append(contentsOf: withUnsafeBytes(of: latInt32, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: lngInt32, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: accuracy, Array.init))
        
        return encodeAES(Data(data), with: getEncryptionKey(metaKey))
    }
    
    static func decodeMetaData(_ encryptedData: Data, with metaKey: Data) -> ContactMetaData {
        let data = decodeAES(encryptedData, with: getEncryptionKey(metaKey))
        
        let timeInterval = Double(bytesToInt32(data.prefix(8).bytes))
        let date = Date(timeIntervalSince1970: timeInterval)
        
        var coord: ContactCoord?
        
        let latInt32 = bytesToInt32(data.subdata(in: 8..<16).bytes)
        if latInt32 != Int32.max {
            let lngInt32 = bytesToInt32(data.subdata(in: 16..<24).bytes)
            let accuracy = bytesToInt32(data.prefix(8).bytes)
            
            coord = ContactCoord(lat: coordToDouble(latInt32),
                                 lng: coordToDouble(lngInt32),
                                 accuracy: Int(accuracy))
        }
        
        return ContactMetaData(coord: coord, date: date)
    }
    
    private static func coordToInt(_ value: Double) -> Int32 {
        return Int32(value * coordPrecision)
    }
    
    private static func coordToDouble(_ value: Int32) -> Double {
        return Double(value) / coordPrecision
    }
    
    private static func bytesToInt32(_ bytes: [UInt8]) -> Int32 {
        var value: Int32 = 0
        
        for byte in bytes {
            value = value << 8
            value = value | Int32(byte)
        }
        
        return value
    }
    
    private static func getRollingId(_ dailyKey: Data, date: Date) -> Data {
        let rpiKey = getEncryptionKey(dailyKey)
        
        return getRollingId(rpiKey, getEnIntervalNumber(for: date))
    }
    
    static func match(_ rollingId: String, _ dayNumber: Int, _ dailyKey: Data) -> Bool {
        let rpiKey = getEncryptionKey(dailyKey)
        
        let firstEnIntervalNumber = getEnIntervalNumber(dayNumber * daySeconds)
        let nextDayEnIntervalNumber = getEnIntervalNumber((dayNumber + 1) * daySeconds)
        
        for enIntervalNumber in firstEnIntervalNumber..<nextDayEnIntervalNumber {
            if rollingId == getRollingId(rpiKey, enIntervalNumber).base64EncodedString() {
                return true
            }
        }
        
        return false
    }
    
    private static func getEncryptionKey(_ key: Data) -> Data {
        return Data(try! HKDF(password: key.bytes, info: info, keyLength: keyLength).calculate())
    }
    
    private static func getLatestDailyKeys() -> [Data] {
        let lastDayNumber = CryptoUtil.currentDayNumber() - DataManager.maxDays
        
        return Array(
            KeysManager.dailyKeys.filter { dayNumber, _ in dayNumber > lastDayNumber }.values
        )
    }
    
}
