//
//  FXBLocalDataAccessor+ExperimentAccess.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: - Public
public extension FXBLocalDataAccessor {
    
    class ExperimentAccess {
        
        private var connection: DatabaseWriter
        
        internal init(conn: DatabaseWriter) {
            self.connection = conn
        }
        
        public func getActives() async throws -> [FXBExperiment] {
            return try await connection.read({ db in
                return try FXBExperiment
                    .order(FXBExperiment.Columns.start.desc)
                    .order(FXBExperiment.Columns.active)
                    .fetchAll(db)
            })
        }
        
        public func start(
            name: String,
            description: String?=nil,
            start: Date=Date.now,
            end: Date?=nil,
            active: Bool,
            trackGPS: Bool
        ) async throws -> FXBExperiment {
            
            return try await connection.write({ db in
                var exp = FXBExperiment(
                    name: name,
                    description: description,
                    start: start,
                    end: nil,
                    active: active,
                    trackGPS: trackGPS
                )
                try exp.insert(db)
                return exp
            })
        }
        
        public func deleteExperiment(id: Int64) async throws {
            try await connection.write({ db in
                let exp = try FXBExperiment.fetchOne(db, key: ["id": id])
                try exp?.delete(db)
            })
        }
        
        public func createTimestamp(
            name: String?=nil,
            description: String?=nil,
            experimentId: Int64?=nil
        ) async throws -> FXBTimestamp {
            
            return try await connection.write({ db in
                var ts = FXBTimestamp(
                    name: name,
                    description: description,
                    ts: Date.now,
                    experimentId: experimentId
                )
                try ts.insert(db)
                return ts
            })
        }
        
        public func stopExperiment(id: Int64) async throws -> FXBExperiment? {
            return try await connection.write { db in
                var exp = try FXBExperiment.fetchOne(db, key: ["id": id])
                exp?.end = Date.now
                exp?.active = false
                try exp?.update(db)
                return exp
            }
        }
        
        
        public func getTimestamps(for expId: Int64) async throws -> [FXBTimestamp] {
            return try await connection.read({ db in
                return try FXBTimestamp
                    .filter(Column("experiment_id") == expId)
                    .fetchAll(db)
            })
        }
        
        public func updateTimestamp(
            id: Int64,
            name: String,
            description: String
        ) async throws -> FXBTimestamp? {
            
            return try await connection.write { db -> FXBTimestamp? in
                var ts = try FXBTimestamp.fetchOne(db, key: ["id": id])
                ts?.name = name
                ts?.description = description
                try ts?.update(db)
                return ts
            }
        }
        
        public func deleteTimestamp(
            id: Int64
        ) async throws {
            
            return try await connection.write({ db in
                try FXBTimestamp.deleteOne(db, key: id)
            })
        }
    }
}

// MARK: - Internal
internal extension FXBLocalDataAccessor.ExperimentAccess {
    
}
