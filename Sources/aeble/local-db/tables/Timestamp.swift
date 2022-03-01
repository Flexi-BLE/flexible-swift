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
    var experimentId: Int64?
    var createdAt: Date
    var datetime: Date
        
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case experimentId = "experiment_id"
        case createdAt = "created_at"
        case datetime
    }
    
    init(name: String?, description: String?=nil, datetime:Date=Date.now, experimentId: Int64?=nil) {
        self.name = name
        self.description = description
        self.datetime = datetime
        self.createdAt = Date.now
        self.experimentId = experimentId
    }
}

extension Timestamp: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let description = Column(CodingKeys.description)
        static let eventId = Column(CodingKeys.experimentId)
        static let createdAt = Column(CodingKeys.createdAt)
        static let datetime = Column(CodingKeys.datetime)
    }
    
    static var databaseTableName: String = "timestamp"
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.name.stringValue, .text).notNull()
        table.column(CodingKeys.description.stringValue, .text)
        table.column(CodingKeys.experimentId.stringValue, .integer)
            .indexed()
            .references(Experiment.databaseTableName, onDelete: .cascade)
        table.column(CodingKeys.createdAt.stringValue, .datetime).notNull(onConflict: .fail)
        table.column(CodingKeys.datetime.stringValue, .datetime)
    }
}
