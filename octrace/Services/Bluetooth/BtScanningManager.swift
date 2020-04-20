import Foundation
import CoreBluetooth
import UIKit

class BtScanningManager: NSObject {
    
    static let shared = BtScanningManager()
    
    private static let tag = "SCAN"
    
    private var manager: CBCentralManager!
    
    private var blePeripheral: CBPeripheral?
    private var peripherals: [CBPeripheral:Int] = [:]
    
    override private init() {
        super.init()
        
        manager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    // MARK: - Scan
    
    func startScan() {
        manager.scanForPeripherals(withServices: [BLE_SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        log("Scanning has started")
    }
    
    private func log(_ text: String) {
        LogsManager.append(tag: BtScanningManager.tag, text: text)
    }
}

extension BtScanningManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            log("Bluetooth Enabled")
        } else {
            log("Bluetooth Disabled - Make sure your Bluetooth is turned on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        log("Found peripheral: \(peripheral.identifier.uuidString), RSSI: \(RSSI.stringValue), advertisementData: \(advertisementData.debugDescription)")
        
        peripherals[peripheral] = RSSI.intValue
        
        blePeripheral = peripheral
        blePeripheral?.delegate = self
        
        connect(to: peripheral)
    }
    
    // MARK: - Connect to peripheral
    
    private func connect(to peripheral: CBPeripheral) {
        manager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
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
        
        let char = service.characteristics?.first(where: { $0.uuid == BLE_CHARACTERISTIC_UUID })
        
        if let characteristic = char {
            peripheral.readValue(for: characteristic)

            log("Read value for Characteristic: \(characteristic.uuid)")
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        if data.count != 16 {
            log("Recieved unexpected data length \(data.count)")
        } else {
            let rollingId = data.base64EncodedString()
            
            log("Recieved rollingId from peripheral: \(rollingId)")
            
            let lastLocation = LocationManager.lastLocation
            
            if let location = lastLocation,
                let rssi = peripherals[peripheral] {
                let encounter = BtEncounter(rssi, location)
                
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
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
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
