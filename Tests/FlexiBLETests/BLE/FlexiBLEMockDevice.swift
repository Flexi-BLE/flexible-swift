//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/14/23.
//

import Foundation
import CoreBluetoothMock
@testable import FlexiBLE

extension CBMUUID {
    // Example Acceleration FlexiBLE Service
    static let FlexiBLEAccelServiceUUID = CBUUID(string: "1a240001-c2ed-4d11-ad1e-fc06d8a02d37")
    static let FlexiBLEAccelDataCharUUID = CBMUUID(string: "1a240002-c2ed-4d11-ad1e-fc06d8a02d37")
    static let FlexIBLEAccelConfigCharUUID = CBMUUID(string: "1a240003-c2ed-4d11-ad1e-fc06d8a02d37")
}

extension CBMCharacteristicMock {
    // FlexiBLE Service
    static let FlexiBLEEpochCharUUID = CBMCharacteristicMock(
        type: CBMUUID(string: CBUUID.EpochCharUUID.uuidString),
        properties: [.read, .write],
        descriptors: CBMClientCharacteristicConfigurationDescriptorMock()
    )
    
    static let FlexiBLERefreshEpochCharUUID = CBMCharacteristicMock(
        type: CBMUUID(string: CBUUID.RefreshEpochCharUUID.uuidString),
        properties: [.read],
        descriptors: CBMClientCharacteristicConfigurationDescriptorMock()
    )
    
    static let FlexiBLESpecificationURLCharUUID = CBMCharacteristicMock(
        type: CBMUUID(string: CBUUID.SpecURLUUID.uuidString),
        properties: [.read],
        descriptors: CBMClientCharacteristicConfigurationDescriptorMock()
    )
    
    
    // Example Acceleration FlexiBLE Service
    static let FlexiBLEAccelDataChar = CBMCharacteristicMock(
        type: .FlexiBLEAccelDataCharUUID,
        properties: [.notify, .read],
        descriptors: CBMClientCharacteristicConfigurationDescriptorMock()
    )
    
    static let FlexiBLEAccelConfigChar = CBMCharacteristicMock(
        type: .FlexIBLEAccelConfigCharUUID,
        properties: [.read, .write],
        descriptors: CBMClientCharacteristicConfigurationDescriptorMock()
    )
}

extension CBMServiceMock {

    static let FlexiBLEMock = CBMServiceMock(
        type: CBMUUID(string: CBUUID.FlexiBLEAccelServiceUUID.uuidString),
        primary: true,
        characteristics:
            .FlexiBLEEpochCharUUID,
            .FlexiBLERefreshEpochCharUUID,
            .FlexiBLESpecificationURLCharUUID
    )
    
    static let AccelMock = CBMServiceMock(
        type: .FlexiBLEAccelServiceUUID,
        primary: false,
        characteristics:
            .FlexiBLEAccelDataChar,
            .FlexiBLEAccelConfigChar
    )
    
}

internal class FlexiBLEAccelMockDelegate: CBMPeripheralSpecDelegate {
    
    let specURL: String = "https://flexible.xyz/specs/mock.json"
    var specURLData: Data {
        return specURL.data(using: .ascii) ?? Data()
    }
    
    
    // FLEXIBLE SERVICE
    var epoch: Date? = nil
    var epochData: Data {
        if let epoch = epoch {
            var milli = Int64(epoch.unixEpochMilliseconds)
            return Data(bytes: &milli, count: MemoryLayout.size(ofValue: milli))
        } else {
            return Data()
        }
    }
    
    let refreshEpoch: Bool = false
    var refreshEpochData: Data {
        return refreshEpoch ? Data([0x01]) : Data([0x00])
    }
    
    // ACCEL SERVICE
    //  - byte 0: sensor state
    //  - byte 1-2: desired frequency
    private let accelConfigLength: Int = 3
    var accelConfigData: Data = Data([0x00, 0x00, 0x20])
    
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveReadRequestFor characteristic: CBMCharacteristicMock) -> Result<Data, Error> {
        
        switch characteristic.uuid {
        case .SpecURLUUID: return .success(specURLData)
        case .EpochCharUUID: return .success(epochData)
        case .RefreshEpochCharUUID: return .success(refreshEpochData)
        case .FlexIBLEAccelConfigCharUUID: return .success(accelConfigData)
        default: return .failure(CBError.uuidNotAllowed as! Error)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveWriteRequestFor characteristic: CBMCharacteristicMock, data: Data) -> Result<Void, Error> {
        
        switch characteristic.uuid {
        case .EpochCharUUID:
            let epochMilliseconds = data.withUnsafeBytes { ptr in
                return ptr.load(as: Int64.self)
            }
            epoch = Date(timeIntervalSince1970: Double(epochMilliseconds) / 1_000.0)
            return .success(())
        case .FlexIBLEAccelConfigCharUUID:
            guard data.count == accelConfigLength else {
                return .failure(CBError.invalidParameters as! Error)
            }
            
            accelConfigData = data
            return .success(())
        default:
            return .failure(CBError.uuidNotAllowed as! Error)
        }
    }
}

internal func buildFlexiBLEAccel(delegate: FlexiBLEAccelMockDelegate) -> CBMPeripheralSpec {
    return CBMPeripheralSpec
        .simulatePeripheral(proximity: .near)
        .advertising(
            advertisementData: [
                CBMAdvertisementDataLocalNameKey    : "Flexible Accel 01",
                CBMAdvertisementDataServiceUUIDsKey : [CBMUUID(string: CBUUID.FlexiBLEServiceUUID.uuidString)],
                CBMAdvertisementDataIsConnectable   : true as NSNumber
            ],
            withInterval: 0.250,
            alsoWhenConnected: false
        )
        .connectable(
            name: "Flexible Accel 01",
            services: [.FlexiBLEMock, .AccelMock],
            delegate: delegate,
            connectionInterval: 0.150,
            mtu: 23
        )
        .build()
}


