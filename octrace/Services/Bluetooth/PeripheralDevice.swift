import CoreBluetooth

class PeripheralDevice {
    
    var peripheral: CBPeripheral
    var response: String?
    
    init(peripheral: CBPeripheral, response: String? = nil) {
        self.peripheral = peripheral
        self.response = response
    }
}

extension PeripheralDevice: Equatable {
    static func == (lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        return lhs.peripheral.identifier.uuidString == rhs.peripheral.identifier.uuidString
    }
}
