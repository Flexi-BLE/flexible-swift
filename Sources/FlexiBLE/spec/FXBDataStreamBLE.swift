//
//  AEDataStreamBLE.swift
//  
//
//  Created by Blaine Rothrock on 4/14/22.
//

import Foundation

internal struct FXBDataStreamBLE: Codable {
    let serviceUuid: String
    let dataCharUuid: String
    let configCharUuid: String
}
