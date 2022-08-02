//
//  AEBLERegisteredPeripheral.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetooth

public class AEBLERegisteredPeripheral: NSObject, ObservableObject {
    @Published public private(set) var state: AEBLEPeripheralState = .disconnected
    
    var isEnabled: Bool = true
    
    /// AE Representation of Peripheral
    public let metadata: AEBLERegisteredDevice
    
    internal var serviceHandlers: [AEBLEServiceHandler] = []
    
    @Published public var batteryLevel: Int?
    @Published public var rssi: Int = 0
    
    internal var cbp: CBPeripheral?
    
    internal init(metadata: AEBLERegisteredDevice) {
        self.metadata = metadata
    }
    
    internal func set(peripheral: CBPeripheral) {
        if self.cbp == nil {
            self.cbp = peripheral
            self.didUpdateState()
        }
    }
    
    internal func didUpdateState() {
        guard let peripheral = self.cbp else { return }
        
        switch peripheral.state {
        case .connected, .connecting: self.onConnect()
        default: self.onDisconnect()
        }
    }
    
    public func requestRSSI() {
        cbp?.readRSSI()
    }
    
    private func onConnect() {
        guard let peripheral = self.cbp else { return }
        self.state = .connected
        peripheral.delegate = self
        
        peripheral.discoverServices(metadata.serviceIds)
    }
    
    private func onDisconnect() {
        self.serviceHandlers = []
        self.state = .disconnected
    }
}

// MARK: - Core Bluetooth Peripheral Delegate
extension AEBLERegisteredPeripheral: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            bleLog.debug("did discover registered service \(service.uuid)")
            if metadata.serviceIds.contains(service.uuid) {
                peripheral.discoverCharacteristics(nil, for: service)
                
                if let registeredService = BLERegisteredService.from(service.uuid) {
                    
                    serviceHandlers.append(registeredService.handler())
                }
            }
            
            
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else {
            bleLog.error("no registered characteristics found for \(service.uuid)")
            return
        }
        
        bleLog.info("found registered \(characteristics.count) characteristics for service \(service.uuid)")
        
        
        if let handler = serviceHandlers.first(where: { $0.serviceUuid == service.uuid }) {
            handler.setup(peripheral: peripheral, service: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        
        bleLog.info("did update value for registered descriptor \(descriptor.uuid)")
        
        if let error = error {
            bleLog.error("BLE descriptor Update Error: \(error.localizedDescription)")
            return
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        bleLog.info("did update value for registered characteristic \(characteristic.uuid)")
        
        if let error = error {
            bleLog.error("BLE Update Error: \(error.localizedDescription)")
            return
        }
        
        guard let service = characteristic.service else { return }
        
        
        if let handler = serviceHandlers.first(where: { $0.serviceUuid == service.uuid }) {
            handler.didUpdate(uuid: characteristic.uuid, data: characteristic.value)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        bleLog.info("did write value for characteristic \(characteristic.uuid)")
        
        if let error = error {
            bleLog.error("BLE Write Error: \(error.localizedDescription)")
            return
        }
        
        guard let service = characteristic.service else { return }
        
        if let handler = serviceHandlers.first(where: { $0.serviceUuid == service.uuid }) {
            handler.didWrite(uuid: service.uuid)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.rssi = Int(truncating: RSSI)
    }
}

