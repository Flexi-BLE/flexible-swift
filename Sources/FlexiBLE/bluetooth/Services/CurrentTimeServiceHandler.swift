//
//  CurrentTimeServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetooth

internal class CurrentTimeServiceHandler: ServiceHandler {
    var device: Device
    internal var peripheral: CBPeripheral
    
    internal var serviceUuid: CBUUID = BLERegisteredService.currentTime.uuid
    
    init(device: Device, peripheral: CBPeripheral) {
        self.device = device
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
