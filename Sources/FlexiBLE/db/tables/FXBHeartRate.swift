//
//  HeartRate.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import GRDB

public struct FXBHeartRate: Codable, FXBTimeSeriesRecord {
    public var id: Int64?
    public var ts: Int64
    public var sensorLocation: String
    public var bpm: Int
    public var deviceName: String
    public var createdAt: Date
    public var uploaded: Bool = false
//    internal var specId: Int64
    
    enum CodingKeys: String, CodingKey {
        case id, ts
        case sensorLocation = "sensor_location"
        case bpm
        case deviceName = "device_name"
        case createdAt = "created_at"
        case uploaded
//        case specId = "spec_id"
    }
    
    init(ts: Date, bpm: Int, sensorLocation: String, deviceName: String) {
        self.id = nil
        self.ts = ts.dbPrimaryKey
        self.bpm = bpm
        self.sensorLocation = sensorLocation
        self.createdAt = Date.now
        self.deviceName = deviceName
    }
}

extension FXBHeartRate: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let ts = Column(CodingKeys.ts)
        static let sensorLocation = Column(CodingKeys.sensorLocation)
        static let bpm = Column(CodingKeys.bpm)
        static let deviceName = Column(CodingKeys.deviceName)
        static let createdAt = Column(CodingKeys.createdAt)
        static let uploaded = Column(CodingKeys.uploaded)
    }
    
    mutating public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    public static var databaseTableName: String = "heart_rate"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.ts.stringValue, .integer).notNull().indexed()
        table.column(CodingKeys.sensorLocation.stringValue, .text)
        table.column(CodingKeys.bpm.stringValue, .integer).notNull()
        table.column(CodingKeys.deviceName.stringValue, .text)
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.uploaded.stringValue, .boolean).defaults(to: false)
    }
}
