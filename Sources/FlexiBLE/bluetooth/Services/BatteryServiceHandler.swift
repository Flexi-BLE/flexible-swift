//
//  FXBBatteryServiceHandler.swift
//  
//
//  Created by blaine on 6/21/22.
//

import Foundation
import CoreBluetooth

internal class BatteryServiceHandler: ServiceHandler {
    var device: Device
    internal let peripheral: CBPeripheral
    
    internal var serviceUuid: CBUUID = BLERegisteredService.battery.uuid
    
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

