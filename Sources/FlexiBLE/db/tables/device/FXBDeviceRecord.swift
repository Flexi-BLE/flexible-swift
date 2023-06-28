//
//  FXBDeviceRecord.swift
//  
//
//  Created by Blaine Rothrock on 6/27/23.
//

import Foundation
import GRDB

public struct FXBDeviceRecord: Codable {
    
    public var id: Int64?
    public let deviceType: String
    public let deviceName: String
    public let connectedAt: Date
    public var disconnectedAt: Date?=nil
    public var role: FlexiBLEDeviceRole
    public var referenceDate: Date?=nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceType = "device_type"
        case deviceName = "device_name"
        case connectedAt = "connected_at"
        case disconnectedAt = "disconnected_at"
        case role
        case referenceDate = "reference_date"
    }
    
    init(deviceType: String, deviceName: String, connectedAt: Date, role: FlexiBLEDeviceRole) {
        self.deviceType = deviceType
        self.deviceName = deviceName
        self.connectedAt = connectedAt
        self.role = role
    }
    
    var isConnected: Bool {
        return disconnectedAt == nil
    }
}

extension FXBDeviceRecord: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let deviceType = Column(CodingKeys.deviceType)
        static let deviceName = Column(CodingKeys.deviceName)
        static let connectedAt = Column(CodingKeys.connectedAt)
        static let disconntedAt = Column(CodingKeys.disconnectedAt)
        static let role = Column(CodingKeys.role)
        static let referenceDate = Column(CodingKeys.referenceDate)
    }
    
    mutating public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    public static var databaseTableName: String = "device"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.deviceType.stringValue, .text).notNull()
        table.column(CodingKeys.deviceName.stringValue, .text).notNull()
        table.column(CodingKeys.connectedAt.stringValue, .datetime).notNull()
        table.column(CodingKeys.disconnectedAt.stringValue, .datetime)
        table.column(CodingKeys.role.stringValue, .integer).indexed()
        table.column(CodingKeys.referenceDate.stringValue, .datetime).indexed()
    }
}
