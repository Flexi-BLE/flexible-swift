//
//  Timestamp.swift
//  
//
//  Created by Blaine Rothrock on 2/24/22.
//

import Foundation
import GRDB

/// Representation of a singular event in time
public struct FXBTimestamp: Codable {
    public var id: Int64?
    public var name: String?
    public var description: String?
    public var experimentId: Int64?
    var createdAt: Date
    public var ts: Date
    var uploaded: Bool = false
    internal var specId: Int64
        
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case experimentId = "experiment_id"
        case createdAt = "created_at"
        case ts
        case uploaded
        case specId = "spec_id"
    }
    
    init(
        name: String?,
        description: String?=nil,
        ts:Date=Date.now,
        experimentId: Int64?=nil,
        specId: Int64
    ) {
        self.name = name
        self.description = description
        self.ts = ts
        self.createdAt = Date.now
        self.experimentId = experimentId
        self.specId = specId
    }
    
    public static func dummy() -> FXBTimestamp {
        return FXBTimestamp(
            name: "test",
            description: "test123",
            ts: Date(),
            experimentId: 123,
            specId: 1
        )
    }
}

extension FXBTimestamp: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let description = Column(CodingKeys.description)
        static let eventId = Column(CodingKeys.experimentId)
        static let createdAt = Column(CodingKeys.createdAt)
        static let datetime = Column(CodingKeys.ts)
        static let uploaded = Column(CodingKeys.uploaded)
        static let specId = Column(CodingKeys.specId)
    }
    
    mutating public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    public static var databaseTableName: String = "timestamp"
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.name.stringValue, .text).notNull()
        table.column(CodingKeys.description.stringValue, .text)
        table.column(CodingKeys.experimentId.stringValue, .integer)
            .indexed()
            .references(FXBExperiment.databaseTableName, onDelete: .cascade)
        table.column(CodingKeys.createdAt.stringValue, .datetime).notNull(onConflict: .fail)
        table.column(CodingKeys.ts.stringValue, .datetime).notNull().indexed()
        table.column(CodingKeys.uploaded.stringValue, .boolean)
        table.column(CodingKeys.specId.stringValue, .integer)
            .references(FXBSpecTable.databaseTableName)
    }
}
