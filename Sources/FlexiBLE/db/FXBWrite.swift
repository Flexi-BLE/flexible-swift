//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 8/6/22.
//

import Foundation
import GRDB

public struct FXBWrite {
    
    let dbMgr = FXBDBManager.shared
    
    public func purgeAllUploadedRecords() async throws {
        let dynamicTables = await FlexiBLE.shared.read.dynamicTableNames()
        
        try await dbMgr.dbQueue.write({ db in
            let uc = Column("uploaded")
            
            try FXBExperiment.filter(uc == true).deleteAll(db)
            try FXBTimestamp.filter(uc == true).deleteAll(db)
            try FXBHeartRate.filter(uc == true).deleteAll(db)
            try FXBLocation.filter(uc == true).deleteAll(db)
            
            for tbl in dynamicTables {
                let q_data = """
                    DELETE FROM \(tbl)_data
                    WHERE uploaded = true
                """
                try db.execute(sql: q_data)
                
                let q_config = """
                    DELETE FROM \(tbl)_config
                    WHERE uploaded = true
                """
                try db.execute(sql: q_config)
            }
        })
    }
    
    public func purgeAllRecords() {

        FXBDBManager.shared.erase()
//        let dynamicTables = await FlexiBLE.shared.read.dynamicTableNames()
//
//        try await dbMgr.dbQueue.write({ db in
//
//            try FXBConnection.deleteAll(db)
//            try FXBDataUpload.deleteAll(db)
//            try FXBThroughput.deleteAll(db)
//            try FXBExperiment.deleteAll(db)
//            try FXBTimestamp.deleteAll(db)
//            try FXBHeartRate.deleteAll(db)
//            try FXBLocation.deleteAll(db)
//
//            for tbl in dynamicTables {
//                let q_data = """
//                    DELETE FROM \(tbl)_data
//                """
//                try db.execute(sql: q_data)
//
//                let q_config = """
//                    DELETE FROM \(tbl)_config
//                """
//                try db.execute(sql: q_config)
//            }
//
//            try db.execute(literal: "VACUUM")
//        })
    }
    

    
    // MARK: - Connection
    public func recordConnection(deviceType: String, deviceName: String, connectedAt: Date) async throws -> FXBConnection? {
        guard FlexiBLE.shared.specId > 0 else { return nil }
        
        return try await dbMgr.dbQueue.write({ db in
            var connection = FXBConnection(deviceType: deviceType, deviceName: deviceName, specId: FlexiBLE.shared.specId)
            connection.connectedAt = connectedAt
            try connection.insert(db)
            return connection
        })
    }
    
    // MARK: - Throughput
    public func recordThroughput(deviceName: String, dataStreamName: String, byteCount: Int, specId: Int64) async throws {

        try await dbMgr.dbQueue.write { db in
            var throughput = FXBThroughput(
                device: deviceName,
                dataStream: dataStreamName,
                bytes: byteCount,
                specId: specId
            )
            try throughput.insert(db)
        }
    }
    
    //MARK: - Device Spec
    public func recordSpec(_ spec: FXBSpec) async throws -> Int64 {
        let externalId = spec.id
        let version = spec.schemaVersion
        let data = try Data.sharedJSONEncoder.encode(spec)
        
        return try await dbMgr.dbQueue.write { (db) -> Int64 in
            
            let externalIdCol = Column(FXBSpecTable.CodingKeys.externalId.stringValue)
            let versionCol = Column(FXBSpecTable.CodingKeys.version.stringValue)
            
            var extSpecRecord = try FXBSpecTable
                .filter(externalIdCol == externalId && versionCol == version)
                .fetchOne(db)
            
            if let rec = extSpecRecord {
                if rec.data != data {
                    extSpecRecord!.updatedAt = Date()
                    extSpecRecord!.data = data
                    try extSpecRecord!.update(db)
                }
                return rec.id!
            } else {
                var rec = FXBSpecTable(
                    externalId: externalId,
                    version: version,
                    data: data,
                    createdAt: Date(),
                    ts: Date(), updatedAt: nil
                )
                try rec.insert(db)
                return rec.id!
            }
        }
    }
}
