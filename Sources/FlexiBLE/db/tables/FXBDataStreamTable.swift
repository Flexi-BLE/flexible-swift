//
//  FXBDataStreamTable.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import GRDB

internal struct FXBDataStreamTable: Codable {
    var id: Int64?
    var name: String
    var tableName: String
    var deviceName: String
    var spec: Data?
    var createdAt: Date
    
    init(spec: FXBDataStream, deviceName: String) {
        self.name = spec.name
        self.tableName = FXBDatabaseDirectory.tableName(from: spec.name)
        self.spec = try? Data.sharedJSONEncoder.encode(spec)
        self.deviceName = deviceName
        self.createdAt = Date.now
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tableName = "table_name"
        case spec
        case deviceName = "device_name"
        case createdAt = "created_at"
    }
}

extension FXBDataStreamTable: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let tableName = Column(CodingKeys.tableName)
        static let spec = Column(CodingKeys.spec)
        static let deviceName = Column(CodingKeys.deviceName)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    static var databaseTableName: String = "data_stream"
    
    static func create(_ table: TableDefinition) {
        table.autoIncrementedPrimaryKey(CodingKeys.id.stringValue)
        table.column(CodingKeys.name.stringValue, .text).notNull().unique(onConflict: .fail).indexed()
        table.column(CodingKeys.tableName.stringValue, .text)
        table.column(CodingKeys.spec.stringValue, .blob).notNull()
        table.column(CodingKeys.createdAt.stringValue, .datetime).defaults(to: Date())
        table.column(CodingKeys.deviceName.stringValue, .text)
    }
}
