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
    
    typealias PeriperalRecord = (metadata: AEDataStream, values: [PeripheralDataValue])
    
    let metadata: AEThing
    private let db: AEBLEDBManager
    
    private typealias DataStreamPacket = (dataPayload: Data?, timePayload: Data?)
    private var dataStreamPacket: DataStreamPacket?
    
    internal var cbp: CBPeripheral?
    
    init(metadata: AEThing, db: AEBLEDBManager) {
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
            if service.uuid == CBUUID(string: "0x38ae") {
                let charIds = metadata.characteristicIds
                peripheral.discoverCharacteristics(charIds, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        bleLog.info("did discover characteristics for \(service.uuid)")
        
        guard let characteristics = service.characteristics else {
            bleLog.error("no characteristics found for \(service.uuid)")
            return
        }
        
        bleLog.info("found \(characteristics.count) characteristics for service \(service.uuid)")

        if service.uuid == CBUUID(string: metadata.ble.dataServiceId) {
            setupCharsDataService(
                peripheral: peripheral,
                characteristics: characteristics
            )
        }
        
        if service.uuid == CBUUID(string: metadata.ble.infoServiceId) {
            // TODO:
        }
        
        if service.uuid == CBUUID(string: metadata.ble.configServiceId) {
            // TODO:
        }
    }
    
    private func setupCharsDataService(peripheral: CBPeripheral, characteristics: [CBCharacteristic]) {
        for chr in characteristics {
            bleLog.info("characteristic: \(chr.uuid): \(chr.properties.rawValue)")
            
            if let md = metadata.charMetadata(by: chr.uuid) {
                if chr.uuid == CBUUID(string: md.ble.notifyId) {
                    peripheral.setNotifyValue(true, for: chr)
                }
                db.createTable(from: md, forceNew: false)
                peripheral.readValue(for: chr)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        bleLog.info("did update value for characteristic \(characteristic.uuid)")
        
        if let error = error {
            bleLog.error("BLE Update Error: \(error.localizedDescription)")
            return
        }
        
        guard let md = metadata.charMetadata(by: characteristic.uuid),
              let data = characteristic.value else {
            
            return
        }
        
        if characteristic.uuid == md.notifyCbuuid {
            let notifyVal: UInt8 = data[0]
            bleLog.info("data stream notify value \(notifyVal)")
            dataStreamPacket = DataStreamPacket(nil, nil)
            if notifyVal > 0 {
                if let dataChr = characteristic
                    .service?
                    .characteristics?
                    .first(where: { $0.uuid == md.dataCbuuid }) {
                    
                    peripheral.readValue(for: dataChr)
                }
                if md.includeOffsetTimestamp {
                    if let toChr = characteristic
                        .service?
                        .characteristics?
                        .first(where: { $0.uuid == md.timeOffsetCbuuid }) {
                        
                        peripheral.readValue(for: toChr)
                    }
                }
            }
        }
        
        if characteristic.uuid == md.dataCbuuid {
            bleLog.info("recieved data of size \(data.count)")
            if data.count > 0 {
                dataStreamPacket?.dataPayload = data
            }
        }
        
        if characteristic.uuid == md.timeOffsetCbuuid {
            bleLog.info("recieved time offset data of size \(data.count)")
            if data.count > 0 {
                dataStreamPacket?.timePayload = data
            }
        }
        
        if let dsp = dataStreamPacket,
            let _ = dsp.dataPayload,
            !md.includeOffsetTimestamp {
            
            Task { await parseDataStream(db: db, packet: dsp, md: md) }
        } else if let dsp = dataStreamPacket,
            let _ = dsp.dataPayload,
            let _ = dsp.timePayload {
            
            Task { await parseDataStream(db: db, packet: dsp, md: md) }
        }
        
//
//        guard let service = characteristic.service,
//              let serviceMetadata = metadata.serviceMetadata(by: service.uuid),
//              let characteristicMetadata = serviceMetadata.characteristicMatadata(by: characteristic.uuid),
//              let dataValues = characteristicMetadata.dataValues,
//              let data = characteristic.value else { return }
//
//        var values: [PeripheralDataValue] = []
//        for dv in dataValues {
//            let bytes = data[dv.byteStart...dv.byteEnd]
//
//            switch dv.type {
//            case .float:
//                var rawValue: Int = 0
//                for byte in bytes.reversed() {
////                    bleLog.info("\(byte)")
//                    rawValue = rawValue << 8
//                    rawValue = rawValue | Int(byte)
//                }
//
//                var value: Float = Float(rawValue)
//                if let mult = dv.multiplier {
//                    value = Float(rawValue) * mult
//                }
//                values.append(value)
////                bleLog.debug("float value: \(value)")
//            case .int:
//                var value: Int = 0
//                for byte in bytes.reversed() {
////                    bleLog.info("\(byte)")
//                    value = value << 8
//                    value = value | Int(byte)
//                }
//
//                if let mult = dv.multiplier {
//                    value = Int(value) * Int(mult)
//                }
//                values.append(value)
////                bleLog.debug("interger value: \(value)")
//            case .string:
//                let value = String(bytes: bytes, encoding: .utf8) ?? ""
//                values.append(value)
////                bleLog.debug("string value: \(value)")
//            }
//        }
//        self.db.arbInsert(
//            for: characteristicMetadata,
//            values: values
//        )
        
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
    
    private func parseDataStream(db: AEBLEDBManager, packet: DataStreamPacket, md: AEDataStream) async {
        var dataValues: [PeripheralDataValue] = []
        var tsValues: [PeripheralDataValue] = []
        
        if let data = packet.dataPayload {
            bleLog.debug("parsing data values")
            dataValues = AEBLEPeripheral.parseData(data: data, dataValues: md.dataValues)
        }
        if let data = packet.timePayload {
            bleLog.debug("parsing time offsets")
            tsValues = AEBLEPeripheral.parseData(data: data, dataValues: [md.timeOffsetValue])
        }
        
        await db.arbInsert(for: md, dataValues: dataValues, tsValues: tsValues, date: Date())
    }
    
    private static func parseData(data: Data, dataValues: [AEDataValue]) -> [PeripheralDataValue] {
        // FIXME: assumes no time offsets
        
        var cursor = 0
        
//        if md.includeAnchorTimestamp {
//            let bytes: [UInt8] = Array(data[cursor..<(cursor+8)])
//            var epoch: UInt64 = 0
//            for byte in bytes.reversed() {
//                epoch = epoch << 8
//                epoch = epoch | UInt64(byte)
//            }
//            bleLog.debug("timestamp: \(epoch)")
//            cursor += 8
//        }
//        if md.intendedFrequencyMs > 0 {
//            let bytes: [UInt8] = Array(data[cursor..<(cursor+4)])
//            var expectedFreq: UInt32 = 0
//            for byte in bytes.reversed() {
//                expectedFreq = expectedFreq << 8
//                expectedFreq = expectedFreq | UInt32(byte)
//            }
//            bleLog.debug("expected frequency: \(expectedFreq)")
//            cursor += 4
//        }
        
        let readingSize = dataValues.reduce(0, { $0 + $1.size })
        
        var values: [PeripheralDataValue] = []
        
        for _ in 0..<(data.count / readingSize) {
            // must copy (new array) or we run into memory issues
            let payload: [UInt8] = Array(data[cursor..<(cursor+readingSize)])
            
            for dv in dataValues {
                let bytes = payload[dv.byteStart..<dv.byteEnd]
                var rawValue: Int = 0
                for byte in bytes {
                    rawValue = rawValue << 8
                    rawValue = rawValue | Int(byte)
                }
                
                if dv.isSigned {
                    // TODO: handle signed
                }
                
                if dv.isUnsignedNegative {
                    // TODO: handle sign flipping
                }
                
                if dv.precision > 0 {
                    // TODO: handle precision (double)
                }
                
                bleLog.debug("  - raw value extracted: \(rawValue)")
                values.append(rawValue)
            }
            
            cursor += readingSize
        }
        
        return values
    }
}
