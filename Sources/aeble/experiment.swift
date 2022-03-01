//
//  experiment.swift
//  
//
//  Created by Blaine Rothrock on 2/24/22.
//

import Foundation
import GRDB



public class AEBLEExperiment {
    private let dbQueue: DatabaseQueue
    
    internal init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func startExperiment(name: String,
                           description: String?=nil,
                           start: Date=Date.now) async -> Result<Experiment, AEBLEError> {
        
        do {
            let res = try await self.dbQueue.write { db -> Result<Experiment, AEBLEError> in
                var event = Experiment(
                    name: name,
                    description: description,
                    start: start,
                    end: nil
                )
                try event.insert(db)
                return .success(event)
            }
            return res
        } catch {
            return .failure(.dbError(msg: "unable to create event"))
        }
    }
    
    public func endExperiment(id: Int64) async -> Result<Bool, Error> {
        do {
            let exp = try await dbQueue.write { db -> Experiment? in
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
            
            let res = await AEBLEDBManager.activeDynamicTables(dbQueue: dbQueue)
            guard case .success(let dtNames) = res else {
                return .failure(AEBLEError.dbError(msg: "No active tables"))
            }
            
            for tableName in dtNames {
                try await dbQueue.write { db in
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
            
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    public func deleteExperiment(id: Int64) async -> Result<Bool, Error> {
        do {
            return try await dbQueue.write { db -> Result<Bool, Error> in
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
            return try await dbQueue.read { db -> Result<Experiment?, AEBLEError> in
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
            try await dbQueue.write { db in
                try Timestamp(
                    name: name,
                    description: description,
                    datetime: Date.now,
                    experimentId: experiment?.id
                ).insert(db)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
}
