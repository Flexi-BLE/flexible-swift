//
//  FXBlocalDataAccessor+Connection.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: - Public
extension FXBLocalDataAccessor {
    
    public class ConnectionAccess {
        
        private var connection: DatabaseWriter
        
        internal init(conn: DatabaseWriter) {
            self.connection = conn
        }
        
        public func get(connectedOnly: Bool = false) async throws -> [FXBConnection] {
            
            return try await connection.read({ db in
                if connectedOnly {
                    return try FXBConnection
                        .filter(Column(FXBConnection.CodingKeys.disconnectedAt.stringValue) == nil)
                        .order(literal: "connected_at DESC")
                        .fetchAll(db)
                }
                return try FXBConnection
                    .order(literal: "connected_at DESC")
                    .fetchAll(db)
            })
        }
    }
}

// MARK: - Internal
internal extension FXBLocalDataAccessor.ConnectionAccess {
    func updateOrphandedConnectionRecords() throws {
        try connection.write { db in
            let sql = """
                UPDATE \(FXBConnection.databaseTableName)
                SET \(FXBConnection.CodingKeys.disconnectedAt.stringValue) = :date
                WHERE \(FXBConnection.CodingKeys.disconnectedAt.stringValue) IS NULL;
            """
            try db.execute(sql: sql, arguments: ["date": Date.now.SQLiteFormat()])
        }
    }
    
    func update(_ rec: inout FXBConnection) throws {
        try connection.write({ db in
            try rec.update(db)
        })
    }
    
    func insert(_ rec: inout FXBConnection) throws {
        try connection.write({ db in
            try rec.insert(db)
        })
    }
}
