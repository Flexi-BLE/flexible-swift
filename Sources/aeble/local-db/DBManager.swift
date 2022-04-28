//
//  DBManager.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import GRDB

/// Initializes and manages a local SQLite database for storing all data related to aeble, including:
public final class AEBLEDBManager {
    internal let dbQueue: DatabaseQueue
    private let migrator = DBMigrator()
    public let dbPath = AEBLEDBManager.documentDirPath()
    
    /// Create and retrurn data directory url in application file structure
    private static func documentDirPath(for dbName: String="aeble") -> URL {
        let fileManager = FileManager()
        
        do {
            let dirPath = try fileManager
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appendingPathComponent("data", isDirectory: true)
            
            try fileManager.createDirectory(at: dirPath, withIntermediateDirectories: true)
            
            return dirPath.appendingPathComponent("\(dbName).sqlite")
        } catch {
            fatalError("Unable to access document directory")
        }
    }
    
    /// parameter url: URL for SQLite database with `.sqlite` extension. Will create if does not exist.
    init() throws {
        var configuration = Configuration()
        configuration.qos = DispatchQoS.userInitiated
                    
        self.dbQueue = try DatabaseQueue(
            path: self.dbPath.path,
            configuration: configuration
        )
        
        self.migrator.migrate(self.dbQueue)
    }
    
    public func purgeUpdatedDynamicRecords() async {
        let tableNames = await activeDynamicTables()
        let statements = tableNames.map{ "DELETE FROM \($0) WHERE updated = true" }
        let sql = statements.joined(separator: "; ")
        try? await dbQueue.write({ db in
            try? db.execute(sql: sql)
        })
    }
    
    public func purgeAllDynamicRecords() async {
        let tableNames = await activeDynamicTables()
        let statements = tableNames.map{ "DELETE FROM \($0)" }
        let sql = statements.joined(separator: "; ")
        try? await dbQueue.write({ db in
            try? db.execute(sql: sql)
        })
    }
    
    public func lastDataStreamDate(for stream: AEDataStream) async -> Date? {
        do {
            return try await dbQueue.read({ (db) -> Date? in
                let q = """
                    SELECT created_at
                    FROM \(stream.name)
                    ORDER BY created_at DESC
                    LIMIT 1
                """
                let date = try Date.fetchOne(db, sql: q)
                return date
            })
        } catch {
            return nil
        }
    }
    
    public func lastDataStreamDate(for thing: AEThing) async -> Date? {
        var dates: [Date] = []
        for ds in thing.dataStreams {
            if let date = await lastDataStreamDate(for: ds) {
                dates.append(date)
            }
        }
        return dates.max()
    }
    
    public func actualRecordCount(for dataStream: AEDataStream) async -> Int {
        do {
            return try await dbQueue.read({ db in
                let q = """
                    SELECT COUNT(id) FROM \(dataStream.name)
                """
                return try Int.fetchOne(db, sql: q) ?? 0
            })
        } catch { return 0 }
    }
    
    public func actualRecordCount(for thing: AEThing) async -> Int {
        var count = 0
        for ds in thing.dataStreams {
            count += await actualRecordCount(for: ds)
        }
        return count
    }
    
    public func recordCountByIndex(for dataStream: AEDataStream) async -> Int {
        do {
            return try await dbQueue.read({ db in
                let q = """
                    SELECT MAX(id) FROM \(dataStream.name)
                """
                return try Int.fetchOne(db, sql: q) ?? 0
            })
        } catch { return 0 }
    }
    
    public func recordCountByIndex(for thing: AEThing) async -> Int {
        var count = 0
        for ds in thing.dataStreams {
            count += await recordCountByIndex(for: ds)
        }
        return count
    }
    
    public func unUploadedCount(for dataStream: AEDataStream) async -> Int {
        do {
            return try await dbQueue.read({ db in
                let q = """
                    SELECT COUNT(id)
                    FROM \(dataStream.name)
                    WHERE uploaded = 0
                """
                return try Int.fetchOne(db, sql: q) ?? 0
            })
        } catch { return 0 }
    }
    
    public func unUploadedCount(for thing: AEThing) async -> Int {
        var count = 0
        for ds in thing.dataStreams {
            count += await unUploadedCount(for: ds)
        }
        return count
    }
    
