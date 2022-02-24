//
//  DBMigrator.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import GRDB

/// Handles GRDB migrations on schema changes
internal class DBMigrator {
    var migrator = DatabaseMigrator()
    
    init() {
        self.migrator.registerMigration("v1") { db in
            try? db.create(
                table: DynamicTable.databaseTableName,
                ifNotExists: true,
                body: DynamicTable.create
            )
            
            try? db.create(
                table: Event.databaseTableName,
                ifNotExists: true,
                body: Event.create
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
