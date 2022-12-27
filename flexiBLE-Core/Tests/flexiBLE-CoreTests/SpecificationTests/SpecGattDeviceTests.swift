//
//  SpecGattDeviceTests.swift
//  
//
//  Created by Blaine Rothrock on 12/27/22.
//

import XCTest
@testable import flexiBLE_Core


final class SpecGattDeviceTests: XCTestCase {

    func testDecode() throws {
        let spec = SpecMock.valid
        guard let _ = spec.gattDevices.first else {
            XCTFail("at least one GATT device should exist")
            return
        }
    }

    func testCreateAndAdd() throws {
        let spec = SpecMock.valid
        
        let gattDevice = FXBSpecGattDevice(name: "test")
        spec.add(gattDevice, forKey: "tester")
        
        XCTAssert(spec.gattDevice(forKey: "tester") != nil, "should contain gatt device")
        
        spec.removeGattDevice(forKey: "tester")
        
        XCTAssert(spec.gattDevice(forKey: "tester") == nil, "should not contain gatt device")
    }
}
