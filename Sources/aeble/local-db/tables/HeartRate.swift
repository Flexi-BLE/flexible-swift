//
//  HeartRate.swift
//  
//
//  Created by Blaine Rothrock on 8/1/22.
//

import Foundation
import GRDB

public struct HeartRate: Codable {
    public var id: Int64?
    public var sensorLocation: String
    public var bpm: Int
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sensorLocation = "sensor_location"
        case bpm
        case createdAt = "created_at"
    }
    
    init(bpm: Int, sensorLocation: String) {
        self.bpm = bpm
        self.sensorLocation = sensorLocation
        self.createdAt = Date.now
    }
}

extension HeartRate: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sensorLocation = Column(CodingKeys.sensorLocation)
        static let bpm = Column(CodingKeys.bpm)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    mutating public func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    public static var databaseTableName: String = "heart_rate"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.sensorLocation.stringValue, .text)
        table.column(CodingKeys.bpm.stringValue, .integer).notNull()
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
    }
}
