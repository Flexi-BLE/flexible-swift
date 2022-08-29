//
//  DynamicTable.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import GRDB

internal struct DynamicTable: Codable {
    var id: Int64?
    var name: String
    var originalName: String
    var metadata: Data?
    var createdAt: Date
    var active: Bool = true
    
    init(name: String, metadata: Data?) {
        self.name = name
        self.originalName = name
        self.metadata = metadata
        self.createdAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName = "original_name"
        case metadata
        case createdAt = "created_at"
        case active
    }
}

extension DynamicTable: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let originalName = Column(CodingKeys.originalName)
        static let metadata = Column(CodingKeys.metadata)
        static let createdAt = Column(CodingKeys.createdAt)
        static let active = Column(CodingKeys.active)
    }
    
    static var databaseTableName: String = "dynamic_table"
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.name.stringValue, .text).notNull().unique(onConflict: .fail)
        table.column(CodingKeys.originalName.stringValue, .text).notNull()
        table.column(CodingKeys.metadata.stringValue, .blob).notNull()
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.active.stringValue, .boolean).defaults(to: true)
    }
}
