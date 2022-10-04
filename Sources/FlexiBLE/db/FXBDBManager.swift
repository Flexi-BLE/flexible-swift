//
//  FXBDBManager.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import GRDB

/// Initializes and manages a local SQLite database for storing all data related to aeble, including:
public final class FXBDBManager {
    
    internal static var shared = FXBDBManager()
    
    internal let dbQueue: DatabaseQueue
    private let migrator = FXBDBMigrator()
    public let dbPath = FXBDBManager.documentDirPath()
    
    /// Create and retrurn data directory url in application file structure
    private static func documentDirPath(for dbName: String="aeble") -> URL {
        let fileManager = FileManager()
        
        do {
            let dirPath = try fileManager
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appendingPathComponent("resources", isDirectory: true)
            
            try fileManager.createDirectory(at: dirPath, withIntermediateDirectories: true)
            
            return dirPath.appendingPathComponent("\(dbName).sqlite")
        } catch {
            fatalError("Unable to access document directory")
        }
    }
    
    /// parameter url: URL for SQLite database with `.sqlite` extension. Will create if does not exist.
    private init() {        
        var configuration = Configuration()
        configuration.qos = DispatchQoS.userInitiated
        
        #if DEBUG
        // Protect sensitive information by enabling verbose debugging in DEBUG builds only
//        Bundle.module.copyFilesFromBundleToDocumentsFolderWith(fileName: "aeble.sqlite", in: "resources")
        configuration.publicStatementArguments = true

        #endif
                    
        do {
            self.dbQueue = try DatabaseQueue(
                path: self.dbPath.path,
                configuration: configuration
            )
            
            self.migrator.migrate(self.dbQueue)
        } catch {
            fatalError("cannot create database")
        }
        
        do {
            try self.dbQueue.write { db in
                let sql = """
                    UPDATE \(FXBConnection.databaseTableName)
                    SET \(FXBConnection.CodingKeys.disconnectedAt.stringValue) = '\(Date.now.SQLiteFormat())'
                    WHERE \(FXBConnection.CodingKeys.disconnectedAt.stringValue) IS NULL;
                """
                try db.execute(sql: sql)
            }
        } catch {
            pLog.error("unable to update handing connection records: \(error.localizedDescription)")
        }
    }
    
