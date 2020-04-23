import UIKit
import CoreLocation
import Firebase
import AlamofireNetworkActivityIndicator

let MAKE_CONTACT_CATEGORY = "MAKE_CONTACT"
let EXPOSED_CONTACT_CATEGORY = "EXPOSED_CONTACT"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var deviceTokenEncoded: String?
    
    private static let tag = "APP"
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
        let exposedContactMessageCategory = UNNotificationCategory(identifier: EXPOSED_CONTACT_CATEGORY,
                                                                    actions: [],
                                                                    intentIdentifiers: [],
                                                                    options: .customDismissAction)
        
        let center = UNUserNotificationCenter.current()
        
        center.setNotificationCategories([makeContactMessageCategory, exposedContactMessageCategory])
        center.delegate = self
        
        application.registerForRemoteNotifications()
        
        
        /*
         * Locaction updates
         */
        
        LocationManager.initialize(self)
        
        
        log("App did finish launching")
        
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
                if let id = url.valueOf("i"),
                    let key = url.valueOf("k"),
                    let token = url.valueOf("d"),
                    let platform = url.valueOf("p"),
                    let tst = url.valueOf("tst") {
                    self.withRootController { rootViewController in
                        rootViewController.makeContact(
                            id: id,
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
        log("App did enter background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
        log("App will enter foreground")
        
        LocationManager.updateAccuracy(foreground: true)
        
        // This is called in order for viewWillAppear to be executed
        self.window?.rootViewController?.beginAppearanceTransition(true, animated: false)
        self.window?.rootViewController?.endAppearanceTransition()
    }
    
    private func log(_ text: String) {
        LogsManager.append(tag: AppDelegate.tag, text: text)
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
                let id = SecurityUtil.decodeAES(secret, with: key).base64EncodedString()
                
                // TODO verify that we have location here
                LocationManager.registerCallback { location in
                    let contact = Contact(id, location, tst)
                    
                    ContactsManager.addContact(contact)
                    
                    if let qrLinkViewController = QrLinkViewController.instance {
                        qrLinkViewController.dismiss(animated: true, completion: nil)
                    }
                    
                    self.withRootController { rootViewController in
                        rootViewController.addContact(contact)
                    }
                }
                
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
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
