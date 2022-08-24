//
//  experiment.swift
//  
//
//  Created by Blaine Rothrock on 2/24/22.
//

import Foundation
import GRDB



public class AEBLEExperiment {
    private let db: AEBLEDBManager
    
    internal init(db: AEBLEDBManager) {
        self.db = db
    }
    
    public func startExperiment(name: String,
                                description: String?=nil,
                                start: Date=Date.now,
                                active: Bool,
                                trackGPS: Bool) async -> Result<Experiment, AEBLEError> {
        
        do {
            let res = try await self.db.dbQueue.write { db -> Result<Experiment, AEBLEError> in
                var exp = Experiment(
                    name: name,
                    description: description,
                    start: start,
                    end: nil,
                    active: active,
                    trackGPS: trackGPS
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
                                 trackGPS: Bool) async -> Result<Experiment, AEBLEError> {
        
        do {
            let res = try await self.db.dbQueue.write { db -> Result<Experiment, AEBLEError> in
                var exp = Experiment(
                    name: name,
                    description: description,
                    start: start,
                    end: end,
                    active: active,
                    trackGPS: trackGPS
                )
                try exp.insert(db)
                return .success(exp)
            }
            return res
        } catch {
            return .failure(.dbError(msg: "unable to create event"))
        }
    }
    
    
    public func endExperiment(id: Int64) async -> Result<Bool, Error> {
        do {
            let exp = try await db.dbQueue.write { db -> Experiment? in
                var exp = try Experiment.fetchOne(db, key: ["id": id])
                exp?.end = Date.now
                try exp?.update(db)
                return exp
            }
            
            guard let exp = exp,
                  let expId = exp.id,
                  let expEnd = exp.end else {
                return .failure(AEBLEError.dbError(msg: "No event found"))
            }
            
            let dtNames = await db.activeDynamicTables()
            
            for tableName in dtNames {
                try await db.dbQueue.write { db in
                    let sql = """
                        UPDATE \(tableName)
                        SET experiment_id = \(expId)
                        WHERE created_at >= ? AND created_at < ?
                    """
                    try db.execute(
                        sql: sql,
                        arguments: StatementArguments([exp.start, expEnd])
                    )
                }
            }
            
            let settings = try await AEBLESettingsStore.activeSetting(dbQueue: db.dbQueue)
            //            let expRes = await AEBLEAPI.createExperiment(exp: exp, settings: settings)
            //
            //            switch expRes {
            //            case .success(let inserted):
            //                if inserted {
            //                    try await db.dbQueue.write { db in
            //                        var exp = try Experiment.fetchOne(db, key: ["id": id])
            //                        exp?.uploaded = true
            //                        try exp?.update(db)
            //                    }
            //                }
            //            case .failure(_): break
            //            }
            
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    public func deleteExperiment(id: Int64) async -> Result<Bool, Error> {
        do {
            return try await db.dbQueue.write { db -> Result<Bool, Error> in
                let exp = try Experiment.fetchOne(db, key: ["id": id])
                try exp?.delete(db)
                return .success(true)
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func activeEvent() async -> Result<[Experiment]?, AEBLEError> {
        do {
            return try await db.dbQueue.read { db -> Result<[Experiment]?, AEBLEError> in
                let exp = try Experiment
                    .order(Experiment.Columns.start.desc)
                    .order(Experiment.Columns.active)
                    .fetchAll(db)
                
                return .success(exp)
                
            }
        } catch {
            return .failure(.dbError(msg: error.localizedDescription))
        }
    }
    
    
    public func createTimeMarker(name: String?=nil, description: String?=nil, experimentId: Int64?=nil) async -> Result<Timestamp, AEBLEError> {
        do {
            let res = try await self.db.dbQueue.write { db -> Result<Timestamp, AEBLEError> in
                var ts = Timestamp(
                    name: name,
                    description: description,
                    datetime: Date.now,
                    experimentId: experimentId
                )
                try ts.insert(db)
                return .success(ts)
            }
            return res
        } catch {
            return .failure(.dbError(msg: "unable to create event"))
        }
    }
    
    
    public func getTimestampForExperiment(withID: Int64) async -> Result<[Timestamp]?, AEBLEError> {
        do {
            return try await db.dbQueue.read { db -> Result<[Timestamp]?, AEBLEError> in
                let ts = try Timestamp
                    .filter(Column("experiment_id") == withID)
                    .fetchAll(db)
                
                return .success(ts)
                
            }
        } catch {
            return .failure(.dbError(msg: error.localizedDescription))
        }
    }
    
    public func stopExperiment(id: Int64) async -> Result<Experiment, Error> {
        do {
            let exp = try await db.dbQueue.write { db -> Experiment? in
                var exp = try Experiment.fetchOne(db, key: ["id": id])
                exp?.end = Date.now
                exp?.active = false
                try exp?.update(db)
                return exp
            }
            
            guard let exp = exp,
                  let _ = exp.id,
                  let _ = exp.end else {
                return .failure(AEBLEError.dbError(msg: "No event found"))
            }
            return .success(exp)
        } catch {
            return .failure(error)
        }
    }
    
    public func updateTimemarker(forID: Int64, name: String, description: String) async -> Result<Bool, Error> {
        do {
            _ = try await db.dbQueue.write { db -> Timestamp? in
                var ts = try Timestamp.fetchOne(db, key: ["id": forID])
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

extension AEBLEExperiment {
    public func trackGPSLocation(latitude: Double,
                                 longitude: Double,
                                 altitude: Double,
                                 horizontalAcc: Double,
                                 verticalAcc: Double,
                                 timestamp: Date) async -> Result<Bool, AEBLEError> {

        do {
            let res = try await self.db.dbQueue.write { db -> Result<Bool, AEBLEError> in
                
                var loc = Location(latitude: latitude,
                                   longitude: longitude,
                                   altitude: altitude,
                                   horizontalAccuracy: horizontalAcc,
                                   verticalAccuracy: verticalAcc,
                                   timestamp: timestamp
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
