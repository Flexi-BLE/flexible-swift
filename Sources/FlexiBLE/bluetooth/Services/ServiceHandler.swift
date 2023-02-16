//
//  ServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetoothMock

protocol ServiceHandler {
    var database: FXBLocalDataAccessor { get }
    
    var serviceUuid: CBUUID { get }
    
    func setup(peripheral: CBPeripheral, service: CBService)
    
    func didWrite(peripheral: CBPeripheral, uuid: CBUUID)
    func didUpdate(peripheral: CBPeripheral, characteristic: CBCharacteristic)
}
