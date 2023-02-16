//
//  InitializeApp.swift
//  
//
//  Created by Blaine Rothrock on 2/14/23.
//

import XCTest
@testable import FlexiBLE

final class InitializeApp: XCTestCase {
    
    override func tearDownWithError() throws {
        try TestUtils.tearDownFlexiBLE()
    }

    func testProfileCreation() throws {
        let flexiBLE = FlexiBLE()
        
        print("TEST: app data path: \(flexiBLE.appDataPath)")
        
        XCTAssertNil(flexiBLE.profile)
        flexiBLE.createProfile(with: nil, name: "test", setActive: true)
        XCTAssertNotNil(flexiBLE.profile)
    }
    
    func testSwitchProfile() throws {
        let flexiBLE = FlexiBLE()
        XCTAssertNil(flexiBLE.profile)
        
        flexiBLE.createProfile(with: nil, name: "test1", setActive: true)
        XCTAssert(flexiBLE.profile?.name == "test1", "profile not set")
        
        let newProfileId = flexiBLE.createProfile(
            with: nil,
            name: "test2",
            setActive: false
        )
        XCTAssert(flexiBLE.profile?.name == "test1", "profile should not change")
        
        flexiBLE.switchProfile(to: newProfileId)
        XCTAssert(flexiBLE.profile?.name == "test2", "profile should be updated")
        XCTAssert(FlexiBLEAppData.shared.lastProfile()?.id == newProfileId, "should be new profile")
    }
}
