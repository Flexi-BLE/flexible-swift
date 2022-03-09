//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 3/8/22.
//

import Foundation
import GRDB

internal enum DataUploadStatus: String, Codable {
    case success
    case fail
}

internal struct DataUpload: Codable {
    var id: Int64?
    var status: DataUploadStatus
    var createdAt: Date
    var duration: TimeInterval
    var numberOfRecords: Int
    var measurement: String?
    var errorMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case createdAt = "created_at"
        case duration
        case numberOfRecords = "number_of_records"
        case measurement
        case errorMessage = "error_message"
    }
}

extension DataUpload: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let status = Column(CodingKeys.status)
        static let createdAt = Column(CodingKeys.createdAt)
        static let duration = Column(CodingKeys.duration)
        static let numberOfRecords = Column(CodingKeys.numberOfRecords)
        static let measurement = Column(CodingKeys.measurement)
        static let errorMessage = Column(CodingKeys.errorMessage)
    }
    
    static var databaseTableName: String = "data_upload"
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.status.stringValue, .text)
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.duration.stringValue, .integer)
        table.column(CodingKeys.numberOfRecords.stringValue, .integer)
        table.column(CodingKeys.measurement.stringValue, .text)
        table.column(CodingKeys.errorMessage.stringValue, .text)
    }
}
