//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: - Public
public extension FXBLocalDataAccessor {
    
    class DataStreamConfigAccess {
        
        private var connection: DatabaseWriter
        private var spec: FXBSpec
        
        internal init(conn: DatabaseWriter, spec: FXBSpec) {
            self.connection = conn
            self.spec = spec
        }
        
        public func config(for ds: FXBDataStream, deviceName: String) async -> GenericRow? {
            let tableName = "\(DBUtility.tableName(from: ds.name))_config"
            
            let sql = """
                SELECT \(ds.configValues.map({ $0.name }).joined(separator: ", "))
                FROM \(tableName)
                WHERE device = :deviceName
                ORDER BY ts DESC
                LIMIT 1;
            """
            
            do {
                return try await connection.read { db in
                    let pragma = try Row.fetchAll(db, sql: "PRAGMA table_info(\(tableName));")
                    let info = pragma.map({ FXBTableInfo.make(from: $0) })
                        
                    let result = try Row.fetchOne(db, sql: sql, arguments: ["deviceName": deviceName])
                    return result.map({ GenericRow(metadata: info, row: $0) })
                }
            } catch {
                pLog.error("Error fetching latest config for \(ds.name): \(error.localizedDescription)")
            }
            
            return nil
        }
        
        public func getLatest(
            forDataStream dataStreamName: String,
            inDevice deviceName: String
        ) async throws -> Data? {
                
            return try await connection.read { db -> Data? in
                    
                // query for table pargma (dynamic table creation)
                let tableRecRows = try Row.fetchAll(db, sql: "PRAGMA table_info(\(dataStreamName)_config)")
                let tableInfo = tableRecRows.map({FXBTableInfo.make(from: $0)})
                        
                guard tableInfo.count > 0 else {
                    pLog.error("unable to find table pragma in fetching latest config for \(dataStreamName)")
                    return nil
                }
                
                // query for latest record
                let q = """
                    SELECT * FROM \(dataStreamName)_config
                    ORDER BY ts DESC
                    LIMIT 1
                """
                
                guard let configRow = try Row.fetchOne(db, sql: q) else {
                    pLog.info("no latest config record found for \(dataStreamName)")
                    return nil
                }
                // convert to generic row (dynamic record)
                let lastConfig = GenericRow(metadata: tableInfo, row: configRow)
                
                guard let dataStream = self.spec
                    .devices.first(where: { deviceName.starts(with: $0.name) })?
                    .dataStreams.first(where: { $0.name == dataStreamName }) else {

                    pLog.error("unable to find data stream specification cooresponding to \(dataStreamName)")
                    return nil
                }
                
                // build config byte array
                var lastConfigData = Data()
                for configValue in dataStream.configValues {
                    guard let val: String = lastConfig.getValue(for: configValue.name) else {
                        pLog.error("unable to extract value for value \(configValue.name) in lastest \(dataStreamName) config")
                        return nil
                    }
                    lastConfigData += configValue.pack(value: val)
                }
                
                return lastConfigData
            }
        }
    }
}


// MARK: - Internal
internal extension  FXBLocalDataAccessor.DataStreamConfigAccess {
    func get(
        for name: String,
        from start: Date?=nil,
        to end: Date?=nil,
        uploaded: Bool?=nil,
        limit: Int=1000
    ) async throws -> [GenericRow] {
        
        
        let tableInfo = try DBUtility.tableInfo(with: connection, for: name)
        
        let records = try await connection.read({ db -> [GenericRow] in
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
        
        return records
    }
    
    func insert(
        for ds: FXBDataStream,
        values: [String],
        device: String
    ) async throws{
        
        let tableName = "\(DBUtility.tableName(from: ds.name))_config"
        
        let cols = "\(ds.configValues.map({ $0.name }).joined(separator: ", "))"
        let placeholders = "\(ds.configValues.map({ _ in "?" }).joined(separator: ", "))"
        
        let sql = """
            INSERT INTO \(tableName)
            (\(cols), ts, device)
            VALUES (\(placeholders), ?, ?);
        """
        
        let args = StatementArguments(values + [Date(), device])
        
        try await connection.write { [sql, args] db in
            try db.execute(
                sql: sql,
                arguments: args ?? StatementArguments()
            )
        }
    }
}
