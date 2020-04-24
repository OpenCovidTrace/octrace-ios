import UIKit
import WebKit
import Alamofire

let NEWS_ENDPOINT = "https://\(HOST)/newsroom.html?from=app"

class InfoViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        
        webView.load(
            URLRequest(url: URL(string: NEWS_ENDPOINT)!)
        )
    }
    
}
