import Foundation
import CoreBluetooth
import UIKit

class BtScanningManager: NSObject {
    
    static let shared = BtScanningManager()
    
    private static let tag = "SCAN"
    
    var state: CBManagerState?
    
    private var manager: CBCentralManager!
    
    private var peripheralsRssi: [CBPeripheral: Int] = [:]

    private var foundedDevices = [PeripheralDevice]()

    func setup() {
        manager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    private func log(_ text: String) {
        LogsManager.append(tag: BtScanningManager.tag, text: text)
    }
}

extension BtScanningManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log(central.state.name())
        
        state = central.state
        
        if state == .poweredOn {
            manager.scanForPeripherals(withServices: [BLE_SERVICE_UUID],
                                       options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            
            log("Scanning has started")
        } else if state == .poweredOff {
            foundedDevices.removeAll()
            if let rootViewController = RootViewController.instance {
                rootViewController.showBluetoothOffWarning()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {

        let foundDevice = PeripheralDevice(peripheral: peripheral)
        if foundedDevices.contains(foundDevice) { return }
        log("Found peripheral: \(peripheral.identifier.uuidString), RSSI: \(RSSI.stringValue), " +
            "advertisementData: \(advertisementData.debugDescription)")
        peripheralsRssi[peripheral] = RSSI.intValue
        peripheral.delegate = self
        connect(to: peripheral)

    }
    
    // MARK: - Connect to peripheral
    
    private func connect(to peripheral: CBPeripheral) {
        manager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([BLE_SERVICE_UUID])
        log("Connect to: \(peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("Fail Connect to: \(peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log("Disconnected from: \(peripheral.identifier.uuidString)")
    }
    
}

extension BtScanningManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let errorValue = error {
            log("Error discovering services: \(errorValue.localizedDescription)")
            
            return
        }
        
        let bleService = peripheral.services?.first(where: { $0.uuid == BLE_SERVICE_UUID })
        guard let unwrappedBleService = bleService else { return }
        
        log("Discover service: \(unwrappedBleService.uuid.uuidString)")
        
        peripheral.discoverCharacteristics([BLE_CHARACTERISTIC_UUID], for: unwrappedBleService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let errorValue = error {
            log("Error discovering services: \(errorValue.localizedDescription)")
            return
        }
        if let char = service.characteristics?.first(where: { $0.uuid == BLE_CHARACTERISTIC_UUID }) {
            peripheral.readValue(for: char)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }

        if data.count != 16 {
            log("Received unexpected data length \(data.count)")
        } else {
            let rollingId = data.base64EncodedString()

            log("Received rollingId from peripheral: \(rollingId)")

            let lastLocation = LocationManager.lastLocation

            if let location = lastLocation,
                let rssi = peripheralsRssi[peripheral] {
                let encounter = BtEncounter(rssi, location)
                let foundDevice = PeripheralDevice(peripheral: peripheral, response: rollingId)
                foundedDevices.append(foundDevice)
                BtContactsManager.addContact(rollingId, encounter)
            } else {
                if lastLocation == nil {
                    log("Failed to record contact: no location data.")
                } else {
                    log("Failed to record contact: no rssi data.")
                }
            }
        }

        manager.cancelPeripheralConnection(peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let errorValue = error {
            log("Error changing notification state: \(errorValue.localizedDescription)")

            return
        }

        if characteristic.isNotifying {
            log("Subscribed. Notification has begun for: \(characteristic.uuid.uuidString)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
    }

}
