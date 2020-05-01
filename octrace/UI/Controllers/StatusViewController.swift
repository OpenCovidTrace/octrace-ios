import UIKit
import Alamofire

class StatusViewController: IndicatorViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    
    @IBAction func statusChange(_ sender: Any) {
        if UserStatusManager.sick() {
            showInfo(R.string.localizable.new_statuses_disclaimer())
        } else {
            confirm(R.string.localizable.report_covid_confirmation()) {
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
        KeysManager.uploadNewKeys(includeToday: true)
        
        refreshStatus()
    }
    
    private func refreshStatus() {
        let status: String
        if UserStatusManager.sick() {
            status = R.string.localizable.symptoms_status()

            statusButton.setTitle(R.string.localizable.whats_next_button(), for: .normal)
            statusButton.backgroundColor = .systemGreen
        } else {
            status = R.string.localizable.healthy()
            
            statusButton.setTitle(R.string.localizable.got_symptoms_button(), for: .normal)
            statusButton.backgroundColor = .systemRed
        }

        statusLabel.text = R.string.localizable.status_title(status)
    }
    
}
