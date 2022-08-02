//
//  AEInfoServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 7/21/22.
//

import Foundation
import CoreBluetooth

internal class AEInfoServiceHandler: AEBLEServiceHandler {
    
    internal var serviceUuid: CBUUID
    private let def: AEThing
    
    internal var referenceDate: Date?
    internal var referenceMs: UInt64?
    
    init(serviceId: CBUUID, def: AEThing) {
        self.serviceUuid = serviceId
        self.def = def
    }
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        
        if let epochChar = service.characteristics?.first(where: { $0.uuid == def.epochTimeUuid }) {
            
            let now = Date()
            var nowMs = UInt64(now.timeIntervalSince1970*1000)
            var data = Data()
            withUnsafePointer(to: &nowMs) {
                data.append(UnsafeBufferPointer(start: $0, count: 1))
            }
            
            bleLog.info("Writing epoch time: \(now) (\(nowMs))")
            
            peripheral.writeValue(data, for: epochChar, type: .withResponse)
            
            self.referenceDate = now
            self.referenceMs = nowMs
        }
    }
    
    func didWrite(uuid: CBUUID) {
        bleLog.debug("did write value for \(self.def.name)")
    }
    
    func didUpdate(uuid: CBUUID, data: Data?) {
        guard let data = data else {
            return
        }
        
        if uuid == def.epochTimeUuid {
            
            if data.count == 8 {
            
                let refMs = data.withUnsafeBytes({ $0.load(as: UInt64.self) })
                if refMs != referenceMs {
                    bleLog.error("failed to update epoch time")
                    referenceDate = nil
                    referenceMs = nil
                }
            }
        }
        
    }
}
