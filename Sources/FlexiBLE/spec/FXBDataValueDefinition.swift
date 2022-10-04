//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 4/13/22.
//

import Foundation

public enum FXBDataValueQueryType: String, Codable {
    case value
    case tag
    case none
}

public struct FXBDataValueDefinition: Codable {
    public let name: String
    public let description: String?
    public let uint: String?
    internal let byteStart: Int
    internal let byteEnd: Int
    internal let size: Int
    public let type: FXBDataValueType
    internal let multiplier: Double?
    public let variableType: FXBDataValueQueryType
    public let dependsOn: [String]?
    public let valueOptions: [String]?

//    internal let isUnsignedNegative: Bool
//    internal let isSigned: Bool
//    internal let precision: Int
}
