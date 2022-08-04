//
//  LocalQueryReadOnly.swift
//  
//
//  Created by Blaine Rothrock on 8/3/22.
//

import Foundation
import GRDB

public struct LocalQueryReadOnly {
    
    let dbMgr = AEBLEDBManager.shared
    
    // MARK: - Location
    public func GetLocations(
        startDate: Date=Date(),
        endDate: Date?=nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> [Location] {
        
        let locations = try await dbMgr.dbQueue.read { db -> [Location] in
            var q: QueryInterfaceRequest<Location> = Location
                .filter(Column("timestamp") >= startDate)
            
            if let endDate = endDate {
                q = q.filter(Column("timestamp") <= endDate)
            }
            
            if let limit = limit {
                q = q.limit(limit, offset: offset)
            }
            
            return try q.fetchAll(db)
        }
        
        return locations
    }
}
