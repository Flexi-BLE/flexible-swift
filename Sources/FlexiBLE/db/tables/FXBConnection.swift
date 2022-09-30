//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 8/7/22.
//

import Foundation
import GRDB

public struct FXBConnection: Codable {
    public var id: Int64?
    public var deviceType: String
    public var deviceName: String
    
    public var specId: Int64
    
    public var specificationIdString: String?
    public var specificationVersion: String?
    public var latestReferenceDate: Date?
    
    public var connectedAt: Date?
    public var disconnectedAt: Date?
    
    public var ts: Date
    public var uploaded: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceType = "device_type"
        case deviceName = "device_name"
        case specId = "spec_id"
        case specificationIdString = "specification_id_string"
        case specificationVersion = "specification_version"
        case latestReferenceDate = "latest_reference_date"
        case connectedAt = "connected_at"
        case disconnectedAt = "disconnected_at"
        case ts
        case uploaded
    }
    
    init(deviceType: String, deviceName: String, specId: Int64) {
        self.deviceType = deviceType
        self.deviceName = deviceName
        self.specId = specId

        self.ts = Date()
    }
}

extension FXBConnection: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let deviceType = Column(CodingKeys.deviceType)
        static let deviceName = Column(CodingKeys.deviceName)
        static let specId = Column(CodingKeys.specId)
        static let specificationIdString = Column(CodingKeys.specificationIdString)
        static let specificationVersion = Column(CodingKeys.specificationVersion)
        static let latestReferenceDate = Column(CodingKeys.latestReferenceDate)
        static let connectedAt = Column(CodingKeys.connectedAt)
        static let disconnectedAt = Column(CodingKeys.disconnectedAt)
        static let uploaded = Column(CodingKeys.uploaded)
        static let ts = Column(CodingKeys.ts)
    }
    
    mutating public func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    public static var databaseTableName: String = "connection"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.deviceType.stringValue, .text)
        table.column(CodingKeys.deviceName.stringValue, .text)
        table.column(CodingKeys.specId.stringValue, .integer)
            .references(FXBSpecTable.databaseTableName)
        table.column(CodingKeys.specificationIdString.stringValue, .text)
        table.column(CodingKeys.specificationVersion.stringValue, .text)
        table.column(CodingKeys.latestReferenceDate.stringValue, .date)
        table.column(CodingKeys.connectedAt.stringValue, .datetime)
        table.column(CodingKeys.disconnectedAt.stringValue, .datetime)
        table.column(CodingKeys.uploaded.stringValue, .boolean)
        table.column(CodingKeys.ts.stringValue, .date).indexed()
    }
}
