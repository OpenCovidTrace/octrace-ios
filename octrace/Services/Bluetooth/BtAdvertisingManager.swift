import Foundation
import CoreBluetooth

class BtAdvertisingManager: NSObject {
    
    static let shared = BtAdvertisingManager()
    
    private static let tag = "ADV"
    
    private var manager: CBPeripheralManager!
    private var managerPoweredOn: (() -> Void)?

    override private init() {
        super.init()
        
        manager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    // MARK: - Services
    
    func startService() {
        managerPoweredOn = { [weak self] in
            self?.addServices()
        }
    }
    
    private func addServices() {
        let characteristic = CBMutableCharacteristic(type: BLE_CHARACTERISTIC_UUID, properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])

        let service = CBMutableService(type: BLE_SERVICE_UUID, primary: true)
        service.characteristics = [characteristic]
        manager.add(service)
        
        startAdvertising()
    }
    
    private func startAdvertising() {
        manager.startAdvertising([CBAdvertisementDataLocalNameKey: "BLEPrototype", CBAdvertisementDataServiceUUIDsKey: [BLE_SERVICE_UUID]])
        
        log("Advertising has started")
    }
    
    private func log(_ text: String) {
        LogsManager.append(tag: BtAdvertisingManager.tag, text: text)
    }
}

extension BtAdvertisingManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            log("Bluetooth Device is UNKNOWN")
        case .unsupported:
            log("Bluetooth Device is UNSUPPORTED")
        case .unauthorized:
            log("Bluetooth Device is UNAUTHORIZED")
        case .resetting:
            log("Bluetooth Device is RESETTING")
        case .poweredOff:
            log("Bluetooth Device is POWERED OFF")
        case .poweredOn:
            log("Bluetooth Device is POWERED ON")
            managerPoweredOn?()
        @unknown default:
            log("Unknown State")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        let data = SecurityUtil.getRollingId()
        if request.offset > data.count {
            manager.respond(to: request, withResult: .invalidOffset)
            
            return
        }
        
        let range = request.offset..<data.count
        request.value = data.subdata(in: range)
        
        manager.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
    }
    
}
