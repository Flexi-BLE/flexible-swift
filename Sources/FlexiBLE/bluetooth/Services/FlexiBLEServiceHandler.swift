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

public class FlexiBLEServiceHandler: ServiceHandler, ObservableObject {
    static var FlexiBLEServiceUUID = CBUUID(string: "1a220001-c2ed-4d11-ad1e-fc06d8a02d37")
    static var EpochCharUUID = CBUUID(string: "1a220002-c2ed-4d11-ad1e-fc06d8a02d37")
    static let SpecURLUUID = CBUUID(string: "1a220003-c2ed-4d11-ad1e-fc06d8a02d37")
    static let RefreshEpochCharUUID = CBUUID(string: "1a220005-c2ed-4d11-ad1e-fc06d8a02d37")
    
    let serviceUuid: CBUUID = FlexiBLEServiceHandler.FlexiBLEServiceUUID

    internal var database: FXBLocalDataAccessor
    
    private let spec: FXBDeviceSpec

    @Published internal var specURL: URL?
    internal var referenceDate: Date?
    private var tempRefDate: Date?
    
    private var dataObserver: AnyCancellable?
    
    init(spec: FXBDeviceSpec, database: FXBLocalDataAccessor) {
        self.database = database
        self.spec = spec
    }
    
    private func writeEpoch(peripheral: CBPeripheral) {
        guard let infoService = peripheral.services?.first(where: { $0.uuid == Self.FlexiBLEServiceUUID }),
              let epochChar = infoService.characteristics?.first(where: { $0.uuid == Self.EpochCharUUID }) else {
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
    
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        
        if let _ = service.characteristics?.first(where: { $0.uuid == Self.EpochCharUUID }) {
            writeEpoch(peripheral: peripheral)
        }
        
        // set notify for epoch reset request
        if let epochResetChar = service.characteristics?.first(where: { $0.uuid == Self.RefreshEpochCharUUID }) {
            peripheral.setNotifyValue(true, for: epochResetChar)
        }
        
        if let urlChar = service.characteristics?.first(where: { $0.uuid == Self.SpecURLUUID }) {
            peripheral.readValue(for: urlChar)
        }
    }
    
    func didWrite(peripheral: CBPeripheral, uuid: CBUUID) {
        if uuid == Self.EpochCharUUID {
            if let temp = tempRefDate {
                self.referenceDate = temp
                tempRefDate = nil
            }
        }
    }
    
    func didUpdate(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        guard let data = characteristic.value else {
            return
        }
            
        if characteristic.uuid == Self.SpecURLUUID {
            if let urlString = String(data: data, encoding: .utf8),
               let url = URL(string: urlString) {
                
                self.specURL = url
            }
            
        } else if characteristic.uuid == Self.RefreshEpochCharUUID {
            if data[0] == 1 {
                writeEpoch(peripheral: peripheral)
            }
        }
    }
}
