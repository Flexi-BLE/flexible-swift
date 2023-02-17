//
//  FlexiBLEServiceTests.swift
//  
//
//  Created by Blaine Rothrock on 2/16/23.
//

import XCTest
import CoreBluetoothMock
import Combine
@testable import FlexiBLE

final class FlexiBLEServiceTests: XCTestCase {
    
    var peripheralDelegate = FlexiBLEAccelMockDelegate()
    
    lazy var peripheral: CBMPeripheralSpec = {
       return buildFlexiBLEAccel(delegate: peripheralDelegate)
    }()
    
    func createProfile() -> FlexiBLEProfile {
        let flexible = FlexiBLE()
        flexible.createProfile(
            with: SpecificationMock.container
                .add(device: SpecificationMock.accelDevice),
            name: "test",
            setActive: true
        )
        return flexible.profile!
    }
            

    override func setUpWithError() throws {
        try super.setUpWithError()
        // start mocked core bluetooth
        CBMCentralManagerMock
            .simulatePeripherals([self.peripheral])
        
        CBMCentralManagerMock
            .simulateInitialState(.poweredOn)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        try TestUtils.tearDownFlexiBLE()
        CBMCentralManagerMock.tearDownSimulation()
    }

    func testEpochTimeSet() throws {
        
    }
    
    func testEpochTimeReset() throws {
        
    }
    
    func testDeviceSpecURL() throws {
        let profile = createProfile()
        
        let expSearch = self.expectation(description: "Searching for Device")
        
        var deviceManager: FlexiBLEDeviceManager?
        
        let obsFind = profile.devicesManager.deviceFoundSubject
            .first()
            .sink {
                deviceManager = $0
                expSearch.fulfill()
            }
        
        
        profile.startScan()
        waitForExpectations(timeout: 0.5, handler: nil)
        
        guard let deviceManager = deviceManager else {
            XCTFail("should have device manager for found device")
            return
        }
        
        let expConnect = self.expectation(description: "Connecting to device")
        obsFind.cancel()
        
        let obsConnect = deviceManager
            .connect()
            .sink(
                receiveCompletion: { _ in expConnect.fulfill() },
                receiveValue: {}
            )
        
        waitForExpectations(timeout: 0.5, handler: nil)
        obsConnect.cancel()
        
        sleep(5)
        
    }

}
