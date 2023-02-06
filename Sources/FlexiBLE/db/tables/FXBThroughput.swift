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
    public var ts: Int64
    public var dataStream: String
    public var bytes: Int
    public var deviceName: String
    public var uploaded: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, ts
        case dataStream = "data_stream"
        case bytes
        case deviceName = "device_name"
        case uploaded
    }
    
    init(dataStream: String, bytes: Int, deviceName: String) {
        self.id = nil
        self.ts = Date().dbPrimaryKey
        self.dataStream = dataStream
        self.bytes = bytes
        self.deviceName = deviceName
    }
}

extension FXBThroughput: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let ts = Column(CodingKeys.ts)
        static let dataStream = Column(CodingKeys.dataStream)
        static let bytes = Column(CodingKeys.bytes)
        static let deviceName = Column(CodingKeys.deviceName)
        static let uploaded = Column(CodingKeys.uploaded)
    }
    
    mutating public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    public static var databaseTableName: String = "throughput"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.ts.stringValue, .integer).notNull().indexed()
        table.column(CodingKeys.dataStream.stringValue, .text)
        table.column(CodingKeys.bytes.stringValue, .integer)
        table.column(CodingKeys.deviceName.stringValue, .text)
        table.column(CodingKeys.uploaded.stringValue, .boolean)
    }
}
