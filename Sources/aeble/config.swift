//
//  config.swift
//  
//
//  Created by blaine on 2/23/22.
//

import Foundation


public class AEBLEConfig {
    
    internal var metadata: PeripheralMetadataPayload
    public var dbURL: URL
    
    var deviceId: String
//    var batchUploadNumOfRecords: Int = 1000
    
    public var userId: String
    
    public init(
        dbName: String="aeble",
        userId: String,
        deviceId: String
    ) {
        self.metadata = AEBLEConfig.loadDefaultMetadata()
        self.dbURL = AEBLEConfig.documentDirPath(for: dbName)
        self.userId = userId
        self.deviceId = deviceId
    }
    
    private static func loadDefaultMetadata(fileName: String = "default_peripheral_metadata.json") -> PeripheralMetadataPayload {
        return Bundle.module.decode(
            PeripheralMetadataPayload.self,
            from: fileName
        )
    }
    
    /// Create and retrurn data directory url in application file structure
    private static func documentDirPath(for dbName: String="aeble") -> URL {
        let fileManager = FileManager()
        
        do {
            let dirPath = try fileManager
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appendingPathComponent("data", isDirectory: true)
            
            try fileManager.createDirectory(at: dirPath, withIntermediateDirectories: true)
            
            return dirPath.appendingPathComponent("\(dbName).sqlite")
        } catch {
            fatalError("Unable to access document directory")
        }
    }
    
}
