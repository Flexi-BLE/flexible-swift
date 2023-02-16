//
//  BluetoothTests.swift
//  
//
//  Created by Blaine Rothrock on 2/14/23.
//

import XCTest
import CoreBluetoothMock
import Combine
@testable import FlexiBLE

final class BluetoothDeviceConnectionTests: XCTestCase {
    
    var peripheralDelegate = FlexiBLEAccelMockDelegate()
    
    lazy var peripheral: CBMPeripheralSpec = {
       return buildFlexiBLEAccel(delegate: peripheralDelegate)
    }()
    
    func flexiBLE() -> FlexiBLE {
        let flexible = FlexiBLE()
        flexible.createProfile(
            with: SpecificationMock.container
                .add(device: SpecificationMock.accelDevice),
            name: "test",
            setActive: true
        )
        return flexible
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

    func testFindDeviceWithSubject() throws {
        guard let profile = flexiBLE().profile else {
            XCTFail("profile should be loaded")
            return
        }
        
        let expectation = self.expectation(description: "Looking for Device2")
        
        let obs = profile.devicesManager.deviceFoundSubject.sink { deviceManager in
            XCTAssert(deviceManager.isConnected == false)
            XCTAssert(deviceManager.name != "noname")
            XCTAssert(deviceManager.name == self.peripheral.name)
            expectation.fulfill()
        }
        
        profile.startScan()
        
        waitForExpectations(timeout: 0.5, handler: nil)
        obs.cancel()
    }
    
    func testFindDeviceLater() throws {
        guard let profile = flexiBLE().profile else {
            XCTFail("profile should be loaded")
            return
        }
        
        let expectation = self.expectation(description: "Looking for Device")
        
        let obs = profile
            .devicesManager
            .deviceFoundSubject
            .first()
            .sink { _ in expectation.fulfill() }
        
        profile.startScan()
        
        waitForExpectations(timeout: 0.5, handler: nil)
        obs.cancel()

        XCTAssert(
            profile.devicesManager.foundDevices.count == 1,
            "should only be one found device")
        
        XCTAssertNotNil(
            profile.devicesManager.foundDevices.first(where: { $0.name == peripheral.name }),
            "should find found device by name")
        
        XCTAssert(
            profile.devicesManager.connectedDevices.isEmpty,
            "should be zero connected devices"
        )
    }
    
    func testConnectToDevice() {
        guard let profile = flexiBLE().profile else {
            XCTFail("profile should be loaded")
            return
        }

        let expFind = self.expectation(description: "Waiting for Device Discovery")
        
        var deviceManager: FlexiBLEDeviceManager?
        let obsFind = profile
            .devicesManager
            .deviceFoundSubject
            .first()
            .sink {
                deviceManager = $0
                expFind.fulfill()
            }
        
        profile.startScan()
        wait(for: [expFind], timeout: 0.5)
        obsFind.cancel()
        
        guard let deviceManager = deviceManager else {
            XCTFail("should have device manager")
            return
        }
        
        let expConnect = self.expectation(description: "Waiting for Device Connection")
        
        let obsConnect = deviceManager.connect().sink(
            receiveCompletion: { _ in expConnect.fulfill() },
            receiveValue: {}
        )
        
        wait(for: [expConnect], timeout: 0.5)
        obsConnect.cancel()
    }
    
    func testConnectToDeviceAccessLater() {
        guard let profile = flexiBLE().profile else {
            XCTFail("profile should be loaded")
            return
        }
        
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

        XCTAssert(
            profile.devicesManager.connectedDevices.count == 1,
            "should only be one found device")
        
        XCTAssertNotNil(
            profile.devicesManager.connectedDevices.first(where: { $0.name == peripheral.name }),
            "should find found device by name")
        
        XCTAssert(
            profile.devicesManager.foundDevices.isEmpty,
            "should be zero connected devices"
        )
        
        profile.stopScan()
    }

}
