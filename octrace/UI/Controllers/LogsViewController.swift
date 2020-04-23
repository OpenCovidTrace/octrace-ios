import UIKit

class LogsViewController: UIViewController {

    static var instance: LogsViewController?
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        
        df.dateStyle = .long
        df.timeStyle = .medium
        
        return df
    }()
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func clear(_ sender: Any) {
        confirm("Are you sure you want to clear all logs?") {
            LogsManager.clear()
        }
    }
    
    override func viewDidLoad() {
        indicator.show()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        refresh()
        
        indicator.hide()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        LogsViewController.instance = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        LogsViewController.instance = nil
    }
    
    func refresh() {
        var logString = ""
        
        LogsManager.logs.forEach { item in
            logString += "[\(LogsViewController.dateFormatter.string(from: item.date))] <\(item.tag)> \(item.text)\n"
        }
        
        if logString.isEmpty {
            logString = "Nothing yet."
        }
        
        textView.text = logString
        
        let bottom = NSRange(location: textView.text.count - 1, length: 1)
        textView.scrollRangeToVisible(bottom)
    }
    
}
