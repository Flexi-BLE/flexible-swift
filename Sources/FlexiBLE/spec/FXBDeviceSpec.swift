//
//  FXBDeviceSpec.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

public struct FXBDeviceSpec: Codable, Equatable, Hashable {
    public let id: UUID = UUID()
    public let name: String
    public let description: String
    public let configValues: [FXBDataStreamConfig]
    public let commands: [FXBCommandSpec]
    public let dataStreams: [FXBDataStream]
    
    internal let ble: FXBDeviceBLE
    
    public static func ==(lhs: FXBDeviceSpec, rhs: FXBDeviceSpec) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
