//
//  FXBDeviceBLE.swift
//  
//
//  Created by Blaine Rothrock on 4/14/22.
//

import Foundation
import CoreBluetooth

internal struct FXBDeviceBLE: Codable {
    let bleRegisteredServices: [BLERegisteredService]
    let infoServiceUuid: String
    let epochCharUuid: String
    let specVersionCharUuid: String
}
