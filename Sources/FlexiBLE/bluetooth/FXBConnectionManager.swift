//
//  AEBLEConnectionManager.swift
//  
//
//  Created by blaine on 2/22/22.
//

import Foundation
import CoreBluetooth
import Combine

public class FXBConnectionManager: NSObject, ObservableObject {
    var centralManager: CBCentralManager!
    
    @Published public private(set) var centralState: CBManagerState = .unknown
    @Published public private(set) var isScanning: Bool = false
        
    @Published public private(set) var peripherals: [FXBPeripheral] = []
    @Published public private(set) var registeredPeripherals: [FXBRegisteredPeripheral] = []
    
    private var scanOnPoweredOn: Bool = true
    private let db: FXBDBManager
    
    required init(db: FXBDBManager) {
        self.db = db
        super.init()
        
        self.centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: "AEBLE"]
        )
    }
    
    public func peripheral(for name: String) -> FXBPeripheral? {
        return peripherals.first(where: { $0.metadata.name == name })
    }
    
    public func registeredPeripheral(for name: String) -> FXBRegisteredPeripheral? {
        return registeredPeripherals.first(where: { $0.metadata.name == name })
    }
    
    public func disable(thing: FXBDevice) {
        guard let p = self.peripherals.first(where: { $0.metadata.name == thing.name }) else {
            return
        }
        
        if !p.isEnabled { return }
        
        switch p.state {
        case .connected:
            p.isEnabled = false
            if let cbPeripheral = p.cbp {
                centralManager.cancelPeripheralConnection(cbPeripheral)
            }
        default:
            p.isEnabled = false
        }
        toggleScanWithConnections()
    }
    
    public func disable(registeredDevice: FXBRegisteredDevice) {
        guard let p = self.registeredPeripherals.first(where: { $0.metadata.name == registeredDevice.name }) else {
            return
        }
        
        if !p.isEnabled { return }
        
        switch p.state {
        case .connected:
            p.isEnabled = false
            if let cbPeripheral = p.cbp {
                centralManager.cancelPeripheralConnection(cbPeripheral)
            }
        default:
            p.isEnabled = false
        }
        
        toggleScanWithConnections()
    }
    
    public func enable(thing: FXBDevice) {
        guard let p = self.peripherals.first(where: { $0.metadata.name == thing.name }) else {
            return
        }
        
        if p.isEnabled && p.state == .connected { return }
        
        p.isEnabled = true
        
        toggleScanWithConnections()
    }
    
    public func enable(registeredDevice: FXBRegisteredDevice) {
        guard let p = self.registeredPeripherals.first(where: { $0.metadata.name == registeredDevice.name }) else {
            return
        }
        
        if p.isEnabled && p.state == .connected { return }
        
        p.isEnabled = true
        
        toggleScanWithConnections()
    }
    
    public func updateConfig(
        thingName: String,
        dataSteam: FXBDataStream,
        data: Data
    ) {
        
        if let p = peripherals.first(where: { $0.metadata.name == thingName }) {
            if let dsh = p.serviceHandlers.first(where: { $0.def.name == dataSteam.name }),
               let cbp = p.cbp {
                
                dsh.writeConfig(peripheral: cbp, data: data)
            }
        }
        
    }
    
    internal func scan(with payload: FXBSpec) {
        for peripheralMetadata in payload.devices {
            let p = FXBPeripheral(
                metadata: peripheralMetadata,
                db: self.db
            )
            self.peripherals.append(p)
        }
        
        for rdm in payload.bleRegisteredDevices {
            if registeredPeripherals.first(where: { $0.metadata.name != rdm.name }) == nil {
                let dp = FXBRegisteredPeripheral(metadata: rdm)
                self.registeredPeripherals.append(dp)
            }
        }
        
        guard centralManager.state == .poweredOn else { return }
        
        if isScanning { stopScan() }
        startScan()
    }
    
    private func toggleScanWithConnections() {
        var allConnected = true
        
        for p in peripherals {
            if p.isEnabled && p.state != .connected {
                allConnected = false
                break
            }
        }
        
        for p in registeredPeripherals {
            if p.isEnabled && p.state != .connected {
                allConnected = false
                break
            }
        }
        
        if allConnected {
            stopScan()
        } else {
            startScan()
        }
    }
    
    private func startScan() {
        guard centralManager.state == .poweredOn else {
            bleLog.fault("central manager state is not on: \(self.centralManager.state.rawValue)")
            return
        }
        
        var services: [CBUUID] = []
        for p in self.peripherals {
            if p.isEnabled {
                services.append(contentsOf: p.metadata.serviceIds)
            }
        }
        
        for device in self.registeredPeripherals {
            if device.isEnabled {
                services.append(contentsOf: device.metadata.serviceIds)
            }
        }

        guard services.count > 0 else {
            bleLog.info("scanning enabled, but no services, not starting scan.")
            return
        }

        bleLog.info("started scan")
        bleLog.info("scanning for devices with services: \(services)")
        
        centralManager.scanForPeripherals(
            withServices:nil,
            options: nil
        )
        isScanning = centralManager.isScanning
    }
    
    internal func stopScan() {
        centralManager.stopScan()
        isScanning = centralManager.isScanning
        
        bleLog.info("stopped scan")
    }
    
    internal func disconnect(_ peripheral: FXBPeripheral) {
        guard let p = peripheral.cbp else { return }
        
        centralManager.cancelPeripheralConnection(p)
    }
    
    private func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: [:])
    }
}

