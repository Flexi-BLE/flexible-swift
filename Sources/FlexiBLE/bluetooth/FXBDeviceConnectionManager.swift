//
//  FXBDeviceConnectionManager.swift
//  
//
//  Created by blaine on 2/22/22.
//

import Foundation
import CoreBluetooth
import Combine
import GRDB

/// FlexiBLE Bluetooth Enabled CoreBluetooth Delegate
///
/// - Author: Blaine Rothrock
public class FXBDeviceConnectionManager: NSObject {
    
    /// AE Representation of Peripheral
    private let spec: FXBDeviceSpec
    private let peripheral: CBPeripheral
    private var deviceRecord: FXBDeviceRecord
    
    @Published public var batteryLevel: Int?
    @Published public var rssi: Int = 0
    
    internal var observers = Set<AnyCancellable>()
    
    internal var serviceHandlers: [DataStreamHandler] = []
    internal let infoServiceHandler: InfoServiceHandler
    
    internal init(spec: FXBDeviceSpec, peripheral: CBPeripheral, deviceRecord: FXBDeviceRecord) {
        self.spec = spec
        self.peripheral = peripheral
        self.deviceRecord = deviceRecord
        
        self.infoServiceHandler = InfoServiceHandler(
            spec: self.spec,
            peripheral: peripheral,
            deviceRecord: deviceRecord
        )
        
        super.init()
        self.peripheral.delegate = self
        self.peripheral.discoverServices(spec.serviceIds)
    }
    
    public func requestRSSI() {
        peripheral.readRSSI()
    }
}

// MARK: - Core Bluetooth Peripheral Delegate
extension FXBDeviceConnectionManager: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            bleLog.debug("did discover service \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
            
            if let ds = spec.dataStreams.first(where: { $0.serviceCbuuid == service.uuid }) {
                let handler = DataStreamHandler(
                    uuid: service.uuid,
                    deviceName: peripheral.name ?? spec.name,
                    dataStream: ds
                )
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
        } else if service.uuid == spec.infoServiceUuid {
            infoServiceHandler.setup(service: service)
        }
        
        else {
            bleLog.info("found unknown characteristics for service \(service.uuid)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        bleLog.info("did update value for characteristic \(characteristic.uuid)")
        
        if let error = error {
            bleLog.error("BLE Update Error: \(error.localizedDescription)")
            return
        }
        
        guard let service = characteristic.service else { return }
        
        if let handler = serviceHandlers.first(where: { $0.serviceUuid == service.uuid }) {
            
            if let deviceRecord = FlexiBLE.shared.dbAccess?.device.device(id: self.deviceRecord.id) {
                handler.didUpdate(
                    uuid: characteristic.uuid,
                    data: characteristic.value,
                    referenceDate: deviceRecord.referenceDate
                )
                self.deviceRecord = deviceRecord
            }
        } else if service.uuid == spec.infoServiceUuid {
            infoServiceHandler.didUpdate(characteristic: characteristic)
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
        } else if service.uuid == spec.infoServiceUuid {
            infoServiceHandler.didWrite(uuid: characteristic.uuid)
        }
        
        peripheral.readValue(for: characteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.rssi = Int(truncating: RSSI)
    }
}

// MARK: - Core Bluetooth Delegate Helpers
extension FXBDeviceConnectionManager {
    // TODO: A place for this sort of thing
}


// MARK: - Registered Services
extension FXBDeviceConnectionManager {
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


