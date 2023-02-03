//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: - Public
extension FXBLocalDataAccessor {
    
    public class DataStreamAccess {
        private var transactionalManager: TransactionalDBConnectionManager
        
        internal init(transactionalManager: TransactionalDBConnectionManager) {
            self.transactionalManager = transactionalManager
        }
        
        public func records(
            for tableName: String,
            from start: Date?=nil,
            to end: Date?=nil,
            deviceName: String?=nil,
            uploaded: Bool?=nil,
            limit: Int=1000
        ) async throws -> [GenericRow] {
            
            // build sql
            let (sql, arguments) = dataFetchQueryBuilder(
                tableName: tableName,
                start: start,
                end: end,
                deviceName: deviceName,
                uploaded: uploaded,
                limit: limit
            )
            
            let dbs = try transactionalManager.getDbs(between: start, and: end)
            
            guard let dbEx = dbs.first else { return [] }
            
            let tableInfos = try DBUtility.tableInfo(
                with: try transactionalManager.connection(for: dbEx),
                for: tableName
            )
            
            var records: [GenericRow] = []
            for db in dbs {
                let conn = try transactionalManager.connection(for: db)
                let rows = try await conn.read({ db in
                    return try Row.fetchAll(db, sql: sql, arguments: arguments)
                })
                records += rows.map({ GenericRow(metadata: tableInfos, row: $0) })
            
                if records.count > limit {
                    break
                }
            }
            
            return records
        }
        
        public func updateUploaded(tableName: String, start: Date?=nil, end: Date?=nil) async throws {
            let dbs = try transactionalManager.getDbs(between: start, and: end)
            for db in dbs {
                let connection = try transactionalManager.connection(for: db)
                try await connection.write({ db in
                    
                    var dateClause = ""
                    if let _ = start, let _ = end {
                        dateClause = "ts BETWEEN :start AND :end"
                    } else if let _ = start {
                        dateClause = "ts >= :start"
                    } else if let _ = end {
                        dateClause = "ts =< :end"
                    }
                    
                    var sqlData = """
                        UPDATE \(tableName)
                        SET uploaded = true
                    """
                    
                    if !dateClause.isEmpty {
                        sqlData += "\nWHERE \(dateClause)"
                    }
                    
                    try db.execute(sql: sqlData, arguments: ["start": start?.dbPrimaryKey, "end": end?.dbPrimaryKey])
                    
                    
                    var sqlThroughput = """
                        UPDATE throughput
                        SET uploaded = true
                        WHERE data_stream = :dataStream
                    """
                    
                    if !dateClause.isEmpty {
                        sqlThroughput += "\nAND \(dateClause)"
                    }
                    
                    try db.execute(
                        sql: sqlThroughput,
                        arguments: [
                            "start": start,
                            "end": end,
                            "dataStream": tableName.replacingOccurrences(of: "_data", with: "").replacingOccurrences(of: "_config", with: "")
                        ]
                    )
                    
                    
                })
            }
        }
        
        public func purgeUploaded(for tableName: String) async throws {
            let dbs = try transactionalManager.getDbs(between: nil, and: nil)
            for db in dbs {
                let connection = try transactionalManager.connection(for: db)
                try await connection.write({ db in
                    let sql = """
                        DELETE FROM \(tableName)
                        WHERE uploaded = true
                    """
                    
                    try db.execute(sql: sql)
                    
                    try FXBThroughput
                        .filter(FXBThroughput.Columns.uploaded == true)
                        .filter(FXBThroughput.Columns.uploaded == tableName.replacingOccurrences(of: "_data", with: "").replacingOccurrences(of: "_config", with: ""))
                        .deleteAll(db)
                })
            }
        }
        
        public func tableInfo(for tableName: String) throws -> [FXBTableInfo] {
            let db = try transactionalManager.latestDB()
            let tableInfos = try DBUtility.tableInfo(
                with: try transactionalManager.connection(for: db),
                for: tableName
            )
            
            return tableInfos
        }
    }
}

// MARK: - Internal
internal extension FXBLocalDataAccessor.DataStreamAccess {
    
    func insert(
        for ds: FXBDataStream,
        anchorDate: Double,
        allValues: [[AEDataValue]],
        timestamps: [Double],
        device: String
    ) async throws {
        let tableName = "\(DBUtility.tableName(from: ds.name))"
        
        let varColsString = "\(ds.dataValues.map({ $0.name }).joined(separator: ", "))"
        let sysCols = ["created_at", "ts", "device"]
        let sysColsString = sysCols.joined(separator: ", ")
        let placeholders = "\(ds.dataValues.map({ _ in "?" }).joined(separator: ", "))"
        
        var sql = """
            INSERT INTO \(tableName)
        """
        let colsSql = "(\(varColsString), \(sysColsString)) VALUES"
        sql += colsSql
        
        var args: [Any] = []
        
        for (i, values) in allValues.enumerated() {
            args.append(contentsOf: values)
            args.append(Date())
            
            switch ds.precision {
            case .ms: sql += "(\(placeholders), ?, ?, ?), "
            case .us: sql += "(\(placeholders), ?, ?, ?, ?), "
            }
            
            if ds.offsetDataValue != nil {
                args.append(Int64(timestamps[i]*1_000_000.0))
            } else {
                args.append(Date())
            }
            
            args.append(device)
        }
        
        sql.removeLast(2)
        sql += ";"
        
        let db = try transactionalManager.latestDB()
        let connection = try transactionalManager.connection(for: db)
        
        try await connection.write { [sql, args] db in
            try db.execute(
                sql: sql,
                arguments: StatementArguments(args) ?? StatementArguments()
            )
        }
    }
    
    private func dataFetchQueryBuilder(
        tableName: String,
        start: Date?=nil,
        end: Date?=nil,
        deviceName: String?=nil,
        uploaded: Bool?=false,
        limit: Int?=nil
    ) -> (String, StatementArguments) {
        var sql = """
            SELECT *
            FROM \(tableName)
        """
        
        var arguments: [String: (any DatabaseValueConvertible)?] = [:]
        
        if !(start == nil && end == nil && deviceName == nil && uploaded == nil) {
            sql += "\nWHERE "
        }
        
        if let deviceName = deviceName {
            sql += "\ndevice = :deviceName"
            arguments["deviceName"] = deviceName
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
        
        if let limit = limit {
            sql += "\nlimit :limit"
            arguments["limit"] = limit
        }
        
        return (sql, StatementArguments(arguments))
    }
}
