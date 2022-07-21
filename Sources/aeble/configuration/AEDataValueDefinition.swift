//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 4/13/22.
//

import Foundation

public struct AEDataValueDefinition: Codable {
    public let name: String
    public let description: String?
    public let uint: String?
    internal let byteStart: Int
    internal let byteEnd: Int
    internal let size: Int
    internal let type: AEDataValueType
//    internal let isUnsignedNegative: Bool
//    internal let isSigned: Bool
//    internal let precision: Int
}
