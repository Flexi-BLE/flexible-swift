//
//  Experiment.swift
//  
//
//  Created by blaine on 2/23/22.
//

import Foundation
import GRDB

/// Representation of a time frame
public struct Experiment: Codable {
    public var id: Int64?
    public var uuid: String
    public var name: String
    public var description: String?
    public var start: Date
    public var end: Date?
    internal var uploaded: Bool = false
    internal var createdAt: Date
        
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case name
        case description
        case createdAt = "created_at"
        case start
        case end
        case uploaded
    }
    
    init(name: String, description: String?=nil, start:Date=Date.now, end:Date?=nil) {
        self.name = name
        self.uuid = UUID().uuidString
        self.description = description
        self.createdAt = Date.now
        self.start = start
        self.end = end
    }
}

extension Experiment: TableRecord {
    static let timestampForeignKey = ForeignKey([Timestamp.CodingKeys.experimentId.rawValue])
        static var timestamps = hasMany(Timestamp.self, using: timestampForeignKey)
        var timestamps: QueryInterfaceRequest<Timestamp> {
            request(for: Experiment.timestamps)
        }
}

extension Experiment: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let uuid = Column(CodingKeys.uuid)
        static let description = Column(CodingKeys.description)
        static let createdAt = Column(CodingKeys.createdAt)
        static let start = Column(CodingKeys.start)
        static let end = Column(CodingKeys.end)
        static let uploaded = Column(CodingKeys.uploaded)
    }
        
    mutating public func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
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
        table.column(CodingKeys.uploaded.stringValue, .boolean)
    }
}

extension Experiment {
    public static func dummyActive() -> Experiment {
        var exp = Experiment(
            name: "dummy exp", description: "--",
            start: Date.now.addingTimeInterval(-3600),
            end: nil
        )
        exp.id = 1000
        return exp
    }
    
    public static func dummyEnded() -> Experiment {
        var exp = Experiment.dummyActive()
        exp.end = Date.now.addingTimeInterval(-10)
        return exp
    }
}
