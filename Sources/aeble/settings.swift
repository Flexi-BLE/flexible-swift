//
//  SettingsStore.swift
//  
//
//  Created by blaine on 3/9/22.
//

import Foundation
import GRDB
import Combine


final public class AEBLESettingsStore: ObservableObject {
    internal let dbQueue: DatabaseQueue
    
    internal lazy var peripheralConfig: PeripheralMetadataPayload = {
        if settings.peripheralConfigurationId == "local default" {
            return AEBLESettingsStore.loadLocalPeripheralMetadata()
        } else {
            // TODO: Local from DB or Server
            fatalError("remote load of config not supported")
        }
    }()
    
    internal lazy var settings: Settings = {
        do {
            return try dbQueue.write { db -> Settings in
                return try AEBLESettingsStore.activeSetting(db: db)
            }
        } catch {
            self.updated = false
            return Settings.defaults
        }
    }()
    
    public var updated: Bool = true
    
    
    internal static func activeSetting(db: Database) throws -> Settings {
        let s = try Settings
            .filter(Settings.Columns.isActive == true)
            .fetchOne(db)
        if let s = s { return s }
        else {
            var s = Settings.defaults
            try s.insert(db)
            return s
        }
    }
    
    internal static func loadLocalPeripheralMetadata(
        filename: String="default_peripheral_metadata.json"
    ) -> PeripheralMetadataPayload {
        
        return Bundle.module.decode(PeripheralMetadataPayload.self, from: filename)
    }
    
    internal static func activeSetting(dbQueue: DatabaseQueue) async throws -> Settings {
        return try await dbQueue.write { db -> Settings in
            return try AEBLESettingsStore.activeSetting(db: db)
        }
    }
    
    internal init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func update() async -> Result<Bool, Error> {
        do {
            return try await dbQueue.write { db -> Result<Bool, Error> in
                self.settings.updatedAt = Date.now
                if let _ = self.settings.id {
                    try self.settings.update(db)
                } else {
                    try self.settings.insert(db)
                }
                
                self.updated = true
                return .success(true)
            }
        } catch {
            return .failure(error)
        }
    }
    
    public var deviceId: String {
        set {
            settings.deviceId = newValue
            Task(priority: .background) { await update() }
        }
        get { settings.deviceId }
    }
    
    public var userId: String {
        set {
            settings.userId = newValue
            Task(priority: .background) { await update() }
        }
        get { settings.userId }
    }
    
    public var apiURL: URL {
        set {
            settings.apiURL = newValue
            Task(priority: .background) { await update() }
        }
        get { settings.apiURL }
    }
    
    public var uploadBatch: Int {
        set {
            settings.uploadBatch = newValue
            Task(priority: .background) { await update() }
        }
        get { settings.uploadBatch }
    }
    
    public var useRemoteServer: Bool {
        set {
            settings.useRemoteServer = newValue
            Task(priority: .background) { await update() }
        }
        get { settings.useRemoteServer }
    }
    
    public var peripheralConfigurationType: PeripheralConfigType {
        set {
            settings.peripheralConfigurationId = newValue.id
            Task(priority: .background) { await update() }
        }
        get {
            return PeripheralConfigType.fromId(settings.peripheralConfigurationId)
        }
    }
}

extension AEBLESettingsStore {
    public enum PeripheralConfigType: Equatable {
        case localDefault
        case remote(id: String)
         
        public var id: String {
            switch self {
            case .localDefault:
                return "local default"
            case .remote(let id):
                return id
            }
        }
        
        public static func fromId(_ id: String) -> PeripheralConfigType {
            if id == "local default" {
                return .localDefault
            } else {
                return .remote(id: id)
            }
        }
    }
}
