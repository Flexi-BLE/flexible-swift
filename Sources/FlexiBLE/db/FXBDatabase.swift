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
    
    init(specification: FXBSpec, mainDBPath: URL, transactionalDBPath: URL) {
        self.spec = specification
        
        dbLog.info("starting database for \(self.spec.id) @ \(mainDBPath.absoluteString)")
         
        var configuration = Configuration()
        configuration.qos = DispatchQoS.userInitiated
        
        do {
            
            // create the main connection
            mainConnection = try DatabaseQueue(
                path: mainDBPath.absoluteString,
                configuration: configuration
            )
            
            transactionalDBMgr = TransactionalDBConnectionManager(
                withMainConnection: mainConnection,
                spec: spec,
                dbPath: transactionalDBPath
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
