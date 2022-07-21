//
//  AEBLEPeripheral.swift
//  
//
//  Created by blaine on 2/22/22.
//

import Foundation
import CoreBluetooth
import Combine
import GRDB

public enum AEBLEPeripheralState: String {
    case notFound = "not found"
    case connected = "connected"
    case disconnected = "disconnected"
}

/// AEBLE Bluetooth Enabled CoreBluetooth Delegate
///
/// - Author: Blaine Rothrock
public class AEBLEPeripheral: NSObject, ObservableObject {
    @Published public private(set) var state: AEBLEPeripheralState = .disconnected
    
    var isEnabled: Bool = true
    
    /// AE Representation of Peripheral
    public let metadata: AEThing
    
    @Published public var batteryLevel: Int?
    @Published public var rssi: Int = 0
    
    internal var serviceHandlers: [AEBLEDataStreamHandler] = []
    private var uploaders: [AEStreamDataUploader] = []
    
    /// Reference to database
    /// - Remark:
    ///  Holding reference to the database is not ideal, this should be reworked to require database dependency.
    private let db: AEBLEDBManager

    /// Core Bluetooth Peripheral
    internal var cbp: CBPeripheral?
    
    internal init(metadata: AEThing, db: AEBLEDBManager) {
        self.metadata = metadata
        self.db = db
    }
    
    internal func set(peripheral: CBPeripheral) {
        self.cbp = peripheral
        self.didUpdateState()
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
extension AEBLEPeripheral: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            bleLog.debug("did discover service \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
            
            if let ds = metadata.dataStreams.first(where: { $0.serviceCbuuid == service.uuid }) {
                let handler = AEBLEDataStreamHandler(uuid: service.uuid, def: ds)
                serviceHandlers.append(handler)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            bleLog.error("no characteristics found for \(service.uuid)")
            return
        }
        
        bleLog.info("found \(characteristics.count) characteristics for service \(service.uuid)")
        
        if let _ = BLERegisteredService.from(service.uuid) {
            handleRegisteredServiceDiscovery(peripheral: peripheral, service: service)
        } else if let handler = serviceHandlers.first(where: { $0.serviceUuid == service.uuid }) {
            handler.setup(peripheral: peripheral, service: service)
        } else {
            bleLog.info("found unknown characteristics for service \(service.uuid)")
        }

        // TODO: Manager Service
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        bleLog.info("did update value for characteristic \(characteristic.uuid)")
        
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
            handler.didWrite(uuid: characteristic.uuid)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.rssi = Int(truncating: RSSI)
    }
}

// MARK: - Core Bluetooth Delegate Helpers
extension AEBLEPeripheral {
    // TODO: A place for this sort of thing
}


// MARK: - Registered Services
extension AEBLEPeripheral {
    func handleRegisteredServiceDiscovery(peripheral: CBPeripheral, service: CBService) {
        guard let regSvc = BLERegisteredService.from(service.uuid) else { return }
        
        switch regSvc {
        case .battery: setupBatteryLevel(peripheral: peripheral, service: service)
        case .currentTime: setupCurrentTimeService(peripheral: peripheral, service: service)
        default: break
        }
    }
    
    func setupBatteryLevel(peripheral: CBPeripheral, service: CBService) {
        guard let batLevelChar = service.characteristics?.first(where: { $0.uuid == CBUUID(string: "2a19") }) else { return }
        
        peripheral.setNotifyValue(true, for: batLevelChar)
        peripheral.readValue(for: batLevelChar)
    }
    
    func setupCurrentTimeService(peripheral: CBPeripheral, service: CBService) {
        // TODO: implement
        print("placeholder: setup current time service")
    }
    
    func handleRegisteredServiceUpdate(peripheral: CBPeripheral, char: CBCharacteristic) {
        guard let service = char.service else { return }
        switch BLERegisteredService.from(service.uuid) {
        case .battery: didUpdateBattery(char)
        case .currentTime: didUpdateCurrentTime(char)
        default: break
        }
    }
    
    func didUpdateBattery(_ char: CBCharacteristic) {
        guard let data = char.value else {
            return
        }
        self.batteryLevel = Int(data[0])
    }
    
    func didUpdateCurrentTime(_ char: CBCharacteristic) {
        // TODO: implement
        print("placeholder: did update current time")
    }
}


