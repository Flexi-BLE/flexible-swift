//
//  LocalQueryReadOnly.swift
//  
//
//  Created by Blaine Rothrock on 8/3/22.
//

import Foundation
import GRDB

public struct FXBRead {
    
    let dbMgr = FXBDBManager.shared
    
    // MARK: - Location
    public func GetLocations(
        startDate: Date=Date(),
        endDate: Date?=nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> [FXBLocation] {
        
        let locations = try await dbMgr.dbQueue.read { db -> [FXBLocation] in
            var q: QueryInterfaceRequest<FXBLocation> = FXBLocation
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
    
    
    // MARK: - Aggregate
    internal func dynamicTableNames(active: Bool = false) async -> [String] {
        do {
            return try await dbMgr.dbQueue.read { db -> [String] in
                
                var dts: [DynamicTable]
                if active {
                    dts = try DynamicTable
                        .filter(Column(DynamicTable.CodingKeys.active.stringValue) == true)
                        .fetchAll(db)
                } else {
                    dts = try DynamicTable.fetchAll(db)
                }
                
                return dts.map({ $0.name })
            }
        } catch {
            return []
        }
    }
    
    public func GetTotalRecords(from start: Date, to end: Date) async throws -> Int {
        let dtns = await dynamicTableNames()
        
        return try await dbMgr.dbQueue.read { db -> Int in
            var total = 0
            for tbl in dtns {
                let q = """
                    SELECT COUNT(id)
                    FROM \(tbl)
                    WHERE ts >= '\(start.SQLiteFormat())' AND ts < '\(end.SQLiteFormat())'
                """
                
                total += try Int.fetchOne(
                    db,
                    sql: q
                ) ?? 0
            }
            return total
        }
    }
}
