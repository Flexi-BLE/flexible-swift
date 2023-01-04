//
//  File.swift
//  
//
//  Created by blaine on 9/2/22.
//

import Foundation
import GRDB

enum FXBTimeSeriesTable {
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
        case .dynamicConfig(let name): return name
        }
    }
}

extension FXBTimeSeriesTable {
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
    
    private func getSpecs(for specIds: [Int64]) async throws -> [Int64: FXBSpec] {
        return try await FXBDBManager.shared.dbQueue.read { db -> [Int64:FXBSpec] in
            var dict: [Int64:FXBSpec] = [:]
            
            let specTbls = try FXBSpecTable
                .filter(specIds.contains(Column("id")))
                .fetchAll(db)
            
            for specTbl in specTbls {
                let spec = try Data
                    .sharedJSONDecoder
                    .decode(FXBSpec.self, from: specTbl.data)
                    
                dict[specTbl.id!] = spec
            }
            
            return dict
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
        
        let tableInfo = try await FXBDBManager
            .shared.dbQueue.read({ db -> [FXBTableInfo] in
            let result = try Row.fetchAll(db, sql: "PRAGMA table_info(\(name))")
            return result.map({ FXBTableInfo.make(from: $0) })
        })
        
        let records = try await FXBDBManager.shared
            .dbQueue.read({ db -> [GenericRow] in
            var q = "SELECT * FROM \(name)"
            if uploaded != nil || start != nil || end != nil {
                q += " WHERE"
            }
            if let uploaded = uploaded {
                q += " uploaded = \(uploaded)"
                if start != nil || end != nil {
                    q += " AND"
                }
            }
            if let start = start {
                q += " ts >= '\(start.SQLiteFormat())'"
                if end != nil {
                    q += " AND"
                }
            }
            if let end = end {
                q += " ts < '\(end.SQLiteFormat())'"
            }
            
            q += " LIMIT \(limit)"
            
            return try Row
                .fetchAll(db, sql: q)
                .map({ GenericRow(metadata: tableInfo, row: $0) })
        })
        
        
        
        let specIds = Array(Set(records.compactMap({ r -> Int64? in
            return r.getValue(for: "spec_id")
        })))
        
        let specs = try await getSpecs(for: specIds)
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let specId: Int64 = rec.getValue(for: "spec_id"),
                  let id: Int64 = rec.getValue(for: "id"),
                  let tsStr: String = rec.getValue(for: "ts"),
                  let ts = Date.fromSQLString(tsStr),
                  let deviceName: String = rec.getValue(for: "device"),
                  let spec = specs[specId],
                  let device = spec.devices.first(where: { deviceName.starts(with: $0.name) }),
                  let measurement = device.dataStreams.first(where: { $0.name == name.replacingOccurrences(of: "_data", with: "") }) else {
                continue
            }
            
            let ilp = ILPRecord(
                staticTable: .dynamicData(name: name),
                id: id,
                measurement: name,
                timestamp: ts
            )
            
            ilp.tag("device_id", deviceId)
            
            for dv in measurement.dataValues {
//                print(device)
//                print(dv.name)
//                print(dv.type)
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
//                switch dv.type {
//                case .float:
//                    if let v: Float = rec.getValue(for: dv.name) {
//                        ilp.field(dv.name, float: v)
//                    }
//                case .int:
//                    if let v: Int = rec.getValue(for: dv.name) {
//                        ilp.field(dv.name, int: v)
//                    }
//                case .string:
//                    if let v: String = rec.getValue(for: dv.name) {
//                        ilp.field(dv.name, str: v)
//                    }
//                case .unsignedInt:
//                    if let v: UInt = rec.getValue(for: dv.name) {
//                        ilp.field(dv.name, uint: v)
//                    }
//                }
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
        
        let tableInfo = try await FXBDBManager
            .shared.dbQueue.read({ db -> [FXBTableInfo] in
            let result = try Row.fetchAll(db, sql: "PRAGMA table_info(\(name))")
            return result.map({ FXBTableInfo.make(from: $0) })
        })
        
        let records = try await FXBDBManager.shared
            .dbQueue.read({ db -> [GenericRow] in
            var q = "SELECT * FROM \(name)"
            if uploaded != nil || start != nil || end != nil {
                q += " WHERE"
            }
            if let uploaded = uploaded {
                q += " uploaded = \(uploaded)"
                if start != nil || end != nil {
                    q += " AND"
                }
            }
            if let start = start {
                q += " ts >= '\(start.SQLiteFormat())'"
                if end != nil {
                    q += " AND"
                }
            }
            if let end = end {
                q += " ts < '\(end.SQLiteFormat())'"
            }
            
            q += " LIMIT \(limit)"
            
            let recs = try Row
                .fetchAll(db, sql: q)
                
                
            return recs.map({ GenericRow(metadata: tableInfo, row: $0) })
        })
        
        
        
        let specIds = Array(Set(records.compactMap({ r -> Int64? in
            return r.getValue(for: "spec_id")
        })))
        
        let specs = try await getSpecs(for: specIds)
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let specId: Int64 = rec.getValue(for: "spec_id"),
                  let id: Int64 = rec.getValue(for: "id"),
                  let tsStr: String = rec.getValue(for: "ts"),
                  let ts = Date.fromSQLString(tsStr),
                  let deviceName: String = rec.getValue(for: "device"),
                  let spec = specs[specId],
                  let device = spec.devices.first(where: { deviceName.starts(with: $0.name) }),
                  let measurement = device.dataStreams.first(where: { $0.name == name.replacingOccurrences(of: "_config", with: "") }) else {
                continue
            }
            
            let ilp = ILPRecord(
                staticTable: .dynamicConfig(name: name),
                id: id,
                measurement: name,
                timestamp: ts
            )
            
            ilp.tag("device_id", deviceId)
            
            for cv in measurement.configValues {
                if let v: String = rec.getValue(for: cv.name) {
                    if let options = cv.options {
                        guard let idx = Int(v) else { continue }
                        ilp.field(cv.name, str: options[idx].name)
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
        let records = try await FXBDBManager.shared.dbQueue.read { db -> [FXBHeartRate] in
            let tsCol = Column("ts")
            let uploadedCol = Column("uploaded")
            
            var q = FXBHeartRate.all()
            if let start = start { q = q.filter(tsCol >= start) }
            if let end = end { q = q.filter(tsCol < end) }
            if let uploaded = uploaded { q = q.filter(uploadedCol == uploaded) }
            q = q.limit(limit, offset: 0)
            
            return try q.fetchAll(db)
        }
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let id = rec.id else { continue }
            
            let ilp = ILPRecord(
                staticTable: self,
                id: id,
                measurement: FXBHeartRate.databaseTableName,
                timestamp: rec.ts
            )
            
            ilp.tag("deviceId", deviceId)
            ilp.field("bpm", int: rec.bpm)
            
            ilps.append(ilp)
        }
        
        return ilps
    }
    
    private func IRPQueryLocation(from start: Date?=nil, to end: Date?=nil, uploaded: Bool?=false, limit: Int=1000, deviceId: String) async throws -> [ILPRecord] {
        let records = try await FXBDBManager.shared.dbQueue.read { db -> [FXBLocation] in
            let tsCol = Column("ts")
            let uploadedCol = Column("uploaded")
            
            var q = FXBLocation.all()
            if let start = start { q = q.filter(tsCol >= start) }
            if let end = end { q = q.filter(tsCol < end) }
            if let uploaded = uploaded { q = q.filter(uploadedCol == uploaded) }
            q = q.limit(limit, offset: 0)
            
            return try q.fetchAll(db)
        }
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let id = rec.id else { continue }
            
            let ilp = ILPRecord(
                staticTable: self,
                id: id,
                measurement: FXBLocation.databaseTableName,
                timestamp: rec.ts
            )
            
            ilp.tag("deviceId", deviceId)
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
        let records = try await FXBDBManager.shared.dbQueue.read { db -> [FXBExperiment] in
            let tsCol = Column("ts")
            let endCol = Column("end")
            let uploadedCol = Column("uploaded")
            
            var q = FXBExperiment.filter(endCol != nil)
            if let start = start { q = q.filter(tsCol >= start) }
            if let end = end { q = q.filter(tsCol < end) }
            if let uploaded = uploaded { q = q.filter(uploadedCol == uploaded) }
            q = q.limit(limit, offset: 0)
            
            return try q.fetchAll(db)
        }
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let id = rec.id else { continue }
            
            let ilp_st = ILPRecord(
                staticTable: self,
                id: id,
                measurement: FXBExperiment.databaseTableName,
                timestamp: rec.start
            )
            
            ilp_st.tag("deviceId", deviceId)
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
            
            ilp_end.tag("deviceId", deviceId)
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
        let records = try await FXBDBManager.shared.dbQueue.read { db -> [FXBTimestamp] in
            let tsCol = Column("ts")
            let uploadedCol = Column("uploaded")
            
            var q = FXBTimestamp.all()
            if let start = start { q = q.filter(tsCol >= start) }
            if let end = end { q = q.filter(tsCol < end) }
            if let uploaded = uploaded { q = q.filter(uploadedCol == uploaded) }
            q = q.limit(limit, offset: 0)
            
            
            return try q.fetchAll(db)
        }
        
        var ilps: [ILPRecord] = []
        
        for rec in records {
            guard let id = rec.id else { continue }
            
            let ilp = ILPRecord(
                staticTable: self,
                id: id,
                measurement: FXBTimestamp.databaseTableName,
                timestamp: rec.ts
            )
            
            ilp.tag("deviceId", deviceId)
            ilp.field("existanceValue", int: 1)
            if let des = rec.description {
                ilp.field("description", str: des)
            }
            
            ilps.append(ilp)
        }
        
        return ilps
    }
    
    func updateUpload(lines: [ILPRecord]) async throws {
        try await FXBDBManager.shared.dbQueue.write { db in
            let idMax = lines.map({ $0.recordId }).max() ?? 0
            let idMin = lines.map({ $0.recordId }).min() ?? 0
            
            let q = """
                UPDATE \(tableName)
                SET uploaded = true
                WHERE id >= \(idMin) AND id <= \(idMax)
            """
            
            
            try db.execute(sql: q)
        }
    }
}
