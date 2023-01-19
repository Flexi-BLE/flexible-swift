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
        
        public func count(
            for tableName: String,
            from start: Date?=nil,
            to end: Date?=nil,
            deviceName: String?=nil,
            uploaded: Bool? = false
        ) async throws -> Int {
            
            // build the SQL query which will be used on all transactional databases
            let sql = dataCountQueryBuilder(
                tableName: tableName,
                start: start,
                end: end,
                deviceName: deviceName,
                uploaded: false
            )
            
            // retrieve all database records from main
            let dbs = try transactionalManager.getDbs(between: start, and: end)
            
            var count = 0
            for db in dbs {
                let conn = try transactionalManager.connection(for: db)
                await count += try conn.read({ db in
                    return try Int.fetchOne(db, sql: sql) ?? 0
                })
            }
            
            return count
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
            let sql = dataFetchQueryBuilder(
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
                    return try Row.fetchAll(db, sql: sql)
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
                        dateClause = "ts > :start"
                    } else if let _ = end {
                        dateClause = "ts < :end"
                    }
                    
                    var sqlData = """
                        UPDATE \(tableName)
                        SET uploaded = true
                    """
                    
                    if !dateClause.isEmpty {
                        sqlData += "\nWHERE \(dateClause)"
                    }
                    
                    try db.execute(sql: sqlData, arguments: ["start": start, "end": end])
                    
                    
                    var sqlThroughput = """
                        UPDATE throughput
                        SET uploaded = true
                        WHERE ts BETWEEN :start AND :end
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
        let tableName = "\(FXBDatabaseDirectory.tableName(from: ds.name))_data"
        
        let varColsString = "\(ds.dataValues.map({ $0.name }).joined(separator: ", "))"
        var sysCols = ["created_at", "ts", "device"]
        switch ds.precision {
        case .ms: break
        case .us: sysCols.insert("ts_precision", at: 2)
        }
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
                args.append(Date(timeIntervalSince1970: timestamps[i]))
                switch ds.precision {
                case .ms: break
                case .us: args.append(Int((timestamps[i] - Double(Int(timestamps[i]))) * 1_000_000))
                }

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
    
    private func dataCountQueryBuilder(
        tableName: String,
        start: Date? = nil,
        end: Date? = nil,
        deviceName: String?=nil,
        uploaded: Bool? = false
    ) -> String {
        var sql = """
                SELECT COUNT(id)
                FROM \(tableName)
            """
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
            sql += "\nts BETWEEN '\(start.SQLiteFormat())' AND '\(end.SQLiteFormat())'"
            if (uploaded != nil) { sql += " AND" }
        } else if let start = start {
            sql += "\nts >= '\(start.SQLiteFormat())'"
            if (uploaded != nil) { sql += " AND" }
        } else if let end = end {
            sql += "\nts < '\(end.SQLiteFormat())'"
            if (uploaded != nil) { sql += " AND" }
        }
        
        if let uploaded = uploaded {
            sql += "\nuploaded == \(uploaded);"
        }
        
        return sql
    }
    
    private func dataFetchQueryBuilder(
        tableName: String,
        start: Date?=nil,
        end: Date?=nil,
        deviceName: String?=nil,
        uploaded: Bool?=false,
        limit: Int?=nil
    ) -> String {
        var sql = """
            SELECT *
            FROM \(tableName)
        """
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
            sql += "\nts BETWEEN '\(start.SQLiteFormat())' AND '\(end.SQLiteFormat())'"
            if (uploaded != nil) { sql += " AND" }
        } else if let start = start {
            sql += "\nts >= '\(start.SQLiteFormat())'"
            if (uploaded != nil) { sql += " AND" }
        } else if let end = end {
            sql += "\nts < '\(end.SQLiteFormat())'"
            if (uploaded != nil) { sql += " AND" }
        }
        
        if let uploaded = uploaded {
            sql += "\nuploaded == \(uploaded)"
        }
        
        if let limit = limit {
            sql += "\nlimit \(limit)"
        }
        
        return sql
    }
}
