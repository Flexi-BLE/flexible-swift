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
    private lazy var batch: DataBatch = {
        return DataBatch(db: self)
    }()
    
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
    
    internal func dynamicTable(for table: String) async -> Result<DynamicTable?, Error> {
        do {
            let t = try await dbQueue.read { db in
                return try DynamicTable.fetchOne(db, key: ["name": table])
            }
            return .success(t)
        } catch {
            return .failure(error)
        }
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
            }
            
            let metadataData = try? Data.sharedJSONEncoder.encode(metadata)
            let dynamicTable = DynamicTable(name: tableName, metadata: metadataData)
            try? dynamicTable.insert(db)
            pLog.info("Dynamic Table Created \(tableName)")
        }
    }
    
//    internal func createTable(from metadata: PeripheralCharacteristicMetadata, forceNew: Bool=false) {
//        guard let dataValues = metadata.dataValues else { return }
//        let tableName = tableName(from: metadata.name)
//
//        try? self.dbQueue.write { db in
//            let tables = try? DynamicTable.fetchAll(db)
//
//            if let table = tables?.first(where: { $0.name == metadata.name }),
//               let data = table.metadata {
//
//                let existingMetdata = try? Data.sharedJSONDecoder.decode(PeripheralCharacteristicMetadata.self, from: data)
//                if existingMetdata != metadata || forceNew {
//                    replaceDynamicTable(
//                        db: db,
//                        existingTable: table,
//                        tableName: tableName,
//                        nextNum: tables!.count
//                    )
//                } else { return }
//            }
//
//            try? db.drop(table: tableName)
//            try? db.create(table: tableName) { t in
//                t.autoIncrementedPrimaryKey("id")
//                t.column("created_at", .datetime).defaults(to: Date())
//                t.column("uploaded", .boolean).defaults(to: false)
//                t.column("experiment_id", .integer)
//                    .indexed()
//                    .references(Experiment.databaseTableName)
//                t.column("is_current_schema", .boolean).defaults(to: true)
//                t.column("user_id", .text).notNull(onConflict: .fail)
//
//                for dv in dataValues {
//                    switch dv.type {
//                    case .float: t.column(dv.name, .double)
//                    case .int: t.column(dv.name, .integer)
//                    case .string: t.column(dv.name, .text)
//                    }
//                }
//            }
//
//            let metadataData = try? Data.sharedJSONEncoder.encode(metadata)
//            let dynamicTable = DynamicTable(name: tableName, metadata: metadataData)
//            try? dynamicTable.insert(db)
//            pLog.info("Dynamic Table Created \(tableName)")
//        }
//    }
    
    internal func arbInsert(
        for ds: AEDataStream,
        values: [AEDataValue],
        with dbQueue: DatabaseQueue?=nil) async {
        
            let tableName = tableName(from: ds.name)
        
            let cols = "\(ds.dataValues.map({ $0.name }).joined(separator: ", "))"
            let placeholders = "\(ds.dataValues.map({ _ in "?" }).joined(separator: ", "))"
            
            let sql = """
                INSERT INTO \(tableName)
                (\(cols), created_at, user_id) VALUES
                (\(placeholders), ?, ?)
            """
            
            try? await (dbQueue ?? self.dbQueue)?.write { db in
                let settings = try AEBLESettingsStore.activeSetting(db: db)
                
                try? db.execute(
                    sql: sql,
                    arguments: StatementArguments(values + [Date(), settings.userId]) ?? StatementArguments()
                )
            }
            
            self.batch.increment(for: tableName)
    }
    
//    // TODO: make async response
//    internal func arbInsert(for cm: PeripheralCharacteristicMetadata, values: [PeripheralDataValue], with dbQueue: DatabaseQueue?=nil) {
//        guard let dataValues = cm.dataValues else { return }
//
//        let tableName = tableName(from: cm.name)
//
//        let cols = "\(dataValues.map({ $0.name }).joined(separator: ", "))"
//        let placeholders = "\(dataValues.map({ _ in "?" }).joined(separator: ", "))"
//
//        let sql = """
//            INSERT INTO \(tableName)
//            (\(cols), created_at, user_id) VALUES
//            (\(placeholders), ?, ?)
//        """
//
//        try? (dbQueue ?? self.dbQueue)?.write { db in
//            let settings = try AEBLESettingsStore.activeSetting(db: db)
//
//            try? db.execute(
//                sql: sql,
//                arguments: StatementArguments(values + [Date(), settings.userId]) ?? StatementArguments()
//            )
//        }
//
//        self.batch.increment(for: tableName)
//    }
    
    internal func activeDynamicTables() async -> Result<[String], Error> {
        do {
            let dts = try await self.dbQueue.read { db -> [String] in
                let dts = try DynamicTable
                    .filter(Column(DynamicTable.CodingKeys.active.stringValue) == true)
                    .fetchAll(db)
                
                return dts.map({ $0.name })
            }
            
            return .success(dts)
        } catch {
            return .failure(error)
        }
    }
}
