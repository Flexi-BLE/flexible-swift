//
//  File.swift
//  
//
//  Created by blaine on 4/26/22.
//

import Foundation

import Foundation

public enum FXBDataValueType: String, Codable {
    case int = "int"
    case float = "float"
    case string = "string"
    case unsignedInt = "uint"
}

public protocol AEDataValue: CustomStringConvertible, Codable {}
extension String: AEDataValue { }
extension Float: AEDataValue { }
extension Double: AEDataValue { }
extension Int: AEDataValue { }
