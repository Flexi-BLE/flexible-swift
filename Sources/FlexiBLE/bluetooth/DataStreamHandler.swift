//
//  DataStreamHandler.swift
//  
//
//  Created by Blaine Rothrock on 7/16/22.
//

import Foundation
import Combine
import CoreBluetoothMock
import SwiftUI


public class DataStreamHandler {
    
    let database: FXBLocalDataAccessor
    let serviceUuid: CBUUID
    let deviceName: String
    let def: FXBDataStream
    
    public typealias RawDataStreamRecord = (ts: Date, values: [AEDataValue])
    
    public var firehose = PassthroughSubject<RawDataStreamRecord, Never>()
    public var firehoseTS = PassthroughSubject<Date, Never>()
    
    private var lastestConfig: Data?
    
    private var previousReferenceDate: Date = Date(timeIntervalSince1970: TimeInterval.infinity)
    private var previousAnchorMS: UInt32 = 0
    
    private var defaultConfig: Data {
        return def.configValues.reduce(Data(), { $0 + $1.pack(value: $1.defaultValue) })
    }
    
    private func lastConfig() async -> Data {
        do {
            return try await database
                .dataStreamConfig
                .getLatest(forDataStream: def.name, inDevice: deviceName) ?? defaultConfig
        } catch {
            return defaultConfig
        }
    }
    
    init(database: FXBLocalDataAccessor, uuid: CBUUID, deviceName: String, dataStream: FXBDataStream) {
        self.database = database
        self.serviceUuid = uuid
        self.deviceName = deviceName
        self.def = dataStream
    }
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        if let c = service.characteristics?.first(where: { $0.uuid == def.dataCbuuid }) {
            peripheral.setNotifyValue(true, for: c)
        }
        
        if let c = service.characteristics?.first(where: { $0.uuid == def.configCbuuid }) {
            peripheral.readValue(for: c)
        }
    }
    
    func didUpdate(uuid: CBUUID, data: Data?, referenceDate: Date?=nil) {
        guard let data = data else { return }
        
        switch uuid {
        case def.dataCbuuid: Task { await didUpdateData(data: data, referenceDate: referenceDate ?? Date()) }
        case def.configCbuuid: Task { await didUpdateConfig(data: data) }
        default: bleLog.error("did update unknown characteristic: \(uuid)")
        }
    }
    
    func didWrite(uuid: CBUUID) {
        bleLog.debug("did write value for \(self.def.name)")
    }
    
    private func didUpdateData(data: Data, referenceDate: Date) async {
        var packetSize = def.dataValues.reduce(0) { $0 + $1.size }
        
        if let offsetDef = def.offsetDataValue {
            packetSize += offsetDef.size
        }
        
        var dataStartByte = 0
        
        let uints = data[0..<4].withUnsafeBytes({ $0.load(as: UInt32.self) })
        
        var anchorDate: Double
        
        if uints > previousAnchorMS && previousReferenceDate < referenceDate {
            // reference date has changed, but anchor has not decreased (must wait)
            anchorDate = previousReferenceDate.timeIntervalSince1970 as Double
        } else {
            anchorDate = referenceDate.timeIntervalSince1970 as Double
            previousReferenceDate = referenceDate
        }
        
        previousAnchorMS = uints

        
        switch def.precision {
        case .ms:
            let ms = Double(uints) / 1_000.0
            bleLog.debug("\(anchorDate): anchor ms: \(uints), seconds: \(ms), data size \(data.count)")
            anchorDate = anchorDate + ms
        case .us:
            let us = Double(uints) / 1_000_000.0
            bleLog.debug("\(anchorDate): anchor us: \(uints), seconds: \(us), data size \(data.count)")
            anchorDate = anchorDate + us
        }
       
        dataStartByte = 4
        
        var allValues: [[AEDataValue]] = []
        var timestamps: [Double] = []
        
        var timestampCounter = anchorDate
        
        for step in 0..<(Int(data.count - dataStartByte) / packetSize) {
            let i = (step * packetSize) + dataStartByte
            let packet = data[i..<i+packetSize]
            var values: [AEDataValue] = []
            
            for dv in def.dataValues {
                let v = packet[i+dv.byteStart..<i+dv.byteEnd]
                
                values.append(dv.unpack(data: v))
            }
            
            allValues.append(values)
    
            if let offsetDef = def.offsetDataValue {
                let units = Double(offsetDef.offset(from: packet[i+offsetDef.byteStart..<i+offsetDef.byteEnd]))
                
                switch def.precision {
                case .ms:
                    timestampCounter = timestampCounter + (units / 1_000.0)
                    let timestamp = timestampCounter
                    timestamps.append(timestamp)
                case .us:
                    timestampCounter = timestampCounter + (units / 1_000_000.0)
                    let timestamp = timestampCounter
                    timestamps.append(timestamp)
                }
                
                self.firehose.send(
                    RawDataStreamRecord(
                        ts: Date(timeIntervalSince1970: timestampCounter),
                        values: values
                    )
                )
                
                self.firehoseTS.send(Date(timeIntervalSince1970: timestampCounter))
            }
        }
        
        do {
            try await database.dataStream.insert(
                for: def,
                anchorDate: anchorDate,
                allValues: allValues,
                timestamps: timestamps,
                device: deviceName
            )
            
            var throughput = FXBThroughput(
                dataStream: def.name,
                bytes: data.count,
                deviceName: deviceName
            )
            
            try database.throughput.record(&throughput)
        } catch {
            dbLog.error("unable to insert transactional records: \(error.localizedDescription)")
        }
    }
    
    private func didUpdateConfig(data: Data) async {
        guard !def.configValues.isEmpty else {
            return
        }
        
        self.lastestConfig = data
        
        bleLog.debug("config read")
        
        var values: [String] = []
        
        for cv in def.configValues {
            let unpackedVal = cv.unpack(data: data)
            values.append(String(describing: unpackedVal))
            
            bleLog.debug("config value loaded: \(cv.name): \(String(describing: unpackedVal))")
        }
        
        do {
            try await database
                .dataStreamConfig
                .insert(
                    for: def,
                    values: values,
                    device: deviceName
                )
        } catch {
            dbLog.error("unable to insert data stream config record: \(error.localizedDescription)")
        }
    }
    
    internal func writeConfig(peripheral: CBPeripheral, data: Data) {
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUuid }),
            let char = service.characteristics?.first(where: { $0.uuid == def.configCbuuid }) else {
            return
        }
        
        peripheral.writeValue(data, for: char, type: .withResponse)
    }
    
    internal func writeDefaultConfig(peripheral: CBPeripheral) {
        self.writeConfig(peripheral: peripheral, data: self.defaultConfig)
    }
    
    internal func writeLastConfig(peripheral: CBPeripheral) {
        Task {
            let latest = await self.lastConfig()
            self.writeConfig(peripheral: peripheral, data: latest)
        }
    }
}

