//
//  Location.swift
//  
//
//  Created by Nikhil Khandelwal on 8/3/22.
//

import Foundation
import GRDB

public struct FXBLocation: Codable, FXBTimeSeriesRecord {
    public var ts: Int64
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var horizontalAccuracy: Double
    public var verticalAccuracy: Double
    public var deviceName: String
    public var createdAt: Date
    public var uploaded: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case ts
        case latitude
        case longitude
        case createdAt = "created_at"
        case altitude
        case horizontalAccuracy = "horizontal_acc"
        case verticalAccuracy = "vertical_acc"
        case deviceName = "device_name"
        case uploaded
//        case specId = "spec_id"

    }
    
    public init(
        ts: Date,
        latitude: Double,
        longitude: Double,
        altitude: Double,
        horizontalAccuracy: Double,
        verticalAccuracy: Double,
        deviceName: String
    ) {
        self.ts = ts.dbPrimaryKey
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.deviceName = deviceName
        self.createdAt = Date.now
//        self.specId = specId
    }
}

extension FXBLocation: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.ts)
        static let latitude = Column(CodingKeys.latitude)
        static let longitude = Column(CodingKeys.longitude)
        static let altitude = Column(CodingKeys.altitude)
        static let horiztalAccuracy = Column(CodingKeys.horizontalAccuracy)
        static let verticalAccuracy = Column(CodingKeys.verticalAccuracy)
        static let deviceName = Column(CodingKeys.deviceName)
        static let createdAt = Column(CodingKeys.createdAt)
        static let uploaded = Column(CodingKeys.uploaded)
//        static let specId = Column(CodingKeys.specId)
    }
    
    mutating public func didInsert(_ inserted: InsertionSuccess) {
        ts = inserted.rowID
    }
    
    public static var databaseTableName: String = "location"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.ts.stringValue)
        table.column(CodingKeys.latitude.stringValue, .double)
        table.column(CodingKeys.longitude.stringValue, .double)
        table.column(CodingKeys.altitude.stringValue, .double)
        table.column(CodingKeys.horizontalAccuracy.stringValue, .double)
        table.column(CodingKeys.verticalAccuracy.stringValue, .double)
        table.column(CodingKeys.deviceName.stringValue, .text)
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.uploaded.stringValue, .boolean)
    }
}
