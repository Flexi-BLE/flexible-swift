//
//  File 2.swift
//  
//
//  Created by Blaine Rothrock on 2/15/23.
//

import Foundation
import Combine
import os
import CoreBluetoothMock


public class FlexiBLEDeviceManager {
    private unowned let bluetoothManager: CombineBluetoothManager = .shared
    
    private var spec: FXBDeviceSpec
    private var database: FXBLocalDataAccessor
    internal var foundDevice: FoundPeripheral
    
    private var observables: [AnyCancellable] = []
    private var connectionSubject: PassthroughSubject<Void, Error> = .init()
    
    public var flexibleService: FlexiBLEServiceManager
    public var dataStreams: [String:DataStreamManager] = .init()
    
    public var isConnected: Bool = false
    public var name: String {
        return foundDevice.advertismentData.name ?? "noname"
    }
    
    init(spec: FXBDeviceSpec, database: FXBLocalDataAccessor, foundDevice: FoundPeripheral) {
        self.spec = spec
        self.database = database
        self.foundDevice = foundDevice
    
        for ds in spec.dataStreams {
            self.dataStreams[ds.id] = DataStreamManager(
                dataStream: ds,
                database: database,
                foundDevice: foundDevice
            )
        }
        
        flexibleService = FlexiBLEServiceManager(database: database, foundDevice: foundDevice)
        
        self.observe()
    }
    
    public func connect() -> AnyPublisher<Void, Error> {
        bluetoothManager.connect(foundDevice.peripheral)
        return connectionSubject
            .timeout(1.0, scheduler: DispatchQueue.global(qos: .userInitiated))
            .first()
            .eraseToAnyPublisher()
        
    }
    
    
    private func observe() {
        bluetoothManager.connectSubject
            .filter({ $0.identifier == self.foundDevice.peripheral.identifier })
            .sink(receiveValue: { _ in
                self.isConnected = true
                self.connectionSubject.send(())
            })
            .store(in: &observables)
        
        bluetoothManager.disconnectSubject
            .filter({ $0.periperal.identifier == self.foundDevice.peripheral.identifier })
            .sink(receiveValue: { _ in self.isConnected = false })
            .store(in: &observables)
    }
}
