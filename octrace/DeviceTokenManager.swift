class DeviceTokenManager {
    
    private init() {}
    
    static var deviceToken: String?
    
    static private var callback: ((String) -> Void)?
    
    static func updateToken(_ token: String) {
        deviceToken = token
        
        if let call = callback {
            call(token)
            
            callback = nil
        }
    }
    
    static func withToken(_ call: @escaping (String) -> Void) {
        if let token = deviceToken {
            call(token)
        } else {
            callback = call
        }
    }
    
}
