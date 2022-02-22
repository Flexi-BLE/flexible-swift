//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import GRDB

/// Representation of database table metadata from `PRAGMA table_info([tableName])`
public struct TableInfo: Codable {
    public var cid: Int
    public var name: String
    public var type: String
    public var notNull: Int
    public var pk: Int
    
    internal static func make(from row: Row) -> TableInfo {
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
public class GenericColumn<T> {
    public var tableInfo: TableInfo
    public var value: T
    
    init(tableInfo: TableInfo, value: T) {
        self.tableInfo = tableInfo
        self.value = value
    }
}

public class GenericRow: Identifiable {
    public var id = UUID()
    public var metadata: [TableInfo]
    public var columns = [GenericColumn<Any>]()
    
    init(metadata: [TableInfo], row: Row) {
        self.metadata = metadata
        for p in self.metadata {
            columns.append(GenericColumn<Any>(tableInfo: p, value: row[p.name] ?? 0))
        }
    }
}
