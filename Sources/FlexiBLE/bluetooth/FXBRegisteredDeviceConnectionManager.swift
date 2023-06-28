//
//  AEBLERegisteredPeripheral.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetooth

public class FXBRegisteredDeviceConnectionManager: NSObject, ObservableObject {
    
    var isEnabled: Bool = true
    
    /// FlexiBLE device representation
    public let deviceRecord: FXBDeviceRecord
    private let spec: FXBRegisteredDeviceSpec
    private let peripheral: CBPeripheral
    
    internal var serviceHandlers: [ServiceHandler] = []
    
    @Published public var batteryLevel: Int?
    @Published public var rssi: Int = 0
    
    internal init(deviceRecord: FXBDeviceRecord, spec: FXBRegisteredDeviceSpec, periperal: CBPeripheral) {
        self.deviceRecord = deviceRecord
        self.spec = spec
        self.peripheral = periperal
        
        super.init()
        peripheral.delegate = self
        peripheral.discoverServices(spec.serviceIds)
    }
    
    public func requestRSSI() {
        peripheral.readRSSI()
    }
}

// MARK: - Core Bluetooth Peripheral Delegate
extension FXBRegisteredDeviceConnectionManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            bleLog.debug("did discover registered service \(service.uuid)")
            if spec.serviceIds.contains(service.uuid) {
                peripheral.discoverCharacteristics(nil, for: service)
                
                if let registeredService = BLERegisteredService.from(service.uuid) {
                    
                    serviceHandlers.append(registeredService.handler(deviceRecord: deviceRecord, peripheral: peripheral))
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
            handler.setup(service: service)
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
            handler.didUpdate(
                characteristic: characteristic
            )
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

