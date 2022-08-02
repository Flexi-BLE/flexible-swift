//
//  BatteryServiceHandler.swift
//  
//
//  Created by blaine on 6/21/22.
//

import Foundation
import CoreBluetooth

internal class BatteryServiceHandler: AEBLEServiceHandler {
    internal var serviceUuid: CBUUID = BLERegisteredService.battery.uuid
    
    init() { }
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        
    }
    
    func didWrite(uuid: CBUUID) {
        bleLog.debug("did write value for \(self.serviceUuid)")
    }
    
    func didUpdate(uuid: CBUUID, data: Data?) {
    
    }
}

