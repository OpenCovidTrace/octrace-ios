import UIKit
import WebKit
import Alamofire

class InfoViewController: UIViewController {
    
    private static let newsEndpoint = "https://\(NetworkUtil.host)/newsroom.html?from=app"
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>,
                                                modifiedSince: date) {}
        
        webView.load(
            URLRequest(url: URL(string: InfoViewController.newsEndpoint)!)
        )
    }
    
}
