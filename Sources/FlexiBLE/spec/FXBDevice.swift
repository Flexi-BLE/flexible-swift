//
//  PeripheralMetadata.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

public struct FXBDevice: Codable, Equatable {
    public let id: UUID = UUID()
    public let name: String
    public let description: String
    public let tags: [String]
    public let globalConfigValues: [String]
    public let dataStreams: [FXBDataStream]
    
    internal let ble: FXBDeviceBLE
    
    public static func ==(lhs: FXBDevice, rhs: FXBDevice) -> Bool {
        return lhs.id == rhs.id
    }
}
