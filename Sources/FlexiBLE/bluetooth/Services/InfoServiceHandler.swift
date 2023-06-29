//
//  AEInfoServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 7/21/22.
//

import Foundation
import CoreBluetooth
import Combine
import GRDB

public enum FlexiBLEDeviceRole: UInt, Codable {
    case metroLeader = 2
    case metroFollower = 1
    case independent = 0
    case unknown = 255
    
    public var description: String {
        switch self {
        case .metroLeader:
            return "Metro Leader"
        case .metroFollower:
            return "Metro Follower"
        case .independent:
            return "Independent"
        case .unknown:
            return "Unknown"
        }
    }
}

public class InfoServiceHandler: ServiceHandler, ObservableObject {
    var serviceUuid: CBUUID

    private let spec: FXBDeviceSpec
    
    public struct InfoData {
        public let referenceDate: Date?
    }

    private var tempRefDate: Date?
    internal var deviceRecord: FXBDeviceRecord
    
    @Published public var infoData: InfoData?
    
    private var dataObserver: AnyCancellable?
    
    internal var peripheral: CBPeripheral
    
    init(spec: FXBDeviceSpec, peripheral: CBPeripheral, deviceRecord: FXBDeviceRecord) {
        self.spec = spec
        self.peripheral = peripheral
        self.serviceUuid = spec.infoServiceUuid
        self.deviceRecord = deviceRecord
    }
    
    private func writeEpoch() {
        guard let infoService = peripheral.services?.first(where: { $0.uuid == spec.infoServiceUuid }),
              let epochChar = infoService.characteristics?.first(where: { $0.uuid == spec.epochTimeUuid }) else {
            bleLog.error("unable to write epoch reference time: cannot locate reference time characteristic.")
            return
        }
        
        let now = Date()
        var nowMs = UInt64(now.timeIntervalSince1970*1000)
        var data = Data()
        withUnsafePointer(to: &nowMs) {
            data.append(UnsafeBufferPointer(start: $0, count: 1))
        }
        
        bleLog.info("Writing epoch time to \(self.peripheral.name ?? "--device--"): \(now) (\(nowMs))")
        peripheral.writeValue(data, for: epochChar, type: .withResponse)
    
        self.tempRefDate = now // wait to commit until written
    }
    
    private func updateRole(_ data: Data) {
        if let role = FlexiBLEDeviceRole(rawValue: UInt(data[0])) {
            bleLog.debug("Did update device role: \(role.description)")
            self.deviceRecord.role = role
            try? FlexiBLE.shared.dbAccess?.device.upsert(device: &self.deviceRecord)
            
            if role == .metroFollower {
                Task {
                    if let referenceDate = try await FlexiBLE.shared.dbAccess?.device.getLastRefTime(for: spec.name, with: .metroLeader) {
                        self.deviceRecord.set(referenceDate: referenceDate)
                        try? FlexiBLE.shared.dbAccess?.device.upsert(device: &self.deviceRecord)
                    }
                }
            }
        }
    }
    
    func setup(service: CBService) {
        
        if let _ = service.characteristics?.first(where: { $0.uuid == spec.epochTimeUuid }) {
            writeEpoch()
        }
        
        // set notify for epoch reset request
        if let epochResetChar = service.characteristics?.first(where: { $0.uuid == spec.refreshEpochUuid }) {
            peripheral.setNotifyValue(true, for: epochResetChar)
        }
        
        if let deviceOutChar = service.characteristics?.first(where: { $0.uuid == spec.deviceOutUuid }) {
            peripheral.setNotifyValue(true, for: deviceOutChar)
        }
        
        if let deviceRoleChar = service.characteristics?.first(where: { $0.uuid == spec.deviceRoleUuid }) {
            peripheral.setNotifyValue(true, for: deviceRoleChar)
            peripheral.readValue(for: deviceRoleChar)
        }
    }
    
    public func send(cmd: FXBCommandSpec, req: FXBCommandSpecRequest) {
        guard let infoService = peripheral.services?.first(where: { $0.uuid == spec.infoServiceUuid }),
              let deviceInChar = infoService.characteristics?.first(where: { $0.uuid == spec.deviceInUuid }) else {
            
            return
        }
        
        let data = Data([FXBCommandHeader.request.rawValue, cmd.commandCode, req.code])
        peripheral.writeValue(data, for: deviceInChar, type: .withoutResponse)
        
    }
    
    func didWrite(uuid: CBUUID) {
        if uuid == spec.epochTimeUuid {
            if let temp = tempRefDate {
                switch deviceRecord.role {
                case .metroLeader:
                    self.deviceRecord.set(referenceDate: temp)
                    try? FlexiBLE.shared.dbAccess?.device.upsert(device: &self.deviceRecord)
                    self.infoData = InfoData(referenceDate: temp)
                    try? FlexiBLE.shared.dbAccess?.device.updateFollers(referenceDate: temp, deviceType: spec.name)
                    
                    tempRefDate = nil
                case .metroFollower:
                    break
                case .independent, .unknown:
                    self.deviceRecord.set(referenceDate: temp)
                    try? FlexiBLE.shared.dbAccess?.device.upsert(device: &self.deviceRecord)
                    self.infoData = InfoData(referenceDate: temp)
                    
                    tempRefDate = nil
                }
            }
        }
    }
    
    func didUpdate(characteristic: CBCharacteristic) {
        guard let data = characteristic.value else {
            return
        }
                        
        if characteristic.uuid == spec.refreshEpochUuid {
            if data[0] == 1 {
                writeEpoch()
            }
        } else if characteristic.uuid == spec.deviceOutUuid {
            bleLog.debug("Did reviece device out data: \(data)")
        } else if characteristic.uuid == spec.deviceRoleUuid {
            updateRole(data)
        }
    }
}
