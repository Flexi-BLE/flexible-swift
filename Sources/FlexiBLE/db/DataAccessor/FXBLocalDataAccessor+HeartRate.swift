//
//  FXBLocalDataAccessor+HeartRateAccess.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: - Public
public extension FXBLocalDataAccessor {
    
    class HeartRateAccess {
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
internal extension FXBLocalDataAccessor.HeartRateAccess {
    
    func record(_ hr: inout FXBHeartRate) throws {
        
        let db = try transactionalManager.latestDB()
        try transactionalManager.connection(for: db).write({ db in
            try hr.insert(db)
        })
        
    }
    
}
