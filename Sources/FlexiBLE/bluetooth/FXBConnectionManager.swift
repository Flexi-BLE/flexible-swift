//
//  AEBLEConnectionManager.swift
//  
//
//  Created by blaine on 2/22/22.
//

import Foundation
import CoreBluetooth
import Combine

public class FXBConnectionManager: NSObject, ObservableObject {
    var centralManager: CBCentralManager!
    
    @Published public private(set) var centralState: CBManagerState = .unknown
    @Published public private(set) var isScanning: Bool = false
        
    @Published public private(set) var fxbFoundDevices: [FXBDevice] = []
    @Published public private(set) var fxbConnectedDevices: [FXBDevice] = []
    
    @Published public private(set) var foundRegisteredDevices: [FXBRegisteredDevice] = []
    @Published public private(set) var connectedRegisteredDevices: [FXBRegisteredDevice] = []
    
    private var spec: FXBSpec?
    private var scanOnPoweredOn: Bool = true
    private let db: FXBDBManager
    
    private var autoConnectDevices: [String] = []
    
    required init(db: FXBDBManager) {
        self.db = db
        super.init()
        
        self.centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: "FlexiBLE"]
        )
    }
    
    public func enable(device: FXBDevice) {
        guard centralManager.state == .poweredOn else {
            return
        }
        
        device.connectionState = .connecting
        centralManager.connect(device.cbPeripheral)
    }
    
    public func disable(device: FXBDevice) {
        centralManager.cancelPeripheralConnection(device.cbPeripheral)
    }
    
    public func enable(device: FXBRegisteredDevice) {
        guard centralManager.state == .poweredOn else {
            return
        }
        
        centralManager.connect(device.cbPeripheral)
    }
    
    public func disable(device: FXBRegisteredDevice) {
        centralManager.cancelPeripheralConnection(device.cbPeripheral)
    }
    
    public func updateConfig(
        deviceName: String,
        dataStream: FXBDataStream,
        data: Data?=nil
    ) {
        
        if let device = fxbConnectedDevices.first(where: { $0.deviceName == deviceName }) {
            guard let manager = device.connectionManager else { return }
            if let dsh = manager.serviceHandlers.first(where: { $0.def.name == dataStream.name }) {
                if let data = data {
                    dsh.writeConfig(peripheral: device.cbPeripheral, data: data)
                } else {
                    dsh.writeDefaultConfig(peripheral: device.cbPeripheral)
                }
            }
        }
    }
    
    public func registerAutoConnect(devices: [String]) {
        self.autoConnectDevices = devices
        
        fxbFoundDevices.forEach { device in
            if autoConnectDevices.contains(device.deviceName), device.connectionState != .connected {
                enable(device: device)
            }
        }
        
        foundRegisteredDevices.forEach { device in
            if autoConnectDevices.contains(device.deviceName), device.connectionState != .connected {
                enable(device: device)
            }
        }
    }
    
    internal func scan(with spec: FXBSpec) {
        self.spec = spec
        
        guard centralManager.state == .poweredOn else { return }
        
        if isScanning { stopScan() }
        startScan()
    }
    
    private func startScan() {
        guard centralManager.state == .poweredOn,
              let spec = self.spec else {
            bleLog.fault("central manager state is not on: \(self.centralManager.state.rawValue)")
            return
        }
        
        var services: [CBUUID] = []
        for device in spec.devices {
            services.append(device.infoServiceUuid)
        }
        
        for device in spec.bleRegisteredDevices {
            services.append(contentsOf: device.serviceIds)
        }

        guard services.count > 0 else {
            bleLog.info("scanning enabled, but no services, not starting scan.")
            return
        }

        bleLog.info("started scan")
        bleLog.info("scanning for devices with services: \(services)")
        
        centralManager.scanForPeripherals(
            withServices:services,
            options: nil
        )
        DispatchQueue.main.async {
            self.isScanning = self.centralManager.isScanning
        }
    }
    
    internal func stopScan() {
        centralManager.stopScan()
        DispatchQueue.main.async {
            self.isScanning = self.centralManager.isScanning
            self.fxbFoundDevices = []
            self.foundRegisteredDevices = []
        }
        
        bleLog.info("stopped scan")
    }
}

extension FXBConnectionManager: CBCentralManagerDelegate {
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let perfs = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for perf in perfs {
                print(perf)
            }
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.centralState = central.state
        
