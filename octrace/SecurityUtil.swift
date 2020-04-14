import Foundation
import CryptoSwift

class SecurityUtil {
    
    private static let daySeconds = 60 * 60 * 24
    
    private init() {}
    
    static func encodeAES(_ value: String, with key: Data) -> Data {
        let aes = getAes(from: key)
        
        return Data(try! aes.encrypt(value.bytes))
    }
    
    static func decodeAES(_ value: String, with key: Data) -> Data {
        let aes = getAes(from: key)
        
        return Data(try! aes.decrypt(value.bytes))
    }
    
    private static func getAes(from key: Data) -> AES {
        return try! AES(
            key: key.bytes,
            blockMode: CBC(iv: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            padding: .pkcs5
        )
    }
    
    static func generateKey() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        if status != errSecSuccess { // Always test the status.
            fatalError("Failed to generate random bytes")
        }
        
        print("Generated key: \(bytes)")
        
        return Data(bytes)
    }
    
    static func getDailyKey(_ key: Data, _ dayNumber: Int) -> Data {
        var info = "CT-DTK".bytes
        
        info.append(contentsOf: withUnsafeBytes(of: dayNumber.bigEndian, Array.init))
        
        return Data(try! HKDF(password: key.bytes, info: info, keyLength: 16).calculate())
    }
    
    static func getSecretDailyKey(_ key: Data, _ dayNumber: Int) -> String {
        var dailyKey = getDailyKey(key, dayNumber)
        
        dailyKey.append(key)
        
        return dailyKey.sha256().base64EncodedString()
    }
    
    static func getRollingId() -> Data {
        let dailyKey = KeyManager.getDailyKey(for: SecurityUtil.currentDayNumber())
        
        return getRollingId(dailyKey, getCurrentTimeIntervalNumber())
    }
    
    static func getRollingId(_ dailyKey: Data, _ timeIntervalNumber: UInt8) -> Data {
        var info = "CT-RPI".bytes
        
        info.append(contentsOf: withUnsafeBytes(of: timeIntervalNumber.bigEndian, Array.init))
        
        let bytes = try! HMAC(key: info, variant: .sha256).authenticate(dailyKey.bytes)
        
        return Data(bytes.prefix(16))
    }
    
    static func getDayNumber(from tst: Int64) -> Int {
        return Int(tst/1000) / daySeconds
    }
    
    static func currentDayNumber() -> Int {
        return getTimestamp() / daySeconds
    }
    
    static func getDayNumber(for timestamp: Int) -> Int {
        return timestamp / daySeconds
    }
    
    static func getCurrentTimeIntervalNumber() -> UInt8 {
        return getTimeIntervalNumber(for: getTimestamp())
    }
    
    static func getTimeIntervalNumber(for timestamp: Int) -> UInt8 {
        return UInt8((timestamp - getDayNumber(for: timestamp) * daySeconds) / (60 * 10))
    }
    
    private static func getTimestamp() -> Int {
        return Int(Date.timeIntervalBetween1970AndReferenceDate + Date.timeIntervalSinceReferenceDate)
    }
    
}
