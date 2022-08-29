//
//  FXBBatteryServiceHandler.swift
//  
//
//  Created by blaine on 6/21/22.
//

import Foundation
import CoreBluetooth

internal class BatteryServiceHandler: ServiceHandler {
    var deviceName: String
    
    internal var serviceUuid: CBUUID = BLERegisteredService.battery.uuid
    
    init(deviceName: String) {
        self.deviceName = deviceName
    }
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        
    }
    
    func didWrite(uuid: CBUUID) {
        bleLog.debug("did write value for \(self.serviceUuid)")
    }
    
    func didUpdate(uuid: CBUUID, data: Data?) {
    
    }
}

