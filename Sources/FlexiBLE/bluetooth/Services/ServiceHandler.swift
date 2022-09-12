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
    var deviceName: String { get }
    
    func setup(peripheral: CBPeripheral, service: CBService)
    
    func didWrite(uuid: CBUUID)
    func didUpdate(uuid: CBUUID, data: Data?)
}
