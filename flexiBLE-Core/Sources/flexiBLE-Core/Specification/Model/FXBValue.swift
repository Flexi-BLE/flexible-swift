//
//  FXBSpecValue.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation

public class FXBSpecValue: Codable, Identifiable {
    public let id: UUID
    public let name, valueDescription: String
    private(set) var index: Int
    public let dataType: FXBSpecValueDataType
    public let unit: String?
    internal let byteLength: Int
    public let defaultValue: Int?
    internal let multiplier: Float
    public let options: [FXBSpecOption]?
    public let range: FXBSpecRange?

    internal enum CodingKeys: String, CodingKey {
        case id, name
        case valueDescription = "description"
        case index
        case dataType = "data_type"
        case unit
        case byteLength = "byte_length"
        case defaultValue = "default_value"
        case multiplier, options, range
    }
}

extension FXBSpecValue: Equatable, Hashable {
    public static func == (lhs: FXBSpecValue, rhs: FXBSpecValue) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Inferred data type for FlexiBLE device values.
/// Along with the `length` field, will determine how a value is decoded (into the the database) and encoded (BLE byte array).
///
/// - Usage:
///     - FXBValueDataType.bool // 1 bit boolean
///     - FXBValueDataType.int // twos-compliment of size (8,16,32,64)
///     - FXBValueDataType.uint // unsigned int of size (8,16,32,64)
///     - FXBValueDataType.float // single precision 32-bit float
///     - FXBValueDataType.double // double precision 64-bit double
public enum FXBSpecValueDataType: String, Codable {
    case bool = "bool"
    case integer = "int"
    case unsignedInteger = "uint"
    case float = "float"
}

public class FXBSpecOption: Codable {
    public let name, optionDescription: String
    public let value: Int
    
    init(name: String, description: String, value: Int) {
        self.name = name
        self.optionDescription = description
        self.value = value
    }

    internal enum CodingKeys: String, CodingKey {
        case name
        case optionDescription = "description"
        case value
    }
}

public class FXBSpecRange: Codable {
    let start, end, step: Int
    
    init(start: Int, end: Int, step: Int) {
        self.start = start
        self.end = end
        self.step = step
    }
}
