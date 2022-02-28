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
    
    public func startEvent(name: String,
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
    
    public func endEvent(id: Int64) async -> Result<Bool, Error> {
        do {
            try await dbQueue.write { db in
                var event = try Experiment.fetchOne(db, key: ["id": id])
                event?.end = Date.now
                try event?.update(db)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    public func activeEvent() async -> Result<Experiment, AEBLEError> {
        do {
            return try await dbQueue.read { db -> Result<Experiment, AEBLEError> in
                let exp = try Experiment
                    .filter(Experiment.Columns.end == nil)
                    .order(Experiment.Columns.start.desc)
                    .fetchOne(db)
                
                if let e = exp {
                    return .success(e)
                }
                return .failure(.dbError("unable to create experiment"))
                    
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func markTime(name: String?=nil, description: String?=nil) async -> Result<Bool, Error> {
        do {
            try await dbQueue.write { db in
                try Timestamp(
                    name: name,
                    description: description,
                    datetime: Date.now
                ).insert(db)
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
}
