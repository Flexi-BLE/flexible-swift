//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/15/23.
//

import Foundation
import Combine
import os
import CoreBluetoothMock

public class DataStreamManager {
    private unowned let bluetoothManager: CombineBluetoothManager = .shared
    
    private var spec: FXBDataStream
    private var database: FXBLocalDataAccessor
    private var foundDevice: FoundPeripheral
    
    private var log: Logger
    
    private var observables: [AnyCancellable] = .init()
    
    init(dataStream: FXBDataStream, database: FXBLocalDataAccessor, foundDevice: FoundPeripheral) {
        self.spec = dataStream
        self.database = database
        self.foundDevice = foundDevice
        self.log = Logger(subsystem: "com.flexiBLE.datastream", category: "\(foundDevice.advertismentData.name ?? "--unknown--")")
        
        self.observe()
    }
    
    func disconnect() {
        for ob in observables {
            ob.cancel()
        }
        observables = []
    }
    
    private func observe() {
        bluetoothManager.servicesSubject
            .filter({ $0.peripheral.identifier == self.foundDevice.peripheral.identifier })
            .map({ ($0.services.filter({ self.spec.serviceCbuuid == $0.uuid }).first, $0.error) })
            .sink { [unowned self] (service, error) in
                self.log.info("did discover services for \(self.spec.name)")
            }
            .store(in: &observables)
        
        bluetoothManager.characteristicsSubject
            .filter({ $0.peripheral.identifier == self.foundDevice.peripheral.identifier })
            .filter({ $0.service == self.spec.serviceCbuuid })
            .sink { [unowned self] (_, service, characteristic, error) in
                guard service.uuid == self.spec.serviceCbuuid else {
                    return
                }
                self.log.info("did discover characteristics for \(self.spec.name):\(service.uuid)")
                
                for char in characteristic {
                    switch char.uuid {
                    case self.spec.configCbuuid: self.setupConfig(char)
                    case self.spec.dataCbuuid: self.setupData(char)
                    default: self.log.error("Unknown Characteristic Found")
                    }
                }
            }
            .store(in: &observables)
        
        bluetoothManager.updateValueSubject
            .filter({ $0.peripheral.identifier == self.foundDevice.peripheral.identifier })
            .filter({ $0.characteristic.uuid == self.spec.configCbuuid })
            .sink(receiveValue: { (_, char, data, error) in
                guard let data = data else {
                    return
                }
                self.recieve(config: data)
            })
            .store(in: &observables)
        
        bluetoothManager.updateValueSubject
            .filter({ $0.peripheral.identifier == $0.peripheral.identifier })
            .filter({ $0.characteristic.uuid == self.spec.dataCbuuid })
            .sink(receiveValue: { (_, char, data, error) in
                guard let data = data else {
                    return
                }
                self.recieve(data: data)
            })
            .store(in: &observables)
    }
}


// MARK: - Data
private extension DataStreamManager {
    func setupData(_ char: CBCharacteristic) {
        log.debug("setup data for \(self.foundDevice.advertismentData.name ?? "--unknown--")")
        foundDevice.peripheral.setNotifyValue(true, for: char)
    }
    
    func recieve(data: Data) {
        log.debug("did receive data for \(self.foundDevice.advertismentData.name ?? "--unknown--"): \(data)")
    }
}

// MARK: - Configuration
private extension DataStreamManager {
    func setupConfig(_ char: CBCharacteristic) {
        log.debug("setup config for \(self.foundDevice.advertismentData.name ?? "--unknown--")")
        foundDevice.peripheral.readValue(for: char)
    }
    
    func recieve(config data: Data) {
        log.debug("did receive config for \(self.foundDevice.advertismentData.name ?? "--unknown--"): \(data)")
    }
}
