//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 4/13/22.
//

import Foundation

//public struct AEDataStream: Codable, Equatable {
//    public let id: String
//    public let name: String
//    public let description: String?
//    public let batchSize: Int
//    public let uploadBatchSize: Int
//    internal let payloadSize: Int
//    internal let includeOffsetTimestamp: Bool
//    public let intendedFrequencyMs: Int
//    internal let includeAnchorTimestamp: Bool
//
//    public let dataValues: [AEDataValueDefinition]
//    internal let timeOffsetValue: AEDataValueDefinition
//
//    internal let ble: AEDataStreamBLE
//
//    public static func ==(lhs: AEDataStream, rhs: AEDataStream) -> Bool {
//        return lhs.id == rhs.id
//    }
//}

public struct AEDataStream: Codable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    internal let includeAnchorTimestamp: Bool
    
    public let offsetDataValue: AEDataValueDefinition?
    public let dataValues: [AEDataValueDefinition]
    public let configValues: [AEDataStreamConfig]
    
    internal let ble: AEDataStreamBLE
    
    public static func ==(lhs: AEDataStream, rhs: AEDataStream) -> Bool {
        return lhs.id == rhs.id
    }
}
