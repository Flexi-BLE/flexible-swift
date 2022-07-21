//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 7/16/22.
//

import Foundation
import CoreBluetooth
import SwiftUI


class AEBLEDataStreamHandler {
    
    let serviceUuid: CBUUID
    let def: AEDataStream
    
    private var lastestConfig: Data?
    
    init(uuid: CBUUID, def: AEDataStream) {
        self.serviceUuid = uuid
        self.def = def
    }
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        AEBLEDBManager.shared.createTable(from: def)
        
        if let c = service.characteristics?.first(where: { $0.uuid == def.dataCbuuid }) {
            peripheral.setNotifyValue(true, for: c)
        }
        
        if let c = service.characteristics?.first(where: { $0.uuid == def.configCbuuid }) {
            peripheral.readValue(for: c)
        }
    }
    
    func didUpdate(uuid: CBUUID, data: Data?) {
        guard let data = data else { return }
        
        switch uuid {
        case def.dataCbuuid: Task { await didUpdateData(data: data) }
        case def.configCbuuid: Task { await didUpdateConfig(data: data) }
        default: bleLog.error("did update unknown characteristic: \(uuid)")
        }
    }
    
    func didWrite(uuid: CBUUID) {
        // TODO: implement
    }
    
    private func didUpdateData(data: Data) async {
        var packetSize = def.dataValues.reduce(0) { $0 + $1.size }
        if let offsetDef = def.offsetDataValue {
            packetSize += offsetDef.size
        }
        
        
        let anchorDate = Date()
        if def.includeAnchorTimestamp {
            // TODO: handle anchor timestamp
            bleLog.debug("TODO: handle anchor timestamp")
        }
        
        var allValues: [[AEDataValue]] = []
        var offsets: [AEDataValue] = []
        
        var lastOffset: Int = 0
        
        for step in 0..<Int(data.count / packetSize) {
            let i = step * packetSize
            let packet = data[i..<i+packetSize]
            var values: [AEDataValue] = []
            
            for dv in def.dataValues {
                let v = packet[i+dv.byteStart..<i+dv.byteEnd]
                values.append(dv.unpack(data: v))
            }
            allValues.append(values)
            
            if let offsetDef = def.offsetDataValue {
                let v = packet[i+offsetDef.byteStart..<i+offsetDef.byteEnd]

                let offset = offsetDef.offset(from: v) + lastOffset
                lastOffset = offset
                offsets.append(offset)
            }
        }
        
        await AEBLEDBManager.shared
            .dynamicDataRecordInsert(
                for: def,
                anchorDate: anchorDate,
                allValues: allValues,
                offsets: offsets
            )
    }
    
    private func didUpdateConfig(data: Data) async {
        self.lastestConfig = data
        
        bleLog.debug("config read")
        
        var values: [String] = []
        
        for cv in def.configValues {
            let unpackedVal = cv.unpack(data: data)
            values.append(String(describing: unpackedVal))
            
            bleLog.debug("config value loaded: \(cv.name): \(String(describing: unpackedVal))")
        }
        
        await AEBLEDBManager.shared
            .dynamicConfigRecordInsert(
                for: def,
                values: values
            )
    }
    
    internal func writeConfig(peripheral: CBPeripheral, data: Data) {
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUuid }),
            let char = service.characteristics?.first(where: { $0.uuid == def.configCbuuid }) else {
            return
        }
        
        peripheral.writeValue(data, for: char, type: .withResponse)
    }
}

extension AEDataStreamConfig {
    func unpack(data: Data) -> AEDataValue {
        guard data.count >= self.byteEnd else { return 0 }
        
        var _data = data
        
        if _data.count > self.size {
            _data = data[self.byteStart..<self.byteEnd]
        }
        
        switch self.type {
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
        
        switch self.type {
        case .float:
            switch self.size {
            case 2:
                var val = Float16(value) ?? Float16(defaultValue) ?? Float16(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            case 4:
                var val = Float32(value) ?? Float32(defaultValue) ?? Float32(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            case 8:
                var val = Float64(value) ?? Float64(defaultValue) ?? Float64(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            default: break
            }
        case .int:
            switch self.size {
            case 1:
                var val = Int8(value) ?? Int8(defaultValue) ?? Int8(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            case 2:
                var val = Int16(value) ?? Int16(defaultValue) ?? Int16(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            case 4:
                var val = Int32(value) ?? Int32(defaultValue) ?? Int32(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            case 8:
                var val = Int64(value) ?? Int64(defaultValue) ?? Int64(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            default: break
            }
        case .unsignedInt:
            switch self.size {
            case 1:
                var val = UInt8(value) ?? UInt8(defaultValue) ?? UInt8(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            case 2:
                var val = UInt16(value) ?? UInt16(defaultValue) ?? UInt16(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            case 4:
                var val = UInt32(value) ?? UInt32(defaultValue) ?? UInt32(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            case 8:
                var val = UInt64(value) ?? UInt64(defaultValue) ?? UInt64(0)
                withUnsafePointer(to: &val) {
                    data.append(UnsafeBufferPointer(start: $0, count: self.size))
                }
            default: break
            }
        case .string:
            data.append(value.data(using: .ascii) ?? defaultValue.data(using: .ascii) ?? Data(repeating: 0, count: self.size))
        }
        
        return data
    }
}

extension AEDataValueDefinition {
    func unpack(data: Data) -> AEDataValue {
        guard data.count >= self.byteEnd else { return 0 }
        
        var _data = data
        
        if _data.count > self.size {
            _data = data[self.byteStart..<self.byteEnd]
        }

        switch self.type {
        case .float: return Int(0)
        case .int:
            var val : Int = 0
            for byte in _data {
                val = val << 8
                val = val | Int(byte)
            }

            return val
        case .unsignedInt:
            var val : UInt = 0
            for byte in _data {
                val = val << 8
                val = val | UInt(byte)
            }
            
            return Int(val)
        case .string:
            return String(data: _data, encoding: .ascii) ?? ""
        }
    }
    
    func offset(from data: Data) -> Int {
        guard data.count >= self.byteEnd else { return 0 }
        
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
