//
//  AEBLERegisteredDevice.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation


public struct FXBRegisteredDevice: Codable {
    public let name: String
    internal let services: [BLERegisteredService]
    public let description: String
}
