import UIKit

class Dp3tLogsViewController: UIViewController {

    static var instance: Dp3tLogsViewController?
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func clear(_ sender: Any) {
        confirm(R.string.localizable.clear_log_confiration_question()) {
            Dp3tLogsManager.clear()
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
        Dp3tLogsViewController.instance = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Dp3tLogsViewController.instance = nil
    }
    
    func refresh() {
        var logString = ""
        
        Dp3tLogsManager.logs.forEach { item in
            logString += "[\(AppDelegate.dateFormatter.string(from: item.date))] \(item.text)\n"
        }
        
        if logString.isEmpty {
            logString = "Nothing yet."
        }
        
        textView.text = logString
        
        let bottom = NSRange(location: textView.text.count - 1, length: 1)
        textView.scrollRangeToVisible(bottom)
    }
    
}
