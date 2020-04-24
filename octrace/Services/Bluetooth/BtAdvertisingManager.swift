import Foundation
import CoreBluetooth

class BtAdvertisingManager: NSObject {
    
    static let shared = BtAdvertisingManager()
    
    private static let tag = "ADV"
    
    private var manager: CBPeripheralManager!

    func setup() {
        manager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    private func startAdvertising() {
        manager.startAdvertising([CBAdvertisementDataLocalNameKey: "BLEPrototype",
                                  CBAdvertisementDataServiceUUIDsKey: [BLE_SERVICE_UUID]])
    }
    
    private func log(_ text: String) {
        LogsManager.append(tag: BtAdvertisingManager.tag, text: text)
    }
}

extension BtAdvertisingManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        log(peripheral.state.name())

        if peripheral.state == .poweredOn {
			let data = SecurityUtil.getRollingId()
            let characteristic = CBMutableCharacteristic(type: BLE_CHARACTERISTIC_UUID,
                                                         properties: [.read],
                                                         value: data,
                                                         permissions: [.readable])
            let service = CBMutableService(type: BLE_SERVICE_UUID, primary: true)
            service.characteristics = [characteristic]
            manager.add(service)
            
            startAdvertising()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        log("Advertising has started")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
//        let data = SecurityUtil.getRollingId()
//        if request.offset > data.count {
//            manager.respond(to: request, withResult: .invalidOffset)
//
//            return
//        }
//        
//        let range = request.offset..<data.count
//        request.value = data.subdata(in: range)
//
//        manager.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic) {
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
    }
    
}
