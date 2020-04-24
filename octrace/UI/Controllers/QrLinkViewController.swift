import UIKit
import Alamofire

class QrLinkViewController: UIViewController {

    static var instance: QrLinkViewController?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        indicator.show()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // FIXME this won't work if user disabled notifications
        if let token = AppDelegate.deviceTokenEncoded {
            let rollingId = SecurityUtil.getRollingId().base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let tst = Date.timestamp()
            let key = EncryptionKeysManager.generateKey(for: tst).base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
            imageView.image = generateQRCode(from: CONTACT_ENDPOINT + "app/contact?d=\(token)&i=\(rollingId)&k=\(key)&p=i&t=\(tst)")
            
            label.isHidden = false
            indicator.hide()
        } else {
            dismiss(animated: true)
            showError("Failed to get notifications token.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        QrLinkViewController.instance = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        QrLinkViewController.instance = nil
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
}
