//
//  DBMigrator.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import GRDB

/// Handles GRDB migrations on schema changes
internal class FXBDBMigrator {
    var migrator = DatabaseMigrator()
    
    init() {        
        self.migrator.registerMigration("v1") { db in
            
            try? db.create(
                table: FXBSpecTable.databaseTableName,
                ifNotExists: true,
                body: FXBSpecTable.create
            )
            
            try? db.create(
                table: DynamicTable.databaseTableName,
                ifNotExists: true,
                body: DynamicTable.create
            )
            
            try? db.create(
                table: FXBExperiment.databaseTableName,
                ifNotExists: true,
                body: FXBExperiment.create
            )
            
            try? db.create(
                table: FXBLocation.databaseTableName,
                ifNotExists: true,
                body: FXBLocation.create
            )
            
            try? db.create(
                table: FXBThroughput.databaseTableName,
                ifNotExists: true,
                body: FXBThroughput.create
            )
            
            try? db.create(
                table: FXBConnection.databaseTableName,
                ifNotExists: true,
                body: FXBConnection.create
            )
            
            try? db.create(
                table: FXBTimestamp.databaseTableName,
                ifNotExists: true,
                body: FXBTimestamp.create
            )
            
            try? db.create(
                table: FXBDataUpload.databaseTableName,
                ifNotExists: true,
                body: FXBDataUpload.create
            )
        }
        
        #if DEBUG
        // Speed up development by nuking the database when migrations change
        self.migrator.eraseDatabaseOnSchemaChange = true
        #endif
    }
    
    func migrate(_ writer: DatabaseWriter) {
        try? self.migrator.migrate(writer, upTo: "v1")
    }
}