        switch central.state {
        case .poweredOn:
            print("powered on")
            if scanOnPoweredOn { startScan() }
        default: break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        bleLog.debug("peripheral found: \(peripheral.name ?? "--none--"), (\(peripheral.identifier))")
        
        guard let peripheralName = peripheral.name, let spec = self.spec else { return }
        
        if let deviceDef = spec.devices.first(where: { peripheralName.starts(with: $0.name) }) {
            
            if let connectedDevice = fxbConnectedDevices.first(where: { peripheralName == $0.deviceName }) {
                if autoConnectDevices.contains(peripheralName) {
                    self.enable(device: connectedDevice)
                }
                return
            }
            
            if let foundDevice = fxbFoundDevices.first(where: { peripheralName == $0.deviceName }) {
                if autoConnectDevices.contains(peripheralName) {
                    self.enable(device: foundDevice)
                }
                return
            }
            
            let device = FXBDevice(
                spec: deviceDef,
                specVersion: spec.schemaVersion,
                specId: spec.id,
                deviceName: peripheralName,
                cbPeripheral: peripheral
            )
            
            fxbFoundDevices.append(device)
            
            if autoConnectDevices.contains(peripheralName) {
                self.enable(device: device)
            }
        }
        
        if let registeredDeviceSpec = spec.bleRegisteredDevices.first(where: { peripheralName.starts(with: $0.name) }) {
            if let connectedDevice = connectedRegisteredDevices.first(where: { peripheralName == $0.deviceName }) {
                if autoConnectDevices.contains(peripheralName) {
                    self.enable(device: connectedDevice)
                }
                return
            }
            if let foundDevice = foundRegisteredDevices.first(where: { peripheralName == $0.deviceName }) {
                if autoConnectDevices.contains(peripheralName) {
                    self.enable(device: foundDevice)
                }
                return
            }
            
            let device = FXBRegisteredDevice(
                spec: registeredDeviceSpec,
                specVersion: spec.schemaVersion,
                deviceName: peripheralName,
                cbPeripheral: peripheral
            )
            
            foundRegisteredDevices.append(device)
            
            if autoConnectDevices.contains(peripheralName) {
                self.enable(device: device)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        if let i = fxbFoundDevices.firstIndex(where: { $0.deviceName == peripheral.name }) {
            let device = fxbFoundDevices[i]
            
            bleLog.info("connceted to: \(device.spec.name)")
            
            device.connect(with: FXBDeviceConnectionManager(spec: device.spec, peripheral: peripheral))
            
            fxbFoundDevices.remove(at: i)
            fxbConnectedDevices.append(device)
        } else if let i = foundRegisteredDevices.firstIndex(where: { $0.deviceName == peripheral.name }) {
            let device = foundRegisteredDevices[i]
            
            bleLog.info("connceted to: \(device.deviceName)")
            
            device.connect(with: FXBRegisteredDeviceConnectionManager(device: device))
            foundRegisteredDevices.remove(at: i)
            connectedRegisteredDevices.append(device)
        
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let i = fxbFoundDevices.firstIndex(where: { $0.deviceName == peripheral.name }) {
            let device = fxbFoundDevices[i]
            bleLog.info("failed connection to \(device.spec.name), error: \(error?.localizedDescription ?? "--none--")")
            device.connectionState = .disconnected
        } else if let i = foundRegisteredDevices.firstIndex(where: { $0.deviceName == peripheral.name }) {
            let device = foundRegisteredDevices[i]
            bleLog.info("failed connection to \(device.spec.name), error: \(error?.localizedDescription ?? "--none--")")
            device.connectionState = .disconnected
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
                
        if let i = fxbConnectedDevices.firstIndex(where: { $0.deviceName == peripheral.name }) {
            let device = fxbConnectedDevices[i]
            
            bleLog.info("\(peripheral.name ?? "--unknown--") disconnected")
            
            device.disconnect()
            fxbConnectedDevices.remove(at: i)
            if isScanning {
                stopScan()
                startScan()
            }
    
        } else if let i = connectedRegisteredDevices.firstIndex(where: { $0.deviceName == peripheral.name }) {
            let device = connectedRegisteredDevices[i]
            
            bleLog.info("\(peripheral.name ?? "--unknown--") disconnected")
            
            device.disconnect()
            connectedRegisteredDevices.remove(at: i)
            if isScanning {
                stopScan()
                startScan()
            }
            
        }
    }
}
