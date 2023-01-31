//
//  FXBTransactionalDBCreator.swift
//  
//
//  Created by Blaine Rothrock on 1/17/23.
//

import Foundation
import GRDB

internal enum FXBTransactionalDBCreator {
    static internal func create(with writer: DatabaseWriter, spec: FXBSpec) throws {
        try writer.write { db in
            try db.create(
                table: FXBLocation.databaseTableName,
                ifNotExists: true,
                body: FXBLocation.create
            )
            
            try db.create(
                table: FXBHeartRate.databaseTableName,
                ifNotExists: true,
                body: FXBHeartRate.create
            )
            
            try db.create(
                table: FXBThroughput.databaseTableName,
                ifNotExists: true,
                body: FXBThroughput.create
            )
            
            try db.create(
                table: FXBDataUpload.databaseTableName,
                ifNotExists: true,
                body: FXBDataUpload.create
            )
        }
        
        let allDataStreams = spec.devices.reduce([], { $0 + $1.dataStreams })
        for ds in allDataStreams {
            try Self.createDynamicDataTable(from: ds, with: writer)
        }
    }
    
    static internal func createDynamicDataTable(
        from def: FXBDataStream,
        with connection: DatabaseWriter,
        forceNew: Bool=false
    ) throws {
        let name = DBUtility.tableName(from: def.name)
        let dataTableName = "\(name)_data"
        
        try connection.write { db in
            try? db.drop(table: dataTableName)
            try db.create(table: dataTableName) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("created_at", .datetime).defaults(to: Date())
                t.column("uploaded", .boolean).defaults(to: false)
                t.column("device", .text)
                
                for dv in def.dataValues {
                    t.column(dv.name, .double)
                }
                
                t.column("ts", .date).notNull().indexed()
                switch def.precision {
                case .ms: break
                case .us: t.column("ts_precision", .integer).notNull().indexed()
                }
            }
        }
    }
}
