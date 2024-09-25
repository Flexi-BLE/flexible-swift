//
//  File.swift
//  
//
//  Created by blaine on 9/2/22.
//

import Foundation
import GRDB

public enum FXBUploadableTable {
    case experiment
    case heartRate
    case location
    case timestamp
    case dynamicData(name: String)
    case dynamicConfig(name: String)
    
    var tableName: String {
        switch self {
        case .experiment: return FXBExperiment.databaseTableName
        case .timestamp: return FXBTimestamp.databaseTableName
        case .heartRate: return FXBHeartRate.databaseTableName
        case .location: return FXBLocation.databaseTableName
        case .dynamicData(let name): return name
        case .dynamicConfig(let name): return "\(name)_config"
        }
    }
}

internal extension FXBUploadableTable {
    func ILPQuery(from start: Date?=nil, to end: Date?=nil, uploaded: Bool=false, limit: Int, deviceId: String) async throws -> [ILPRecord] {
    
        switch self {
        case .heartRate: return try await IRPQueryHeartRate(from: start, to: end, uploaded: uploaded, limit: limit, deviceId: deviceId)
        case .location: return try await IRPQueryLocation(from: start, to: end, uploaded: uploaded, limit: limit, deviceId: deviceId)
        case .experiment: return try await IRPQueryExperiment(from: start, to: end, uploaded: uploaded, limit: limit, deviceId: deviceId)
        case .timestamp: return try await IRPQueryTimestamp(from: start, to: end, uploaded: uploaded, limit: limit, deviceId: deviceId)
        case .dynamicData(let name): return try await IRPQueryDynamicData(name: name, from: start, to: end, uploaded: uploaded, limit: limit, deviceId: deviceId)
        case .dynamicConfig(let name): return try await IRPQueryDynamicConfig(name: name, from: start, to: end, uploaded: uploaded, limit: limit, deviceId: deviceId)
        }
    }
    
