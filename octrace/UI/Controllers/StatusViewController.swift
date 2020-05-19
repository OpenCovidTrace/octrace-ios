import UIKit
import Alamofire

class StatusViewController: IndicatorViewController {
    
    @IBOutlet weak var recordTrackSwitch: UISwitch!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var shareTrackSwitch: UISwitch!
    @IBOutlet weak var shareMetaDataSwitch: UISwitch!
    
    @IBAction func statusChange(_ sender: Any) {
        if UserSettingsManager.sick() {
            showInfo(R.string.localizable.whats_next_text())
        } else {
            confirm(R.string.localizable.report_exposure_confirmation()) {
                self.updateUserStatus(UserSettingsManager.exposed)
                
                self.choose(R.string.localizable.tracks_upload_confirmation(),
                             yesHandler: {
                                UserSettingsManager.uploadTrack = true
                                self.shareTrackSwitch.setOn(true, animated: true)
                                
                                TracksManager.uploadNewTracks()
                                
                                self.requestMetaDataDisclosure()
                },
                             noHandler: {
                                self.requestMetaDataDisclosure()
                })
            }
        }
    }
    
    @IBAction func recordTrackSwitched(_ sender: Any) {
        UserSettingsManager.recordTrack = recordTrackSwitch.isOn
    }
    
    @IBAction func shareTrackSwitched(_ sender: Any) {
        UserSettingsManager.uploadTrack = shareTrackSwitch.isOn
    }
    
    @IBAction func shareMetaDataSwitched(_ sender: Any) {
        UserSettingsManager.discloseMetaData = shareMetaDataSwitch.isOn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // This value could've change through on-boarding so we have to force refresh
        recordTrackSwitch.setOn(UserSettingsManager.recordTrack, animated: animated)
    }
    
    private func updateUserStatus(_ status: String) {
        UserSettingsManager.status = status
        
        refreshStatus()
    }
    
    private func refreshStatus() {
        let status: String
        if UserSettingsManager.sick() {
            status = R.string.localizable.exposed()

            statusButton.setTitle(R.string.localizable.whats_next_button(), for: .normal)
            statusButton.backgroundColor = .systemGreen
            
            shareTrackSwitch.isEnabled = true
            shareTrackSwitch.setOn(UserSettingsManager.uploadTrack, animated: false)
            shareMetaDataSwitch.isEnabled = true
            shareMetaDataSwitch.setOn(UserSettingsManager.discloseMetaData, animated: false)
        } else {
            status = R.string.localizable.normal()
            
            statusButton.setTitle(R.string.localizable.exposed_button(), for: .normal)
            statusButton.backgroundColor = .systemRed
        }

        statusLabel.text = R.string.localizable.status_title(status)
    }
    
    private func requestMetaDataDisclosure() {
        choose(R.string.localizable.share_meta_data_confirmation(),
                     yesHandler: {
                        UserSettingsManager.discloseMetaData = true
                        self.shareMetaDataSwitch.setOn(true, animated: true)
                        
                        KeysManager.uploadNewKeys(includeToday: true)
        },
                     noHandler: {
                        KeysManager.uploadNewKeys(includeToday: true)
        })
    }
}
