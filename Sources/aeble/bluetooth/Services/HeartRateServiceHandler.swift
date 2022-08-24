//
//  HeartRateServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import CoreBluetooth

internal class HeartRateServiceHandler: AEBLEServiceHandler {
    internal var serviceUuid: CBUUID = BLERegisteredService.heartRate.uuid
    
    private var sensorLocation: String = "unknown"
    private let heartRateMeasurementUuid = CBUUID(string: "2a37")
    private let bodyLocationUuid = CBUUID(string: "2a38")
    internal var deviceName: String
    
    init(deviceName: String) {
        self.deviceName = deviceName
    }
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        for characteristic in service.characteristics ?? [] {
            switch characteristic.uuid {
            case heartRateMeasurementUuid: peripheral.setNotifyValue(true, for: characteristic)
            case bodyLocationUuid: peripheral.readValue(for: characteristic)
            default: break
            }
        }
        
        Task {
            await AEBLEDBManager.shared.createTable(for: .heartRate)
        }
    }
    
    func didWrite(uuid: CBUUID) {
        bleLog.debug("did write value for \(self.serviceUuid)")
    }
    
    func didUpdate(uuid: CBUUID, data: Data?) {
        guard let data = data else { return }
        
        switch uuid {
        case heartRateMeasurementUuid:
            var hr: Int = -1
            
            let byteArray = [UInt8](data)
            
            let firstBitValue = byteArray[0] & 0x01
            if firstBitValue == 0 {
                hr = Int(byteArray[1])
            } else {
                hr = (Int(byteArray[1]) << 8) + Int(byteArray[2])
            }
            
            bleLog.debug("heart rate: \(hr)")
            Task { [hr] in
                await AEBLEDBManager.shared.insert(
                    bpm: hr,
                    sensorLocation: sensorLocation
                )
                
                try? await LocalQueryWrite().recordThroughput(
                     deviceName: self.deviceName,
                     dataStreamName: "heart_rate",
                     byteCount: data.count
                 )
            }
        case bodyLocationUuid:
            if let byte = data.first {
                sensorLocation = getSensorLocation(for: byte)
                bleLog.debug("Sensor Location: \(self.sensorLocation)")
            }
        default: break
        }
    }
    
    private func getSensorLocation(for val: UInt8) -> String {
        switch val {
        case 0: return "other"
        case 1: return "chest"
        case 2: return "wrist"
        case 3: return "finger"
        case 4: return "hand"
        case 5: return "ear lobe"
        case 6: return "foot"
        default: return "unknown"
        }
    }
}
