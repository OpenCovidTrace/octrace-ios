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
        
        LogsManager.append("<SCAN> Scanning has started")
    }
    
}

extension BtScanningManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            LogsManager.append("<SCAN> Bluetooth Enabled")
        } else {
            LogsManager.append("<SCAN> Bluetooth Disabled - Make sure your Bluetooth is turned on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        LogsManager.append("<SCAN> Found peripheral: \(peripheral.identifier.uuidString), RSSI: \(RSSI.stringValue), advertisementData: \(advertisementData.debugDescription)")
        
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
        LogsManager.append("<SCAN> Connect to: \(peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        LogsManager.append("<SCAN> Fail Connect to: \(peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        LogsManager.append("<SCAN> Disconnected from: \(peripheral.identifier.uuidString)")
    }
    
}

extension BtScanningManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let errorValue = error {
            LogsManager.append("<SCAN> Error discovering services: \(errorValue.localizedDescription)")
            
            return
        }
        
        let bleService = peripheral.services?.first(where: { $0.uuid == BLE_SERVICE_UUID })
        guard let unwrappedBleService = bleService else { return }
        
        LogsManager.append("<SCAN> Discover service: \(unwrappedBleService.uuid.uuidString)")
        
        peripheral.discoverCharacteristics([BLE_CHARACTERISTIC_UUID], for: unwrappedBleService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let errorValue = error {
            LogsManager.append("<SCAN> Error discovering services: \(errorValue.localizedDescription)")
            
            return
        }
        
        let char = service.characteristics?.first(where: { $0.uuid == BLE_CHARACTERISTIC_UUID })
        
        if let characteristic = char {
            peripheral.readValue(for: characteristic)

            LogsManager.append("<SCAN> Read value for Characteristic: \(characteristic.uuid)")
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        if data.count != 16 {
            LogsManager.append("<SCAN> Recieved unexpected data length \(data.count)")
        } else {
            let rollingId = data.base64EncodedString()
            
            LogsManager.append("<SCAN> Recieved rollingId from peripheral: \(rollingId)")
            
            let lastLocation = LocationManager.lastLocation
            
            if let location = lastLocation,
                let rssi = peripherals[peripheral] {
                let encounter = BtEncounter(rssi, location)
                
                BtContactsManager.addContact(rollingId, encounter)
            } else {
                if lastLocation == nil {
                    LogsManager.append("<SCAN> Failed to record contact: no location data.")
                } else {
                    LogsManager.append("<SCAN> Failed to record contact: no rssi data.")
                }
            }
        }
        
        manager.cancelPeripheralConnection(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let errorValue = error {
            LogsManager.append("<SCAN> Error changing notification state: \(errorValue.localizedDescription)")
            
            return
        }
        
        if characteristic.isNotifying {
            LogsManager.append("<SCAN> Subscribed. Notification has begun for: \(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    }
    
}
