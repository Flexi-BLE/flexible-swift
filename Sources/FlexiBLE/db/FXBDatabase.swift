//
//  FXBDatabase.swift
//  
//
//  Created by Blaine Rothrock on 1/17/23.
//

import Foundation
import GRDB

final class FXBDatabase {
    
    internal let spec: FXBSpec
    
    internal var mainConnection: DatabaseQueue
    private let mainMigrator = FXBMainDBMigrator()
    
    internal let transactionalDBMgr: TransactionalDBConnectionManager
    
    internal var transactionalDB: TransactionalDatabase
    internal var transactionalConnection: DatabaseWriter
    
    init(for profile: FlexiBLEProfile) {
        self.spec = profile.specification
        
        dbLog.info("starting database for \(self.spec.id) @ \(profile.mainDatabasePath.absoluteString)")
         
        var configuration = Configuration()
        configuration.qos = DispatchQoS.userInitiated
        
        do {
            
            // create the main connection
            mainConnection = try DatabaseQueue(
                path: profile.mainDatabasePath.absoluteString,
                configuration: configuration
            )
            
            transactionalDBMgr = TransactionalDBConnectionManager(
                withMainConnection: mainConnection,
                spec: spec,
                dbPath: profile.transactionalDatabasesBasePath
            )
            dbLog.info("established main database connection")
            
            // migrate or create the database
            mainMigrator.migrate(mainConnection, spec: spec)
        
            // find or create the transactional database, create connection
            transactionalDB = try transactionalDBMgr.latestDB()
            transactionalConnection = try transactionalDBMgr.connection(for: transactionalDB)
            
        } catch {
            fatalError("Unable to initialize main database: \(error.localizedDescription)")
        }
    }
}
