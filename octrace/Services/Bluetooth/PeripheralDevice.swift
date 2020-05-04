import CoreBluetooth

struct PeripheralDevice {
    
    let peripheral: CBPeripheral
    let rssi: Int
    
    init(peripheral: CBPeripheral, rssi: Int) {
        self.peripheral = peripheral
        self.rssi = rssi
    }

}

extension PeripheralDevice: Equatable {
    static func == (lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        return (lhs.peripheral.identifier.uuidString == rhs.peripheral.identifier.uuidString) && (lhs.rssi == rhs.rssi)
    }
}
