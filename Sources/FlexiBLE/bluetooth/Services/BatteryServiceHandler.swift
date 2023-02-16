//
//  FXBBatteryServiceHandler.swift
//  
//
//  Created by blaine on 6/21/22.
//

import Foundation
import CoreBluetoothMock

internal class BatteryServiceHandler: ServiceHandler {
    var device: Device
    
    internal var database: FXBLocalDataAccessor
    internal var serviceUuid: CBUUID = BLERegisteredService.battery.uuid
    
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

