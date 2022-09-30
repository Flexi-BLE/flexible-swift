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
    
    public func getDistinctValuesForColumn(for column_name: String, table_name: String) async -> [String]? {
        return try? await dbMgr.dbQueue.read { db -> [String] in
            var distinctValues: [String] = []
            let q = """
                    SELECT DISTINCT \(column_name)
                    FROM \(table_name)_data
                """
            let queryResult = try Row.fetchAll(db, sql: q)
            for eachEntry in queryResult {
                if let doubleValue = Double.fromDatabaseValue(eachEntry[column_name]) {
                    distinctValues.append(String(doubleValue))
                }
            }
            return distinctValues
        }
    }
    
    public func getDatabaseValuesWithQuery(sqlQuery: String, columnName: String, propertyName: String) async -> (queryData:[(mark: String, data: [(ts: Date, val: Double)])], maxVal: Double, minValue: Double, lastRecordTime: Date) {
        do {
            return try await dbMgr.dbQueue.read({ db in
                var databaseResult: [(mark: String, data:[(ts: Date, val: Double)])] = []
                var minValue = Double.greatestFiniteMagnitude
                var maxValue = -Double.greatestFiniteMagnitude
                var lastRecordedTimestamp = Date.now
                
                var dataset: [(ts: Date, val: Double)] = []
                
                let fetchedRows = try Row.fetchAll(db, sql: sqlQuery)
                if fetchedRows.count == 0 {
                    return ([],0.0,0.0, lastRecordedTimestamp)
                }
                for row in fetchedRows {
                    let timestamp: Date = row["ts"]
                    let value: Double = row[columnName]
                    
                    maxValue = max(maxValue, value)
                    minValue = min(minValue, value)
                    lastRecordedTimestamp = timestamp
                    
                    dataset.append((ts: timestamp, val: value))
                }
                databaseResult.append((mark: "\(propertyName)-\(columnName)", data: dataset))
                return (databaseResult, maxValue, minValue, lastRecordedTimestamp)
            })
        }  catch { return ([],0.0,0.0, Date.now)}
    }
    
    public func getRecordsForQuery(sqlQuery: String, tableName: String) async -> [GenericRow]? {
        do {
            let tableInfo = try await FXBDBManager
                .shared.dbQueue.read({ db -> [FXBTableInfo] in
                    let result = try Row.fetchAll(db, sql: "PRAGMA table_info(\(tableName))")
                    return result.map({ FXBTableInfo.make(from: $0) })
                })
            
            let records = try await FXBDBManager.shared
                .dbQueue.read({ db -> [GenericRow] in
                return try Row
                    .fetchAll(db, sql: sqlQuery)
                    .map({ GenericRow(metadata: tableInfo, row: $0) })
            })
            return records
        } catch(let errMessage) {
            print(errMessage)
            // Error ?
        }
        return nil
    }
}
