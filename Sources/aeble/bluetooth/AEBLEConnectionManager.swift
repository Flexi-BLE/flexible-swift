//
//  AEBLEConnectionManager.swift
//  
//
//  Created by blaine on 2/22/22.
//

import Foundation
import CoreBluetooth
import Combine

public class AEBLEConnectionManager: NSObject, ObservableObject {
    var centralManager: CBCentralManager!
    
    @Published public private(set) var centralState: CBManagerState = .unknown
    @Published public private(set) var isScanning: Bool = false
        
    @Published public private(set) var peripherals: [AEBLEPeripheral] = []
    
    private var scanOnPoweredOn: Bool = true
    private let db: AEBLEDBManager
    
    required init(db: AEBLEDBManager) {
        self.db = db
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func peripheral(for name: String) -> AEBLEPeripheral? {
        return peripherals.first(where: { $0.metadata.name == name })
    }
    
    public func disable(thing: AEThing) {
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
            if isScanning { startScan() }
        }
    }
    
    public func enable(thing: AEThing) {
        guard let p = self.peripherals.first(where: { $0.metadata.name == thing.name }) else {
            return
        }
        
        if p.isEnabled && p.state == .connected { return }
        
        p.isEnabled = true
        if isScanning { startScan() }
    }
    
    public func updateConfig(
        thingName: String,
        dataSteam: AEDataStream,
        data: Data
    ) {
        
        if let p = peripherals.first(where: { $0.metadata.name == thingName }) {
            if let dsh = p.serviceHandlers.first(where: { $0.def.name == dataSteam.name }),
               let cbp = p.cbp {
                
                dsh.writeConfig(peripheral: cbp, data: data)
            }
        }
        
    }
    
    internal func scan(with payload: AEDeviceConfig) {
        for peripheralMetadata in payload.things {
            let AEBLEPeripheral = AEBLEPeripheral(
                metadata: peripheralMetadata,
                db: self.db
            )
            self.peripherals.append(AEBLEPeripheral)
        }
        
        guard centralManager.state == .poweredOn else { return }
        
        if isScanning { stopScan() }
        startScan()
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

        guard services.count > 0 else {
            bleLog.info("scanning enabled, but no services, not starting scan.")
            return
        }

        bleLog.info("starting scan for services: \(services)")
        
        centralManager.scanForPeripherals(
            withServices:nil,
            options: nil
        )
        isScanning = centralManager.isScanning
    }
    
    internal func stopScan() {
        centralManager.stopScan()
        isScanning = centralManager.isScanning
    }
    
    internal func disconnect(_ peripheral: AEBLEPeripheral) {
        guard let p = peripheral.cbp else { return }
        
        centralManager.cancelPeripheralConnection(p)
    }
    
    private func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: [:])
    }
}

extension AEBLEConnectionManager: CBCentralManagerDelegate {
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
        guard let peri = peripherals.first(where: { $0.metadata.name == peripheral.name }),
                peri.isEnabled else { return }
        
        peri.set(peripheral: peripheral)
        bleLog.info("Peripheral Found \(peri.metadata.name)")
        
        centralManager.connect(
            peripheral
//            options: [
//                CBConnectPeripheralOptionNotifyOnConnectionKey: true,
//                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
//            ]
        )
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let peri = peripherals.first(where: { $0.metadata.name == peripheral.name }) else { return }
        bleLog.info("connceted to: \(peri.metadata.name)")
        peri.didUpdateState()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let peri = peripherals.first(where: { $0.metadata.name == peripheral.name }) else { return }
        bleLog.info("\(peri.metadata.name) disconnected")
        peri.didUpdateState()
        
        if (isScanning) { startScan() }
    }
}

extension AEBLEConnectionManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        bleLog.info("Services Discovered: \(peripheral.services ?? [])")
    }
}
