//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 8/7/22.
//

import Foundation
import GRDB

public struct FXBConnection: Codable {
    public enum Status: String, Codable {
        case connected
        case disconnected
    }
    
    public var id: Int64?
    public var device: String
    public var status: Status
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case device
        case status
        case createdAt = "created_at"
    }
    
    init(device: String, status: Status) {
        self.device = device
        self.status = status
        self.createdAt = Date()
    }
}

extension FXBConnection: TableRecord, FetchableRecord, MutablePersistableRecord {
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let device = Column(CodingKeys.device)
        static let status = Column(CodingKeys.status)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    mutating public func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    public static var databaseTableName: String = "connection"
    
    internal static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.device.stringValue, .text)
        table.column(CodingKeys.status.stringValue, .text)
        table.column(CodingKeys.createdAt.stringValue, .datetime)
    }
}
