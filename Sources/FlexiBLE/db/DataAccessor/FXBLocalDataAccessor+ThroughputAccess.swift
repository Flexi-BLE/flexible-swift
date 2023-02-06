//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: - Public
public extension FXBLocalDataAccessor {
    
    class ThroughputAccess {
        private var transactionalManager: TransactionalDBConnectionManager
        
        internal init(transactionalManager: TransactionalDBConnectionManager) {
            self.transactionalManager = transactionalManager
        }
        
        func get(
            from start: Date?=nil,
            to end: Date?=nil,
            deviceName: String?=nil,
            uploaded: Bool?=nil,
            limit: Int=1000
        ) async throws -> [FXBHeartRate] {
            
            
            return try await transactionalManager.getTableRecords(
                startDate: start,
                endDate: end,
                deviceName: deviceName,
                uploaded: uploaded,
                limit: limit
            )
        }
    }
}


// MARK: - Internal
internal extension FXBLocalDataAccessor.ThroughputAccess {
    
    func record(_ rec: inout FXBThroughput) throws {
        
        let db = try transactionalManager.latestDB()
        try transactionalManager.connection(for: db).write({ db in
            try rec.insert(db)
        })
        
    }
    
}

