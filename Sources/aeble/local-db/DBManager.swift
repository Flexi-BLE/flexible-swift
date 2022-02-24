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
    let dbQueue: DatabaseQueue?
    let dbPath: URL
    
    private let migrator = DBMigrator()
    
    /// parameter url: URL for SQLite database with `.sqlite` extension. Will create if does not exist.
    init(with url: URL) {
                
        self.dbPath = url
        
        pLog.info("Database Path: \(self.dbPath)")
        
        var configuration = Configuration()
        configuration.qos = DispatchQoS.userInitiated
                    
        self.dbQueue = try? DatabaseQueue(
            path: dbPath.path,
            configuration: configuration
        )
        
        self.migrator.migrate(self.dbQueue!)
    }
    
    // MARK: - Not Public
    
    /// replace space with underscores for dynamically naming tables in SQL
    private func tableName(from name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "_").lowercased()
    }
    
    /// Inactivate a dynamically created table (update name and set active=0)
    private func replaceDynamicTable(db: Database, existingTable: DynamicTable, tableName: String, nextNum: Int) {
        let newName = "\(tableName)_\(nextNum)"
        let sql = """
            UPDATE \(DynamicTable.databaseTableName)
            SET name = '\(newName)',
                active = 0
            WHERE id = \(existingTable.id!)
        """
        try? db.execute(sql: "ALTER TABLE `\(tableName)` RENAME TO `\(newName)`")
        try? db.execute(sql: sql)
        
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
        
        try? dbQueue?.read { db in
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
        
        try? dbQueue?.read { db in
            let result = try Row.fetchAll(db, sql: sql)
            metadata = result.map({ TableInfo.make(from: $0) })
            print(result)
        }
        
        return metadata
    }
    
    public func data(for tableName: String, metadata: [TableInfo], offset: Int=0, limit: Int=100) async -> [GenericRow]? {
        
        let sql = """
            SELECT \(metadata.map({$0.name}).joined(separator: ", "))
            FROM \(tableName)
            ORDER BY created_at DESC
            LIMIT \(limit)
            OFFSET \(offset);
        """
        
        let data: [GenericRow]? = try? await dbQueue?.read { db in
            let result = try Row.fetchAll(db, sql: sql)
            return result.map({ row in
                GenericRow(metadata: metadata, row: row)
            })
        }
        
        pLog.info("queried")
        return data
    }
    
    internal func createTable(from metadata: PeripheralCharacteristicMetadata, forceNew: Bool=false) {
        guard let dataValues = metadata.dataValues else { return }
        let tableName = tableName(from: metadata.name)

        try? self.dbQueue?.write { db in
            let tables = try? DynamicTable.fetchAll(db)
            
            if let table = tables?.first(where: { $0.name == metadata.name }),
               let data = table.metadata {
                
                let existingMetdata = try? Data.sharedJSONDecoder.decode(PeripheralCharacteristicMetadata.self, from: data)
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
                t.column("user_id", .text).notNull(onConflict: .fail)

                for dv in dataValues {
                    switch dv.type {
                    case .float: t.column(dv.name, .double)
                    case .int: t.column(dv.name, .integer)
                    case .string: t.column(dv.name, .text)
                    }
    
                }
            }
    
            let metadataData = try? Data.sharedJSONEncoder.encode(metadata)
            let dynamicTable = DynamicTable(name: tableName, metadata: metadataData)
            try? dynamicTable.insert(db)
            pLog.info("Dynamic Table Created \(tableName)")
        }
    }
    
    internal func arbInsert(for cm: PeripheralCharacteristicMetadata, values: [PeripheralDataValue], with dbQueue: DatabaseQueue?=nil) {
        guard let dataValues = cm.dataValues else { return }
        
        let tableName = tableName(from: cm.name)
        
        let cols = "\(dataValues.map({ $0.name }).joined(separator: ", "))"
        let placeholders = "\(dataValues.map({ _ in "?" }).joined(separator: ", "))"
        
        let sql = """
            "INSERT INTO \(tableName)
            (\(cols), created_at, user_id) VALUES
            (\(placeholders), ?)
        """
        
        try? (dbQueue ?? self.dbQueue)?.write { db in
            try? db.execute(
                sql: sql,
                arguments: StatementArguments(values + [Date(), "--id--"]) ?? StatementArguments()
            )
        }
    }
}
