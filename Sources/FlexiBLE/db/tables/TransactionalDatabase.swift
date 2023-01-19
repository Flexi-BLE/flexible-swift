//
//  TransactionalDatabase.swift
//  
//
//  Created by Blaine Rothrock on 1/17/23.
//

import Foundation
import GRDB

public class TransactionalDatabase: Codable {
    public var id: Int64?
    public private(set) var createdAt: Date
    public private(set) var path: URL
    public private(set) var startDate: Date
    public private(set) var endDate: Date?
    public private(set) var isLocked: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case path = "path"
        case startDate = "start_date"
        case endDate = "end_date"
        case isLocked = "is_locked"
    }
    
    init(path: URL, startDate: Date) {
        self.createdAt = Date.now
        self.path = path
        self.startDate = startDate
    }
    
    func setStart(_ date: Date) {
        self.startDate = date
    }
    
    func setEndDate(_ date: Date) {
        self.endDate = date
    }
    
    func lock() {
        self.isLocked = true
    }
}

extension TransactionalDatabase: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let createdAt = Column(CodingKeys.createdAt)
        static let path = Column(CodingKeys.path)
        static let startDate = Column(CodingKeys.startDate)
        static let endDate = Column(CodingKeys.endDate)
        static let isLocked = Column(CodingKeys.isLocked)
    }
    
    public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    public static var databaseTableName: String = "transactional_database"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.path.stringValue, .text).notNull()
        table.column(CodingKeys.createdAt.stringValue, .date).defaults(to: Date.now)
        table.column(CodingKeys.startDate.stringValue, .date)
        table.column(CodingKeys.endDate.stringValue, .date)
        table.column(CodingKeys.isLocked.stringValue, .boolean).defaults(to: false)
    }
}
