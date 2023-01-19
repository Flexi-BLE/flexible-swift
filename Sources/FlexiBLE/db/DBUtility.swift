//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

/// static database utility methods (universal)
internal enum DBUtility {
    internal static func getTableNames(with reader: DatabaseReader) throws -> [String] {
        let excludedTables = ["grdb_migrations"]

        var tableNames: [String] = []

        let sql = """
            SELECT name
            FROM sqlite_schema
            WHERE
                type = 'table' AND
                name not LIKE 'sqlite_%';
        """

        try reader.read { db in
            let result = try Row.fetchAll(db, sql: sql)
            tableNames = result.map({ $0["name"] })
        }

        return tableNames.filter({ !excludedTables.contains($0) })
    }
    
    internal static func tableInfo(with reader: DatabaseReader, for table: String) throws -> [FXBTableInfo] {
        var metadata: [FXBTableInfo] = []
        
        let sql = """
            PRAGMA table_info(\(table));
        """
        
        try reader.read { db in
            let result = try Row.fetchAll(db, sql: sql)
            metadata = result.map({ FXBTableInfo.make(from: $0) })
            print(result)
        }
        
        return metadata
    }
    
    internal static func dbSize(with reader: DatabaseReader) throws -> Int? {
        try reader.read({ db in
            let pageSizeSQL = "PRAGMA page_size;"
            let pageSize = try Int.fetchOne(db, sql: pageSizeSQL)
            
            let pageCountSQL = "PRAGMA page_count;"
            let pageCount = try Int.fetchOne(db, sql: pageCountSQL)
            
            guard let pageSize = pageSize, let pageCount = pageCount else {
                return nil
            }
            
            return pageSize * pageCount
        })
    }
}
