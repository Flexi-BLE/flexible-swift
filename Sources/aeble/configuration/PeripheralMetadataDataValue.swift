//
//  PeripheralMetadataDataValue.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

internal enum PeripheralMetadataDataValueType: String, Codable {
    case int = "int"
    case float = "float"
    case string = "string"
}

internal protocol PeripheralDataValue: CustomStringConvertible, Codable {}
extension String: PeripheralDataValue { }
extension Float: PeripheralDataValue { }
extension Double: PeripheralDataValue { }
extension Int: PeripheralDataValue { }

//internal struct PeripheralMetadataDataValue: Codable, Equatable {
//    let name: String
//    let type: PeripheralMetadataDataValueType
//    let byteStart: Int
//    let byteEnd: Int
//    let unit: String?
//    let description: String?
//    let multiplier: Float?
//    let index: Bool?
//}
