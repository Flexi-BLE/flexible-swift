//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 8/6/22.
//

import Foundation
import GRDB

public struct FXBThroughput: Codable, FXBTimeSeriesRecord {
    public var id: Int64?
    public var dataStream: String
    public var bytes: Int
    public var ts: Date
    public var deviceName: String
    public var uploaded: Bool = false
//    public var specId: Int64
    
    enum CodingKeys: String, CodingKey {
        case id
        case dataStream = "data_stream"
        case bytes
        case ts
        case deviceName = "device_name"
        case uploaded
//        case specId = "spec_id"
    }
    
    init(dataStream: String, bytes: Int, deviceName: String) {
        self.dataStream = dataStream
        self.bytes = bytes
        self.ts = Date()
        self.deviceName = deviceName
//        self.specId = specId
    }
}

extension FXBThroughput: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let dataStream = Column(CodingKeys.dataStream)
        static let bytes = Column(CodingKeys.bytes)
        static let ts = Column(CodingKeys.ts)
        static let deviceName = Column(CodingKeys.deviceName)
        static let uploaded = Column(CodingKeys.uploaded)
//        static let specId = Column(CodingKeys.specId)
    }
    
    mutating public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    public static var databaseTableName: String = "throughput"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.dataStream.stringValue, .text)
        table.column(CodingKeys.bytes.stringValue, .integer)
        table.column(CodingKeys.ts.stringValue, .datetime)
        table.column(CodingKeys.deviceName.stringValue, .text)
        table.column(CodingKeys.uploaded.stringValue, .boolean)
//        table.column(CodingKeys.specId.stringValue, .integer)
//            .references(FXBSpecTable.databaseTableName)
    }
}
