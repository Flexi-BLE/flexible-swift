//
//  PeripheralServiceMetadata.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

internal struct PeripheralServiceMetadata: Codable, Equatable {
    let uuid: String
    let characteristics: [PeripheralCharacteristicMetadata]?
}
