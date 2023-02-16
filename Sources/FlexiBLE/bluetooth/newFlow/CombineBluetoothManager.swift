//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/15/23.
//

import Foundation
import os
import Combine
import CoreBluetoothMock

public typealias FoundPeripheral = (peripheral: CBPeripheral, advertismentData: CBAdvertisementData)

internal extension CBManagerState {
    var string: String {
        switch self {
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        case .resetting: return "Resetting"
        case .unauthorized: return "Unauthorized"
        case .unknown: return "Unknown"
        case .unsupported: return "Unsupported"
        }
    }
}

final class CombineBluetoothManager: NSObject {
    static let shared: CombineBluetoothManager = .init()
    
    // Central
    internal var stateSubject: PassthroughSubject<CBManagerState, Never> = .init()
    internal var discoverSubject: PassthroughSubject<FoundPeripheral, Never> = .init()
    internal var connectSubject: PassthroughSubject<CBPeripheral, Never> = .init()
    internal var disconnectSubject: PassthroughSubject<(periperal: CBPeripheral, error: Error?), Never> = .init()
    
    // Peripheral
    internal var servicesSubject: PassthroughSubject<(peripheral: CBPeripheral, services: [CBService], error: Error?), Never> = .init()
    internal var characteristicsSubject: PassthroughSubject<(peripheral: CBPeripheral, service: CBService, characteristics: [CBCharacteristic], error: Error?), Never> = .init()
    internal var updateValueSubject: PassthroughSubject<(peripheral: CBPeripheral, characteristic: CBCharacteristic, data: Data?, error: Error?), Never> = .init()
    internal var didWriteValueSubject: PassthroughSubject<(peripheral: CBPeripheral, characteristic: CBCharacteristic, data: Data?, error: Error?), Never> = .init()
    
    private let log = Logger(subsystem: "com.flexiBLE.ble", category: "bleManager")
    
    private var centralManager: CBCentralManager!
     
    func start() {
        centralManager = CBCentralManagerFactory.instance(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: "FlexiBLE"]
        )
    }
    
    func stop() {
        centralManager.stopScan()
    }
    
    func scan(services: [CBUUID]=[]) {
        log.info("starting scan")
        centralManager.stopScan()
        centralManager.scanForPeripherals(withServices: [CBUUID.FlexiBLEServiceUUID] + services)
    }
    
    func connect(_ peripheral: CBPeripheral) {
        log.info("connect peripheral: \(peripheral.identifier)")
        peripheral.delegate = self
        centralManager.connect(peripheral)
    }
}

// MARK: - Bluetooth Central Delegate
extension CombineBluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBMCentralManager) {
        log.info("did update central manager state: \(central.state.string)")
        stateSubject.send(central.state)
    }
    
    func centralManager(_ central: CBMCentralManager, didDiscover peripheral: CBMPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let advData = CBAdvertisementData(data: advertisementData)
        log.info("did discover peripheral \(advData.name ?? "--unknown--") (\(peripheral.identifier)")
        discoverSubject.send((peripheral, advData))
    }
    
    func centralManager(_ central: CBMCentralManager, didDisconnectPeripheral peripheral: CBMPeripheral, error: Error?) {
        log.info("did disconnect peripheral \(peripheral.identifier)")
        disconnectSubject.send((peripheral, error))
    }
    
    func centralManager(_ central: CBMCentralManager, didConnect peripheral: CBMPeripheral) {
        log.info("did connect peripheral \(peripheral.identifier)")
        connectSubject.send(peripheral)
        peripheral.discoverServices(nil)
    }
}

// MARK: - Peripheral Delegate
extension CombineBluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBMPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            servicesSubject.send((peripheral, [], error))
            return
        }
        
        servicesSubject.send((peripheral, services, error))
        services.forEach({ peripheral.discoverCharacteristics(nil, for: $0) })
    }
    
    func peripheral(_ peripheral: CBMPeripheral, didDiscoverCharacteristicsFor service: CBMService, error: Error?) {
        guard let characteristics = service.characteristics else {
            characteristicsSubject.send((peripheral, service, [], error))
            return
        }
        
        characteristicsSubject.send((peripheral, service, characteristics, error))
    }
    
    func peripheral(_ peripheral: CBMPeripheral, didUpdateValueFor characteristic: CBMCharacteristic, error: Error?) {
        updateValueSubject.send((peripheral, characteristic, characteristic.value, error))
    }
    
    func peripheral(_ peripheral: CBMPeripheral, didWriteValueFor characteristic: CBMCharacteristic, error: Error?) {
        didWriteValueSubject.send((peripheral, characteristic, characteristic.value, error))
    }
}
