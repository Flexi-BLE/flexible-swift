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
    var connectionRecord: FXBConnection? { get }
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
    public var connectionRecord: FXBConnection?
    
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
    
    internal func connect(with connectionManager: FXBDeviceConnectionManager) {
        self.connectionState = .initializing
        self.connectionManager = connectionManager
        
        self.connectionManager?.infoServiceHandler
            .$infoData
            .receive(on: DispatchQueue.main)
            .sink(
                receiveValue: { [weak self] infoData in
                    guard let self = self, let infoData = infoData else { return }
                    
                    guard let specId = infoData.specId,
                          let versionId = infoData.versionId,
                          let referenceDate = infoData.referenceDate else { return }
                    
                    if self.connectionState != .connected {
                        bleLog.info("\(self.deviceName) Initialized: (\(referenceDate)")
                        
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
                    
                    if specId == self.loadedSpecId,
                       versionId == self.loadedSpecVersion {
                        self.isSpecVersionMatched = true
                    } else {
                        self.isSpecVersionMatched = false
                    }
                    
                    Task(priority: .background) { [weak self] in
                        do {
                            self?.connectionRecord?.latestReferenceDate = referenceDate
                            self?.connectionRecord?.specificationIdString = specId
                            self?.connectionRecord?.specificationVersion = versionId
                            
                            if self?.connectionRecord != nil {
                                try FlexiBLE.shared.dbAccess?.connection.update(&self!.connectionRecord!)
                            }
                        } catch {
                            pLog.error("unable to update reference date for connection record")
                        }
                    }
                }
            ).store(in: &cancellables)
        
        Task {
            do {
                self.connectionRecord = FXBConnection(
                    deviceType: spec.name,
                    deviceName: deviceName
                )
                self.connectionRecord?.connectedAt = Date.now
                try FlexiBLE.shared.dbAccess?.connection.insert(&self.connectionRecord!)
            } catch {
                pLog.error("unable to record connection")
            }
        }
    }
    
    internal func disconnect() {
        DispatchQueue.main.async {
            self.connectionManager = nil
            self.connectionState = .disconnected
        }
        
        Task {
            self.connectionRecord?.disconnectedAt = Date()
            do {
                try FlexiBLE.shared.dbAccess?.connection.update(&self.connectionRecord!)
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
    public var connectionRecord: FXBConnection?
    
    @Published public var connectionManager: FXBRegisteredDeviceConnectionManager?
    @Published public var connectionState: DeviceConnectionState = .disconnected
    
    internal init(spec: FXBRegisteredDeviceSpec, specVersion: String, deviceName: String, cbPeripheral: CBPeripheral) {
        self.spec = spec
        self.loadedSpecVersion = specVersion
        self.deviceName = deviceName
        self.cbPeripheral = cbPeripheral
    }
    
    internal func connect(with connectionManager: FXBRegisteredDeviceConnectionManager) {
        self.connectionManager = connectionManager
        self.connectionState = .connected
        
        Task {
            do {
        
                connectionRecord = FXBConnection(
                    deviceType: spec.name,
                    deviceName: deviceName
                )
                connectionRecord?.connectedAt = Date.now
                try FlexiBLE.shared.dbAccess?.connection.insert(&connectionRecord!)
                
            } catch {
                pLog.error("unable to record connection")
            }
        }
    }
    
    internal func disconnect() {
        self.connectionManager = nil
        self.connectionState = .disconnected
        
        Task {
            self.connectionRecord?.disconnectedAt = Date()
            do {
                try FlexiBLE.shared.dbAccess?.connection.update(&connectionRecord!)
            } catch {
                pLog.error("unable to update connection record with disconnected date")
            }
        }
    }
}
