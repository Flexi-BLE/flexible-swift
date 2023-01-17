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
    
    internal var dbQueue: DatabasePool
    private let migrator = FXBDBMigrator()
    public let dbPath = FXBDBManager.documentDirPath()
    
    internal var archiveSizeThresholdBytes: UInt64?=nil
    internal var activeKeepTimeInterval: Double = 1_000_000
    
    private var lastArchive: Date = Date.now
    private var isArchving: Bool = false
    
    static let activeDBName: String = "FXB_active.sqlite"
    
    /// Create and retrurn data directory url in application file structure
    private static func documentDirPath() -> URL {
        return Self.dbDirectory().appendingPathComponent(Self.activeDBName)
    }
    
    private static func dbDirectory() -> URL {
        do {
            let dirPath = try FileManager.default
                .url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                .appendingPathComponent(
                    "resources",
                    isDirectory: true
                )
            
            try FileManager.default.createDirectory(
                at: dirPath,
                withIntermediateDirectories: true
            )
            
            return dirPath
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
            self.dbQueue = try DatabasePool(
                path: self.dbPath.path,
                configuration: configuration
            )
            
            self.migrator.migrate(self.dbQueue)
        } catch {
            fatalError("cannot create database")
        }
        
        // in the event of application restart, update disconnection date of a any connection records
        updateOrphandedConnectionRecords()
    }

    internal func erase() {
        do {
            try self.dbQueue.erase()
            self.migrator.migrate(self.dbQueue)
        } catch {
            pLog.error("unable to delete database")
        }
    }


    // MARK: - Not Public
    
    /// replace space with underscores for dynamically naming tables in SQL
    private func tableName(from name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "_").lowercased()
    }
    
    /// Set all connection records with null disconnected date to current date.
    private func updateOrphandedConnectionRecords() {
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
            if let table = tables?.first(where: { $0.name == name }),
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
                switch metadata.precision {
                case .ms: break
                case .us: t.column("ts_precision", .integer).notNull().indexed()
                }
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
        anchorDate: Double,
        allValues: [[AEDataValue]],
        timestamps: [Double],
        specId: Int64,
        device: String
    ) async {
        let tableName = "\(tableName(from: ds.name))_data"
        
        let varColsString = "\(ds.dataValues.map({ $0.name }).joined(separator: ", "))"
        var sysCols = ["created_at", "ts", "spec_id", "device"]
        switch ds.precision {
        case .ms: break
        case .us: sysCols.insert("ts_precision", at: 2)
        }
        let sysColsString = sysCols.joined(separator: ", ")
        let placeholders = "\(ds.dataValues.map({ _ in "?" }).joined(separator: ", "))"
        
        var sql = """
            INSERT INTO \(tableName)
        """
        let colsSql = "(\(varColsString), \(sysColsString)) VALUES"
        sql += colsSql
        
        var args: [Any] = []
        
        for (i, values) in allValues.enumerated() {
            args.append(contentsOf: values)
            args.append(Date())
            switch ds.precision {
            case .ms: sql += "(\(placeholders), ?, ?, ?, ?), "
            case .us: sql += "(\(placeholders), ?, ?, ?, ?, ?), "
            }
            
            if ds.offsetDataValue != nil {
                args.append(Date(timeIntervalSince1970: timestamps[i]))
                switch ds.precision {
                case .ms: break
                case .us: args.append(Int((timestamps[i] - Double(Int(timestamps[i]))) * 1_000_000))
                }

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
        
        if let archiveSizeThresholdBytes = self.archiveSizeThresholdBytes,
            Date.now.addingTimeInterval(-activeKeepTimeInterval) > lastArchive {
            lastArchive = Date.now
            if activeDBSize() >= archiveSizeThresholdBytes, !isArchving {
                isArchving = true
                Task(priority: .background) {
                    await createDBBackup(startingAt: Date.now.addingTimeInterval(-activeKeepTimeInterval), progressCallback: nil)
                }
            }
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
    
    /// created a db backup and purges records before a given time.
    public func createDBBackup(startingAt date: Date, progressCallback: ((Bool, Float)->())?) async {
        
        pLog.info("dbbackup: Starting backup process")
        
        let backupName = "archive_\(date.timestamp()).sqlite"
        let archivePath = Self.dbDirectory()
            .appendingPathComponent(backupName)
        
        
        var configuration = Configuration()
        configuration.qos = .background
        
        do {
            let archiveQueue = try DatabaseQueue(
                path: archivePath.absoluteString,
                configuration: configuration
            )
            
            try self.dbQueue.backup(to: archiveQueue, progress: { progress in
                let percent = Float(progress.completedPageCount) / Float(progress.totalPageCount)
                pLog.info("dbbackup: database backup progress (complete: \(progress.isCompleted)): \(percent * 100.0)%")
                
                progressCallback?(progress.isCompleted, percent)
            })
            
            // delete old data records
            pLog.info("dbbackup: Deleting records before \(date)")
            let tables = await activeDynamicTables()
            
            try await self.dbQueue.write { [tables] db in
//                try db.inSavepoint {
                for table in tables {
                    
                    pLog.info("dbbackup: deleting data from \(table)_data before \(date.SQLiteFormat())")
                    
                    let sqlData = """
                        DELETE FROM \(table)_data
                        WHERE ts < '\(date.SQLiteFormat())'
                    """
                    
                    try db.execute(sql: sqlData)
                    
//                        let sqlConfig = """
//                            DELETE FROM \(table)_config
//                            WHERE ts < '\(date.SQLiteFormat())'
//                        """
//
//                        try db.execute(sql: sqlConfig)
                
                }
                
                let tsCol = Column("ts")
                
                try FXBHeartRate.filter(tsCol < date).deleteAll(db)
                try FXBLocation.filter(tsCol < date).deleteAll(db)
                try FXBDataUpload.filter(tsCol < date).deleteAll(db)
                try FXBThroughput.filter(FXBThroughput.Columns.createdAt < date).deleteAll(db)
                
                var backup = FXBBackup(date: date, fileName: archivePath.absoluteString)
                try backup.insert(db)
                
                
                    
//                    return .commit
//                }
                
            }
            

            pLog.info("dbbackup: setting last archive to \(Date.now)")

            self.isArchving = false
            
            
        } catch {
            self.isArchving = false
            pLog.error("dbbackup: unable to create backup \(backupName): \(error.localizedDescription)")
            
        }
        
    }
    
    private func getLastArchive() -> Date? {
        do {
            return try dbQueue.write { db -> Date? in
                return try FXBBackup.order(Column("createAt")).fetchOne(db)?.ts
            }
        } catch {
            return nil
        }
    }
    
    private func activeDBSize() -> UInt64 {
        let path = Self.dbDirectory().appendingPathComponent(Self.activeDBName)
    
        if let attr = try? FileManager.default.attributesOfItem(atPath: path.path) {
            let size = attr[FileAttributeKey.size] as! UInt64
            pLog.info("active database size: \(size) bytes")
            return size
        } else {
            return 0
        }
    }
}
