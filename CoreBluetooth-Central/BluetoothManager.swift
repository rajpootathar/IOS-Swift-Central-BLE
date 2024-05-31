import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = BluetoothManager()

    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var message: [String] = []
    var centralManager: CBCentralManager!
    var serviceUUID: CBUUID = CBUUID(string: "C8D89CD2-E1A8-4434-B41C-3159E8CA0981")

    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "com.example.MyApp.BluetoothManager"])
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Scan Started")
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        } else {
            print("Central manager state: \(central.state.rawValue)")
        }
    }
    
    func removeDiscoveredPeripherals() {
        print("Removing")
        discoveredPeripherals = []
        print("Removed")
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Peripheral Device: ", peripheral.name ?? "Unknown", peripheral.services?.first ?? "No services")

        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        print("Connected")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }

        for service in peripheral.services ?? [] {
            if service.uuid == serviceUUID {
                print("Discovered service with UUID: \(service.uuid)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }

        print("Found \(service.characteristics?.count ?? 0) characteristics for service \(service.uuid): \(String(describing: service.characteristics))")
        
        for characteristic in service.characteristics ?? [] {
            print("Characteristic UUID: \(characteristic.uuid)")

            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error reading characteristic value: \(error!.localizedDescription)")
            return
        }

        if let value = characteristic.value {
            if let stringValue = String(data: value, encoding: .utf8) {
                print("Characteristic \(characteristic.uuid) value: \(stringValue)")
                DispatchQueue.main.async {
                    self.message.append(stringValue)
                }
            } else {
                print("Failed to decode characteristic value as UTF-8 string")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("Restoring state...")
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                print("Restoring peripheral: \(peripheral.name ?? "Unknown Device")")
                peripheral.delegate = self
                if !discoveredPeripherals.contains(peripheral) {
                    discoveredPeripherals.append(peripheral)
                }
                if peripheral.state == .connected {
                    peripheral.discoverServices([serviceUUID])
                } else {
                    // Attempt to connect to the peripheral
                    centralManager.connect(peripheral, options: nil)
                }
            }
            print("Restored \(peripherals.count) peripherals.")
        } else {
            print("No peripherals to restore")
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }
}
