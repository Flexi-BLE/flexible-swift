//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 4/13/22.
//

import Foundation

public enum FXBTimeSeriesPrecision: String, Codable {
    case ms = "ms"
    case us = "us"
}

public struct FXBDataStream: Codable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    internal let precision: FXBTimeSeriesPrecision
    
    public let offsetDataValue: FXBDataValueDefinition?
    public let dataValues: [FXBDataValueDefinition]
    public let configValues: [FXBDataStreamConfig]
    
    internal let ble: FXBDataStreamBLE
    
    public static func ==(lhs: FXBDataStream, rhs: FXBDataStream) -> Bool {
        return lhs.id == rhs.id
    }
}

public extension FXBDataStream {
    func config(for name: String) -> FXBDataStreamConfig? {
        return self.configValues.first(where: { $0.name == name })
    }
    
    func dataValue(for name: String) -> FXBDataValueDefinition? {
        return self.dataValues.first(where: { $0.name == name })
    }
}
