import Foundation
import CryptoSwift

class CryptoUtil {
    
    private static let keyLength = 16
    
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
        return try! AES(
            key: key.bytes,
            blockMode: CBC(iv: [UInt8](repeating: 0, count: keyLength)),
            padding: .pkcs5
        )
    }
    
    
    // MARK: - Apple/Google crypto spec:
    // https://www.blog.google/documents/56/Contact_Tracing_-_Cryptography_Specification.pdf
    
    private static let daySeconds = 60 * 60 * 24
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
    
    static func getRollingId() -> Data {
        let dailyKey = getDailyKey(for: currentDayNumber())
        
        return getRollingId(dailyKey, date: Date())
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
    
    private static func getRollingId(_ rpiKey: Data, _ enIntervalNumber: Int) -> Data {
        var paddedData = rpiPrefix
        for _ in 6...11 {
            paddedData.append(0)
        }
        
        paddedData.append(contentsOf: withUnsafeBytes(of: enIntervalNumber, Array.init))
        
        return CryptoUtil.encodeAES(Data(paddedData), with: rpiKey)
    }

    private static func getEnIntervalNumber(for date: Date) -> Int {
        Int(date.timeIntervalSince1970) / (60 * 10)
    }
    
    static func getDailyKey(for dayNumber: Int) -> Data {
        var dailyKeys = KeysManager.dailyKeys
        
        if let existingDailyKey = dailyKeys[dayNumber] {
            return existingDailyKey
        }
        
        let dailyKey = CryptoUtil.generateKey()
        
        dailyKeys[dayNumber] = dailyKey
        
        KeysManager.dailyKeys = dailyKeys
        
        return dailyKey
    }
    
    private static func getRollingId(_ dailyKey: Data, date: Date) -> Data {
        let rpiKey = Data(try! HKDF(password: dailyKey.bytes, info: info, keyLength: keyLength).calculate())
        
        return getRollingId(rpiKey, getEnIntervalNumber(for: date))
    }
    
    static func match(_ rollingId: String, _ date: Date, _ dailyKey: Data) -> Bool {
        let enIntervalNumber = getEnIntervalNumber(for: date)
        
        let rpiKey = getRpiKey(dailyKey)
        
        // We check 3 nearest ids in case of timestamp rolling
        let idExact = getRollingId(rpiKey, enIntervalNumber).base64EncodedString()
        let idBefore = getRollingId(rpiKey, enIntervalNumber - 1).base64EncodedString()
        let idAfter = getRollingId(rpiKey, enIntervalNumber + 1).base64EncodedString()
        
        return rollingId == idExact || rollingId == idBefore || rollingId == idAfter
    }
    
    private static func getRpiKey(_ dailyKey: Data) -> Data {
        return Data(try! HKDF(password: dailyKey.bytes, info: info, keyLength: keyLength).calculate())
    }
    
    private static func getLatestDailyKeys() -> [Data] {
        let lastDayNumber = CryptoUtil.currentDayNumber() - DataManager.maxDays
        
        return Array(
            KeysManager.dailyKeys.filter { dayNumber, _ in dayNumber > lastDayNumber }.values
        )
    }
    
}
