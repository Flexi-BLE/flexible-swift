//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/14/23.
//

import Foundation
@testable import FlexiBLE

enum SpecificationMock {
    static var container: FXBSpec {
        return FXBSpec(
            id: UUID().uuidString,
            schemaVersion: FXBSpec.schemaVersion,
            createdAt: Date.now,
            updatedAt: Date.now,
            bleRegisteredDevices: [],
            devices: []
        )
    }
    
    static var simpleArduinoDevice: FXBDeviceSpec {
        return Bundle.module.decode(FXBDeviceSpec.self, from: "simple-device-spec.json")
    }
    
    static var accelDevice: FXBDeviceSpec {
        return Bundle.module.decode(FXBDeviceSpec.self, from: "accel-device.json")
    }
}
