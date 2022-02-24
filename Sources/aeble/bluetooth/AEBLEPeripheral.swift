//
//  File.swift
//  
//
//  Created by blaine on 2/22/22.
//

import Foundation
import CoreBluetooth
import Combine
import GRDB

internal enum AEBLEPeripheralState: String {
    case notFound = "not found"
    case connected = "connected"
    case disconnected = "disconnected"
}

internal class AEBLEPeripheral: NSObject, ObservableObject {
    @Published private(set) var state: AEBLEPeripheralState = .disconnected
    
    typealias PeriperalRecord = (metadata: PeripheralCharacteristicMetadata, values: [PeripheralDataValue])
    
    let metadata: PeripheralMetadata
    private let db: AEBLEDBManager
//    lazy var dbQueue: DatabaseQueue? = {
//        var configuration = Configuration()
//        configuration.qos = DispatchQoS.utility
//
//        return try? DatabaseQueue(
//            path: self.dbUrl.path,
//            configuration: configuration
//        )
//    }()
    
    internal var cbp: CBPeripheral?
    
    init(metadata: PeripheralMetadata, db: AEBLEDBManager) {
        self.metadata = metadata
        self.db = db
    }
    
    func set(peripheral: CBPeripheral) {
        self.cbp = peripheral
        self.didUpdateState()
    }
    
    func didUpdateState() {
        guard let peripheral = self.cbp else { return }
        
        switch peripheral.state {
        case .connected, .connecting: self.onConnect()
        default: self.onDisconnect()
        }
    }
    
    private func onConnect() {
        guard let peripheral = self.cbp else { return }
        self.state = .connected
        peripheral.delegate = self
        
        peripheral.discoverServices(metadata.serviceIds)
    }
    
    private func onDisconnect() {
        self.state = .disconnected
    }
}

extension AEBLEPeripheral: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(service)
            let charIds = metadata.services?.first(where: { $0.cbuuid == service.uuid })?.characteristicIds
            peripheral.discoverCharacteristics(charIds, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        bleLog.info("did discover characteristics for \(service.uuid)")
        guard let characteristics = service.characteristics,
              let serviceMetadata = metadata.serviceMetadata(by: service.uuid) else { return }
        
        for characteristic in characteristics {
            bleLog.info("characteristic: \(characteristic.uuid): \(characteristic.properties.rawValue)")
            
            guard let charMetadata = serviceMetadata.characteristicMatadata(by: characteristic.uuid) else { return }
            
            if charMetadata.notify {
                peripheral.setNotifyValue(true, for: characteristic)
            }
             
//            DBManager.shared.createTable(from: charMetadata, forceNew: false)
            
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        bleLog.info("did update value for characteristic \(characteristic.uuid)")
        guard let service = characteristic.service,
              let serviceMetadata = metadata.serviceMetadata(by: service.uuid),
              let characteristicMetadata = serviceMetadata.characteristicMatadata(by: characteristic.uuid),
              let dataValues = characteristicMetadata.dataValues,
              let data = characteristic.value else { return }
        
        var values: [PeripheralDataValue] = []
        for dv in dataValues {
            let bytes = data[dv.byteStart...dv.byteEnd]
        
            switch dv.type {
            case .float:
                var rawValue: Int = 0
                for byte in bytes.reversed() {
                    bleLog.info("\(byte)")
                    rawValue = rawValue << 8
                    rawValue = rawValue | Int(byte)
                }
                
                var value: Float = Float(rawValue)
                if let mult = dv.multiplier {
                    value = Float(rawValue) * mult
                }
                values.append(value)
                bleLog.debug("float value: \(value)")
            case .int:
                var value: Int = 0
                for byte in bytes.reversed() {
                    bleLog.info("\(byte)")
                    value = value << 8
                    value = value | Int(byte)
                }
                
                if let mult = dv.multiplier {
                    value = Int(value) * Int(mult)
                }
                values.append(value)
                bleLog.debug("interger value: \(value)")
            case .string:
                let value = String(bytes: bytes, encoding: .utf8) ?? ""
                values.append(value)
                bleLog.debug("string value: \(value)")
            }
        }
        self.db.arbInsert(
            for: characteristicMetadata,
            values: values
        )
        
//        TODO: batch update to influx
//        for (i, dv) in dataValues.enumerated() {
//            if dv.index ?? false {
//                point.addTag(key: dv.name, value: "\(values[i])")
//            } else {
//                point.addField(key: dv.name, value: .double(Double(values[i])))
//            }
//        }
//        try? InfluxDB.writePoints([point])
        
    }
}
