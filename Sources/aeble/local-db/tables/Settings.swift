//
//  File.swift
//  
//
//  Created by blaine on 3/9/22.
//

import Foundation
import GRDB

internal struct Settings: Codable {
    var id: Int64?
    var deviceId: String
    var userId: String
    var apiURL: URL
    var uploadBatch: Int
    var peripheralConfigurationId: String
    var useRemoteServer: Bool
    var sensorDataBucketName: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case userId = "user_id"
        case apiURL = "api_url"
        case uploadBatch = "upload_batch"
        case peripheralConfigurationId = "peripheral_configuration_id"
        case useRemoteServer = "use_remote_server"
        case sensorDataBucketName = "sensor_data_bucket_name"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static var defaults: Settings {
        return Settings(
            id: nil,
            deviceId: "--test--",
            userId: "--test--",
            apiURL: URL(string: "https://aeble.xyz")!,
            uploadBatch: 10000,
            peripheralConfigurationId: "local default",
            useRemoteServer: true,
            sensorDataBucketName: "dump",
            isActive: true,
            createdAt: Date.now,
            updatedAt: nil
        )
    }
}

extension Settings: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let deviceId = Column(CodingKeys.deviceId)
        static let userId = Column(CodingKeys.userId)
        static let apiURL = Column(CodingKeys.apiURL)
        static let uploadBatch = Column(CodingKeys.uploadBatch)
        static let peripheralconfigurationId = Column(CodingKeys.peripheralConfigurationId)
        static let useRemoteServer = Column(CodingKeys.useRemoteServer)
        static let sensorDataBucketName = Column(CodingKeys.sensorDataBucketName)
        static let isActive = Column(CodingKeys.isActive)
        static let createdAt = Column(CodingKeys.createdAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        self.id = rowID
    }
    
    static var databaseTableName: String = "settings"
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.deviceId.stringValue, .text)
        table.column(CodingKeys.userId.stringValue, .text)
        table.column(CodingKeys.apiURL.stringValue, .text)
        table.column(CodingKeys.uploadBatch.stringValue, .integer)
        table.column(CodingKeys.peripheralConfigurationId.stringValue, .text)
        table.column(CodingKeys.useRemoteServer.stringValue, .boolean)
        table.column(CodingKeys.sensorDataBucketName.stringValue, .text)
        table.column(CodingKeys.isActive.stringValue, .boolean)
        table.column(CodingKeys.createdAt.stringValue, .datetime)
        table.column(CodingKeys.updatedAt.stringValue, .datetime)
    }
}
