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
        filename: String="exthub.json"
    ) -> AEDeviceConfig {
        
        return Bundle.module.decode(AEDeviceConfig.self, from: filename)
    }
    
    internal static func activeSetting(dbQueue: DatabaseQueue) async throws -> Settings {
        return try await dbQueue.write { db -> Settings in
            return try AEBLESettingsStore.activeSetting(db: db)
        }
    }
    
    internal init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    internal func peripheralConfig() async -> AEDeviceConfig {
        if settings.peripheralConfigurationId == "local default" {
            return AEBLESettingsStore.loadLocalPeripheralMetadata()
        } else {
            do {
                if let existing = try await dbQueue.write({ db -> AEDeviceConfig? in
                    if let config = try PeripheralConfiguration
                        .filter(PeripheralConfiguration.Columns.externalId == self.settings.peripheralConfigurationId)
                        .fetchOne(db) {
                        return try Data.sharedJSONDecoder.decode(AEDeviceConfig.self, from: config.data)
                    }
                    return nil
                }) {
                    return existing
                }
                
                let res = await AEBLEAPI.getConfig(settings: self.settings)
                switch res {
                case .success(let remote):
                    if let remote = remote {
                        try await dbQueue.write { db in
                            var c = PeripheralConfiguration(
                                externalId: self.settings.peripheralConfigurationId,
                                data: try Data.sharedJSONEncoder.encode(remote),
                                createdAt: remote.createdAt,
                                updatedAt: remote.updatedAt
                            )
                            try c.insert(db)
                        }
                        return remote
                    }
                    else {
                        throw AEBLEError.configError(
                            msg: "no remote configuration found for id \(self.settings.peripheralConfigurationId)"
                        )
                    }
                case .failure(let error):
                    throw error
                }
            } catch {
                settings.peripheralConfigurationId = "local default"
                return AEBLESettingsStore.loadLocalPeripheralMetadata()
            }
        }
    }
    
    public func avaiablePeripheralConfiguration() async -> [String] {
        let res = await AEBLEAPI.getAvaiableConfigs(settings: self.settings)
        switch res {
        case .success(let names): return names
        case .failure(_): return []
        }
    }
    
    public func buckets() async -> [String] {
        let res = await AEBLEAPI.getBuckets(settings: self.settings)
        switch res {
        case .success(let names): return names
        case .failure(_): return []
        }
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
    
    public var sensorDataBucketName: String {
        set {
            settings.sensorDataBucketName = newValue
            Task(priority: .background) { await update() }
        }
        get { settings.sensorDataBucketName }
    }
    
    public var peripheralConfigurationType: PeripheralConfigType {
        set {
            settings.peripheralConfigurationId = newValue.id
            Task(priority: .background) {
                let _ = await peripheralConfig()
                let _ = await update()
            }
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
