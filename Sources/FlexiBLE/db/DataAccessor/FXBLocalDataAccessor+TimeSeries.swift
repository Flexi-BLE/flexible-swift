//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/2/23.
//

import Foundation
import GRDB

public extension FXBLocalDataAccessor {

    class TimeSeries{
        
        private var transactionalManager: TransactionalDBConnectionManager
        private var mainConnection: DatabaseWriter
        
        init(transactionManager: TransactionalDBConnectionManager, mainConnection: DatabaseWriter) {
            self.transactionalManager = transactionManager
            self.mainConnection = mainConnection
        }
        
        public func count(
            for table: FXBUploadableTable,
            start: Date?,
            end: Date?,
            deviceName: String?,
            uploaded: Bool?
        ) async throws -> Int {
            
            switch table {
            case .dynamicData(_), .heartRate, .location:
                return try await transactionalCount(
                    for: table,
                    start: start,
                    end: end,
                    deviceName: deviceName,
                    uploaded: uploaded
                )
            case .dynamicConfig(_), .experiment, .timestamp:
                return try await mainCount(
                    for: table,
                    start: start,
                    end: end,
                    deviceName: deviceName,
                    uploaded: uploaded
                )
            }
        }
        
        private func mainCount(
            for table: FXBUploadableTable,
            start: Date?,
            end: Date?,
            deviceName: String?,
            uploaded: Bool?
        ) async throws -> Int {
            let (sql, arguments) = dataCountQueryBuilder(
                tableName: table.tableName,
                start: start,
                end: end,
                deviceName: deviceName,
                uploaded: false
            )
            
            return try await mainConnection.read({ db in
                return try Int.fetchOne(db, sql: sql, arguments: arguments) ?? 0
            })
        }
        
        private func transactionalCount(
            for table: FXBUploadableTable,
            start: Date?,
            end: Date?,
            deviceName: String?,
            uploaded: Bool?
        ) async throws -> Int {
            let (sql, arguments) = dataCountQueryBuilder(
                tableName: table.tableName,
                start: start,
                end: end,
                deviceName: deviceName,
                uploaded: uploaded
            )
            
            // retrieve all database records from main
            let transactionalDBs = try transactionalManager.getDbs(between: start, and: end)
            
            var count = 0
            for transactionalDB in transactionalDBs {
                let conn = try transactionalManager.connection(for: transactionalDB)
                await count += try conn.read({ db in
                    return try Int.fetchOne(db, sql: sql, arguments: arguments) ?? 0
                })
            }
            
            return count
        }
        
        private func dataCountQueryBuilder(
            tableName: String,
            start: Date? = nil,
            end: Date? = nil,
            deviceName: String?=nil,
            uploaded: Bool? = false
        ) -> (String, StatementArguments) {
            var sql = """
                    SELECT COUNT(ts)
                    FROM \(tableName)
                """
            
            var arguments: [String: (any DatabaseValueConvertible)?] = [:]
            
            if !(start == nil && end == nil && deviceName == nil && uploaded == nil) {
                sql += "\nWHERE "
            }
            
            if let deviceName = deviceName {
                sql += "\ndevice = '\(deviceName)'"
                if (uploaded != nil || start != nil || end != nil) {
                    sql += " AND"
                }
            }
            
            if let start = start, let end = end {
                sql += "\nts BETWEEN :start_ts AND :end_ts"
                
                arguments["start_ts"] = start.dbPrimaryKey
                arguments["end_ts"] = end.dbPrimaryKey
                
                if (uploaded != nil) { sql += " AND" }
            } else if let start = start {
                sql += "\nts >= :start_ts"
                arguments["start_ts"] = start.dbPrimaryKey
                if (uploaded != nil) { sql += " AND" }
            } else if let end = end {
                sql += "\nts < :end_ts"
                arguments["end_ts"] = end.dbPrimaryKey
                if (uploaded != nil) { sql += " AND" }
            }
            
            if let uploaded = uploaded {
                sql += "\nuploaded == :uploaded"
                arguments["uploaded"] = uploaded
            }
            
            return (sql, StatementArguments(arguments))
        }
        
    }
    
}
