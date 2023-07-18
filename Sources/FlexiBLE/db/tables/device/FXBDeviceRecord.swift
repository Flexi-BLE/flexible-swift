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
    public var role: FlexiBLEDeviceRole = .unknown
    public var referenceEpoch: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceType = "device_type"
        case deviceName = "device_name"
        case connectedAt = "connected_at"
        case disconnectedAt = "disconnected_at"
        case role
        case referenceEpoch = "reference_epoch"
    }
    
    init(deviceType: String, deviceName: String, connectedAt: Date, role: FlexiBLEDeviceRole) {
        self.deviceType = deviceType
        self.deviceName = deviceName
        self.connectedAt = connectedAt
        self.role = role
        self.referenceEpoch = 0.0
    }
    
    var isConnected: Bool {
        return disconnectedAt == nil
    }
    
    var referenceDate: Date {
        return Date(timeIntervalSince1970: referenceEpoch)
    }
    
    mutating func set(referenceDate date: Date) {
        self.referenceEpoch = date.timeIntervalSince1970 as Double
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
        static let referenceEpoch = Column(CodingKeys.referenceEpoch)
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
        table.column(CodingKeys.referenceEpoch.stringValue, .double)
    }
}
