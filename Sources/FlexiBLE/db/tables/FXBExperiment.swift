//
//  Experiment.swift
//  
//
//  Created by blaine on 2/23/22.
//

import Foundation
import GRDB

/// Representation of a time frame
public struct FXBExperiment: Codable {
    public var id: Int64?
    public var uuid: String
    public var name: String
    public var description: String?
    public var start: Date
    public var end: Date?
    private var ts: Date
    public var trackGPS: Bool = false
    public var active: Bool = false
    internal var uploaded: Bool = false
    internal var createdAt: Date
//    internal var specId: Int64?
        
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case name
        case description
        case createdAt = "created_at"
        case start
        case end
        case ts
        case uploaded
        case active
        case trackGPS = "track_gps"
//        case specId = "spec_id"
    }
    
    init(
        name: String,
        description: String?=nil,
        start:Date=Date.now,
        end:Date?=nil,
        active: Bool,
        trackGPS: Bool=false
    ) {
        self.name = name
        self.uuid = UUID().uuidString
        self.description = description
        self.createdAt = Date.now
        self.start = start
        self.end = end
        self.ts = start
        self.active = active
        self.trackGPS = trackGPS
//        self.specId = specId
    }
}

extension FXBExperiment: TableRecord {
    static let timestampForeignKey = ForeignKey([FXBTimestamp.CodingKeys.experimentId.rawValue])
        static var timestamps = hasMany(FXBTimestamp.self, using: timestampForeignKey)
        var timestamps: QueryInterfaceRequest<FXBTimestamp> {
            request(for: FXBExperiment.timestamps)
        }
}

extension FXBExperiment: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let uuid = Column(CodingKeys.uuid)
        static let description = Column(CodingKeys.description)
        static let createdAt = Column(CodingKeys.createdAt)
        static let start = Column(CodingKeys.start)
        static let end = Column(CodingKeys.end)
        static let ts = Column(CodingKeys.ts)
        static let active = Column(CodingKeys.active)
        static let uploaded = Column(CodingKeys.uploaded)
        static let trackGPS = Column(CodingKeys.trackGPS)
//        static let specId = Column(CodingKeys.specId)
    }
        
    mutating public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    public static var databaseTableName: String = "experiment"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.name.stringValue, .text).notNull()
        table.column(CodingKeys.uuid.stringValue, .text).notNull()
        table.column(CodingKeys.description.stringValue, .text)
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.start.stringValue, .datetime)
        table.column(CodingKeys.end.stringValue, .datetime)
        table.column(CodingKeys.ts.stringValue, .datetime).notNull().indexed()
        table.column(CodingKeys.uploaded.stringValue, .boolean)
        table.column(CodingKeys.active.stringValue, .boolean)
        table.column(CodingKeys.trackGPS.stringValue, .boolean)
//        table.column(CodingKeys.specId.stringValue, .integer)
//            .references(FXBSpecTable.databaseTableName)
    }
}

extension FXBExperiment {
    public static func dummyActive() -> FXBExperiment {
        var exp = FXBExperiment(
            name: "dummy exp", description: "--",
            start: Date.now.addingTimeInterval(-3600),
            end: nil,
            active: true,
            trackGPS: true
        )
        exp.id = 1000
        return exp
    }
    
    public static func dummyEnded() -> FXBExperiment {
        var exp = FXBExperiment.dummyActive()
        exp.end = Date.now.addingTimeInterval(-10)
        return exp
    }
}
