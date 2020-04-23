import UIKit

class IndicatorViewController: UIViewController {

    var indicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        indicator = addActivityIndicator()
    }

}

extension UIActivityIndicatorView {

    func show() {
        startAnimating()
    }

    func hide() {
        stopAnimating()
        hidesWhenStopped = true
    }

}
