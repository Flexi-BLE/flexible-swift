//
//  FXBBackup.swift
//  
//
//  Created by Blaine Rothrock on 1/17/23.
//

import Foundation
import GRDB

//public struct FXBBackup: Codable {
//    public var id: Int64?
//    public var ts: Date
//    public var createdAt: Date
//    public var fileName: String
//
//    enum CodingKeys: String, CodingKey {
//        case id, ts
//        case createdAt = "created_at"
//        case fileName = "file_name"
//    }
//
//    init(date: Date, fileName: String) {
//        self.ts = date
//        self.createdAt = Date.now
//        self.fileName = fileName
//    }
//}
//
//extension FXBBackup: TableRecord, FetchableRecord, MutablePersistableRecord {
//
//    enum Columns {
//        static let id = Column(CodingKeys.id)
//        static let ts = Column(CodingKeys.ts)
//        static let createdAt = Column(CodingKeys.createdAt)
//        static let fileName = Column(CodingKeys.fileName)
//    }
//
//    mutating public func didInsert(_ inserted: InsertionSuccess) {
//        id = inserted.rowID
//    }
//
//    public static var databaseTableName: String = "database_backup"
//
//    internal static func create(_ table: TableDefinition) {
//        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
//        table.column(CodingKeys.fileName.stringValue, .text).notNull()
//        table.column(CodingKeys.createdAt.stringValue, .date).defaults(to: Date.now)
//        table.column(CodingKeys.ts.stringValue, .date).indexed()
//    }
//}
