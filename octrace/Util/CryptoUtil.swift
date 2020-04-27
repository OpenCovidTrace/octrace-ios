import Foundation
import CryptoSwift

class CryptoUtil {
    
    private init() {}
    
    static let daySeconds = 60 * 60 * 24
    
    static let spec = AgSpecV1_1.instance
    
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
        return try! AES(
            key: key.bytes,
            blockMode: CBC(iv: [UInt8](repeating: 0, count: 16)),
            padding: .pkcs5
        )
    }
    
    
    // MARK: - Apple/Google crypto spec:
    // https://www.blog.google/documents/56/Contact_Tracing_-_Cryptography_Specification.pdf
    
    static func generateKey(_ size: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: size)
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
        return spec.getLatestDailyKeys().map(toSecretKey)
    }
    
    static func getRollingId() -> Data {
        let dailyKey = spec.getDailyKey(for: currentDayNumber())
        
        return spec.getRollingId(dailyKey, date: Date())
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
    
}


protocol CryptoSpec {
    
    /// Temporary Exposure Key
    func getDailyKey(for dayNumber: Int) -> Data
    
    /// Rolling Proximity Identifier
    func getRollingId(_ dailyKey: Data, date: Date) -> Data
    
    /// This is extension to Apple/Google spec: we use contact timestamp to match daily key
    func match(_ rollingId: String, _ date: Date, _ dailyKey: Data) -> Bool
    
    func getLatestDailyKeys() -> [Data]
}


class AgSpecV1 {
    
    private init() {}
    
    private static func getRollingId(_ dailyKey: Data, _ timeIntervalNumber: UInt8) -> Data {
        var info = "CT-RPI".bytes
        
        info.append(contentsOf: [timeIntervalNumber])
        
        let bytes = try! HMAC(key: info, variant: .sha256).authenticate(dailyKey.bytes)
        
        return Data(bytes.prefix(16))
    }
    
    private static func getTimeIntervalNumber(for date: Date) -> UInt8 {
        return UInt8(
            (Int(date.timeIntervalSince1970) - CryptoUtil.getDayNumber(for: date) * CryptoUtil.daySeconds) / (60 * 10)
        )
    }
    
}


extension AgSpecV1: CryptoSpec {
    
    func getDailyKey(for dayNumber: Int) -> Data {
        var info = "CT-DTK".bytes
        
        info.append(contentsOf: withUnsafeBytes(of: dayNumber.littleEndian, Array.init))
        
        let tracingKey = KeyManager.tracingKey!
        
        return Data(try! HKDF(password: tracingKey.bytes, info: info, keyLength: 16).calculate())
    }
    
    func getRollingId(_ dailyKey: Data, date: Date) -> Data {
        return AgSpecV1.getRollingId(dailyKey, AgSpecV1.getTimeIntervalNumber(for: date))
    }
    
    func match(_ rollingId: String, _ date: Date, _ dailyKey: Data) -> Bool {
        let timeIntervalNumber = AgSpecV1.getTimeIntervalNumber(for: date)
        
        // We check 3 nearest ids in case of timestamp rolling
        let idExact = AgSpecV1.getRollingId(dailyKey, timeIntervalNumber).base64EncodedString()
        let idBefore = AgSpecV1.getRollingId(dailyKey, timeIntervalNumber - 1).base64EncodedString()
        let idAfter = AgSpecV1.getRollingId(dailyKey, timeIntervalNumber + 1).base64EncodedString()
        
        return rollingId == idExact || rollingId == idBefore || rollingId == idAfter
    }
    
    func getLatestDailyKeys() -> [Data] {
        var result: [Data] = []
        
        let dayNumber = CryptoUtil.currentDayNumber()
        
        var offset = 0
        while offset < DataManager.maxDays {
            result.append(getDailyKey(for: dayNumber - offset))
            
            offset += 1
        }
        
        return result
    }
    
}


/// https://www.blog.google/documents/60/Exposure_Notification_-_Cryptography_Specification_v1.1.pdf
class AgSpecV1_1 {

    static let instance = AgSpecV1_1()
    
    private static let info = "EN-RPIK".bytes
    private static let rpiPrefix = "EN-RPI".bytes
    
    private init() {}
    
    private static func getRollingId(_ dailyKey: Data, _ enIntervalNumber: Int) -> Data {
        let rpiKey = Data(try! HKDF(password: dailyKey.bytes, info: AgSpecV1_1.info, keyLength: 16).calculate())
        
        var paddedData = AgSpecV1_1.rpiPrefix
        for _ in 6...11 {
            paddedData.append(0)
        }
        
        paddedData.append(contentsOf: withUnsafeBytes(of: enIntervalNumber, Array.init))
        
        return CryptoUtil.encodeAES(Data(paddedData), with: rpiKey)
    }

    private static func getEnIntervalNumber(for date: Date) -> Int {
        Int(date.timeIntervalSince1970) / (60 * 10)
    }

}

extension AgSpecV1_1: CryptoSpec {
    
    func getDailyKey(for dayNumber: Int) -> Data {
        var dailyKeys = KeyManager.dailyKeys
        
        if let existingDailyKey = dailyKeys[dayNumber] {
            return existingDailyKey
        }
        
        let dailyKey = CryptoUtil.generateKey(16)
        
        dailyKeys[dayNumber] = dailyKey
        
        KeyManager.dailyKeys = dailyKeys
        
        return dailyKey
    }
    
    func getRollingId(_ dailyKey: Data, date: Date) -> Data {
        return AgSpecV1_1.getRollingId(dailyKey, AgSpecV1_1.getEnIntervalNumber(for: date))
    }
    
    func match(_ rollingId: String, _ date: Date, _ dailyKey: Data) -> Bool {
        let enIntervalNumber = AgSpecV1_1.getEnIntervalNumber(for: date)
        
        // We check 3 nearest ids in case of timestamp rolling
        let idExact = AgSpecV1_1.getRollingId(dailyKey, enIntervalNumber).base64EncodedString()
        let idBefore = AgSpecV1_1.getRollingId(dailyKey, enIntervalNumber - 1).base64EncodedString()
        let idAfter = AgSpecV1_1.getRollingId(dailyKey, enIntervalNumber + 1).base64EncodedString()
        
        return rollingId == idExact || rollingId == idBefore || rollingId == idAfter
    }
    
    func getLatestDailyKeys() -> [Data] {
        let lastDayNumber = CryptoUtil.currentDayNumber() - DataManager.maxDays
        
        return Array(
            KeyManager.dailyKeys.filter { dayNumber, _ in dayNumber > lastDayNumber }.values
        )
    }
    
}
