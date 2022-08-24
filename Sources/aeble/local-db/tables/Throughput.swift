//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 8/6/22.
//

import Foundation
import GRDB

public struct Throughput: Codable {
    public var id: Int64?
    public var device: String
    public var dataStream: String
    public var bytes: Int
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case device
        case dataStream = "data_stream"
        case bytes
        case createdAt = "created_at"
    }
    
    init(device: String, dataStream: String, bytes: Int) {
        self.device = device
        self.dataStream = dataStream
        self.bytes = bytes
        self.createdAt = Date()
    }
}

extension Throughput: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let device = Column(CodingKeys.device)
        static let dataStream = Column(CodingKeys.dataStream)
        static let bytes = Column(CodingKeys.bytes)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    mutating public func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    public static var databaseTableName: String = "throughput"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.device.stringValue, .text)
        table.column(CodingKeys.dataStream.stringValue, .text)
        table.column(CodingKeys.bytes.stringValue, .integer)
        table.column(CodingKeys.createdAt.stringValue, .datetime)
    }
}
