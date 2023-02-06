//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: Public
public extension FXBLocalDataAccessor {
    
    class LocationAccess {
        private var transactionalManager: TransactionalDBConnectionManager
        
        internal init(transactionalManager: TransactionalDBConnectionManager) {
            self.transactionalManager = transactionalManager
        }
        
        public func get(
            from start: Date?=nil,
            to end: Date?=nil,
            deviceName: String?=nil,
            uploaded: Bool?=nil,
            limit: Int=1000
        ) async throws -> [FXBLocation] {
            
            
            return try await transactionalManager.getTableRecords(
                startDate: start,
                endDate: end,
                deviceName: deviceName,
                uploaded: uploaded,
                limit: limit
            )
        }
        
        public func record(_ loc: inout FXBLocation) throws {
            
            let db = try transactionalManager.latestDB()
            try transactionalManager.connection(for: db).write({ db in
                try loc.insert(db)
            })
            
        }
    }
}

// MARK: - Internal
internal extension FXBLocalDataAccessor.LocationAccess {
    
}
