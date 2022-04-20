//
//  DataBatch.swift
//  
//
//  Created by blaine on 3/3/22.
//

import Foundation
import GRDB

internal class DataBatch {
    private var limit = 2500
    private var counter: Int = 0
    private var cursor: Date = Date.now
    private var tables = [String]()
    
    private let db: AEBLEDBManager
    
    init(db: AEBLEDBManager) {
        self.db = db
    }
    
    
    internal func increment(for name: String, by inc: Int = 1, with date: Date = Date()) {
        self.counter += inc
        if !tables.contains(name) { tables.append(name) }
        if counter >= limit {
            let c = self.cursor
            let t = self.tables
            Task {
                await insert(cursor: c, tables: t)
            }
            self.counter = 0
            self.cursor = date
            self.tables = []
        }
    }
    
    private func insert(cursor: Date, tables: [String]) async {
        do {
        
            for table in tables {
                let tblInfo = db.tableInfo(for: table)
                let dtRes = await db.dynamicTable(for: table)
                
                guard case .success(let dt) = dtRes,
                    let dynamicTbl = dt,
                      let md = dynamicTbl.metadata else {
                    return
                }
                
                let metadata = try Data.sharedJSONDecoder.decode(
                    AEDataStream.self,
                    from: md
                )
            
                let sql = """
                SELECT \(tblInfo.map({$0.name}).joined(separator: ", "))
                FROM \(table)
                WHERE uploaded = 0
                ORDER BY created_at DESC
                """
                    
                let data: [GenericRow]? = try await db.dbQueue.read { db in
                    let result = try Row.fetchAll(db, sql: sql)
                    return result.map({ row in
                        GenericRow(metadata: tblInfo, row: row)
                    })
                }
                
                guard let data = data else { return }
                bleLog.info("[UPLOAD] \(data.count) records")
                
                let start = Date.now
                
                let settings = try await AEBLESettingsStore.activeSetting(dbQueue: db.dbQueue)
                
                let res = await AEBLEAPI.batchLoad(
                    metadata: metadata,
                    rows: data,
                    settings: settings
                )
                
                switch res {
                case .success(_):
                    try await db.dbQueue.write { db in
                        let sql = """
                            UPDATE \(table)
                            SET uploaded = 1
                        """
                        
                        try db.execute(
                            sql: sql
                        )
                        
                        
                        let du = DataUpload(
                            id: nil,
                            status: .success,
                            createdAt: Date.now,
                            duration: Date.now.timeIntervalSince(start),
                            numberOfRecords: data.count,
                            bucket: settings.sensorDataBucketName,
                            measurement: metadata.name,
                            errorMessage: nil
                        )
                        
                        try du.insert(db) }
                case .failure(let error):
                    try await db.dbQueue.write { db in
                        let du = DataUpload(
                            id: nil,
                            status: .fail,
                            createdAt: Date.now,
                            duration: 0,
                            numberOfRecords: 0,
                            bucket: nil,
                            measurement: metadata.name,
                            errorMessage: error.localizedDescription
                        )
                        
                        try du.insert(db)
                    }
                }
            }
        } catch {
            try? await db.dbQueue.write { db in
                let du = DataUpload(
                    id: nil,
                    status: .fail,
                    createdAt: Date.now,
                    duration: 0,
                    numberOfRecords: 0,
                    measurement: nil,
                    errorMessage: error.localizedDescription
                )
                
                try? du.insert(db)
            }
        }
    }
}
