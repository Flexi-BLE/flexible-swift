//
//  Timestamp.swift
//  
//
//  Created by Blaine Rothrock on 2/24/22.
//

import Foundation
import GRDB

/// Representation of a singular event in time
internal struct Timestamp: Codable {
    var id: Int64?
    var name: String?
    var description: String?
    var createdAt: Date
    var datetime: Date
        
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case createdAt = "created_at"
        case datetime
    }
    
    init(name: String?, description: String?=nil, datetime:Date=Date.now) {
        self.name = name
        self.description = description
        self.datetime = datetime
        self.createdAt = Date.now
    }
}

extension Timestamp: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let description = Column(CodingKeys.description)
        static let createdAt = Column(CodingKeys.createdAt)
        static let datetime = Column(CodingKeys.datetime)
    }
    
    static var databaseTableName: String = "timestamp"
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.name.stringValue, .text).notNull()
        table.column(CodingKeys.description.stringValue, .text)
        table.column(CodingKeys.createdAt.stringValue, .datetime).notNull(onConflict: .fail)
        table.column(CodingKeys.datetime.stringValue, .datetime)
    }
}
