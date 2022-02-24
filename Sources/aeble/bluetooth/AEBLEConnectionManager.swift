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
    
    @Published var centralState: CBManagerState = .unknown
    @Published var isScanning: Bool = false
        
    @Published private(set) var peripherals: [AEBLEPeripheral] = []
    
    private var scanOnPoweredOn: Bool = true
    private let db: AEBLEDBManager
    
    required init(db: AEBLEDBManager) {
        self.db = db
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    internal func scan(with payload: PeripheralMetadataPayload) {
        for peripheralMetadata in payload.peripherals ?? [] {
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
            services.append(contentsOf: p.metadata.serviceIds)
        }
        
        bleLog.info("starting scan for services: \(services)")
        
        centralManager.scanForPeripherals(
            withServices:services,
            options: nil
        )
        isScanning = centralManager.isScanning
    }
    
    internal func stopScan() {
        centralManager.stopScan()
        isScanning = centralManager.isScanning
    }
    
    internal func disconnect(_ peripheral: AEBLEPeripheral) {
        guard let p = peripheral.peripheral else { return }
        
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
        guard let peri = peripherals.first(where: { $0.metadata.name == peripheral.name }) else { return }
        
        peri.set(peripheral: peripheral)
        bleLog.info("Peripheral Found \(peri.metadata.name)")
        
        centralManager.connect(
            peripheral,
            options: [
                CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
            ]
        )
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let peri = peripherals.first(where: { $0.metadata.name == peripheral.name }) else { return }
        bleLog.info("connceted to: \(peri.metadata.name)")
        peri.didUpdateState()
        stopScan()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let peri = peripherals.first(where: { $0.metadata.name == peripheral.name }) else { return }
        bleLog.info("\(peri.metadata.name) disconnected")
        peri.didUpdateState()
        
        startScan()
    }
}

extension AEBLEConnectionManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        bleLog.info("Services Discovered: \(peripheral.services ?? [])")
    }
}
