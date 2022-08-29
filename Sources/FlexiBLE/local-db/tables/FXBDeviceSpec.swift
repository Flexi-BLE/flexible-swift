//
//  File.swift
//  
//
//  Created by blaine on 3/9/22.
//

import Foundation
import GRDB

internal struct FXBDeviceSpec: Codable {
    var id: Int64?
    var externalId: String
    var data: Data
    var createdAt: Date
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case externalId = "external_id"
        case data
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension FXBDeviceSpec: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let externalId = Column(CodingKeys.externalId)
        static let data = Column(CodingKeys.data)
        static let createdAt = Column(CodingKeys.createdAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        self.id = rowID
    }
    
    static var databaseTableName: String = "peripheral_configuration"
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.externalId.stringValue, .text).notNull(onConflict: .fail)
        table.column(CodingKeys.data.stringValue, .blob).notNull(onConflict: .fail)
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date.now)
        table.column(CodingKeys.updatedAt.stringValue, .datetime)
    }
}
