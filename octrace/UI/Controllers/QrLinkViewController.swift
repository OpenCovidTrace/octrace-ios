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
        if #available(iOS 13.0, *) {
            indicator.style = .large
        }
        
        indicator.show()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let token = AppDelegate.deviceTokenEncoded {
            let rpi = CryptoUtil.getCurrentRpi()
                .base64EncodedString()
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let tst = Date.timestamp()
            let key = EncryptionKeysManager.generateKey(for: tst)
                .base64EncodedString()
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
            imageView.image = generateQRCode(
                from: NetworkUtil.contactEndpoint("app/contact?d=\(token)&r=\(rpi)&k=\(key)&p=i&t=\(tst)")
            )
            
            label.isHidden = false
            indicator.hide()
        } else {
            dismiss(animated: true)
            showError(R.string.localizable.get_notification_token_error())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        QrLinkViewController.instance = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        QrLinkViewController.instance = nil
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        print("Generating QR code for '\(string)'")
        
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
