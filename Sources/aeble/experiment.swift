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
                           start: Date=Date.now) async -> Result<Experiment, AEBLEError> {
        
        do {
            let res = try await self.db.dbQueue.write { db -> Result<Experiment, AEBLEError> in
                var exp = Experiment(
                    name: name,
                    description: description,
                    start: start,
                    end: nil
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
            
            let res = await db.activeDynamicTables()
            guard case .success(let dtNames) = res else {
                return .failure(AEBLEError.dbError(msg: "No active tables"))
            }
            
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
            let expRes = await AEBLEAPI.createExperiment(exp: exp, settings: settings)
            
            switch expRes {
            case .success(let inserted):
                if inserted {
                    try await db.dbQueue.write { db in
                        var exp = try Experiment.fetchOne(db, key: ["id": id])
                        exp?.uploaded = true
                        try exp?.update(db)
                    }
                }
            case .failure(_): break
            }
            
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
    
    public func activeEvent() async -> Result<Experiment?, AEBLEError> {
        do {
            return try await db.dbQueue.read { db -> Result<Experiment?, AEBLEError> in
                let exp = try Experiment
                    .filter(Experiment.Columns.end == nil)
                    .order(Experiment.Columns.start.desc)
                    .fetchOne(db)
                
                return .success(exp)
                    
            }
        } catch {
            return .failure(.dbError(msg: error.localizedDescription))
        }
    }
    
    public func markTime(name: String?=nil, description: String?=nil, experiment: Experiment?=nil) async -> Result<Bool, Error> {
        do {
            
            var ts = Timestamp(
                name: name,
                description: description,
                datetime: Date.now,
                experimentId: experiment?.id
            )
            
            let settings = try await AEBLESettingsStore.activeSetting(dbQueue: db.dbQueue)
            let res = await AEBLEAPI.createTimestamp(ts: ts, settings: settings)
            
            switch res {
            case .success(let inserted):
                if inserted {
                    ts.uploaded = true
                }
            case .failure(_): break
            }
            
            try await db.dbQueue.write { [ts] db in
                try ts.insert(db)
            }
                        
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
}
