//
//  FXBLocalDataAccessor.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: - public
public extension FXBLocalDataAccessor {
    
    class DynamicTableAccess {
        
        var connection: DatabaseWriter
        
        internal init(conn: DatabaseWriter) {
            self.connection = conn
        }
        
        public func tableNames() throws -> [String] {
            return try connection.read { db -> [String] in
                let tables = try FXBDataStreamTable.fetchAll(db)

                return tables.map({ $0.name })
            }
        }
            
    }
}

// MARK: - internal
internal extension FXBLocalDataAccessor.DynamicTableAccess {

}
