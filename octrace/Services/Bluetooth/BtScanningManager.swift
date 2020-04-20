import Foundation
import CoreBluetooth
import UIKit

class BtScanningManager: NSObject {
    
    static let shared = BtScanningManager()
    
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
        
        NSLog("[BT_SCAN] Scanning has started")
    }
    
}

extension BtScanningManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            NSLog("[BT_SCAN] Bluetooth Enabled")
        } else {
            NSLog("[BT_SCAN] Bluetooth Disabled - Make sure your Bluetooth is turned on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        NSLog("[BT_SCAN] Found peripheral: \(peripheral.identifier.uuidString), RSSI: \(RSSI.stringValue), advertisementData: \(advertisementData.debugDescription)")
        
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
        NSLog("[BT_SCAN] Connect to: \(peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("[BT_SCAN] Fail Connect to: \(peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("[BT_SCAN] Disconnected from: \(peripheral.identifier.uuidString)")
    }
    
}

extension BtScanningManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let errorValue = error {
            NSLog("[BT_SCAN] Error discovering services: \(errorValue.localizedDescription)")
            
            return
        }
        
        let bleService = peripheral.services?.first(where: { $0.uuid == BLE_SERVICE_UUID })
        guard let unwrappedBleService = bleService else { return }
        
        NSLog("[BT_SCAN] Discover service: \(unwrappedBleService.uuid.uuidString)")
        
        peripheral.discoverCharacteristics([BLE_CHARACTERISTIC_UUID], for: unwrappedBleService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let errorValue = error {
            NSLog("[BT_SCAN] Error discovering services: \(errorValue.localizedDescription)")
            
            return
        }
        
        let char = service.characteristics?.first(where: { $0.uuid == BLE_CHARACTERISTIC_UUID })
        
        if let characteristic = char {
            peripheral.readValue(for: characteristic)

            NSLog("[BT_SCAN] Read value for Characteristic: \(characteristic.uuid)")
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        if data.count != 16 {
            NSLog("[BT_SCAN] Recieved unexpected data length \(data.count)")
        } else {
            let rollingId = data.base64EncodedString()
            
            NSLog("[BT_SCAN] Recieved rollingId from peripheral: \(rollingId)")
            
            let lastLocation = LocationManager.lastLocation
            
            if let location = lastLocation,
                let rssi = peripherals[peripheral] {
                let encounter = BtEncounter(rssi, location)
                
                BtContactsManager.addContact(rollingId, encounter)
            } else {
                if lastLocation == nil {
                    NSLog("[BT_SCAN] Failed to record contact: no location data.")
                } else {
                    NSLog("[BT_SCAN] Failed to record contact: no rssi data.")
                }
            }
        }
        
        manager.cancelPeripheralConnection(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let errorValue = error {
            NSLog("[BT_SCAN] Error changing notification state: \(errorValue.localizedDescription)")
            
            return
        }
        
        if characteristic.isNotifying {
            NSLog("[BT_SCAN] Subscribed. Notification has begun for: \(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    }
    
}
