//
//  FXBLocalDataAccessor+DataUploadAccess.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: - Public
public extension FXBLocalDataAccessor {
    
    class DataUploadAccess {
        private var transactionalManager: TransactionalDBConnectionManager
        
        internal init(transactionalManager: TransactionalDBConnectionManager) {
            self.transactionalManager = transactionalManager
        }
        
        func get(
            from start: Date?=nil,
            to end: Date?=nil
        ) async throws -> [FXBDataUpload] {
            
            
            let dbs = try transactionalManager.getDbs(between: start, and: end)
            var records: [FXBDataUpload] = []
            for db in dbs {
                let connection = try transactionalManager.connection(for: db)
                records += try await connection.read { db in
                    var q: QueryInterfaceRequest = FXBDataUpload.all()
                    
                    if let startDate = start {
                        q = q.filter(Column("ts") >= startDate)
                    }
        
                    if let endDate = end {
                        q = q.filter(Column("ts") <= endDate)
                    }
                    
                    return try q.fetchAll(db)
                }
            }
            return records
            
        }
    }
}


// MARK: - Internal
internal extension FXBLocalDataAccessor.DataUploadAccess {
    
    func record(_ upload: inout FXBDataUpload) throws {
        
        let db = try transactionalManager.latestDB()
        try transactionalManager.connection(for: db).write({ db in
            try upload.insert(db)
        })
        
    }
    
}
