//
//  FXBGattDevice.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation


public class FXBSpecGattDevice: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public var services: [FXBSpecRegisteredGATTService]
    public let gattDeviceDescription: String
    
    public init(name: String, description: String="", services: [FXBSpecRegisteredGATTService]=[]) {
        self.id = UUID()
        self.name = name
        self.gattDeviceDescription = description
        self.services = services
    }

    internal enum CodingKeys: String, CodingKey {
        case id, name, services
        case gattDeviceDescription = "description"
    }
}

extension FXBSpecGattDevice: Equatable, Hashable {
    public static func == (lhs: FXBSpecGattDevice, rhs: FXBSpecGattDevice) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
