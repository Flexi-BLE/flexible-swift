//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import GRDB

/// Representation of database table metadata from `PRAGMA table_info([tableName])`
public struct FXBTableInfo: Codable {
    public var cid: Int
    public var name: String
    public var type: String
    public var notNull: Int
    public var pk: Int
    
    internal static func make(from row: Row) -> FXBTableInfo {
        return FXBTableInfo(
            cid: row["cid"],
            name: row["name"],
            type: row["type"],
            notNull: row["notnull"],
            pk: row["pk"]
        )
    }
    
    public static func dummy() -> FXBTableInfo {
        return FXBTableInfo(cid: 1, name: "dummy_tbl", type: "table", notNull: 0, pk: 0)
    }
}

/// untyped column for table metadata
public class GenericColumn<T> {
    public var tableInfo: FXBTableInfo
    public var value: T
    
    init(tableInfo: FXBTableInfo, value: T) {
        self.tableInfo = tableInfo
        self.value = value
    }
    
    public static func dummy() -> GenericColumn<Any> {
        return GenericColumn<Any>(tableInfo: FXBTableInfo.dummy(), value: 1)
    }
}

public class GenericRow: Identifiable {
    public var id = UUID()
    public var metadata: [FXBTableInfo]
    public var columns = [GenericColumn<Any>]()
    
    init(metadata: [FXBTableInfo], row: Row) {
        self.metadata = metadata
        for p in self.metadata {
            columns.append(GenericColumn<Any>(tableInfo: p, value: row[p.name] ?? 0))
        }
    }
    
    public static func dummy() -> GenericRow {
        return GenericRow(metadata: [FXBTableInfo.dummy()], row: Row())
    }
    
    public func getValue<T>(for colName: String) -> T? {
        if let idx = self.metadata.firstIndex(where: { $0.name == colName }),
           let val = self.columns[idx].value as? T {
            return val
        }
        
        return nil
    }
}
