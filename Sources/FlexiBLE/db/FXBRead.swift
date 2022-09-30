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
                .filter(Column("ts") >= startDate)
            
            if let endDate = endDate {
                q = q.filter(Column("ts") <= endDate)
            }
            
            if let limit = limit {
                q = q.limit(limit, offset: offset)
            }
            
            return try q.fetchAll(db)
        }
        
        return locations
    }
    
    // MARK: - spec
    public func spec(by id: Int64) async -> FXBSpec? {
        if id == FlexiBLE.shared.specId { return FlexiBLE.shared.spec }
        do {
            let specTableRecord = try await dbMgr.dbQueue.read { db in
                return try FXBSpecTable.fetchOne(db, key: id)
            }
            
            if let specTableRecord = specTableRecord {
                return try Data.sharedJSONDecoder.decode(FXBSpec.self, from: specTableRecord.data)
            }
        } catch {
            pLog.error("unable to query spec by id \(id): \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Connections
    public func connectionRecords(connectedOnly: Bool = false) async -> [FXBConnection] {
        do {
            return try await dbMgr.dbQueue.read { db -> [FXBConnection] in
                if connectedOnly {
                    return try FXBConnection
                        .filter(Column(FXBConnection.CodingKeys.disconnectedAt.stringValue) == nil)
                        .order(literal: "connected_at DESC")
                        .fetchAll(db)
                }
                return try FXBConnection
                    .order(literal: "connected_at DESC")
                    .fetchAll(db)
            }
        } catch {
            pLog.error("unable to query connection records \(error.localizedDescription)")
            return []
        }
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
    
    public func getTotalRecords(
        for tableName: String,
        from start: Date?=nil,
        to end: Date?=nil,
        deviceName: String?=nil,
        uploaded: Bool? = false
    ) async throws -> Int {
        return try await dbMgr.dbQueue.read { db -> Int in
            var q = """
                SELECT COUNT(id)
                FROM \(tableName)
            """
            if !(start == nil && end == nil && deviceName == nil && uploaded == nil) {
                q += "\nWHERE "
            }
            
            if let deviceName = deviceName {
                q += "\ndevice = '\(deviceName)'"
                if (uploaded != nil || start != nil || end != nil) {
                    q += " AND"
                }
            }
            
            if let start = start, let end = end {
                q += "\nts BETWEEN '\(start.SQLiteFormat())' AND '\(end.SQLiteFormat())'"
                if (uploaded != nil) { q += " AND" }
            } else if let start = start {
                q += "\nts >= '\(start.SQLiteFormat())'"
                if (uploaded != nil) { q += " AND" }
            } else if let end = end {
                q += "\nts < '\(end.SQLiteFormat())'"
                if (uploaded != nil) { q += " AND" }
            }
            
            if let uploaded = uploaded {
                q += "\nuploaded == \(uploaded);"
            }
            
            return try Int.fetchOne(db, sql: q) ?? 0
        }
    }
}
