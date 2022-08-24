//
//  Location.swift
//  
//
//  Created by Nikhil Khandelwal on 8/3/22.
//

import Foundation
import GRDB

public struct Location: Codable {
    public var id: Int64?
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var horizontalAccuracy: Double
    public var verticalAccuracy: Double
    public var timestamp: Date
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case latitude
        case longitude
        case createdAt = "created_at"
        case altitude
        case horizontalAccuracy = "horizontal_acc"
        case verticalAccuracy = "vertical_acc"
        case timestamp

    }
    
    init(latitude: Double, longitude: Double, altitude: Double, horizontalAccuracy: Double, verticalAccuracy: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
        self.createdAt = Date.now
    }
}

extension Location: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let latitude = Column(CodingKeys.latitude)
        static let longitude = Column(CodingKeys.longitude)
        static let altitude = Column(CodingKeys.altitude)
        static let horiztalAccuracy = Column(CodingKeys.horizontalAccuracy)
        static let verticalAccuracy = Column(CodingKeys.verticalAccuracy)
        static let timestamp = Column(CodingKeys.timestamp)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    mutating public func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    public static var databaseTableName: String = "location"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.latitude.stringValue, .double)
        table.column(CodingKeys.longitude.stringValue, .double)
        table.column(CodingKeys.altitude.stringValue, .double)
        table.column(CodingKeys.horizontalAccuracy.stringValue, .double)
        table.column(CodingKeys.verticalAccuracy.stringValue, .double)
        table.column(CodingKeys.timestamp.stringValue, .datetime)
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
    }
}
