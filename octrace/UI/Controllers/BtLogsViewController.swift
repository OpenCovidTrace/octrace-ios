import UIKit

class BtLogsViewController: UIViewController {

    static var instance: BtLogsViewController?
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func clear(_ sender: Any) {
        confirm(R.string.localizable.clear_log_confiration_question()) {
            BtLogsManager.clear()
        }
    }
    
    override func viewDidLoad() {
        if #available(iOS 13.0, *) {
            indicator.style = .large
        }
        
        indicator.show()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        refresh()
        
        indicator.hide()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        BtLogsViewController.instance = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        BtLogsViewController.instance = nil
    }
    
    func refresh() {
        var logString = ""
        
        BtLogsManager.logs.forEach { item in
            logString += "[\(AppDelegate.dateFormatter.string(from: item.date))] <\(item.tag)> \(item.text)\n"
        }
        
        if logString.isEmpty {
            logString = "Nothing yet."
        }
        
        textView.text = logString
        
        let bottom = NSRange(location: textView.text.count - 1, length: 1)
        textView.scrollRangeToVisible(bottom)
    }
    
}
