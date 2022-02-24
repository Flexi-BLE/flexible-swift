//
//  Event.swift
//  
//
//  Created by blaine on 2/23/22.
//

import Foundation
import GRDB

/// Representation of a time frame
internal struct Event: Codable {
    var id: Int64?
    var name: String
    var description: String?
    var createdAt: Date
    var start: Date
    var end: Date?
        
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case createdAt = "created_at"
        case start
        case end
    }
    
    init(name: String, description: String?=nil, start:Date, end:Date?=nil) {
        self.name = name
        self.description = description
        self.createdAt = Date.now
        self.start = start
        self.end = end
    }
}

extension Event: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let description = Column(CodingKeys.description)
        static let createdAt = Column(CodingKeys.createdAt)
        static let start = Column(CodingKeys.start)
        static let end = Column(CodingKeys.end)
    }
    
    static var databaseTableName: String = "event"
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.name.stringValue, .text).notNull()
        table.column(CodingKeys.description.stringValue, .text)
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.start.stringValue, .datetime)
        table.column(CodingKeys.end.stringValue, .datetime)
    }
}
