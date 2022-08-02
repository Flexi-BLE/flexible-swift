//
//  PeripheralMetadata.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

public struct AEThing: Codable, Equatable {
    public let name: String
    public let description: String
    public let tags: [String]
    public let globalConfigValues: [String]
    public let dataStreams: [AEDataStream]
    
    internal let ble: AEThingBLE
    
    public static func ==(lhs: AEThing, rhs: AEThing) -> Bool {
        return lhs.name == rhs.name
    }
}
