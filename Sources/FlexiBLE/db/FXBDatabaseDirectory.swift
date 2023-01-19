//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/17/23.
//

import Foundation
import GRDB


/// static helpers for the database file structure
enum FXBDatabaseDirectory {
    
    static func dataPath(
        specId: String
    ) -> URL {
        do {
            let dirPath = try FileManager.default
                .url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                .appendingPathComponent(
                    "data_\(specId)",
                    isDirectory: true
                )
            
            try FileManager.default.createDirectory(
                at: dirPath,
                withIntermediateDirectories: true
            )
            
            return dirPath
        } catch {
            fatalError("unable to access document directory (create data directory - \(specId)")
        }
    }
    
    static func transactionalPath(
        specId: String
    ) -> URL {
        do {
            let transactionalPath = Self.dataPath(
                specId: specId
            ).appendingPathComponent("transactional", isDirectory: true)
            
            try FileManager.default
                .createDirectory(at: transactionalPath, withIntermediateDirectories: true)
            
            return transactionalPath
        } catch {
            fatalError("Unable to access document directory (create transactional directory) - \(specId)")
        }
    }
    
    static func mainDatabasePath(
        specId: String
    ) -> URL {
        return dataPath(
            specId: specId
        ).appendingPathComponent("flexible_main.db")
    }
    
    static func tableName(from unformattedName: String) -> String {
        return unformattedName.replacingOccurrences(of: " ", with: "_").lowercased()
    }
    
    static func transactionalDBPath(specId: String) -> URL {
        return Self.transactionalPath(specId: specId)
            .appendingPathComponent("transactional_\(Date.now.timestamp()).db")
    }
    
    static func save(_ spec: FXBSpec) throws {
        try Data.sharedJSONEncoder.encode(spec).write(
            to: FXBDatabaseDirectory.dataPath(specId: spec.id)
                .appendingPathComponent("spec.json")
        )
        dbLog.info("specification JSON saved")
    }
}
