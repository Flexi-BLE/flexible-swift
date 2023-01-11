//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 3/8/22.
//

import Foundation
import GRDB

internal struct FXBDataUpload: Codable {
    var id: Int64?
    var ts: Date
    var tableName: String
    var database: String
    var APIURL: String
    var startDate: Date?
    var endDate: Date
    var expectedUploadCount: Int
    var uploadCount: Int
    var errorMessage: String?
    var uploadTimeSeconds: TimeInterval
    var numberOfAPICalls: Int
    var totalBytes: Int
    
    enum CodingKeys: String, CodingKey {
        case id, ts
        case tableName = "table_name"
        case database
        case APIURL = "api_url"
        case startDate = "start_date"
        case endDate = "end_date"
        case expectedUploadCount = "expected_upload_count"
        case uploadCount = "upload_count"
        case errorMessage = "error_message"
        case uploadTimeSeconds = "upload_time_seconds"
        case numberOfAPICalls = "number_of_api_calls"
        case totalBytes = "total_bytes"
    }
}

extension FXBDataUpload: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let ts = Column(CodingKeys.ts)
        static let tableName = Column(CodingKeys.tableName)
        static let database = Column(CodingKeys.database)
        static let APIURL = Column(CodingKeys.APIURL)
        static let startDate = Column(CodingKeys.startDate)
        static let endDate = Column(CodingKeys.endDate)
        static let expectedUploadCount = Column(CodingKeys.expectedUploadCount)
        static let uploadCount = Column(CodingKeys.uploadCount)
        static let errorMessage = Column(CodingKeys.errorMessage)
        static let uploadTimeSeconds = Column(CodingKeys.uploadTimeSeconds)
        static let numberOfAPICalls = Column(CodingKeys.numberOfAPICalls)
        static let totalBytes = Column(CodingKeys.totalBytes)
    }
    
    static var databaseTableName: String = "data_upload"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.ts.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.tableName.stringValue, .text)
        table.column(CodingKeys.database.stringValue, .text)
        table.column(CodingKeys.APIURL.stringValue, .text)
        table.column(CodingKeys.startDate.stringValue, .datetime)
        table.column(CodingKeys.endDate.stringValue, .datetime)
        table.column(CodingKeys.expectedUploadCount.stringValue, .integer)
        table.column(CodingKeys.uploadCount.stringValue, .integer)
        table.column(CodingKeys.errorMessage.stringValue, .text)
        table.column(CodingKeys.uploadTimeSeconds.stringValue, .double)
        table.column(CodingKeys.numberOfAPICalls.stringValue, .integer)
        table.column(CodingKeys.totalBytes.stringValue, .integer)
    }
}
