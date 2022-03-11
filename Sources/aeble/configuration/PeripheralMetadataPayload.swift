//
//  PeripheralMetadataPayload.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

internal struct PeripheralMetadataPayload: Codable {
    let id: String
    let schemaVersion: String
    let createdAt: Date
    let updatedAt: Date
    let peripherals: [PeripheralMetadata]?
}
