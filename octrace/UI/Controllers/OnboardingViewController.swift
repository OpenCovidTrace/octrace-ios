import UIKit
import CoreLocation
import Alamofire

class OnboardingViewController: UIViewController {
    
    var stage = OnboardingStage.welcome
    var parentController: OnboardingViewController!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var button: RoundButton!
    @IBOutlet weak var skipButton: UIButton!
    
    @IBAction func actionTap(_ sender: Any) {
        switch stage {
        case OnboardingStage.location:
            UserSettingsManager.recordTrack = true
            
            LocationManager.requestAuthorization()
            
            goNext(OnboardingStage.bluetooth)
            
        case OnboardingStage.bluetooth:
            BtAdvertisingManager.shared.setup()
            BtScanningManager.shared.setup()
            
            goNext(OnboardingStage.notifications)
            
        case OnboardingStage.notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _  in
                DispatchQueue.main.async {
                    self.complete()
                }
            }
            
        default: // welcome
            goNext(OnboardingStage.location)
        }
    }
    
    @IBAction func skipTap(_ sender: Any) {
        switch stage {
        case OnboardingStage.location:
            goNext(OnboardingStage.bluetooth)
            
        case OnboardingStage.bluetooth:
            goNext(OnboardingStage.notifications)
                        
        default:
            complete()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch stage {
        case OnboardingStage.location:
            titleLabel.text = R.string.localizable.location_data()
            descriptionLabel.text = R.string.localizable.location_data_description()
            button.setTitle(R.string.localizable.enable_location(), for: .normal)
            
        case OnboardingStage.bluetooth:
            titleLabel.text = R.string.localizable.bluetooth_access()
            descriptionLabel.text = R.string.localizable.bluetooth_access_description()
            button.setTitle(R.string.localizable.enable_bluetooth(), for: .normal)
            
        case OnboardingStage.notifications:
            titleLabel.text = R.string.localizable.notifications()
            descriptionLabel.text = R.string.localizable.notifications_description()
            button.setTitle(R.string.localizable.enable_notifications(), for: .normal)
            
        default:
            titleLabel.text = R.string.localizable.welcome()
            descriptionLabel.text = R.string.localizable.welcome_description()
            button
                .setTitle(R.string.localizable.get_started(), for: .normal)
            skipButton.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch stage {
        case OnboardingStage.welcome:
            if OnboardingManager.status != OnboardingStage.welcome {
                goNext(OnboardingStage.location, skip: true)
            }
            
        case OnboardingStage.location:
            if OnboardingManager.status != OnboardingStage.location {
                goNext(OnboardingStage.bluetooth, skip: true)
            }
            
        case OnboardingStage.bluetooth:
            if OnboardingManager.status != OnboardingStage.bluetooth {
                goNext(OnboardingStage.notifications, skip: true)
            }
            
        default:
            break
        }
    }
    
    static func instanciate() -> OnboardingViewController {
        OnboardingViewController(nib: R.nib.onboardingViewController)
    }
    
    private func goNext(_ nextStage: String, skip: Bool = false) {
        if !skip {
            OnboardingManager.status = nextStage
        }
        
        let nextViewController = OnboardingViewController.instanciate()
        
        nextViewController.stage = nextStage
        nextViewController.parentController = self
        
        navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    private func complete() {
        OnboardingManager.status = OnboardingStage.complete
        
        popOut()
        parentController.popOut()
        parentController.parentController.popOut()
        parentController.parentController.parentController.popOut()
    }
    
}
