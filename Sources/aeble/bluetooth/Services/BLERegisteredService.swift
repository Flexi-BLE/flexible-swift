//
//  BLERegisteredService.swift
//  
//
//  Created by blaine on 6/21/22.
//

import Foundation
import CoreBluetooth

enum BLERegisteredService: String, Codable {
    case battery
    case currentTime = "current-time"
    
    var uuid: CBUUID {
        switch self {
        case .battery: return CBUUID(string: "180f")
        case .currentTime: return CBUUID(string: "1805")
        }
    }
    
    static func from(_ uuid: CBUUID) -> BLERegisteredService? {
        switch uuid {
        case _ where uuid == CBUUID(string: "180f"):
            return .battery
        case _ where uuid == CBUUID(string: "1805"):
            return .currentTime
        default: return nil
        }
    }
}
