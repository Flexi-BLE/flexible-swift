//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 3/8/22.
//

import Foundation
import GRDB

public struct FXBDataUpload: Codable {
    public var id: Int64?
    public var ts: Date
    public var tableName: String
    public var database: String
    public var APIURL: String
    public var startDate: Date?
    public var endDate: Date
    public var expectedUploadCount: Int
    public var uploadCount: Int
    public var errorMessage: String?
    public var uploadTimeSeconds: TimeInterval
    public var numberOfAPICalls: Int
    public var totalBytes: Int
    
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
    
    public static var databaseTableName: String = "data_upload"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
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

public extension FXBDataUpload {
    static func mock() -> FXBDataUpload {
        return FXBDataUpload(
            ts: Date.now,
            tableName: "A Table",
            database: "influxDB",
            APIURL: "https://google.com",
            startDate: Date.now.addingTimeInterval(-100),
            endDate: Date.now.addingTimeInterval(-30),
            expectedUploadCount: 100,
            uploadCount: 100,
            uploadTimeSeconds: 0.001,
            numberOfAPICalls: 1,
            totalBytes: 101
        )
    }
}
