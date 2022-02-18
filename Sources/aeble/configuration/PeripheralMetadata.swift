//
//  PeripheralMetadata.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

internal struct PeripheralMetadata: Codable, Equatable {
    let name: String
    let description: String
    let tags: [String]
    let services: [PeripheralServiceMetadata]?
}
