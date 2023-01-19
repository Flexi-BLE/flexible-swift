//
//  FXBMainDBMigrator.swift
//  
//
//  Created by Blaine Rothrock on 1/17/23.
//

import Foundation
import GRDB

import Foundation
import GRDB

/// Handles GRDB migrations on schema changes
internal class FXBMainDBMigrator{
    var migrator = DatabaseMigrator()
    
    init() {
        self.migrator.registerMigration("v1") { db in
            
            try? db.create(
                table: FXBDataStreamTable.databaseTableName,
                ifNotExists: true,
                body: FXBDataStreamTable.create
            )
            dbLog.debug("created main database table: \(FXBDataStreamTable.databaseTableName)")
            
            try? db.create(
                table: FXBExperiment.databaseTableName,
                ifNotExists: true,
                body: FXBExperiment.create
            )
            dbLog.debug("created main database table: \(FXBExperiment.databaseTableName)")
            
            try? db.create(
                table: FXBConnection.databaseTableName,
                ifNotExists: true,
                body: FXBConnection.create
            )
            dbLog.debug("created main database table: \(FXBConnection.databaseTableName)")
            
            try? db.create(
                table: FXBTimestamp.databaseTableName,
                ifNotExists: true,
                body: FXBTimestamp.create
            )
            dbLog.debug("created main database table: \(FXBTimestamp.databaseTableName)")
            
            try? db.create(
                table: TransactionalDatabase.databaseTableName,
                ifNotExists: true,
                body: TransactionalDatabase.create
            )
            dbLog.debug("created main database table: \(TransactionalDatabase.databaseTableName)")
        }
    }
    
    func migrate(_ writer: DatabaseWriter, spec: FXBSpec) {
        try? self.migrator.migrate(writer, upTo: "v1")
        
        for device in spec.devices {
            for dataStream in device.dataStreams {
                try? createDynamicConfigurationTable(from: dataStream, with: writer)
                try? createDynamicTableRecord(from: dataStream, with: writer, deviceName: device.name)
            }
        }
    }
    
    func createDynamicConfigurationTable(
        from metadata: FXBDataStream,
        with writer: DatabaseWriter,
        forceNew: Bool=false
    ) throws {
        
        let tableName = "\(FXBDatabaseDirectory.tableName(from: metadata.name))_config"
        
        try writer.write { db in
            try? db.drop(table: tableName)
            try db.create(table: tableName) { t in
                
                t.autoIncrementedPrimaryKey("id")
                t.column("ts", .datetime).defaults(to: Date()).indexed()
                t.column("uploaded", .boolean).defaults(to: false)
//                t.column("spec_id", .integer)
//                    .references(FXBSpecTable.databaseTableName)
                t.column("device", .text)
                
                for cv in metadata.configValues {
                    t.column(cv.name, .text).notNull()
                }
            }
        }
        
    }
    
    func createDynamicTableRecord(
        from dataStream: FXBDataStream,
        with writer: DatabaseWriter,
        deviceName: String,
        forceNew: Bool = false
    ) throws {
        
        try writer.write({ db in
            let exists = try !FXBDataStreamTable.filter(FXBDataStreamTable.Columns.name == dataStream.name).isEmpty(db)

            if !exists || forceNew {
                let record = FXBDataStreamTable(spec: dataStream, deviceName: deviceName)
                try record.insert(db)
            }
        })
        
    }
}

