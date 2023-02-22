//
//  AEBLERegisteredDevice.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation


public struct FXBRegisteredDeviceSpec: Codable, Hashable {
    public let name: String
    internal let services: [BLERegisteredService]
    public let description: String
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
