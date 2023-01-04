//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 3/8/22.
//

import Foundation
import GRDB

internal enum FXBDataUploadStatus: String, Codable {
    case success
    case fail
}

internal struct FXBDataUpload: Codable {
    var id: Int64?
    var status: FXBDataUploadStatus
    var ts: Date
    var byteSize: Int
    var numberOfRecords: Int
    var bucket: String?
    var measurement: String?
    var errorMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case ts
        case byteSize
        case numberOfRecords = "number_of_records"
        case bucket
        case measurement
        case errorMessage = "error_message"
    }
}

extension FXBDataUpload: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let status = Column(CodingKeys.status)
        static let ts = Column(CodingKeys.ts)
        static let byteSize = Column(CodingKeys.byteSize)
        static let numberOfRecords = Column(CodingKeys.numberOfRecords)
        static let bucket = Column(CodingKeys.bucket)
        static let measurement = Column(CodingKeys.measurement)
        static let errorMessage = Column(CodingKeys.errorMessage)
    }
    
    static var databaseTableName: String = "data_upload"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.status.stringValue, .text)
        table.column(CodingKeys.ts.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.byteSize.stringValue, .integer)
        table.column(CodingKeys.numberOfRecords.stringValue, .integer)
        table.column(CodingKeys.bucket.stringValue, .text)
        table.column(CodingKeys.measurement.stringValue, .text)
        table.column(CodingKeys.errorMessage.stringValue, .text)
    }
}
