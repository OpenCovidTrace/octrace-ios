import UIKit
import CoreLocation
import Firebase
import AlamofireNetworkActivityIndicator
import DP3TSDK

let MAKE_CONTACT_CATEGORY = "MAKE_CONTACT"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var deviceTokenEncoded: String?
    
    private static let tag = "APP"
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /*
         * Firebase
         */
        
        FirebaseApp.configure()
        
        
        /*
         * Network indicator
         */
        
        NetworkActivityIndicatorManager.shared.isEnabled = true
        
        
        /*
         * Notifications setup
         */
        
        let makeContactMessageCategory = UNNotificationCategory(identifier: MAKE_CONTACT_CATEGORY,
                                                                actions: [],
                                                                intentIdentifiers: [],
                                                                options: .customDismissAction)
        
        let center = UNUserNotificationCenter.current()
        
        center.setNotificationCategories([makeContactMessageCategory])
        center.delegate = self
        
        application.registerForRemoteNotifications()
        
        
        /*
         * Locaction updates
         */
        
        LocationManager.initialize(self)
        
        
        /*
         * DP3T integration
         */
        
        let dp3tBackendUrl = URL(string: "https://demo.dpppt.org/")!
        do {
            try DP3TTracing.initialize(
                with: .manual(
                    .init(appId: Bundle.main.bundleIdentifier!,
                          bucketBaseUrl: dp3tBackendUrl,
                          reportBaseUrl: dp3tBackendUrl,
                          jwtPublicKey: nil)
                )
            )
            
            DP3TTracing.delegate = self

            logDp3t("Library initialized")
        } catch {
            logDp3t("Failed to initialize library: \(error.localizedDescription)")
        }
        
        
        logBt("App did finish launching")
        
        return true
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            guard let url = userActivity.webpageURL else {
                return true
            }
            
            /*
             Existing scheme:
             https://HOST/.well-known/apple-app-site-association
             */
            if url.pathComponents.count == 3 && url.pathComponents[2] == "contact" {
                if let rpi = url.valueOf("r"),
                    let key = url.valueOf("k"),
                    let token = url.valueOf("d"),
                    let platform = url.valueOf("p"),
                    let tst = url.valueOf("t") {
                    self.withRootController { rootViewController in
                        rootViewController.makeContact(
                            rpi: rpi,
                            key: key,
                            token: token,
                            platform: platform,
                            tst: Int64(tst)!
                        )
                    }
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Transforming to format acceptable by backend
        AppDelegate.deviceTokenEncoded = deviceToken.reduce("", { $0 + String(format: "%02X", $1) })
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // This is called in order for viewWillDisappear to be executed
        self.window?.rootViewController?.beginAppearanceTransition(false, animated: false)
        self.window?.rootViewController?.endAppearanceTransition()
        
        LocationManager.updateAccuracy(foreground: false)
        
        print("App did enter background")
        logBt("App did enter background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
        logBt("App will enter foreground")
        
        LocationManager.updateAccuracy(foreground: true)
        
        // This is called in order for viewWillAppear to be executed
        self.window?.rootViewController?.beginAppearanceTransition(true, animated: false)
        self.window?.rootViewController?.endAppearanceTransition()
    }
    
    private func logBt(_ text: String) {
        BtLogsManager.append(tag: AppDelegate.tag, text: text)
    }
    
    private func logDp3t(_ text: String) {
        Dp3tLogsManager.append(text)
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            LocationManager.updateLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            LocationManager.startUpdatingLocation()
        }
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if response.notification.request.content.categoryIdentifier == MAKE_CONTACT_CATEGORY {
            let secret = userInfo["secret"] as! String
            let tst = userInfo["tst"] as! Int64
            
            if let key = EncryptionKeysManager.encryptionKeys[tst] {
                let secretData = Data(base64Encoded: secret)!
                
                let id = CryptoUtil.decodeAES(secretData.prefix(CryptoUtil.keyLength), with: key)
                let meta = CryptoUtil.decodeAES(secretData.suffix(CryptoUtil.keyLength), with: key)
                
                let contact = QrContact(id.base64EncodedString(), meta)
                
                QrContactsManager.addContact(contact)
                
                if let qrLinkViewController = QrLinkViewController.instance {
                    qrLinkViewController.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
        completionHandler([.alert, .sound])
    }
    
    private func withRootController(_ handler: (RootViewController) -> Void) {
        if let navigationController = self.window?.rootViewController as? UINavigationController {
            _ = navigationController.popToRootViewController(animated: false)
            let rootViewController = navigationController.topViewController as! RootViewController
            
            handler(rootViewController)
        }
    }
    
}

extension AppDelegate: DP3TTracingDelegate {
    
    func DP3TTracingStateChanged(_ state: TracingState) {
        logDp3t("Tracing state changed: \(state)")
    }
    
}
