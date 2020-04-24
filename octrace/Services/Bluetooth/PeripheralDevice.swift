import CoreBluetooth

struct PeripheralDevice {
    
    let peripheral: CBPeripheral
    let response: String?
    let rssi: Int
    
    init(peripheral: CBPeripheral, rssi: Int, response: String? = nil) {
        self.peripheral = peripheral
        self.rssi = rssi
        self.response = response
    }
}

extension PeripheralDevice: Equatable {
    static func == (lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        return (lhs.peripheral.identifier.uuidString == rhs.peripheral.identifier.uuidString) && (lhs.rssi == rhs.rssi)
    }
}
