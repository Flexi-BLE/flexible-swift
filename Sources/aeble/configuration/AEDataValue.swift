//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 4/13/22.
//

import Foundation

internal struct AEDataValue: Codable {
    let name: String
    let description: String?
    let uint: String?
    let byteStart: Int
    let byteEnd: Int
    let size: Int
    let isUnsignedNegative: Bool
    let isSigned: Bool
    let precision: Int
}
