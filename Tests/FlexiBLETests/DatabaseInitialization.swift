//
//  DatabaseInitialization.swift
//  
//
//  Created by Blaine Rothrock on 2/14/23.
//

import XCTest
@testable import FlexiBLE

final class DatabaseInitialization: XCTestCase {
    lazy var flexiBLE: FlexiBLE = {
        let flexible = FlexiBLE()
        flexible.createProfile(
            with: SpecificationMock.container
                .add(device: SpecificationMock.simpleArduinoDevice),
            name: "test",
            setActive: true
        )
        return flexible
    }()
    
    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        try TestUtils.tearDownFlexiBLE()
    }

    func testDBInit() throws {
        guard let profile = flexiBLE.profile else {
            XCTFail("profile should exist")
            return
        }
        
        let tableName = try profile.database.dynamicTable.tableNames().sorted(by: >)
        let dataStreamNames = profile.specification.devices.flatMap { device in
            return device.dataStreams.map({ $0.name })
        }.sorted(by: >)
        
        XCTAssert(tableName == dataStreamNames, "should be a table for each data stream")
    }
}