    private func IRPQueryDynamicData(
        name: String,
        from start: Date?=nil,
        to end: Date?=nil,
        uploaded: Bool?=false,
        limit: Int=1000,
        deviceId: String
    ) async throws -> [ILPRecord] {
        
        dbLog.debug("data upload: querying records for \(tableName) from \(start?.timestamp() ?? "--none--") to \(end?.timestamp() ?? "--none--")")

        let records = try await FlexiBLE.shared.dbAccess?.dataStream.records(
            for: tableName,
            from: start,
            to: end,
            deviceName: nil,
            uploaded: uploaded
        ) ?? []
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let tsInt: Int64 = rec.getValue(for: "ts"),
                  let deviceName: String = rec.getValue(for: "device"),
                  let device = FlexiBLE.shared.profile?.specification.devices.first(where: { deviceName.starts(with: $0.name) }),
                  let measurement = device.dataStreams.first(where: { $0.name == name.replacingOccurrences(of: "_data", with: "") }) else {
                continue
            }
            
            let ts = Date(timeIntervalSince1970: Double(tsInt) / 1_000_000.0)
            
            let ilp = ILPRecord(
                staticTable: .dynamicData(name: name),
                id: tsInt,
                measurement: tableName,
                timestamp: ts
            )
            
            ilp.tag("app_id", deviceId.replacingOccurrences(of: " ", with: "_"))
            ilp.tag("device_name", deviceName.replacingOccurrences(of: " ", with: "_"))
            
            for dv in measurement.dataValues {
                if dv.variableType == .value {
                    if let v: Double = rec.getValue(for: dv.name) {
                        ilp.field(dv.name, float: Float(v))
                    }
                } else if dv.variableType == .tag {
                    if let v: Double = rec.getValue(for: dv.name) {
                        if let options = dv.valueOptions {
                            ilp.tag(dv.name, options[Int(v)])
                        } else {
                            ilp.tag(dv.name, String(v))
                        }
                    }
                }
            }
            
            ilps.append(ilp)
        }
        
        
        return ilps
    }
    
    private func IRPQueryDynamicConfig(
        name: String,
        from start: Date?=nil,
        to end: Date?=nil,
        uploaded: Bool?=false,
        limit: Int=1000,
        deviceId: String
    ) async throws -> [ILPRecord] {
        
        let records = try await FlexiBLE.shared.dbAccess?.dataStreamConfig.get(
            for: tableName,
            from: start,
            to: end,
            uploaded: uploaded,
            limit: limit
        ) ?? []
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let tsInt: Int64 = rec.getValue(for: "ts"),
                  let deviceName: String = rec.getValue(for: "device"),
                  let device = FlexiBLE.shared.profile?.specification.devices.first(where: { deviceName.starts(with: $0.name) }),
                  let measurement = device.dataStreams.first(where: { $0.name == name.replacingOccurrences(of: "_config", with: "") }) else {
                continue
            }
            
            let ts = Date(timeIntervalSince1970: Double(tsInt) / 1_000_000.0)
            
            let ilp = ILPRecord(
                staticTable: .dynamicConfig(name: name),
                id: tsInt,
                measurement: tableName,
                timestamp: ts
            )
            
            ilp.tag("app_id", deviceId.replacingOccurrences(of: " ", with: "_"))
            ilp.tag("device_name", deviceName.replacingOccurrences(of: " ", with: "_"))
            
            for cv in measurement.configValues {
                if let v: String = rec.getValue(for: cv.name) {
                    if let options = cv.options {
                        guard let idx = Int(v) else { continue }
                        ilp.field(
                            cv.name,
                            str: options[optional: idx]?.name ?? "--unknown--"
                        )
                    } else {
                        guard let vInt = Int(v) else { continue }
                        ilp.field(cv.name, int: vInt)
                    }
                }
            }
            
            ilps.append(ilp)
        }
        
        
        return ilps
    }
    
    private func IRPQueryHeartRate(from start: Date?=nil, to end: Date?=nil, uploaded: Bool?=false, limit: Int=1000, deviceId: String) async throws -> [ILPRecord] {
        
        let records = try await FlexiBLE.shared.dbAccess?.heartRate.get(
            from: start,
            to: end,
            uploaded: uploaded,
            limit: limit
        ) ?? []
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            let ilp = ILPRecord(
                staticTable: self,
                id: rec.ts,
                measurement: FXBHeartRate.databaseTableName,
                timestamp: rec.tsDate
            )
            
            ilp.tag("app_id", deviceId.replacingOccurrences(of: " ", with: "_"))
            ilp.field("bpm", int: rec.bpm)
            
            ilps.append(ilp)
        }
        
        return ilps
    }
    
    private func IRPQueryLocation(from start: Date?=nil, to end: Date?=nil, uploaded: Bool?=false, limit: Int=1000, deviceId: String) async throws -> [ILPRecord] {
        
        let records = try await FlexiBLE.shared.dbAccess?.location.get(
            from: start,
            to: end,
            uploaded: uploaded,
            limit: limit
        ) ?? []
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            let ilp = ILPRecord(
                staticTable: self,
                id: rec.ts,
                measurement: FXBLocation.databaseTableName,
                timestamp: rec.tsDate
            )
            
            ilp.tag("app_id", deviceId.replacingOccurrences(of: " ", with: "_"))
            ilp.field("lat", float: Float(rec.latitude))
            ilp.field("long", float: Float(rec.longitude))
            ilp.field("alt", float: Float(rec.altitude))
            ilp.field("hor_acc", float: Float(rec.horizontalAccuracy))
            ilp.field("vert_acc", float: Float(rec.verticalAccuracy))
            
            ilps.append(ilp)
        }
        
        return ilps
    }
    
    private func IRPQueryExperiment(from start: Date?=nil, to end: Date?=nil, uploaded: Bool?=false, limit: Int=1000, deviceId: String) async throws -> [ILPRecord] {
        
        let records: [FXBExperiment] = []
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let id = rec.id else { continue }
            
            let ilp_st = ILPRecord(
                staticTable: self,
                id: id,
                measurement: FXBExperiment.databaseTableName,
                timestamp: rec.start
            )
            
            ilp_st.tag("app_id", deviceId.replacingOccurrences(of: " ", with: "_"))
            ilp_st.tag("name", rec.name)
            ilp_st.tag("uuid", rec.uuid)
            ilp_st.tag("type", "start")
            ilp_st.tag("gps", "\(rec.trackGPS)")
            ilp_st.field("existanceValue", int: 1)
            if let des = rec.description {
                ilp_st.field("description", str: des)
            }
            
            ilps.append(ilp_st)
            
            let ilp_end = ILPRecord(
                staticTable: self,
                id: id,
                measurement: FXBExperiment.databaseTableName,
                timestamp: rec.end!
            )
            
            ilp_end.tag("app_id", deviceId.replacingOccurrences(of: " ", with: "_"))
            ilp_end.tag("name", rec.name)
            ilp_end.tag("uuid", rec.uuid)
            ilp_end.tag("type", "stop")
            ilp_end.tag("gps", "\(rec.trackGPS)")
            ilp_end.field("existanceValue", int: 1)
            if let des = rec.description {
                ilp_end.field("description", str: des)
            }
            
            ilps.append(ilp_end)
        }
        
        return ilps
    }
    
    private func IRPQueryTimestamp(from start: Date?=nil, to end: Date?=nil, uploaded: Bool?=false, limit: Int=1000, deviceId: String) async throws -> [ILPRecord] {
        
        let records: [FXBTimestamp] = []
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let id = rec.id else { continue }
            
            let ilp = ILPRecord(
                staticTable: self,
                id: id,
                measurement: FXBTimestamp.databaseTableName,
                timestamp: rec.ts
            )
            
            ilp.tag("app_id", deviceId.replacingOccurrences(of: " ", with: "_"))
            ilp.field("existanceValue", int: 1)
            if let des = rec.description {
                ilp.field("description", str: des)
            }
            
            ilps.append(ilp)
        }
        
        return ilps
    }
    
    func updateUpload(lines: [ILPRecord]) async throws {
        let end = lines.map({ $0.timestamp }).max() ?? Date.now
        let start = lines.map({ $0.timestamp }).min() ?? Date.now
        
        dbLog.debug("data upload: updating upload flag for \(tableName) between \(start.timestamp()) and \(end.timestamp())")
        
        try await FlexiBLE
            .shared
            .dbAccess?
            .dataStream
            .updateUploaded(
                tableName: tableName,
                start: start,
                end: end
            )
    }

    func purgeUploadedRecords() async throws {
        try await FlexiBLE.shared.dbAccess?.dataStream.purgeUploaded(for: tableName)
    }
}
