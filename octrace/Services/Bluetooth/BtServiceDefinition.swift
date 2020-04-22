import Foundation
import CoreBluetooth

let BLE_SERVICE_UUID = CBUUID(nsuuid: UUID(uuidString: "6e400002-b5a3-f393-e0a9-e50e24dcca9f")!)

let BLE_CHARACTERISTIC_UUID = CBUUID(nsuuid: UUID(uuidString: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")!)


extension CBManagerState {
    func name() -> String {
        switch self {
        case .unknown:
            return "UNKNOWN"
        case .unsupported:
            return "UNSUPPORTED"
        case .unauthorized:
            return "UNAUTHORIZED"
        case .resetting:
            return "RESETTING"
        case .poweredOff:
            return "POWERED OFF"
        case .poweredOn:
            return "POWERED ON"
        @unknown default:
            return "Unknown State"
        }
    }
}
