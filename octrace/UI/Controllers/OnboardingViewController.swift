import UIKit
import CoreLocation
import Alamofire
import DP3TSDK

class OnboardingViewController: IndicatorViewController {
    
    var stage = OnboardingStage.welcome
    var parentController: OnboardingViewController!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var button: RoundButton!
    @IBOutlet weak var skipButton: UIButton!
    
    @IBAction func actionTap(_ sender: Any) {
        switch stage {
        case OnboardingStage.location:
            LocationManager.requestAuthorization()
            
            goNext(OnboardingStage.bluetooth)
            
        case OnboardingStage.bluetooth:
            BtAdvertisingManager.shared.setup()
            BtScanningManager.shared.setup()
            
            do {
                try DP3TTracing.startTracing()
                
                Dp3tLogsManager.append("Started tracing")
            } catch {
                Dp3tLogsManager.append("Failed to start tracing: \(error.localizedDescription)")
            }
            
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
            titleLabel.text = "Location Data"
            descriptionLabel.text = """
            All location tracking data is securely stored and does not leave your phone unless you get sick and want to
            notify your contacts, in either an anonymous or a transparent way.
            """
            button.setTitle("Enable location", for: .normal)
            
        case OnboardingStage.bluetooth:
            titleLabel.text = "Bluetooth access"
            descriptionLabel.text = """
            We use bluetooth for anonymous automatic contact tracing. All contacts are securely stored and never leave
            your phone.
            """
            button.setTitle("Enable Bluetooth", for: .normal)
            
        case OnboardingStage.notifications:
            titleLabel.text = "Notifications"
            descriptionLabel.text = """
            Notifications keep you up to date, and also alert you in case you have been in close contact with someone
            that now is infected.
            """
            button.setTitle("Enable notifications", for: .normal)
            
        default:
            titleLabel.text = "Welcome!"
            descriptionLabel.text = """
            Covid Control is here to help you and your community to keep safe and take the appropriate measures in case
            necessary.\n\n
            We are in this together, and each one of us plays an important role.
            """
            button
                .setTitle("Get started!", for: .normal)
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
