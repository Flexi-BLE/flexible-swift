//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 8/6/22.
//

import Foundation
import GRDB

public struct FXBThroughput: Codable {
    public var id: Int64?
    public var device: String
    public var dataStream: String
    public var bytes: Int
    public var createdAt: Date
    public var specId: Int64
    
    enum CodingKeys: String, CodingKey {
        case id
        case device
        case dataStream = "data_stream"
        case bytes
        case createdAt = "created_at"
        case specId = "spec_id"
    }
    
    init(device: String, dataStream: String, bytes: Int, specId: Int64) {
        self.device = device
        self.dataStream = dataStream
        self.bytes = bytes
        self.createdAt = Date()
        self.specId = specId
    }
}

extension FXBThroughput: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let device = Column(CodingKeys.device)
        static let dataStream = Column(CodingKeys.dataStream)
        static let bytes = Column(CodingKeys.bytes)
        static let createdAt = Column(CodingKeys.createdAt)
        static let specId = Column(CodingKeys.specId)
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
        table.column(CodingKeys.specId.stringValue, .integer)
            .references(FXBSpecTable.databaseTableName)
    }
}
