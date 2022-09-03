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
    
    public func getTotalRecords(from start: Date?, to end: Date?, uploaded: Bool = false) async throws -> Int {
        let dtns = await dynamicTableNames()
        
        return try await dbMgr.dbQueue.read { db -> Int in
            var total = 0
            for tbl in dtns {
                var q = """
                    SELECT COUNT(id)
                    FROM \(tbl)
                    WHERE
                """
                
                if let start = start, let end = end {
                    q += "\nts >= '\(start.SQLiteFormat())' AND ts < '\(end.SQLiteFormat())' AND"
                } else if let start = start {
                    q += "\nts >= '\(start.SQLiteFormat())' AND"
                } else if let end = end {
                    q += "\nts < '\(end.SQLiteFormat())' AND"
                }
                
                q += "\nuploaded == \(uploaded);"
                
                total += try Int.fetchOne(
                    db,
                    sql: q
                ) ?? 0
            }
            
            var locReq = FXBLocation.all()
            if let start = start, let end = end {
                locReq = locReq.filter(Column("ts") >= start && Column("ts") < end)
            }
            total += try locReq.filter(Column("uploaded") == uploaded).fetchCount(db)
            
            
            var hrReq = FXBHeartRate.all()
            if let start = start, let end = end {
                hrReq = hrReq.filter(Column("created_at") >= start && Column("created_at") < end)
            }
            total += try hrReq.filter(Column("uploaded") == uploaded).fetchCount(db)
            
            return total
        }
    }
    
    internal func getTotalRecords(for tableName: String, from start: Date?=nil, to end: Date?=nil, uploaded: Bool = false) async throws -> Int {
        return try await dbMgr.dbQueue.read { db -> Int in
            var q = """
                SELECT COUNT(id)
                FROM \(tableName)
                WHERE
            """
            
            if let start = start, let end = end {
                q += "\nts >= '\(start.SQLiteFormat())' AND ts < '\(end.SQLiteFormat())' AND"
            } else if let start = start {
                q += "\nts >= '\(start.SQLiteFormat())' AND"
            } else if let end = end {
                q += "\nts < '\(end.SQLiteFormat())' AND"
            }
            
            q += "\nuploaded == \(uploaded);"
            
            return try Int.fetchOne(db, sql: q) ?? 0
        }
    }
    
    public func getDistinctValuesForColumn(for column_name: String, table_name: String) async -> [String]? {
        var distinctValues: [String] = []
        try? await dbMgr.dbQueue.read { db in
            let q = """
                    SELECT DISTINCT \(column_name)
                    FROM \(table_name)
                """
            let queryResult = try Row.fetchAll(db, sql: q)
            distinctValues = queryResult.map({ $0[column_name] })
            //                for eachEntry in queryResult {
            //                    if let doubleValue = Double.fromDatabaseValue(eachEntry[column_name]) {
            //                        distinctValues.append(String(doubleValue))
            //                    }
            //                }
            //                return distinctValues
        }
        return distinctValues
    }
}
