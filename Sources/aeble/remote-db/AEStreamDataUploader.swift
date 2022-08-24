//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 4/26/22.
//

import Foundation
import GRDB

internal class AEStreamDataUploader {
    internal var dbMgr: AEBLEDBManager
    internal var dataStream: AEDataStream
    internal var recordLimit: Int? = nil
    internal var timeLimit: TimeInterval? = nil
    internal var purgeAfter: TimeInterval = 0
    
    private var lastUpload: Date = Date.now.addingTimeInterval(-1 * 60 * 60 * 24)
    private var counter: Int = 0
    
    private var tableMetadata: [TableInfo]?
    
    init(
        db: AEBLEDBManager,
        dataStream: AEDataStream,
        recordLimit: Int,
        purgeAfter: TimeInterval = 0
    ) {
        self.dbMgr = db
        self.dataStream = dataStream
        self.recordLimit = recordLimit
        self.purgeAfter = purgeAfter
    }
    
    init(
        db: AEBLEDBManager,
        dataStream: AEDataStream,
        timeLimit: TimeInterval,
        purgeAfter: TimeInterval = 0
    ) {
        self.dbMgr = db
        self.dataStream = dataStream
        self.timeLimit = timeLimit
        self.purgeAfter = purgeAfter
    }
    
    init(
        db: AEBLEDBManager,
        dataStream: AEDataStream,
        timeLimit: TimeInterval,
        recordLimit: Int,
        purgeAfter: TimeInterval = 0
    ) {
        self.dbMgr = db
        self.dataStream = dataStream
        self.recordLimit = recordLimit
        self.timeLimit = timeLimit
        self.purgeAfter = purgeAfter
    }
    
    internal func increment(by num: Int = 1) {
        guard let limit = recordLimit else { return }
        counter += num
        if counter >= limit {
//            Task { await upload() }
        }
    }
    
    internal func check() async {
        guard let limit = recordLimit else { return }
        let cnt = try? await dbMgr.dbQueue.read { db in
            return try? Int.fetchOne(
                db,
                sql: "SELECT COUNT(id) FROM \(self.dataStream.name) WHERE uploaded = 0"
            ) ?? 0
        }
        
        if cnt ?? 0 >= limit {
//            await upload()
        }
    }
    
    internal func check(with date: Date = Date.now) {
        guard let limit = timeLimit else { return }
        if lastUpload.distance(to: date) > limit {
//            Task { await upload() }
        }
    }
    
//    private func upload() async {
//        if tableMetadata == nil {
//            tableMetadata = dbMgr.tableInfo(for: self.dataStream.name)
//        }
//        
//        guard let tableMetadata = self.tableMetadata else { return }
//
//        let start = Date.now
//        let dataValueFields: [String] = dataStream.dataValues.map({ $0.name })
//        let fields = ["created_at", "uploaded", "user_id"] + dataValueFields
//        
//        let query = """
//            SELECT \(fields.joined(separator: ", "))
//            FROM \(self.dataStream.name)
//            WHERE uploaded = 0
//            ORDER BY created_at DESC
//        """
//        
//        do {
//            let data: [GenericRow]? = try await dbMgr.dbQueue.read { db in
//                let res = try Row.fetchAll(db, sql: query)
//                return res.map({ GenericRow(metadata: tableMetadata, row: $0) })
//            }
//            
//            guard let data = data else { return }
//            bleLog.info("[UPLOAD] \(data.count) records")
//            
//            let settings = try await AEBLESettingsStore.activeSetting(dbQueue: dbMgr.dbQueue)
//            
//            let res = await AEBLEAPI.batchLoad(
//                metadata: dataStream,
//                rows: data,
//                settings: settings
//            )
//            
//            switch res {
//            case .success(_):
//                bleLog.info("[UPLOAD] success")
//                await purge()
//                await setUploaded(before: Date.now)
//                
//                let upload = DataUpload(
//                    id: nil,
//                    status: .success,
//                    createdAt: Date.now,
//                    duration: Date.now.timeIntervalSince(start),
//                    numberOfRecords: data.count,
//                    bucket: settings.sensorDataBucketName,
//                    measurement: dataStream.name,
//                    errorMessage: nil
//                )
//                await record(upload: upload)
//                
//            case .failure(let error):
//                bleLog.info("[UPLOAD] failure: \(error.localizedDescription)")
//                
//                let upload = DataUpload(
//                    id: nil,
//                    status: .fail,
//                    createdAt: Date.now,
//                    duration: 0,
//                    numberOfRecords: 0,
//                    bucket: nil,
//                    measurement: dataStream.name,
//                    errorMessage: error.localizedDescription
//                )
//                await record(upload: upload)
//            }
//            
//        } catch {
//            bleLog.info("[UPLOAD] unable to upload records: \(error.localizedDescription)")
//        }
//        
//    }
    
    private func purge() async {
        let query = """
            DELETE FROM \(dataStream.name)
            WHERE created_at < ?
                AND uploaded = 1
        """
        
        try? await dbMgr.dbQueue.write({ db in
            try? db.execute(
                sql: query,
                arguments: StatementArguments([Date.now.addingTimeInterval(-self.purgeAfter)])
            )
        })
    }
    
    private func setUploaded(before cursor: Date) async {
        let query = """
            UPDATE \(dataStream.name)
            SET uploaded = 1
            WHERE created_at < ?
        """
        
        try? await dbMgr.dbQueue.write({ db in
            try? db.execute(
                sql: query,
                arguments: StatementArguments([cursor])
            )
        })
    }
    
    private func record(upload: DataUpload) async {
        try? await dbMgr.dbQueue.write { db in
            try? upload.insert(db)
        }
    }
}
