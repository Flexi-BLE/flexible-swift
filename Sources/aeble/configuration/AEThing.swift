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
    // TODO: config data structure
    public let configurations: [String]
    public let dataStreams: [AEDataStream]
    
    internal let ble: AEThingBLE
    internal let timestampSync: AETimeSync
    
    public static func ==(lhs: AEThing, rhs: AEThing) -> Bool {
        return lhs.name == rhs.name
    }
}
