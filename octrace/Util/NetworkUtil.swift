import Alamofire

class NetworkUtil {
    
    #if DEVELOPMENT
    static let host = "dev.openexposuretrace.org"
    #else
    static let host = "openexposuretrace.org"
    #endif

    private init() {
    }
    
    static func contactEndpoint(_ uri: String) -> String {
        return "https://contact.\(host)/\(uri)"
    }
    
    static func storageEndpoint(_ uri: String) -> String {
        return "https://storage.\(host)/\(uri)"
    }
    
    static let eternalRetry = EternalRetry()
}

class EternalRetry: RequestInterceptor {
    func retry(_ request: Request,
               for session: Session,
               dueTo error: Error,
               completion: @escaping (RetryResult) -> Void) {
        completion(.retryWithDelay(3))
        
        print("Scheduled request retry in 3 seconds due to error: \(error.localizedDescription)")
    }
}

extension URL {
    func valueOf(_ param: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else {
            return nil
        }
        
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}

extension AFDataResponse {
    func reportError(_ request: String) {
        let statusCode: Int = response?.statusCode ?? 0
        let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
        
        print("\(request) ERROR: status \(statusCode), body \(body), error \(error?.localizedDescription ?? "nil")")
    }
}