    public func lastDataStreamDate(for stream: FXBDataStream) async -> Date? {
        do {
            return try await dbQueue.read({ (db) -> Date? in
                let q = """
                    SELECT ts
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
    
    public func lastDataStreamDate(for thing: FXBDeviceSpec) async -> Date? {
        var dates: [Date] = []
        for ds in thing.dataStreams {
            if let date = await lastDataStreamDate(for: ds) {
                dates.append(date)
            }
        }
        return dates.max()
    }
    
    public func actualRecordCount(for dataStream: FXBDataStream) async -> Int {
        do {
            return try await dbQueue.read({ db in
                let q = """
                    SELECT COUNT(id) FROM \(dataStream.name)
                """
                return try Int.fetchOne(
                    db,
                    sql: q
                ) ?? 0
            })
        } catch { return 0 }
    }
    
    public func actualRecordCount(for thing: FXBDeviceSpec) async -> Int {
        var count = 0
        for ds in thing.dataStreams {
            count += await actualRecordCount(for: ds)
        }
        return count
    }
    
    public func recordCountByIndex(for dataStream: FXBDataStream) async -> Int {
        do {
            return try await dbQueue.read({ db in
                let q = """
                    SELECT MAX(id) FROM \(dataStream.name)_data
                """
                return try Int.fetchOne(db, sql: q) ?? 0
            })
        } catch { return 0 }
    }
    
    public func recordCountByIndex(for thing: FXBDeviceSpec) async -> Int {
        var count = 0
        for ds in thing.dataStreams {
            count += await recordCountByIndex(for: ds)
        }
        return count
    }
    
    public func unUploadedCount(for dataStream: FXBDataStream) async -> Int {
        do {
            return try await dbQueue.read({ db in
                let q = """
                    SELECT COUNT(id)
                    FROM \(dataStream.name)
                    WHERE uploaded = 0
                """
                return try Int.fetchOne(
                    db,
                    sql: q
                ) ?? 0
            })
        } catch { return 0 }
    }
    
    public func unUploadedCount(for thing: FXBDeviceSpec) async -> Int {
        var count = 0
        for ds in thing.dataStreams {
            count += await unUploadedCount(for: ds)
        }
        return count
    }
    
    public func meanFrequency(for dataSteam: FXBDataStream, last: Int=1000) async -> Float {
        do {
            let dates: [Date] = try await dbQueue.read({ db in
                let q = """
                    SELECT ts
                    FROM \(dataSteam.name)
                    ORDER BY ts DESC
                    LIMIT \(last)
                """
                return try Date.fetchAll(
                    db,
                    sql: q
                )
            })
            var diffs: [Int] = []
            
            guard dates.count > 0 else { return 0 }
            
            for i in 0..<dates.count-1 {
                let first = Int64(dates[i].timeIntervalSince1970 * 1000.0)
                let second = Int64(dates[i+1].timeIntervalSince1970 * 1000.0)
                diffs.append(Int(first - second))
            }
            
            return 1000.0 / Float(diffs.reduce(0, +) / diffs.count)
        } catch { return 0 }
    }
    
    // MARK: - Not Public
    
    /// replace space with underscores for dynamically naming tables in SQL
    private func tableName(from name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "_").lowercased()
    }
    
    /// Inactivate a dynamically created table (update name and set active=0)
    private func replaceDynamicTable(db: Database, existingTable: DynamicTable, baseName: String, nextNum: Int) {
        
        let newDynamicTableName = "\(baseName)_\(nextNum)"
        let newDataName = "\(baseName)_data_\(nextNum)"
        let newConfigName = "\(baseName)_config_\(nextNum)"
        
        let tableUpdateSQL = """
            UPDATE \(DynamicTable.databaseTableName)
            SET name = :name,
                active = 0
            WHERE id = :id
        """
        
        try? db.execute(literal: "ALTER TABLE `\(baseName)_data` RENAME TO `\(newDataName)`")
        try? db.execute(literal: "ALTER TABLE `\(baseName)_config` RENAME TO `\(newConfigName)`")
        
        try? db.execute(
            sql: tableUpdateSQL,
            arguments: StatementArguments([
                "name": newDynamicTableName,
                "id": existingTable.id!
            ])
        )
        
        try? db.execute(literal: "UPDATE \(newDataName) SET is_current_schema = 0;")
        try? db.execute(literal: "UPDATE \(newConfigName) SET is_current_schema = 0;")
        
        pLog.info("found duplicate dynamic table: renamed existing table: \(newDynamicTableName)")
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
    
    public func tableInfo(for table: String) -> [FXBTableInfo] {
        var metadata: [FXBTableInfo] = []
        
        let sql = """
            PRAGMA table_info(\(table));
        """
        
        try? dbQueue.read { db in
            let result = try Row.fetchAll(db, sql: sql)
            metadata = result.map({ FXBTableInfo.make(from: $0) })
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
                    FROM \(name)_data
                    ORDER BY ts DESC
                    LIMIT \(limit)
                    OFFSET \(offset)
                """
                
                return try T.fetchAll(
                    db,
                    sql: q
                )
            })
        } catch { return [] }
    }
    
    public func data(for tableName: String, metadata: [FXBTableInfo], offset: Int=0, limit: Int=100) async -> [GenericRow]? {
        
        let sql = """
            SELECT \(metadata.map({$0.name}).joined(separator: ", "))
            FROM \(tableName)
            ORDER BY ts DESC
            LIMIT \(limit)
            OFFSET \(offset);
        """
        
        let data: [GenericRow]? = try? await dbQueue.read { db in
            let result = try Row.fetchAll(
                db,
                sql: sql
            )
            return result.map({ row in
                GenericRow(metadata: metadata, row: row)
            })
        }
        
        pLog.info("queried")
        return data
    }
    
    public func config(for ds: FXBDataStream) async -> GenericRow? {
        let tableName = "\(tableName(from: ds.name))_config"
        
        let sql = """
            SELECT \(ds.configValues.map({ $0.name }).joined(separator: ", "))
            FROM \(tableName)
            ORDER BY ts DESC
            LIMIT 1;
        """
        
        do {
            return try await dbQueue.read { db in
                let pragma = try Row.fetchAll(db, sql: "PRAGMA table_info(\(tableName));")
                let info = pragma.map({ FXBTableInfo.make(from: $0) })
                    
                let result = try Row.fetchOne(db, sql: sql)
                return result.map({ GenericRow(metadata: info, row: $0) })
            }
        } catch {
            pLog.error("Error fetching latest config for \(ds.name): \(error.localizedDescription)")
        }
        
        return nil
    }
    
