import UIKit
import Alamofire

class StatusViewController: IndicatorViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    
    @IBAction func statusChange(_ sender: Any) {
        if UserStatusManager.sick() {
            showInfo(
                """
                We are planning to introduce new statuses: covid-confirmed and covid-recovered (immune) in the nearest
                future.
                """
            )
        } else {
            confirm(
                """
                You are about to anonymously self-report having symptoms of Covid-19 (Coronavirus). Your tracking
                records will be uploaded to the server for processing.\nNOTE: This procedure is anonymous, your privacy
                is kept at all times.
                """
            ) {
                self.updateUserStatus(UserStatusManager.symptoms)
            }
        }
        
        refreshStatus()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshStatus()
    }
    
    private func updateUserStatus(_ status: String) {
        UserStatusManager.status = status
        
        TracksManager.uploadNewTracks()
        KeysManager.uploadNewKeys()
        
        refreshStatus()
    }
    
    private func refreshStatus() {
        if UserStatusManager.sick() {
            statusLabel.text = "Current status: Symptoms"
            
            statusButton.setTitle("What's next?", for: .normal)
            statusButton.backgroundColor = UIColor.systemGreen
        } else {
            statusLabel.text = "Current status: Healthy"
            
            statusButton.setTitle("I got symptoms :(", for: .normal)
            statusButton.backgroundColor = UIColor.systemRed
        }
    }
    
}
