//
//  FXBLocalDataAccessor+DataUploadAccess.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import Combine
import GRDB

// MARK: - Public
public extension FXBLocalDataAccessor {
    
    class DataUploadAccess {
        private var transactionalManager: TransactionalDBConnectionManager
        
        internal init(transactionalManager: TransactionalDBConnectionManager) {
            self.transactionalManager = transactionalManager
        }
        
        public func publisher(limit: Int=25, table: String?=nil) throws -> AnyPublisher<[FXBDataUpload], Error> {
            return ValueObservation
                .tracking { db in
                    if let table = table {
                        return try FXBDataUpload
                            .filter(FXBDataUpload.Columns.tableName == table)
                            .order(FXBDataUpload.Columns.ts.desc)
                            .limit(limit)
                            .fetchAll(db)
                    } else {
                        return try FXBDataUpload
                            .limit(limit)
                            .order(FXBDataUpload.Columns.ts.desc)
                            .fetchAll(db)
                    }
                }
                .publisher(
                    in: try transactionalManager.connection(for: transactionalManager.latestDB()),
                    scheduling: .immediate
                )
                .eraseToAnyPublisher()
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
                        q = q.filter(Column("ts") >= startDate.dbPrimaryKey)
                    }
        
                    if let endDate = end {
                        q = q.filter(Column("ts") <= endDate.dbPrimaryKey)
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
