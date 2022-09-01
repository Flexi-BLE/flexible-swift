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
    
    // MARK: - Connection
    public func recordConnection(deviceName: String, status: FXBConnection.Status) async throws {
        try await dbMgr.dbQueue.write({ db in
            var connection = FXBConnection(device: deviceName, status: status)
            try connection.insert(db)
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
                    updatedAt: nil
                )
                try rec.insert(db)
                return rec.id!
            }
        }
    }
}
