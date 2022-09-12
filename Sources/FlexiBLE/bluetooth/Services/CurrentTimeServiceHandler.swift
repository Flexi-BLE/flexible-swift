//
//  CurrentTimeServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetooth

internal class CurrentTimeServiceHandler: ServiceHandler {
    var deviceName: String
    
    internal var serviceUuid: CBUUID = BLERegisteredService.currentTime.uuid
    
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
