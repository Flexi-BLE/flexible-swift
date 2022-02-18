//
//  PeripheralMetadataDataValue.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

internal struct PeripheralMetadataDataValue: Codable, Equatable {
    let name: String
    let byteStart: Int
    let byteEnd: Int
    let unit: String?
    let description: String?
    let multiplier: Float?
    let index: Bool?
}
