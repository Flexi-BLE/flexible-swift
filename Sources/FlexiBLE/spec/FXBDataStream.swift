//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 4/13/22.
//

import Foundation

public struct FXBDataStream: Codable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    internal let includeAnchorTimestamp: Bool
    
    public let offsetDataValue: FXBDataValueDefinition?
    public let dataValues: [FXBDataValueDefinition]
    public let configValues: [FXBDataStreamConfig]
    
    internal let ble: FXBDataStreamBLE
    
    public static func ==(lhs: FXBDataStream, rhs: FXBDataStream) -> Bool {
        return lhs.id == rhs.id
    }
}
