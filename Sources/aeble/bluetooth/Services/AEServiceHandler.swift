//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetooth

protocol AEBLEServiceHandler {
    var serviceUuid: CBUUID { get }
    
    func setup(peripheral: CBPeripheral, service: CBService)
    
    func didWrite(uuid: CBUUID)
    func didUpdate(uuid: CBUUID, data: Data?)
}
