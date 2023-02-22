//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

final internal class TransactionalDBConnectionManager {
    
    private var mainConnection: DatabaseWriter
    private var spec: FXBSpec
    private var dbPath: URL
    
    private var connections: [String:DatabasePool] = [:]
    
    private var maxDBSize = 1024 * 1024 * 1024 * 1024 // TBb
    private var lastDBSizeCheck: Date = Date.now
    private var DBSizeCheckInterval: TimeInterval = 6_000 // 100 minutes
    
    internal init(withMainConnection conn: DatabaseWriter, spec: FXBSpec, dbPath: URL) {
        self.mainConnection = conn
        self.spec = spec
        self.dbPath = dbPath
    }
    
    internal func latestDB() throws -> TransactionalDatabase {
        if let transactionalDb = try mainConnection.read({ db in
            return try TransactionalDatabase
                .order(TransactionalDatabase.Columns.createdAt.desc)
                .fetchOne(db)
        }) {
            
            if Date.now > lastDBSizeCheck.addingTimeInterval(DBSizeCheckInterval) {
                let conn = try connection(for: transactionalDb)
                if let size = try DBUtility.dbSize(with: connection(for: transactionalDb)) {
                    lastDBSizeCheck = Date.now
                    dbLog.info("current transaction database size: \(size)")
                    if size > maxDBSize {
                        
                        conn.releaseMemoryEventually()
                        
                        try mainConnection.write { db in
                            transactionalDb.setEndDate(Date.now)
                            try transactionalDb.update(db)
                        }
                        
                        return try createTransactionalDB()
                    }
                }
            }
            
            return transactionalDb
        }
        
        return try createTransactionalDB()
    }
    
    internal func connection(for db: TransactionalDatabase) throws -> DatabasePool {
        if let connection = connections[db.fileName] {
            return connection
        }
        
        var configuration = Configuration()
        configuration.qos = DispatchQoS.userInitiated
        
        if db.isLocked {
            configuration.readonly = true
        }
        
        let connection = try DatabasePool(
            path: dbPath.appendingPathComponent(db.fileName).absoluteString,
            configuration: configuration
        )
        
        connections[db.fileName] = connection
        return connection
    }
    
    private func createTransactionalDB() throws -> TransactionalDatabase {
        var dbRec = TransactionalDatabase(startDate: Date.now)
        
        try mainConnection.write { db in
            try dbRec.insert(db)
        }
        
        try FXBTransactionalDBCreator.create(with: try connection(for: dbRec), spec: spec)
        
        return dbRec
    }
    
    private func getAllDBs() -> [TransactionalDatabase] {
        return try! mainConnection.read({ db in
            return try TransactionalDatabase.fetchAll(db)
        })
    }
    
    internal func getDbs(between start: Date?, and end: Date?) throws -> [TransactionalDatabase] {
        return try mainConnection.read({ db in
            var req = TransactionalDatabase.all()
            
            let startCol = TransactionalDatabase.Columns.startDate
            let endCol = TransactionalDatabase.Columns.endDate
            
            if let start = start, let end = end {
                req = req.filter(startCol <= end)
                req = req.filter(endCol >= start || endCol == nil)
            } else {
                if let start = start {
                    req = req.filter(endCol >= start || (start >= startCol && endCol == nil))
                }
                
                if let end = end {
                    req = req.filter(startCol <= end)
                }
            }
            
            return try req.fetchAll(db)
        })
    }
    
    internal func getTableRecords<T: FXBTimeSeriesRecord>(
        startDate: Date?=nil,
        endDate: Date?=nil,
        deviceName: String?=nil,
        uploaded: Bool?=nil,
        limit: Int=1000
    ) async throws -> [T] {
        
        let dbs = try getDbs(between: startDate, and: endDate)
        var records: [T] = []
        
        for db in dbs {
            let connection = try connection(for: db)
            records += try await connection.read({ db in
                var q: QueryInterfaceRequest<T> = T.all()
                
                if let startDate = startDate {
                    q = q.filter(Column("ts") >= startDate.dbPrimaryKey)
                }
                
                if let deviceName = deviceName {
                    q = q.filter(Column("deviceName") == deviceName)
                }
                
                if let uploaded = uploaded {
                    q = q.filter(Column("uploaded") == uploaded)
                }
                
                if let endDate = endDate {
                    q = q.filter(Column("ts") <= endDate.dbPrimaryKey)
                }
                q = q.order(Column("ts").desc)
                q = q.limit(limit)
                
                return try q.fetchAll(db)
            })
            
            if records.count > limit {
                break
            }
        }
        
        return records
    }
}
