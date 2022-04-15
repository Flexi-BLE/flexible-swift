//
//  PeripheralMetadata.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

internal struct AEThing: Codable, Equatable {
    let name: String
    let description: String
    let tags: [String]
    let configurations: [String]
    let dataStreams: [AEDataStream]
    
    let ble: AEThingBLE
    
    static func ==(lhs: AEThing, rhs: AEThing) -> Bool {
        return lhs.name == rhs.name
    }
}
