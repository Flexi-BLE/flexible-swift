//
//  CurrentTimeServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetoothMock

internal class CurrentTimeServiceHandler: ServiceHandler {
    var device: Device
    
    internal var database: FXBLocalDataAccessor
    internal var serviceUuid: CBUUID = BLERegisteredService.currentTime.uuid
    
    init(device: Device, database: FXBLocalDataAccessor) {
        self.database = database
        self.device = device
    }
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        
    }
    
    func didWrite(peripheral: CBPeripheral, uuid: CBUUID) {
        bleLog.debug("did write value for \(self.serviceUuid)")
    }
    
    func didUpdate(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        
    }
}
