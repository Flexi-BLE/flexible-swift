//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/15/23.
//

import Foundation
import Combine
import CoreBluetoothMock

public class FlexiBLEDevicesManager: ObservableObject {
    var bluetoothManager: CombineBluetoothManager = .shared
    
    private var deviceSpecs: [FXBDeviceSpec] = .init()
    private var observables: [AnyCancellable] = .init()
    private var database: FXBLocalDataAccessor
    
    private var devices: CurrentValueSubject<[UUID: FlexiBLEDeviceManager], Never> = .init([:])
    
    public var deviceFoundSubject: PassthroughSubject<FlexiBLEDeviceManager, Never> = .init()
    public var deviceConnectedSubject: PassthroughSubject<FlexiBLEDeviceManager, Never> = .init()
    
    public var connectedDevices: [FlexiBLEDeviceManager] {
        return devices.value
            .map({ $0.value })
            .filter({ $0.isConnected })
    }
    public var connectedDevicesPublisher: AnyPublisher<[FlexiBLEDeviceManager], Never> {
        return devices
            .map { devices in
                return devices.map({ $0.value })
            }
            .map { devices in
                return devices.filter({ $0.isConnected })
            }
            .eraseToAnyPublisher()
    }
    
    public var foundDevices: [FlexiBLEDeviceManager] {
        return devices.value
            .map({ $0.value })
            .filter({ !$0.isConnected })
    }
    public var foundDevicesPublisher: AnyPublisher<[FlexiBLEDeviceManager], Never> {
        return devices
            .map { devices in
                return devices.map({ $0.value })
            }
            .map { devices in
                return devices.filter({ !$0.isConnected })
            }
            .eraseToAnyPublisher()
    }
    
    private var isScanning: Bool = false
    
    init(devices specs: [FXBDeviceSpec], database db: FXBLocalDataAccessor) {
        deviceSpecs = specs
        database = db
        
        observe()
    }
    
    func add(_ spec: FXBDeviceSpec) {
        deviceSpecs.append(spec)
    }
    
    func start() {
        bluetoothManager.start()
        isScanning = true
    }
    
    func stop() {
        bluetoothManager.stop()
        isScanning = false
        devices = .init([:])
    }
    
    private func observe() {
        bluetoothManager.stateSubject.sink { state in
            switch state {
            case .poweredOn:
                if self.isScanning {
                    // TODO: add more services
                    self.bluetoothManager.scan()
                }
            default: break
            }
        }
        .store(in: &observables)
        
        bluetoothManager.discoverSubject
            .filter({ self.devices.value[$0.peripheral.identifier] == nil })
            .sink(receiveValue: { device in
                
                guard let name = device.advertismentData.name,
                      let spec = self.deviceSpecs.first(where: { name.starts(with: $0.name) }) else {
                    return
                }
                
                let manager = FlexiBLEDeviceManager(
                    spec: spec,
                    database: self.database,
                    foundDevice: device
                )
                 
                self.deviceFoundSubject.send(manager)
                self.devices.value[device.peripheral.identifier] = manager
            })
            .store(in: &observables)
        
        bluetoothManager.connectSubject
            .sink(receiveValue: { peripheral in
                guard let manager = self.devices.value[peripheral.identifier] else {
                    return
                }
                self.deviceConnectedSubject.send(manager)
            })
            .store(in: &observables)
    }
}
