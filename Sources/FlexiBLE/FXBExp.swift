//
//  FXBExperiment.swift
//
//
//  Created by Blaine Rothrock on 2/24/22.
//

import Foundation
import GRDB

public class FXBExp {
    private let db: FXBDBManager
    
    internal init(db: FXBDBManager) {
        self.db = db
    }
    
    public func startExperiment(name: String,
                                description: String?=nil,
                                start: Date=Date.now,
                                active: Bool,
                                trackGPS: Bool,
                                specId: Int64) async -> Result<FXBExperiment, FXBError> {
        
        do {
            let res = try await self.db.dbQueue.write { db -> Result<FXBExperiment, FXBError> in
                var exp = FXBExperiment(
                    name: name,
                    description: description,
                    start: start,
                    end: nil,
                    active: active,
                    trackGPS: trackGPS,
                    specId: specId
                )
                try exp.insert(db)
                return .success(exp)
            }
            return res
        } catch {
            return .failure(.dbError(msg: "unable to create event"))
        }
    }
    
    public func createExperiment(name: String,
                                 description: String?=nil,
                                 start: Date,
                                 end: Date?=nil,
                                 active: Bool,
                                 trackGPS: Bool,
                                 specId: Int64) async -> Result<FXBExperiment, FXBError> {
        
        do {
            let res = try await self.db.dbQueue.write { db -> Result<FXBExperiment, FXBError> in
                var exp = FXBExperiment(
                    name: name,
                    description: description,
                    start: start,
                    end: end,
                    active: active,
                    trackGPS: trackGPS,
                    specId: specId
                )
                try exp.insert(db)
                return .success(exp)
            }
            return res
        } catch {
            return .failure(.dbError(msg: "unable to create event"))
        }
    }
    
    
//    public func endExperiment(id: Int64) async -> Result<Bool, Error> {
//        do {
//            let exp = try await db.dbQueue.write { db -> FXBExperiment? in
//                var exp = try FXBExperiment.fetchOne(db, key: ["id": id])
//                exp?.end = Date.now
//                try exp?.update(db)
//                return exp
//            }
//            
//            guard let exp = exp,
//                  let expId = exp.id,
//                  let expEnd = exp.end else {
//                return .failure(FXBError.dbError(msg: "No event found"))
//            }
//            
//            let dtNames = await db.activeDynamicTables()
//            
//            for tableName in dtNames {
//                try await db.dbQueue.write { db in
//                    let sql = """
//                        UPDATE \(tableName)
//                        SET experiment_id = \(expId)
//                        WHERE created_at >= ? AND created_at < ?
//                    """
//                    try db.execute(
//                        sql: sql,
//                        arguments: StatementArguments([exp.start, expEnd])
//                    )
//                }
//            }
//                        
//            return .success(true)
//        } catch {
//            return .failure(error)
//        }
//    }
    
    public func deleteExperiment(id: Int64) async -> Result<Bool, Error> {
        do {
            return try await db.dbQueue.write { db -> Result<Bool, Error> in
                let exp = try FXBExperiment.fetchOne(db, key: ["id": id])
                try exp?.delete(db)
                return .success(true)
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func activeEvent() async -> Result<[FXBExperiment]?, FXBError> {
        do {
            return try await db.dbQueue.read { db -> Result<[FXBExperiment]?, FXBError> in
                let exp = try FXBExperiment
                    .order(FXBExperiment.Columns.start.desc)
                    .order(FXBExperiment.Columns.active)
                    .fetchAll(db)
                
                return .success(exp)
                
            }
        } catch {
            return .failure(.dbError(msg: error.localizedDescription))
        }
    }
    
    
    public func createTimeMarker(
        name: String?=nil,
        description: String?=nil,
        experimentId: Int64?=nil,
        specId: Int64
    ) async -> Result<FXBTimestamp, FXBError> {
        do {
            let res = try await self.db.dbQueue.write { db -> Result<FXBTimestamp, FXBError> in
                var ts = FXBTimestamp(
                    name: name,
                    description: description,
                    ts: Date.now,
                    experimentId: experimentId,
                    specId: specId
                )
                try ts.insert(db)
                return .success(ts)
            }
            return res
        } catch {
            return .failure(.dbError(msg: "unable to create event"))
        }
    }
    
    
    public func getTimestampForExperiment(withID: Int64) async -> Result<[FXBTimestamp]?, FXBError> {
        do {
            return try await db.dbQueue.read { db -> Result<[FXBTimestamp]?, FXBError> in
                let ts = try FXBTimestamp
                    .filter(Column("experiment_id") == withID)
                    .fetchAll(db)
                
                return .success(ts)
                
            }
        } catch {
            return .failure(.dbError(msg: error.localizedDescription))
        }
    }
    
    public func stopExperiment(id: Int64) async -> Result<FXBExperiment, Error> {
        do {
            let exp = try await db.dbQueue.write { db -> FXBExperiment? in
                var exp = try FXBExperiment.fetchOne(db, key: ["id": id])
                exp?.end = Date.now
                exp?.active = false
                try exp?.update(db)
                return exp
            }
            
            guard let exp = exp,
                  let _ = exp.id,
                  let _ = exp.end else {
                return .failure(FXBError.dbError(msg: "No event found"))
            }
            return .success(exp)
        } catch {
            return .failure(error)
        }
    }
    
    public func updateTimemarker(forID: Int64, name: String, description: String) async -> Result<Bool, Error> {
        do {
            _ = try await db.dbQueue.write { db -> FXBTimestamp? in
                var ts = try FXBTimestamp.fetchOne(db, key: ["id": forID])
                ts?.name = name
                ts?.description = description
                try ts?.update(db)
                return ts
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
        
    }
}

extension FXBExp {
    public func trackGPSLocation(
        latitude: Double,
        longitude: Double,
        altitude: Double,
        horizontalAcc: Double,
        verticalAcc: Double,
        timestamp: Date,
        specId: Int64
    ) async -> Result<Bool, FXBError> {

        do {
            let res = try await self.db.dbQueue.write { db -> Result<Bool, FXBError> in
                
                var loc = FXBLocation(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: altitude,
                    horizontalAccuracy: horizontalAcc,
                    verticalAccuracy: verticalAcc,
                    ts: timestamp,
                    specId: specId
                )
                try loc.insert(db)
                return .success(true)
            }
            return res
        } catch {
            return .failure(.dbError(msg: "unable to create event"))
        }
    }
}
