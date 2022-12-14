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

public class InfoServiceHandler: ServiceHandler, ObservableObject {
    var serviceUuid: CBUUID

    private let spec: FXBDeviceSpec
    
    public struct InfoData {
        public let referenceDate: Date
        public let specId: String
        public let versionId: String
    }

    private var versionId: String = "--none--"
    private var specId: String = "--none--"
    private var referenceDate: Date = Date(timeIntervalSince1970: 0.0)
    
    private var tempRefDate: Date?
    
    @Published public var infoData: InfoData?
    
    private var dataObserver: AnyCancellable?
    
    init(spec: FXBDeviceSpec) {
        self.spec = spec
        self.serviceUuid = spec.infoServiceUuid
    }
    
    private func writeEpoch(peripheral: CBPeripheral) {
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
        
        bleLog.info("Writing epoch time to \(peripheral.name ?? "--device--"): \(now) (\(nowMs))")
        peripheral.writeValue(data, for: epochChar, type: .withResponse)
    
        self.tempRefDate = now // wait to commit until written
    }
    
    private func updateInfoData() {
        infoData = InfoData(
            referenceDate: referenceDate,
            specId: specId,
            versionId: versionId
        )
    }
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        
        if let _ = service.characteristics?.first(where: { $0.uuid == spec.epochTimeUuid }) {
            writeEpoch(peripheral: peripheral)
        }
        
        // set notify for epoch reset request
        if let epochResetChar = service.characteristics?.first(where: { $0.uuid == spec.refreshEpochUuid }) {
            peripheral.setNotifyValue(true, for: epochResetChar)
        }
        
        if let versionChar = service.characteristics?.first(where: { $0.uuid == spec.specVersionUuid }) {
            peripheral.readValue(for: versionChar)
        }
        
        if let idChar = service.characteristics?.first(where: { $0.uuid == spec.specIdUuid }) {
            peripheral.readValue(for: idChar)
        }
    }
    
    func didWrite(peripheral: CBPeripheral, uuid: CBUUID) {
        if uuid == spec.epochTimeUuid {
            if let temp = tempRefDate {
                self.referenceDate = temp
                tempRefDate = nil
                updateInfoData()
            }
        }
    }
    
    func didUpdate(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        guard let data = characteristic.value else {
            return
        }
            
        if characteristic.uuid == spec.specVersionUuid {
            let versionMajor = Int(data[0])
            let versionMinor = Int(data[1])
            let versionPatch = Int(data[2])
            let version = "\(versionMajor).\(versionMinor).\(versionPatch)"
            bleLog.info("specification version for \(self.spec.name): \(version)")
            self.versionId = version
            updateInfoData()
            
        } else if characteristic.uuid == spec.specIdUuid {
            let id = String(data: data, encoding: .ascii)?.replacingOccurrences(of: "\0", with: "")
            bleLog.info("specification id for \(self.spec.name): \(id ?? "--none--")")
            self.specId = id ?? "--none--"
            updateInfoData()
            
        } else if characteristic.uuid == spec.refreshEpochUuid {
            if data[0] == 1 {
                writeEpoch(peripheral: peripheral)
            }
        }
    }
}
