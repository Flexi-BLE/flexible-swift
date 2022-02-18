//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import GRDB

/// Representation of database table metadata from `PRAGMA table_info([tableName])`
internal struct TableInfo: Codable {
    var cid: Int
    var name: String
    var type: String
    var notNull: Int
    var pk: Int
    
    static func make(from row: Row) -> TableInfo {
        return TableInfo(
            cid: row["cid"],
            name: row["name"],
            type: row["type"],
            notNull: row["notnull"],
            pk: row["pk"]
        )
    }
}

/// untyped column for table metadata
internal class GenericColumn<T> {
    var tableInfo: TableInfo
    var value: T
    
    init(tableInfo: TableInfo, value: T) {
        self.tableInfo = tableInfo
        self.value = value
    }
}

internal class GenericRow: Identifiable {
    var id = UUID()
    var metadata: [TableInfo]
    var columns = [GenericColumn<Any>]()
    
    init(metadata: [TableInfo], row: Row) {
        self.metadata = metadata
        for p in self.metadata {
            columns.append(GenericColumn<Any>(tableInfo: p, value: row[p.name] ?? 0))
        }
    }
}
