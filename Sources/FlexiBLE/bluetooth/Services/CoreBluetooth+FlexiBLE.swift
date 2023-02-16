//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/14/23.
//

import Foundation
import CoreBluetooth


extension CBUUID {
    static var FlexiBLEServiceUUID = CBUUID(string: "1a220001-c2ed-4d11-ad1e-fc06d8a02d37")
    static var EpochCharUUID = CBUUID(string: "1a220002-c2ed-4d11-ad1e-fc06d8a02d37")
    static let SpecURLUUID = CBUUID(string: "1a220003-c2ed-4d11-ad1e-fc06d8a02d37")
    static let RefreshEpochCharUUID = CBUUID(string: "1a220005-c2ed-4d11-ad1e-fc06d8a02d37")
}
