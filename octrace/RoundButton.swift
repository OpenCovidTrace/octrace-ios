import UIKit

class RoundButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = 8
    }

}