    public func meanFrequency(for dataSteam: AEDataStream, last: Int=1000) async -> Float {
        do {
            let dates: [Date] = try await dbQueue.read({ db in
                let q = """
                    SELECT created_at
                    FROM \(dataSteam.name)
                    ORDER BY created_at DESC
                    LIMIT \(last)
                """
                return try Date.fetchAll(db, sql: q)
            })
            var diffs: [Int] = []
            for i in 0..<dates.count-1 {
                let first = Int64(dates[i].timeIntervalSince1970 * 1000.0)
                let second = Int64(dates[i+1].timeIntervalSince1970 * 1000.0)
                diffs.append(Int(first - second))
            }
            
            return 1000.0 / Float(diffs.reduce(0, +) / diffs.count)
        } catch { return 0 }
    }
    
    public typealias UploadAggregate = (totalRecords: Int, success: Int, failures: Int)
    public func uploadAgg(for dataStream: AEDataStream) async -> UploadAggregate {
        do {
            return try await dbQueue.read({ db in
                let qRecs = """
                    SELECT SUM(number_of_records)
                    FROM data_upload
                    WHERE status = 'success'
                        AND measurement = '\(dataStream.name)';
                """
                let numRecords = try Int.fetchOne(db, sql: qRecs)
                
                let qSuccess = """
                    SELECT COUNT(id)
                    FROM data_upload
                    WHERE status = 'success'
                        AND measurement = '\(dataStream.name)';
                """
                let successes = try Int.fetchOne(db, sql: qSuccess)
                
                let qFailures = """
                    SELECT COUNT(id)
                    FROM data_upload
                    WHERE status = 'failure'
                        AND measurement = '\(dataStream.name)';
                """
                let failures = try Int.fetchOne(db, sql: qFailures)
                return UploadAggregate(numRecords ?? 0, successes ?? 0, failures ?? 0)
            })
        } catch { return UploadAggregate(0, 0, 0) }
    }
    
    public func uploadAgg(for thing: AEThing) async -> UploadAggregate {
        var totalRecord: Int = 0
        var successes: Int = 0
        var failures: Int = 0
        for ds in thing.dataStreams {
           let ua = await uploadAgg(for: ds)
            totalRecord += ua.totalRecords
            successes += ua.success
            failures += ua.failures
        }
        
        return UploadAggregate(totalRecord, successes, failures)
    }
    
    // MARK: - Not Public
    
