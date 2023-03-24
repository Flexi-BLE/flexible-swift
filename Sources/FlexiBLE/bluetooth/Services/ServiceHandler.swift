//
//  ServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetooth

protocol ServiceHandler {
    var serviceUuid: CBUUID { get }
    var peripheral: CBPeripheral { get }
    
    func setup(service: CBService)
    
    func didWrite(uuid: CBUUID)
    func didUpdate(characteristic: CBCharacteristic)
}
