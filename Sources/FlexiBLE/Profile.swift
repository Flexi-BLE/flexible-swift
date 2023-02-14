//
//  Profile.swift
//  
//
//  Created by Blaine Rothrock on 2/13/23.
//

import Foundation
import GRDB

public class FlexiBLEProfile: Codable, ObservableObject {
    public let id: UUID
    public let name: String
    
    public let createdAt: Date
    public let updatedAt: Date
    
    private var db: FXBDatabase
    private var dbAccessor: FXBLocalDataAccessor
    public let conn: FXBConnectionManager
    
    internal var basePath: URL
    internal var mainDatabasePath: URL
    internal var transactionalDatabasesBasePath: URL
    internal var specificationPath: URL
    
    public var specification: FXBSpec
    
    public init(name: String, spec: FXBSpec) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date.now
        self.updatedAt = Date.now
        
        let basePath = FlexiBLEAppData.createBasePath(name: name, id: id)
        self.basePath = basePath
        self.mainDatabasePath = basePath.appendingPathComponent("main.db")
        self.transactionalDatabasesBasePath = FlexiBLEAppData.createTransactionalDatabasesBasePath(basePath: basePath)
        self.specificationPath = basePath.appendingPathComponent("spec.json")
        
        self.db = FXBDatabase(
            specification: spec,
            mainDBPath: mainDatabasePath,
            transactionalDBPath: transactionalDatabasesBasePath
        )
        self.dbAccessor = FXBLocalDataAccessor(db: db)
        self.conn = FXBConnectionManager(
            database: dbAccessor,
            flexibBLEDevices: spec.devices,
            bleDevices: spec.bleRegisteredDevices
        )
        self.specification = spec
        
        self.saveSpecification()
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try values.decode(UUID.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.createdAt = try values.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try values.decode(Date.self, forKey: .updatedAt)
        
        let basePath = FlexiBLEAppData.createBasePath(name: name, id: id)
        self.basePath = basePath
        self.mainDatabasePath = basePath.appendingPathComponent("main.db")
        self.transactionalDatabasesBasePath = FlexiBLEAppData.createTransactionalDatabasesBasePath(basePath: basePath)
        self.specificationPath = basePath.appendingPathComponent("spec.json")
        
        let data = try Data(contentsOf: specificationPath)
        self.specification = try Data.sharedJSONDecoder.decode(FXBSpec.self, from: data)
        
        self.db = FXBDatabase(
            specification: specification,
            mainDBPath: mainDatabasePath,
            transactionalDBPath: transactionalDatabasesBasePath
        )
        self.dbAccessor = FXBLocalDataAccessor(db: db)
        self.conn = FXBConnectionManager(
            database: dbAccessor,
            flexibBLEDevices: specification.devices,
            bleDevices: specification.bleRegisteredDevices
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.createdAt, forKey: .createdAt)
        try container.encode(self.updatedAt, forKey: .updatedAt)
        saveSpecification()
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, createdAt, updatedAt
    }
    
    public var database: FXBLocalDataAccessor {
        return dbAccessor
    }
    
    public func startScan() {
        if !conn.isScanning {
            conn.scan()
        }
    }
    
    public func stopScan() {
        conn.stopScan()
    }
    
    private func saveSpecification() {
        do {
            let path = self.specificationPath
            let data = try Data.sharedJSONEncoder.encode(self.specification)
            try data.write(to: path)
        } catch {
            pLog.error("unable to save specification: \(error.localizedDescription)")
        }
    }
}
