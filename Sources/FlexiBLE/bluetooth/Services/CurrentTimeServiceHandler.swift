//
//  CurrentTimeServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetooth

internal class CurrentTimeServiceHandler: ServiceHandler {
    var deviceRecord: FXBDeviceRecord
    internal var peripheral: CBPeripheral
    
    internal var serviceUuid: CBUUID = BLERegisteredService.currentTime.uuid
    
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
