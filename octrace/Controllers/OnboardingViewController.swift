import UIKit
import CoreLocation
import Alamofire

class OnboardingViewController: IndicatorViewController {
    
    var stage: OnboaringStage = .welcome
    var parentController: OnboardingViewController!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var button: RoundButton!
    
    @IBAction func actionTap(_ sender: Any) {
        switch stage {
        case .welcome:
            let key = SecurityUtil.generateKey()
            
            KeyManager.setTracingKey(key)
            
            goNext(.location)
            
        case .location:
            LocationManager.requestAuthorization()
            
            goNext(.notifications)
            
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, _) in
                DispatchQueue.main.async {
                    self.complete()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch stage {
        case .welcome:
            titleLabel.text = "Welcome!"
            descriptionLabel.text = "Covid Control is here to help you and your community to keep safe and take the appropriate measures in case necessary.\n\nWe are in this together, and each one of us plays an important role."
            button
                .setTitle("Get started!", for: .normal)
            
        case .location:
            titleLabel.text = "Location Data"
            descriptionLabel.text = "All location tracking data is securely stored and does not leave your phone unless you get sick and want to notify your contacts, in either an anonymous or a transparent way."
            button.setTitle("Enable location", for: .normal)
            
        case .notifications:
            titleLabel.text = "Notifications"
            descriptionLabel.text = "Notifications keep you up to date, and also alert you in case you have been in close contact with someone that now is infected."
            button.setTitle("Enable notifications", for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    static func instanciate() -> OnboardingViewController {
        return OnboardingViewController(nibName: "OnboardingViewController", bundle: nil)
    }
    
    private func goNext(_ nextStage: OnboaringStage) {
        let nextViewController = OnboardingViewController.instanciate()
        
        nextViewController.stage = nextStage
        nextViewController.parentController = self
        
        navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    private func complete() {
        OnboardingManager.doComplete()
        
        popOut()
        parentController.popOut()
        parentController.parentController.popOut()
    }
    
}

enum OnboaringStage: String {
    case welcome = "WELCOME"
    case location = "LOCATION"
    case notifications = "NOTIFICATIONS"
}
