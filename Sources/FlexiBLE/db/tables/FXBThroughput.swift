//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 8/6/22.
//

import Foundation
import GRDB

public struct FXBThroughput: Codable, FXBTimeSeriesRecord {
    public var ts: Int64
    public var dataStream: String
    public var bytes: Int
    public var deviceName: String
    public var uploaded: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case ts
        case dataStream = "data_stream"
        case bytes
        case deviceName = "device_name"
        case uploaded
    }
    
    init(dataStream: String, bytes: Int, deviceName: String) {
        self.ts = Date().dbPrimaryKey
        self.dataStream = dataStream
        self.bytes = bytes
        self.deviceName = deviceName
    }
}

extension FXBThroughput: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let ts = Column(CodingKeys.ts)
        static let dataStream = Column(CodingKeys.dataStream)
        static let bytes = Column(CodingKeys.bytes)
        static let deviceName = Column(CodingKeys.deviceName)
        static let uploaded = Column(CodingKeys.uploaded)
    }
    
    mutating public func didInsert(_ inserted: InsertionSuccess) {
        ts = inserted.rowID
    }
    
    public static var databaseTableName: String = "throughput"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.ts.stringValue)
        table.column(CodingKeys.dataStream.stringValue, .text)
        table.column(CodingKeys.bytes.stringValue, .integer)
        table.column(CodingKeys.deviceName.stringValue, .text)
        table.column(CodingKeys.uploaded.stringValue, .boolean)
    }
}
