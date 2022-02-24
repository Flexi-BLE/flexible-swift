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
                           start: Date=Date.now) -> Int64? {
        
        var id: Int64? = nil
        try? self.dbQueue.write { db in
            let event = Event(
                name: name,
                description: description,
                start: start,
                end: nil
            )
            try? event.insert(db)
            id = event.id
        }
        
        return id
    }
    
    public func endEvent(id: Int64) {
        try? dbQueue.write { db in
            var event = try? Event.fetchOne(db, key: ["id": id])
            event?.end = Date.now
            try event?.update(db)
        }
    }
    
    public func markTime(name: String?=nil, description: String?=nil) {
        try? dbQueue.write { db in
            try? Timestamp(
                name: name,
                description: description,
                datetime: Date.now
            ).insert(db)
        }
    }
    
}
