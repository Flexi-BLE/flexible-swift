//
//  FXBBatteryServiceHandler.swift
//  
//
//  Created by blaine on 6/21/22.
//

import Foundation
import CoreBluetooth

internal class BatteryServiceHandler: ServiceHandler {
    
    var deviceRecord: FXBDeviceRecord
    internal let peripheral: CBPeripheral
    
    internal var serviceUuid: CBUUID = BLERegisteredService.battery.uuid
    
    init(deviceRecord: FXBDeviceRecord, peripheral: CBPeripheral) {
        self.deviceRecord = deviceRecord
        self.peripheral = peripheral
        
    }
    
    func setup(service: CBService) {
        
    }
    
    func didWrite(uuid: CBUUID) {
        bleLog.debug("did write value for \(self.serviceUuid)")
    }
    
    func didUpdate(characteristic: CBCharacteristic) {
        
    }
}

