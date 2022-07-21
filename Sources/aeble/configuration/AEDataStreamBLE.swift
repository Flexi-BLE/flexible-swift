//
//  AEDataStreamBLE.swift
//  
//
//  Created by Blaine Rothrock on 4/14/22.
//

import Foundation

internal struct AEDataStreamBLE: Codable {
//    let notifyId: String
//    let dataId: String
//    let timeOffsetId: String
    let serviceUuid: String
    let dataCharUuid: String
    let configCharUuid: String
}
