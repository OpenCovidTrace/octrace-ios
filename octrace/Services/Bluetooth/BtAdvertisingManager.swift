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
                                  CBAdvertisementDataServiceUUIDsKey: [BtServiceDefinition.bleServiceUuid]])
    }
    
    private func log(_ text: String) {
        BtLogsManager.append(tag: BtAdvertisingManager.tag, text: text)
    }
}

extension BtAdvertisingManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        log(peripheral.state.name())

        if peripheral.state == .poweredOn {
            let characteristic = CBMutableCharacteristic(type: BtServiceDefinition.bleCharacteristicUuid,
                                                         properties: [.read],
                                                         value: nil,
                                                         permissions: [.readable])
            
            let service = CBMutableService(type: BtServiceDefinition.bleServiceUuid, primary: true)
            service.characteristics = [characteristic]
            manager.add(service)
            
            startAdvertising()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        log("Advertising has started")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        let data = CryptoUtil.getCurrentRpi()
        
        if request.offset > data.count {
            manager.respond(to: request, withResult: .invalidOffset)
            
            return
        }
        
        let range = request.offset..<data.count
        request.value = data.subdata(in: range)
        manager.respond(to: request, withResult: .success)
        
        log("Sent RPI to \(request.characteristic.uuid.uuidString)")
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
