//
//  SpecValueTests.swift
//  
//
//  Created by Blaine Rothrock on 12/28/22.
//

import XCTest
@testable import flexiBLE_Core

final class SpecValueTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDecode() throws {
        guard let dataStream = SpecMock.valid.customDevices.first?.dataStreams.first,
              let dataValue = dataStream.dataValues.first,
              let configValue = dataStream.configValues.first else {
                  
            XCTFail("should be at least one data value and config value")
            return
        }
        
        let minConfigIndex = dataStream.configValues.map({ $0.index }).min()
        let minDataIndex = dataStream.dataValues.map({ $0.index }).min()
        
        XCTAssert(minConfigIndex == configValue.index, "should sort by index acending")
        XCTAssert(minDataIndex == dataValue.index, "should sort by index acending")
    }
    
}
