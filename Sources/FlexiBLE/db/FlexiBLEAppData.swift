//
//  FlexiBLEAppData.swift
//  
//
//  Created by Blaine Rothrock on 1/17/23.
//

import Foundation
import GRDB

class FlexiBLEAppData: Codable {
    static var FlexiBLEBasePath: URL {
        guard let path = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
        ).first?.appendingPathComponent("FlexiBLE") else {
            fatalError("unable to access document directory (create FlexiBLE Documents directory)")
        }
        
        return path
    }
    
    static var FlexiBLEAppDataPath: URL {
        return Self.FlexiBLEBasePath.appendingPathComponent("AppData.json")
    }
    
    private static var _shared: FlexiBLEAppData?
    
    static var shared: FlexiBLEAppData {
        if let inst = Self._shared { return inst }
        
        let path = Self.FlexiBLEAppDataPath
        gLog.info("FlexiBLE Application Data File: \(path.absoluteString)")
        
        if !FileManager.default.fileExists(atPath: path.relativePath) {
            let inst = FlexiBLEAppData()
            _shared = inst
            inst.save()
            return inst
        }
        
        do {
            let data = try Data(contentsOf: path)
            let inst = try Data.sharedJSONDecoder.decode(FlexiBLEAppData.self, from: data)
            
            return inst
        } catch {
            return FlexiBLEAppData()
        }
    }
    
    private var lastProfileId: UUID? = nil
    private(set) var profileIds: [UUID] = []
    
    func add(_ id: UUID, setLast: Bool = true) {
        self.profileIds.append(id)
        if setLast {
            self.lastProfileId = id
        }
        self.save()
    }
    
    func remove(_ id: UUID) {
        do {
            if let dir = try FileManager
                .default.contentsOfDirectory(atPath: Self.FlexiBLEBasePath.relativePath)
                .first(where: { $0.hasSuffix(id.uuidString) }) {
                
                let path = Self.FlexiBLEBasePath.appendingPathComponent(dir)
                try FileManager.default.removeItem(atPath: path.relativePath)
                self.profileIds.removeAll(where: { $0 == id })
                if lastProfileId == id {
                    lastProfileId = nil
                }
            }
            
        } catch {
            return
        }
    }
    
    private func profile(by id: UUID) -> FlexiBLEProfile? {
        do {
            if let dir = try FileManager
                .default.contentsOfDirectory(atPath: Self.FlexiBLEBasePath.relativePath)
                .first(where: { $0.hasSuffix(id.uuidString) }) {
                
                let path = Self.FlexiBLEBasePath
                    .appendingPathComponent(dir, conformingTo: .directory)
                    .appendingPathComponent("profile.json", conformingTo: .json)
                let data = try Data(contentsOf: path)
                return try Data.sharedJSONDecoder.decode(FlexiBLEProfile.self, from: data)
            }
        } catch {
            return nil
        }
        return nil
    }
    
    func lastProfile() -> FlexiBLEProfile? {
        if let id = lastProfileId {
            return profile(by: id)
        }
        return nil
    }
    
    func get(id: UUID, setLast: Bool = true) -> FlexiBLEProfile? {
        if let profile = profile(by: id) {
            if setLast {
                lastProfileId = id
                save()
            }
            return profile
        }
        return nil
    }
    
    func save() {
        do {
            let data = try Data.sharedJSONEncoder.encode(self)
            try data.write(to: Self.FlexiBLEAppDataPath)
        } catch {
            pLog.error("Unable to write FlexiBLE Application Data: \(error.localizedDescription)")
        }
    }
}

public class FlexiBLEProfile: Codable {
    public let id: UUID
    public let name: String
    let specId: String?
    
    public let createdAt: Date
    public let updatedAt: Date
    
    public private(set) var autoConnectDeviceNames: [String] = .init()
    
    init(name: String, spec: FXBSpec) {
        self.id = UUID()
        self.name = name
        self.specId = spec.id
        self.createdAt = Date.now
        self.updatedAt = Date.now
        
        self.save(spec: spec)
        self.save()
    }
    
    public func autoConnect(_ deviceName: String) {
        autoConnectDeviceNames.append(deviceName)
        save()
    }
    
    public func removeAutoConnect(_ deviceName: String) {
        autoConnectDeviceNames.removeAll(where: { $0 == deviceName })
        save()
    }
    
    internal var basePath: URL {
        do {
            let path = FlexiBLEAppData.FlexiBLEBasePath
                .appendingPathComponent("\(name)_\(id)", isDirectory: true)
            
            if !FileManager.default.fileExists(atPath: path.absoluteString){
                do {
                    try FileManager.default.createDirectory(
                        at: path.absoluteURL,
                        withIntermediateDirectories: true
                    )
                } catch {
                    fatalError("Error creating directory at path: \(path.absoluteString)")
                }
            }
            
            return path
        }
    }
    
    internal var mainDatabasePath: URL {
        return self.basePath.appendingPathComponent("main.db")
    }
    
    internal var transactionalDatabasesBasePath: URL {
        let path =  self.basePath.appendingPathComponent(
            "transactional",
            conformingTo: .directory
        )
        
        if !FileManager.default.fileExists(atPath: path.absoluteString) {
            do {
                try FileManager.default.createDirectory(
                    at: path,
                    withIntermediateDirectories: true
                )
            } catch {
                fatalError("Error creating directory at path: \(path.absoluteString)")
            }
        }
        
        return path
    }
    
    internal var specificationPath: URL {
        return self.basePath.appendingPathComponent("spec.json")
    }
    
    public lazy var specification: FXBSpec =  {
        do {
            return try Data.sharedJSONDecoder.decode(FXBSpec.self, from: Data(contentsOf: specificationPath))
        } catch {
            fatalError("FXB Specification Corrupt")
        }
    }()
    
    private func save(spec: FXBSpec) {
        do {
            let path = self.specificationPath
            let data = try Data.sharedJSONEncoder.encode(spec)
            try data.write(to: path)
        } catch {
            pLog.error("unable to save specification: \(error.localizedDescription)")
        }
    }
    
    private func save() {
        do {
            let path = self.basePath.appendingPathComponent("profile.json")
            let data = try Data.sharedJSONEncoder.encode(self)
            try data.write(to: path)
        } catch {
            pLog.error("unable to save profile: \(error.localizedDescription)")
        }
    }
}
