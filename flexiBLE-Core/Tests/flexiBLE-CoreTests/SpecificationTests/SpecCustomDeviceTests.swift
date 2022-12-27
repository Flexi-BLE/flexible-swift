//
//  SpecCustomDeviceTests.swift
//  
//
//  Created by Blaine Rothrock on 12/27/22.
//

import XCTest
@testable import flexiBLE_Core

final class SpecCustomDeviceTests: XCTestCase {
    
    func testDecoding() throws {
        let spec = SpecMock.valid
        guard let device = spec.customDevices.first else {
            XCTFail("no device by that key")
            return
        }
        
        XCTAssert(device.dataStreams.count > 0, "device should have data streams")
    }
    
    func testCreateAndAdd() throws {
        let spec = SpecMock.valid
        
        let device = FXBSpecCustomDevice(name: "tester")
        spec.add(device, forKey: "tester")
        
        XCTAssert(spec.customDevice(forKey: "tester") != nil, "device should exist")
        
        spec.removeCustomDevice(forKey: "tester")
        XCTAssert(spec.customDevice(forKey: "tester") == nil, "device should not exist")
    }

}