extension FXBConnectionManager: CBCentralManagerDelegate {
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let perfs = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for perf in perfs {
                print(perf)
            }
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.centralState = central.state
        
        switch central.state {
        case .poweredOn:
            print("powered on")
            if scanOnPoweredOn { startScan() }
        default: break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let p = peripherals.first(where: { $0.metadata.name == peripheral.name }),
           p.isEnabled {
            p.set(peripheral: peripheral)
            bleLog.info("Peripheral Found \(p.metadata.name)")
            
            if peripheral.state == .disconnected {
                centralManager.connect(
                    peripheral
                )
            }
            
        } else if let p = registeredPeripherals.first(where: { $0.metadata.name == peripheral.name }),
                  p.isEnabled {
            
            p.set(peripheral: peripheral)
            
            if peripheral.state == .disconnected {
                bleLog.info("Registered Peripheral Found \(p.metadata.name)")
                centralManager.connect(
                    peripheral
                )
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        if let p = peripherals.first(where: { $0.metadata.name == peripheral.name }) {
            bleLog.info("connceted to: \(p.metadata.name)")
            p.didUpdateState()
            Task {
                try? await FXBWrite().recordConnection(
                    deviceName: p.metadata.name,
                    status: .connected
                )
            }
        } else if let p = registeredPeripherals.first(where: { $0.metadata.name == peripheral.name }) {
            bleLog.info("connceted to: \(p.metadata.name)")
            p.didUpdateState()
            Task {
                try? await FXBWrite().recordConnection(
                    deviceName: p.metadata.name,
                    status: .connected
                )
            }
        }
        
        toggleScanWithConnections()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if let p = peripherals.first(where: { $0.metadata.name == peripheral.name }) {
            bleLog.info("\(p.metadata.name) disconnected")
            p.didUpdateState()
            Task {
                try? await FXBWrite().recordConnection(
                    deviceName: p.metadata.name,
                    status: .disconnected
                )
            }
        } else if let p = registeredPeripherals.first(where: { $0.metadata.name == peripheral.name }) {
            bleLog.info("\(p.metadata.name) disconnected")
            p.didUpdateState()
            Task {
                try? await FXBWrite().recordConnection(
                    deviceName: p.metadata.name,
                    status: .disconnected
                )
            }
        }
        
        if (isScanning) { startScan() }
    }
}
