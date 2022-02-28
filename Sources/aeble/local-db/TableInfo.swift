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
    
    public static func dummy() -> TableInfo {
        return TableInfo(cid: 1, name: "dummy_tbl", type: "table", notNull: 0, pk: 0)
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
    
    public static func dummy() -> GenericColumn<Any> {
        return GenericColumn<Any>(tableInfo: TableInfo.dummy(), value: 1)
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
    
    public static func dummy() -> GenericRow {
        return GenericRow(metadata: [TableInfo.dummy()], row: Row())
    }
}
