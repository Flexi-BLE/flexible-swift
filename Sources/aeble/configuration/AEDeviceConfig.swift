//
//  PeripheralMetadataPayload.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

public struct AEDeviceConfig: Codable {
    internal let id: String
    public let schemaVersion: String
    public let createdAt: Date
    public let updatedAt: Date
    public let tags: [String]
    public let things: [AEThing]
}

extension AEDeviceConfig {
    public static var mock: AEDeviceConfig {
        return Bundle.module.decode(AEDeviceConfig.self, from: "exthub.json")
    }
}