    internal func createTable(from metadata: FXBDataStream, forceNew: Bool=false) {
        let name = tableName(from: metadata.name)
        let dataTableName = "\(name)_data"
        let configTableName = "\(name)_config"
        
        try? self.dbQueue.write { db in
            let tables = try? DynamicTable.fetchAll(db)
            
            // check if tables exist
            if let table = tables?.first(where: { $0.name == dataTableName }),
               let data = table.metadata {
                
                let existingMetdata = try? Data.sharedJSONDecoder.decode(FXBDataStream.self, from: data)
                
                if existingMetdata != metadata || forceNew {
                    replaceDynamicTable(
                        db: db,
                        existingTable: table,
                        baseName: name,
                        nextNum: tables!.count
                    )
                } else { return }
            }
            
            // create data table
            try? db.drop(table: dataTableName)
            try? db.create(table: dataTableName) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("created_at", .datetime).defaults(to: Date())
                t.column("uploaded", .boolean).defaults(to: false)
                t.column("experiment_id", .integer)
                    .indexed()
                    .references(FXBExperiment.databaseTableName)
                t.column("spec_id", .integer)
                    .references(FXBSpecTable.databaseTableName)
                t.column("device", .text)
                
                for dv in metadata.dataValues {
                    t.column(dv.name, .double)
                }
                
                t.column("ts", .date).notNull().indexed()
                
            }
            
            
            // create config table
            try? db.drop(table: configTableName)
            try? db.create(table: configTableName) { t in
                
                t.autoIncrementedPrimaryKey("id")
                t.column("ts", .datetime).defaults(to: Date()).indexed()
                t.column("uploaded", .boolean).defaults(to: false)
                t.column("spec_id", .integer)
                    .references(FXBSpecTable.databaseTableName)
                t.column("device", .text)
                
                for cv in metadata.configValues {
                    t.column(cv.name, .text).notNull()
                }
            }
            
            // create dyanmic table entry
            let metadataData = try? Data.sharedJSONEncoder.encode(metadata)
            let dynamicTable = DynamicTable(name: name, metadata: metadataData)
            try? dynamicTable.insert(db)
            pLog.info("Dynamic Table Created: \(name)")
        }
    }
    
    internal func dynamicDataRecordInsert(
        for ds: FXBDataStream,
        anchorDate: Date,
        allValues: [[AEDataValue]],
        timestamps: [Date],
        specId: Int64,
        device: String
    ) async {
        let tableName = "\(tableName(from: ds.name))_data"
        
        let cols = "\(ds.dataValues.map({ $0.name }).joined(separator: ", "))"
        let placeholders = "\(ds.dataValues.map({ _ in "?" }).joined(separator: ", "))"
        
        var sql = """
            INSERT INTO \(tableName)
        """
        
        let colsSql = "(\(cols), created_at, ts, spec_id, device) VALUES"
        
        sql += colsSql
        
        var args: [Any] = []
        
        for (i, values) in allValues.enumerated() {
            args.append(contentsOf: values)
            args.append(Date())
            sql += "(\(placeholders), ?, ?, ?, ?), "
            
            if ds.includeAnchorTimestamp && ds.offsetDataValue != nil {
                args.append(timestamps[i])
            } else {
                args.append(Date())
            }
            
            args.append(specId)
            args.append(device)
        }
        
        sql.removeLast(2)
        sql += ";"
        
        do {
            try await self.dbQueue.write { [sql, args] db in
                try db.execute(
                    sql: sql,
                    arguments: StatementArguments(args) ?? StatementArguments()
                )
            }
        } catch {
            bleLog.error("error inserting ble data records: \(error.localizedDescription)")
        }
    }
    
    internal func dynamicConfigRecordInsert(
        for ds: FXBDataStream,
        values: [String],
        specId: Int64,
        device: String
    ) async {
        
        let tableName = "\(tableName(from: ds.name))_config"
        
        let cols = "\(ds.configValues.map({ $0.name }).joined(separator: ", "))"
        let placeholders = "\(ds.configValues.map({ _ in "?" }).joined(separator: ", "))"
        
        let sql = """
            INSERT INTO \(tableName)
            (\(cols), ts, spec_id, device)
            VALUES (\(placeholders), ?, ?, ?);
        """
        
        let args = StatementArguments(values + [Date(), specId, device])
        
        do {
            try await self.dbQueue.write { [sql, args] db in
                try db.execute(
                    sql: sql,
                    arguments: args ?? StatementArguments()
                )
            }
        } catch {
            bleLog.error("error inserting ble config record: \(error.localizedDescription)")
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
    
    internal func createTable(for rs: BLERegisteredService) async {
        switch rs {
        case .heartRate:
            try? await self.dbQueue.write({ db in
                try? db.create(
                    table: FXBHeartRate.databaseTableName,
                    ifNotExists: true,
                    body: FXBHeartRate.create
                )
            })
        default: break
        }
    }
    
    internal func insert(bpm: Int, sensorLocation: String, specId: Int64) async {
        do {
            try await self.dbQueue.write({ db in
                var hr = FXBHeartRate(
                    bpm: bpm,
                    sensorLocation: sensorLocation,
                    ts: Date.now,
                    specId: specId
                )
                try hr.insert(db)
            })
        } catch {
            bleLog.error("error inserting heart rate record: \(error.localizedDescription)")
        }
    }
}
