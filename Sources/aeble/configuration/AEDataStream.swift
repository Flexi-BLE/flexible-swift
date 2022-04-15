//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 4/13/22.
//

import Foundation

internal struct AEDataStream: Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let batchSize: Int
    let payloadSize: Int
    let includeOffsetTimestamp: Bool
    let intendedFrequencyMs: Int
    let includeAnchorTimestamp: Bool
    
    let dataValues: [AEDataValue]
    let timeOffsetValue: AEDataValue
    
    let ble: AEDataStreamBLE
    
    static func ==(lhs: AEDataStream, rhs: AEDataStream) -> Bool {
        return lhs.id == rhs.id
    }
}
