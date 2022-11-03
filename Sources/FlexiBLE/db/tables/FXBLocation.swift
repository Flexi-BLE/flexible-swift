//
//  Location.swift
//  
//
//  Created by Nikhil Khandelwal on 8/3/22.
//

import Foundation
import GRDB

public struct FXBLocation: Codable {
    public var id: Int64?
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var horizontalAccuracy: Double
    public var verticalAccuracy: Double
    public var ts: Date
    public var createdAt: Date
    public var uploaded: Bool = false
    internal var specId: Int64
    
    enum CodingKeys: String, CodingKey {
        case id
        case latitude
        case longitude
        case createdAt = "created_at"
        case altitude
        case horizontalAccuracy = "horizontal_acc"
        case verticalAccuracy = "vertical_acc"
        case ts
        case uploaded
        case specId = "spec_id"

    }
    
    init(
        latitude: Double,
        longitude: Double,
        altitude: Double,
        horizontalAccuracy: Double,
        verticalAccuracy: Double,
        ts: Date,
        specId: Int64
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.ts = ts
        self.createdAt = Date.now
        self.specId = specId
    }
}

extension FXBLocation: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let latitude = Column(CodingKeys.latitude)
        static let longitude = Column(CodingKeys.longitude)
        static let altitude = Column(CodingKeys.altitude)
        static let horiztalAccuracy = Column(CodingKeys.horizontalAccuracy)
        static let verticalAccuracy = Column(CodingKeys.verticalAccuracy)
        static let ts = Column(CodingKeys.ts)
        static let createdAt = Column(CodingKeys.createdAt)
        static let uploaded = Column(CodingKeys.uploaded)
        static let specId = Column(CodingKeys.specId)
    }
    
    mutating public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    public static var databaseTableName: String = "location"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.latitude.stringValue, .double)
        table.column(CodingKeys.longitude.stringValue, .double)
        table.column(CodingKeys.altitude.stringValue, .double)
        table.column(CodingKeys.horizontalAccuracy.stringValue, .double)
        table.column(CodingKeys.verticalAccuracy.stringValue, .double)
        table.column(CodingKeys.ts.stringValue, .datetime).notNull().indexed()
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.uploaded.stringValue, .boolean)
        table.column(CodingKeys.specId.stringValue, .integer)
            .references(FXBSpecTable.databaseTableName)
    }
}
