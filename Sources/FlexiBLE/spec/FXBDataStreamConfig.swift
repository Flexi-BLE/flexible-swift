//
//  FXBDataStreamConfig.swift
//  
//
//  Created by blaine on 7/15/22.
//

import Foundation

public enum FXBConfigSelectionType: String, Codable {
    case single = "single"
    case range = "range"
    case bitEncodedMultiSelect = "bit-encoded-multi"
}

public struct FXBDataStreamConfig: Codable {
    public let name: String
    public let description: String
    public let defaultValue: String
    
    internal let byteStart: Int
    internal let byteEnd: Int
    internal let size: Int
    internal let dataType: FXBDataValueType
    public let selectionType: FXBConfigSelectionType
    public let unit: String?
    
    public let options: [AEDataStreamConfigOption]?
    public let range: AEDataStreamConfigRange?
}

public struct AEDataStreamConfigOption: Codable {
    public let name: String
    public let description: String
    public let value: String
}

public struct AEDataStreamConfigRange: Codable {
    public let start: Int
    public let end: Int
    public let step: Int
}