    /// replace space with underscores for dynamically naming tables in SQL
    private func tableName(from name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "_").lowercased()
    }
    
    /// Inactivate a dynamically created table (update name and set active=0)
    private func replaceDynamicTable(db: Database, existingTable: DynamicTable, tableName: String, nextNum: Int) {
        let newName = "\(tableName)_\(nextNum)"
        let tableUpdateSQL = """
            UPDATE \(DynamicTable.databaseTableName)
            SET name = '\(newName)',
                active = 0
            WHERE id = \(existingTable.id!)
        """
        
        try? db.execute(sql: "ALTER TABLE `\(tableName)` RENAME TO `\(newName)`")
        try? db.execute(sql: tableUpdateSQL)
        
        let updateSchemaFlagSQL = """
            UPDATE \(newName)
            SET is_current_schema = 0;
        """
        
        try? db.execute(sql: updateSchemaFlagSQL)
        
        pLog.info("found duplicate dynamic table: renamed existing table: \(tableName)_\(nextNum)")
    }
    
    // MARK: - Database Utilities
   
    public func getTableNames() -> [String] {
        let excludedTables = ["grdb_migrations"]
        
        var tableNames: [String] = []
        
        let sql = """
            SELECT name
            FROM sqlite_schema
            WHERE
                type = 'table' AND
                name not LIKE 'sqlite_%';
        """
        
        try? dbQueue.read { db in
            let result = try Row.fetchAll(db, sql: sql)
            tableNames = result.map({ $0["name"] })
        }
    
        return tableNames.filter({ !excludedTables.contains($0) })
    }
    
    public func tableInfo(for table: String) -> [TableInfo] {
        var metadata: [TableInfo] = []
        
        let sql = """
            PRAGMA table_info('\(table)');
        """
        
        try? dbQueue.read { db in
            let result = try Row.fetchAll(db, sql: sql)
            metadata = result.map({ TableInfo.make(from: $0) })
            print(result)
        }
        
        return metadata
    }
    
    internal func dynamicTable(for table: String) async -> DynamicTable? {
        do {
            return try await dbQueue.read { db in
                return try DynamicTable.fetchOne(db, key: ["name": table])
            }
        } catch {
            return nil
        }
    }
    
    public func dataValues<T: AEDataValue & DatabaseValueConvertible>(
        for name: String,
        measurement: String,
        offset: Int = 0,
        limit: Int=100
    ) async -> [T] {
        do {
            return try await dbQueue.read({ db in
                let q = """
                    SELECT \(measurement)
                    FROM \(name)
                    ORDER BY created_at DESC
                    LIMIT \(limit)
                    OFFSET \(offset)
                """
                
                return try T.fetchAll(db, sql: q)
            })
        } catch { return [] }
    }
    
    public func data(for tableName: String, metadata: [TableInfo], offset: Int=0, limit: Int=100) async -> [GenericRow]? {
        
        let sql = """
            SELECT \(metadata.map({$0.name}).joined(separator: ", "))
            FROM \(tableName)
            ORDER BY created_at DESC
            LIMIT \(limit)
            OFFSET \(offset);
        """
        
        let data: [GenericRow]? = try? await dbQueue.read { db in
            let result = try Row.fetchAll(db, sql: sql)
            return result.map({ row in
                GenericRow(metadata: metadata, row: row)
            })
        }
        
        pLog.info("queried")
        return data
    }
    
    internal func createTable(from metadata: AEDataStream, forceNew: Bool=false) {
        let tableName = tableName(from: metadata.name)
        
        try? self.dbQueue.write { db in
            let tables = try? DynamicTable.fetchAll(db)
            
            if let table = tables?.first(where: { $0.name == metadata.name }),
               let data = table.metadata {
                
                let existingMetdata = try? Data.sharedJSONDecoder.decode(AEDataStream.self, from: data)
                if existingMetdata != metadata || forceNew {
                    replaceDynamicTable(
                        db: db,
                        existingTable: table,
                        tableName: tableName,
                        nextNum: tables!.count
                    )
                } else { return }
            }
            
            try? db.drop(table: tableName)
            try? db.create(table: tableName) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("created_at", .datetime).defaults(to: Date())
                t.column("uploaded", .boolean).defaults(to: false)
                t.column("experiment_id", .integer)
                    .indexed()
                    .references(Experiment.databaseTableName)
                t.column("is_current_schema", .boolean).defaults(to: true)
                t.column("user_id", .text).notNull(onConflict: .fail)
                
                for dv in metadata.dataValues {
                    if dv.precision > 0 {
                        t.column(dv.name, .double)
                    } else {
                        t.column(dv.name, .integer)
                    }
                }
            }
            
            let metadataData = try? Data.sharedJSONEncoder.encode(metadata)
            let dynamicTable = DynamicTable(name: tableName, metadata: metadataData)
            try? dynamicTable.insert(db)
            pLog.info("Dynamic Table Created \(tableName)")
        }
    }
    
    internal func arbInsert(
        for ds: AEDataStream,
        dataValues: [AEDataValue],
        tsValues: [AEDataValue],
        date: Date
    ) async {
        let tableName = tableName(from: ds.name)
    
        let cols = "\(ds.dataValues.map({ $0.name }).joined(separator: ", "))"
        let placeholders = "\(ds.dataValues.map({ _ in "?" }).joined(separator: ", "))"
        
        var sql = """
            INSERT INTO \(tableName)
            (\(cols), created_at, user_id) VALUES
        """
        
        var arguments: [Any] = []
        
        var tsCount = 0
        var dataCount = 0
        var dateCursor = date
        
        while dataCount < dataValues.count {
            
            for i in 0..<ds.dataValues.count {
                arguments.append(dataValues[dataCount+i])
            }
            dataCount += ds.dataValues.count
            
            let offset: Double = Double(tsValues[tsCount] as! Int)
            let d = dateCursor.addingTimeInterval(TimeInterval(offset / 1000.0))
            arguments.append(d)
            dateCursor = d
            
            tsCount += 1
            
            arguments.append("blop")
            sql += "(\(placeholders), ?, ?), "
        }
        
        sql.removeLast(2)
        sql += ";"
        
        do {
            try await self.dbQueue.write { [sql, arguments] db in
                try db.execute(
                    sql: sql,
                    arguments: StatementArguments(arguments) ?? StatementArguments()
                )
            }
        } catch {
            bleLog.error("ERROR INSERT BLE RECORDS: \(error.localizedDescription)")
        
        }
    }
    
    internal func activeDynamicTables() async -> [String] {
        do {
            return try await self.dbQueue.read { db -> [String] in
                let dts = try DynamicTable
                    .filter(Column(DynamicTable.CodingKeys.active.stringValue) == true)
                    .fetchAll(db)
                
                return dts.map({ $0.name })
            }
        } catch {
            return []
        }
    }
}
