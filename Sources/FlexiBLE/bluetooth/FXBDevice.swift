//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 9/21/22.
//

import Foundation
import Combine
import CoreBluetooth

public enum DeviceConnectionState: String, CaseIterable {
    case disconnected = "Disconnected"
    case initializing = "Initializing"
    case connecting = "Connecting"
    case connected = "Connected"
}

public protocol Device {
    var id: UUID { get }
    var connectionState: DeviceConnectionState { get }
    var loadedSpecVersion: String { get }
    var deviceName: String { get }
    var cbPeripheral: CBPeripheral { get }
    var connectionRecord: FXBDeviceRecord? { get }
}

public class FXBDevice: Identifiable, Device {

    public let id: UUID = UUID()
    public let spec: FXBDeviceSpec
    public var connectionManager: FXBDeviceConnectionManager?
    
    @Published public var connectionState: DeviceConnectionState = .disconnected
    @Published public var isSpecVersionMatched: Bool = true
    
    public let loadedSpecVersion: String
    public let loadedSpecId: String
    
    public let deviceName: String
    
    public let cbPeripheral: CBPeripheral
    public var connectionRecord: FXBDeviceRecord?
    
    private var cancellables: [AnyCancellable] = []
    
    internal init(spec: FXBDeviceSpec, specVersion: String, specId: String, deviceName: String, cbPeripheral: CBPeripheral) {
        self.spec = spec
        self.loadedSpecVersion = specVersion
        self.loadedSpecId = specId
        self.deviceName = deviceName
        self.cbPeripheral = cbPeripheral
    }
    
    public func dataHandler(for dataStreamName: String) -> DataStreamHandler? {
        return connectionManager?.serviceHandlers.first(where: { $0.def.name == dataStreamName })
    }
    
    public func infoServiceHandler() -> InfoServiceHandler? {
        return connectionManager?.infoServiceHandler
    }
    
    internal func connect(with peripheral: CBPeripheral) {
        self.connectionState = .initializing
        var connectionRec = FXBDeviceRecord(
            deviceType: spec.name,
            deviceName: deviceName,
            connectedAt: Date.now,
            role: .unknown
        )
        self.connectionRecord = connectionRec
        
        do {
            try FlexiBLE.shared.dbAccess?.device.upsert(device: &connectionRec)
            self.connectionRecord = connectionRec
        } catch {
            pLog.error("unable to record connection")
        }
        
        self.connectionManager = FXBDeviceConnectionManager(
            spec: spec,
            peripheral: peripheral,
            deviceRecord: connectionRec
        )
        
        self.connectionManager?.infoServiceHandler
            .$infoData
            .receive(on: DispatchQueue.main)
            .timeout(.seconds(5), scheduler: DispatchQueue.main)
            .sink(
                receiveValue: { [weak self] infoData in
                    guard let self = self, let infoData = infoData else {
                        return
                    }
                    
                    guard let referenceDate = infoData.referenceDate else { return }
                    guard let role = infoData.deviceRole else { return }
                    
                    if let deviceId = self.connectionRecord?.id,
                        let connectionRecord = FlexiBLE.shared.dbAccess?.device.device(id: deviceId) {
                        self.connectionRecord = connectionRecord
                    }
                
                    
                    if self.connectionState != .connected {
                        bleLog.info("\(self.deviceName) Initialized: (refDate: \(referenceDate), role: \(role.description))")
                        
                        self.connectionManager?.serviceHandlers.forEach {
                            $0.writeLastConfig(peripheral: self.cbPeripheral)
                        }
                        
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + .milliseconds(500),
                            execute: {
                                self.connectionState = .connected
                            }
                        )
                    }
                }
            ).store(in: &cancellables)
    }
    
    internal func disconnect() {
        DispatchQueue.main.async {
            self.connectionManager = nil
            self.connectionState = .disconnected
        }
        
        Task {
            self.connectionRecord?.disconnectedAt = Date()
            do {
                try FlexiBLE.shared.dbAccess?.device.upsert(device: &self.connectionRecord!)
            } catch {
                pLog.error("unable to update connection record with disconnected date")
            }
        }
    }
}

extension FXBDevice: Equatable {
    public static func == (lhs: FXBDevice, rhs: FXBDevice) -> Bool {
        return lhs.deviceName == rhs.deviceName
    }
}

public class FXBRegisteredDevice: ObservableObject, Identifiable, Device {
    public enum State {
        case disconnected
        case connected(manager: FXBRegisteredDeviceConnectionManager)
    }
    
    public let id: UUID = UUID()
    public let spec: FXBRegisteredDeviceSpec
    public let loadedSpecVersion: String
    public let deviceName: String
    
    public let cbPeripheral: CBPeripheral
    public var connectionRecord: FXBDeviceRecord?
    
    @Published public var connectionManager: FXBRegisteredDeviceConnectionManager?
    @Published public var connectionState: DeviceConnectionState = .disconnected
    
    internal init(spec: FXBRegisteredDeviceSpec, specVersion: String, deviceName: String, cbPeripheral: CBPeripheral) {
        self.spec = spec
        self.loadedSpecVersion = specVersion
        self.deviceName = deviceName
        self.cbPeripheral = cbPeripheral
    }
    
    internal func connect(spec: FXBRegisteredDeviceSpec, peripheral: CBPeripheral) {
        do {
            connectionRecord = FXBDeviceRecord(
                deviceType: spec.name,
                deviceName: deviceName,
                connectedAt: Date.now,
                role: .independent
            )
            try FlexiBLE.shared.dbAccess?.device.upsert(device: &connectionRecord!)
            self.connectionManager = FXBRegisteredDeviceConnectionManager(deviceRecord: connectionRecord!, spec: spec, periperal: peripheral)
            self.connectionState = .connected
            
        } catch {
            pLog.error("unable to setup regiestered device")
        }
    }
    
    internal func disconnect() {
        self.connectionManager = nil
        self.connectionState = .disconnected
        
        Task {
            self.connectionRecord?.disconnectedAt = Date()
            do {
                try FlexiBLE.shared.dbAccess?.device.upsert(device: &connectionRecord!)
            } catch {
                pLog.error("unable to update connection record with disconnected date")
            }
        }
    }
}
