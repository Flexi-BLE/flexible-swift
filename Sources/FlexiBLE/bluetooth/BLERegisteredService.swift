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
    case heartRate = "heart-rate"
    
    var uuid: CBUUID {
        switch self {
        case .battery: return CBUUID(string: "180f")
        case .currentTime: return CBUUID(string: "1805")
        case .heartRate: return CBUUID(string: "180d")
        }
    }
    
    static func from(_ uuid: CBUUID) -> BLERegisteredService? {
        switch uuid {
        case _ where uuid == CBUUID(string: "180f"):
            return .battery
        case _ where uuid == CBUUID(string: "1805"):
            return .currentTime
        case _ where uuid == CBUUID(string: "180d"):
            return .heartRate
        default: return nil
        }
    }
    
    func handler(deviceName: String) -> ServiceHandler {
        switch self {
        case .heartRate: return HeartRateServiceHandler(deviceName: deviceName)
        case .currentTime: return CurrentTimeServiceHandler(deviceName: deviceName)
        case .battery: return BatteryServiceHandler(deviceName: deviceName)
        }
    }
}
