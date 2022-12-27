//
//  FXBSpecRegisteredGATTService.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation

/// Supported registered GATT services
///
/// - Remark: See [Bluetooth SIG](https://www.bluetooth.com) for complete list of registered services and characteristics.
public enum FXBSpecRegisteredGATTService: String, Codable {
    case heartRate = "heart_rate"
    case battery = "battery"
}
