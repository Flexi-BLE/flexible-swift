//
//  FlexiBLEServiceManager.swift
//  
//
//  Created by Blaine Rothrock on 2/15/23.
//

import Foundation
import Combine
import os
import CoreBluetoothMock

public class FlexiBLEServiceManager {
    private unowned let bluetoothManager: CombineBluetoothManager = .shared
        
    private var database: FXBLocalDataAccessor
    private var foundDevice: FoundPeripheral
    
    private var log: Logger
    private var observables: [AnyCancellable] = .init()
    
    private var tempRefDate: Date?
    public var refDateSubject: PassthroughSubject<Date, Never> = .init()
    public var refDate: Date?
    
    public var specURLSubject: PassthroughSubject<URL, Never> = .init()
    public var specURL: URL?
    
    init(database: FXBLocalDataAccessor, foundDevice: FoundPeripheral) {
        self.database = database
        self.foundDevice = foundDevice
        self.log = Logger(subsystem: "com.flexiBLE.flexibleservice", category: "\(foundDevice.advertismentData.name ?? "--unknown--")")
        
        self.observe()
    }

    private func observe() {
        bluetoothManager.servicesSubject
            .filter({ $0.peripheral.identifier == self.foundDevice.peripheral.identifier })
            .map({ ($0.services.filter({ CBUUID.FlexiBLEServiceUUID == $0.uuid }).first, $0.error) })
            .sink { [unowned self] (service, error) in
                self.log.info("did discover flexible service for \(self.foundDevice.advertismentData.name ?? "--unknown--")")
            }
            .store(in: &observables)
        
        bluetoothManager.characteristicsSubject
            .filter({ $0.peripheral.identifier == self.foundDevice.peripheral.identifier })
            .filter({ $0.service.uuid == CBUUID.FlexiBLEServiceUUID })
            .sink { [unowned self] (_, service, characteristic, error) in
                self.log.info("did discover epoch characteristics for \(self.foundDevice.advertismentData.name ?? "--unknown--"):\(service.uuid)")
                
                for char in characteristic {
                    switch char.uuid {
                    case CBUUID.EpochCharUUID: break
                    case CBUUID.RefreshEpochCharUUID: break
                    case CBUUID.SpecURLUUID: break
                    default: self.log.error("Unknown Characteristic Found")
                    }
                }
            }
            .store(in: &observables)
        
        bluetoothManager.updateValueSubject
            .filter({ $0.peripheral.identifier == self.foundDevice.peripheral.identifier })
            .sink(receiveValue: { (_, char, data, error) in
                guard let data = data else {
                    return
                }
        
                switch char.uuid {
                case CBUUID.EpochCharUUID: self.epochCharRead(data)
                case CBUUID.RefreshEpochCharUUID: self.refreshEpochCharRead(data)
                case CBUUID.SpecURLUUID: self.specURLRead(data)
                default: self.log.error("Unknown Characteristic Found")
                }
            })
            .store(in: &observables)
        
        bluetoothManager.didWriteValueSubject
            .filter({ $0.peripheral.identifier == self.foundDevice.peripheral.identifier })
            .filter({ $0.characteristic == CBUUID.EpochCharUUID })
            .sink(receiveValue: {
                guard let data = $0.data else { return }
                self.epochCharDidWrite(data)
            })
            .store(in: &observables)
    }
}

private extension FlexiBLEServiceManager {
    func setupEpoch(_ char: CBCharacteristic) {
        let now = Date.now
        var nowMs = UInt64(now.timeIntervalSince1970*1000)
        var data = Data()
        withUnsafePointer(to: &nowMs) { ptr in
            data.append(UnsafeBufferPointer(start: ptr, count: 1))
        }
        
        log.info("writing epoch time to \(self.foundDevice.advertismentData.name ?? "--unknown--"): \(now) (\(nowMs)")
        foundDevice.peripheral.writeValue(data, for: char, type: .withResponse)
        
        self.tempRefDate = now
    }
    
    func epochCharDidWrite(_ data: Data) {
        if let temp = tempRefDate {
            refDate = temp
            tempRefDate = nil
        }
    }
        
    func epochCharRead(_ data: Data) {
        log.debug("did read/update epoch char: \(data)")
        epochCharDidWrite(data)
    }
    
    func setupRefreshEpoch(_ char: CBCharacteristic) {
        log.debug("set notify for refresh epoch char")
        foundDevice.peripheral.setNotifyValue(true, for: char)
    }
    
    func refreshEpochCharRead(_ data: Data) {
        log.debug("did read/update refresh epoch char: \(data)")
        if data[0] == 1 {
            guard let service = foundDevice.peripheral.services?.first(where: { $0.uuid == CBUUID.FlexiBLEServiceUUID }),
                  let char = service.characteristics?.first(where: { $0.uuid == CBUUID.EpochCharUUID }) else {
                log.error("unable to write epoch reference time: cannot locate reference time characteristic.")
                return
            }
            
            setupEpoch(char)
        }
    }
    
    func setupSpecURL(_ char: CBCharacteristic) {
        log.info("read spec URL")
        foundDevice.peripheral.readValue(for: char)
    }
    
    func specURLRead(_ data: Data) {
        log.debug("did read specURL char: \(data)")
        if let urlString = String(data: data, encoding: .ascii),
            let url = URL(string: urlString){
             
            self.specURL = url
            specURLSubject.send(url)
        }
    }
}