extension FXBDataStreamConfig {
    func unpack(data: Data) -> AEDataValue {
        var _data = data
        
        if _data.count > self.size {
            _data = data[self.byteStart..<self.byteEnd]
        }
        
        switch self.dataType {
        case .float: return Float(0)
        case .unsignedInt:
            var val : UInt = 0
            for byte in _data {
                val = val << 8
                val = val | UInt(byte)
            }
            
            return Int(val)
        case .int:
            var val : Int = 0
            for byte in _data {
                val = val << 8
                val = val | Int(byte)
            }

            return val
        case .string:
            return String(data: _data, encoding: .ascii) ?? ""
        }
    }
    
    public func pack(value: String) -> Data {
        
        var data: Data = Data()
        
        switch self.dataType {
        case .float:
            switch self.size {
            case 2:
                var val = Float(value) ?? Float(defaultValue) ?? Float(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            case 4:
                var val = Float32(value) ?? Float32(defaultValue) ?? Float32(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            case 8:
                var val = Float64(value) ?? Float64(defaultValue) ?? Float64(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            default: break
            }
        case .int:
            switch self.size {
            case 1:
                var val = Int8(value) ?? Int8(defaultValue) ?? Int8(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            case 2:
                var val = Int16(value) ?? Int16(defaultValue) ?? Int16(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            case 4:
                var val = Int32(value) ?? Int32(defaultValue) ?? Int32(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            case 8:
                var val = Int64(value) ?? Int64(defaultValue) ?? Int64(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            default: break
            }
        case .unsignedInt:
            switch self.size {
            case 1:
                var val = UInt8(value) ?? UInt8(defaultValue) ?? UInt8(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            case 2:
                var val = UInt16(value) ?? UInt16(defaultValue) ?? UInt16(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            case 4:
                var val = UInt32(value) ?? UInt32(defaultValue) ?? UInt32(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            case 8:
                var val = UInt64(value) ?? UInt64(defaultValue) ?? UInt64(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
            default: break
            }
        case .string:
            data.append(value.data(using: .ascii) ?? defaultValue.data(using: .ascii) ?? Data(repeating: 0, count: self.size))
        }
        
        data = Data(data.reversed()) // little endian
        
        return data
    }
}

extension FXBDataValueDefinition {
    func unpack(data: Data) -> AEDataValue {
        var _data = data
        
        if _data.count > self.size {
            _data = data[self.byteStart..<self.byteEnd]
        }

        switch self.type {
        case .float: return Int(0)
        case .int:
            var val: Int = 0
            
            _data = Data(_data.reversed())
            switch self.size {
            case 1:
                val = Int(_data.withUnsafeBytes({ $0.load(as: Int8.self) }))
            case 2:
                val = Int(_data.withUnsafeBytes({ $0.load(as: Int16.self) }))
            case 4:
                val = Int(_data.withUnsafeBytes({ $0.load(as: Int32.self) }))
            case 8:
                val = Int(_data.withUnsafeBytes({ $0.load(as: Int64.self) }))
            default: return Int(0)
            }
            
            if let m = self.multiplier {
                return round((Double(val) * m) * 1000000) / 1000000.0
            }
            return val
        case .unsignedInt:
            var val: Int = 0
            
            var uval: UInt = 0
            for byte in data {
                uval = uval << 8
                uval = uval | UInt(byte)
            }
            val = Int(uval)
            
            if let m = self.multiplier {
                return round((Double(val) * m) * 1000000) / 1000000.0
            }
            return val
        case .string:
            return String(data: _data, encoding: .ascii) ?? ""
        }
    }
    
    func offset(from data: Data) -> Int {
        var _data = data
        
        if _data.count > self.size {
            _data = data[self.byteStart..<self.byteEnd]
        }
         
        var val : UInt = 0
        for byte in _data {
            val = val << 8
            val = val | UInt(byte)
        }
        
        return Int(val)
    }
}
