//
//  SpecDataStreamTests.swift
//  
//
//  Created by Blaine Rothrock on 12/28/22.
//

import XCTest
@testable import flexiBLE_Core

final class SpecDataStreamTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecode() throws {
        let spec = SpecMock.valid
        guard let customDevice = spec.customDevices.first,
              let _ = customDevice.dataStreams.first else {
            
            XCTFail("should have at least one data stream")
            return
        }
    }
    
    func testAddAndCreate() throws {
        guard let customDevice = SpecMock.valid.customDevices.first else {
            XCTFail("should have at least one custom device")
            return
        }
        
        let dataStream = FXBSpecDataStream(
            name: "tester",
            description: "cool",
            precision: .microsecond,
            writeDefaultOnConnect: true
        )
        
        let dataStreamCount = customDevice.dataStreams.count
        
        customDevice.add(dataStream, forKey: "tester")
        
        XCTAssert(customDevice.dataStream(forKey: "tester") != nil, "data stream should exist")
        XCTAssert(customDevice.dataStreams.count == dataStreamCount+1, "should have one more data stream")
        
        customDevice.removeDataSteam(forKey: "tester")
        
        XCTAssert(customDevice.dataStream(forKey: "tester") == nil, "data stream should not exist")
        XCTAssert(customDevice.dataStreams.count == dataStreamCount, "should have equal data stream")
    }

}
