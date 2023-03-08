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
        public let referenceDate: Date?
    }

    private var referenceDate: Date?
    
    private var tempRefDate: Date?
    
    @Published public var infoData: InfoData?
    
    private var dataObserver: AnyCancellable?
    
    internal var peripheral: CBPeripheral
    
    init(spec: FXBDeviceSpec, peripheral: CBPeripheral) {
        self.spec = spec
        self.peripheral = peripheral
        self.serviceUuid = spec.infoServiceUuid
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
    
    private func updateInfoData() {
        infoData = InfoData(
            referenceDate: referenceDate
        )
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
    }
    
    public func send(cmd: FXBCommandSpec, req: FXBCommandSpecRequest) {
        guard let infoService = peripheral.services?.first(where: { $0.uuid == spec.infoServiceUuid }),
              let deviceInChar = infoService.characteristics?.first(where: { $0.uuid == spec.deviceInUuid }) else {
            
            return
        }
        
        let data = Data([FXBCommandHeader.request.rawValue, cmd.commandCode, req.code])
        peripheral.writeValue(data, for: deviceInChar, type: .withResponse)
        
    }
    
    func didWrite(uuid: CBUUID) {
        if uuid == spec.epochTimeUuid {
            if let temp = tempRefDate {
                self.referenceDate = temp
                tempRefDate = nil
                updateInfoData()
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
        }
    }
}
