//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 4/14/22.
//

import Foundation
import CoreBluetooth

internal struct AEThingBLE: Codable {
    let bleRegisteredServices: [BLERegisteredService]
    let infoServiceUuid: String
}
